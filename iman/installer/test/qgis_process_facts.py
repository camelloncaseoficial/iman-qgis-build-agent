# Runtime do Visual C++ carregado pelo qgis_process instalado (patch de 2026-10-29 da fatia 047, P4), rodado pelo
# proprio qgis_process via PYQGIS_STARTUP. O metodo e o do launch_facts.py (EnumProcessModules + VerQueryValue de
# dentro do processo), mas numa thread em segundo plano: o qgis_process nao chama Py_Finalize (um atexit nao rodaria)
# e nao tem laco de eventos. A thread lista os modulos a cada 50 ms ate o processo sair, guarda cada modulo do VC++
# na primeira vez que o ve e regrava IMAN_FACTS_FILE; o qgis_process solta o GIL depois do Py_Initialize
# (PyEval_SaveThread), entao ela roda
# enquanto o C++ trabalha. Limite: um modulo carregado nos ultimos 50 ms antes de o processo sair nao entra (o
# last_poll_epoch da ultima volta, contra o fim do processo medido de fora, diz o quanto ficou de fora).
# So coleta fatos: quem decide o que passa e o Test-QgisProcessRuntime.ps1.
import ctypes
import json
import os
import threading
import time
from ctypes import wintypes

out_file = os.environ["IMAN_FACTS_FILE"]
psapi = ctypes.WinDLL("psapi")
kernel32 = ctypes.WinDLL("kernel32")
version = ctypes.WinDLL("version")
# tipos explicitos: sem eles o ctypes trunca o pseudo-handle e os HMODULE de 64 bits para int de 32
kernel32.GetCurrentProcess.restype = wintypes.HANDLE
psapi.EnumProcessModules.argtypes = [wintypes.HANDLE, ctypes.POINTER(wintypes.HMODULE), wintypes.DWORD, ctypes.POINTER(wintypes.DWORD)]
kernel32.GetModuleFileNameW.argtypes = [wintypes.HMODULE, wintypes.LPWSTR, wintypes.DWORD]
version.GetFileVersionInfoSizeW.argtypes = [wintypes.LPCWSTR, ctypes.POINTER(wintypes.DWORD)]
version.GetFileVersionInfoW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD, ctypes.c_void_p]
version.VerQueryValueW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR, ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(wintypes.UINT)]

start = time.monotonic()
facts = {"pid": os.getpid(), "polls": 0, "modules_total": 0, "vc_runtime": []}


def module_paths():
    mods = (wintypes.HMODULE * 4096)()
    needed = wintypes.DWORD()
    psapi.EnumProcessModules(kernel32.GetCurrentProcess(), mods, ctypes.sizeof(mods), ctypes.byref(needed))
    paths = []
    for i in range(min(needed.value // ctypes.sizeof(wintypes.HMODULE), 4096)):
        buf = ctypes.create_unicode_buffer(1024)
        kernel32.GetModuleFileNameW(mods[i], buf, 1024)
        paths.append(buf.value)
    return paths


def file_version(path):
    size = version.GetFileVersionInfoSizeW(path, None)
    data = ctypes.create_string_buffer(size)
    version.GetFileVersionInfoW(path, 0, size, data)
    ptr = ctypes.c_void_p()
    length = wintypes.UINT()
    version.VerQueryValueW(data, "\\", ctypes.byref(ptr), ctypes.byref(length))
    ffi = ctypes.cast(ptr, ctypes.POINTER(wintypes.DWORD * 13)).contents
    return "%d.%d.%d.%d" % (ffi[2] >> 16, ffi[2] & 0xFFFF, ffi[3] >> 16, ffi[3] & 0xFFFF)


def is_vc_runtime(path):
    name = os.path.basename(path).lower()
    return name.startswith("msvcp140") or name.startswith("vcruntime140") or name.startswith("concrt140")


def write_facts():
    tmp = out_file + ".part"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(facts, fh, ensure_ascii=False, indent=2)
    os.replace(tmp, out_file)


def poll():
    seen = set()
    while True:
        paths = module_paths()
        facts["polls"] += 1
        facts["modules_total"] = len(paths)
        new = [p for p in paths if is_vc_runtime(p) and p.lower() not in seen]
        for p in new:
            seen.add(p.lower())
            facts["vc_runtime"].append({"module": p, "version": file_version(p), "seen_at_s": round(time.monotonic() - start, 3)})
        # regravado a cada volta: last_poll_s diz ate quando a lista cobre o processo
        facts["last_poll_s"] = round(time.monotonic() - start, 3)
        facts["last_poll_epoch"] = time.time()
        write_facts()
        time.sleep(0.05)


threading.Thread(target=poll, name="iman-vc-runtime", daemon=True).start()
