# Le o icone IDI_ICON1 de dentro de um executavel do Windows e compara as imagens com as de um .ico (A6, fatia 044).
#   python3 pe_icon.py <exe> <ico>   -> JSON com match, as imagens do exe e as do .ico (sha256 de cada uma)
# Le o executavel como dado (LOAD_LIBRARY_AS_DATAFILE): nada dele roda.
import ctypes
import ctypes.wintypes as wt
import hashlib
import json
import struct
import sys

LOAD_LIBRARY_AS_DATAFILE = 0x00000002
LOAD_LIBRARY_AS_IMAGE_RESOURCE = 0x00000020
RT_ICON = 3
RT_GROUP_ICON = 14

k32 = ctypes.WinDLL("kernel32", use_last_error=True)
k32.LoadLibraryExW.restype = wt.HMODULE
k32.LoadLibraryExW.argtypes = [wt.LPCWSTR, wt.HANDLE, wt.DWORD]
k32.FindResourceW.restype = wt.HANDLE
k32.FindResourceW.argtypes = [wt.HMODULE, ctypes.c_void_p, ctypes.c_void_p]
k32.LoadResource.restype = wt.HANDLE
k32.LoadResource.argtypes = [wt.HMODULE, wt.HANDLE]
k32.LockResource.restype = ctypes.c_void_p
k32.LockResource.argtypes = [wt.HANDLE]
k32.SizeofResource.restype = wt.DWORD
k32.SizeofResource.argtypes = [wt.HMODULE, wt.HANDLE]
k32.FreeLibrary.argtypes = [wt.HMODULE]
ENUMRESNAMEPROC = ctypes.WINFUNCTYPE(wt.BOOL, wt.HMODULE, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p)
k32.EnumResourceNamesW.argtypes = [wt.HMODULE, ctypes.c_void_p, ENUMRESNAMEPROC, ctypes.c_void_p]


def _resource(module, name, rtype):
    res = k32.FindResourceW(module, name, rtype)
    if not res:
        return None
    data = k32.LockResource(k32.LoadResource(module, res))
    return ctypes.string_at(data, k32.SizeofResource(module, res))


def _group_names(module):
    names = []

    def cb(_module, _type, name, _param):
        names.append(name if name < 0x10000 else ctypes.wstring_at(name))
        return True

    k32.EnumResourceNamesW(module, RT_GROUP_ICON, ENUMRESNAMEPROC(cb), None)
    return names


def exe_icon_images(path):
    module = k32.LoadLibraryExW(path, None, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE)
    if not module:
        raise SystemExit("nao abriu %s (erro %d)" % (path, ctypes.get_last_error()))
    try:
        names = _group_names(module)
        name = "IDI_ICON1" if "IDI_ICON1" in names else (names[0] if names else None)
        if name is None:
            return None, []
        buf = ctypes.create_unicode_buffer(name) if isinstance(name, str) else None
        group = _resource(module, ctypes.cast(buf, ctypes.c_void_p) if buf else name, RT_GROUP_ICON)
        _, _, count = struct.unpack_from("<HHH", group, 0)
        images = []
        for i in range(count):
            w, h, _, _, _, bits, size, nid = struct.unpack_from("<BBBBHHIH", group, 6 + 14 * i)
            data = _resource(module, nid, RT_ICON)
            images.append({"w": w or 256, "h": h or 256, "bits": bits, "sha256": hashlib.sha256(data).hexdigest()})
        return str(name), images
    finally:
        k32.FreeLibrary(module)


def ico_images(path):
    with open(path, "rb") as fh:
        data = fh.read()
    _, _, count = struct.unpack_from("<HHH", data, 0)
    images = []
    for i in range(count):
        w, h, _, _, _, bits, size, offset = struct.unpack_from("<BBBBHHII", data, 6 + 16 * i)
        chunk = data[offset:offset + size]
        images.append({"w": w or 256, "h": h or 256, "bits": bits, "sha256": hashlib.sha256(chunk).hexdigest()})
    return images


def main(argv):
    name, exe_images = exe_icon_images(argv[0])
    ico = ico_images(argv[1])
    match = bool(exe_images) and sorted(i["sha256"] for i in exe_images) == sorted(i["sha256"] for i in ico)
    print(json.dumps({"group": name, "match": match, "exe": exe_images, "ico": ico}, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
