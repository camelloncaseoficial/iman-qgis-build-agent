# Fatos do produto aberto pelo atalho (Test-Installed.ps1, fatia 047), rodado pelo proprio QGIS via PYQGIS_STARTUP.
# Espera a janela principal, coleta o nome interno e as pastas que o processo usa, o AUMI, o runtime do Visual C++
# carregado e o resultado de uma notificacao do Windows; grava launch-facts.json em IMAN_FACTS_OUT e fecha o QGIS.
# So coleta fatos: quem decide o que passa e o Test-Installed.ps1.
# O PYQGIS_STARTUP roda logo depois do Py_Initialize, antes de o pacote qgis estar no sys.path: aqui so o PyQt5;
# o qgis e importado dentro de collect(), com a janela ja aberta.
import ctypes
import json
import os
import traceback
from ctypes import wintypes

from PyQt5.QtCore import QSettings, QStandardPaths, QTimer

out_dir = os.environ["IMAN_FACTS_OUT"]
facts = {"pid": os.getpid()}


def loaded_vc_runtime():
    psapi = ctypes.WinDLL("psapi")
    kernel32 = ctypes.WinDLL("kernel32")
    version = ctypes.WinDLL("version")
    proc = kernel32.GetCurrentProcess()
    mods = (wintypes.HMODULE * 2048)()
    needed = wintypes.DWORD()
    psapi.EnumProcessModules(proc, mods, ctypes.sizeof(mods), ctypes.byref(needed))
    result = []
    for i in range(needed.value // ctypes.sizeof(wintypes.HMODULE)):
        buf = ctypes.create_unicode_buffer(1024)
        kernel32.GetModuleFileNameW(mods[i], buf, 1024)
        name = os.path.basename(buf.value).lower()
        if not (name.startswith("msvcp140") or name.startswith("vcruntime140") or name.startswith("concrt140")):
            continue
        size = version.GetFileVersionInfoSizeW(buf.value, None)
        data = ctypes.create_string_buffer(size)
        version.GetFileVersionInfoW(buf.value, 0, size, data)
        ptr = ctypes.c_void_p()
        length = wintypes.UINT()
        version.VerQueryValueW(data, "\\", ctypes.byref(ptr), ctypes.byref(length))
        ffi = ctypes.cast(ptr, ctypes.POINTER(wintypes.DWORD * 13)).contents
        ver = "%d.%d.%d.%d" % (ffi[2] >> 16, ffi[2] & 0xFFFF, ffi[3] >> 16, ffi[3] & 0xFFFF)
        result.append({"module": buf.value, "version": ver})
    return result


def process_aumi():
    shell32 = ctypes.WinDLL("shell32")
    ole32 = ctypes.WinDLL("ole32")
    ptr = ctypes.c_wchar_p()
    hr = shell32.GetCurrentProcessExplicitAppUserModelID(ctypes.byref(ptr))
    if hr != 0:
        return None
    value = ptr.value
    ole32.CoTaskMemFree(ptr)
    return value


def write_facts():
    with open(os.path.join(out_dir, "launch-facts.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, ensure_ascii=False, indent=2)


def collect():
    try:
        from qgis.utils import iface
    except ImportError:
        QTimer.singleShot(1000, collect)
        return
    if iface is None or not iface.mainWindow().isVisible():
        QTimer.singleShot(1000, collect)
        return
    try:
        collect_facts(iface)
    except Exception:
        facts["error"] = traceback.format_exc()
        write_facts()
    QTimer.singleShot(4000, iface.actionExit().trigger)


def collect_facts(iface):
    from qgis.core import QgsApplication
    from qgis.gui import QgsGui, QgsNative

    facts["organization"] = QgsApplication.organizationName()
    facts["organization_domain"] = QgsApplication.organizationDomain()
    facts["application"] = QgsApplication.applicationName()
    facts["settings_dir"] = QgsApplication.qgisSettingsDirPath()
    facts["native_settings"] = QSettings().fileName()
    facts["cache_location"] = QStandardPaths.writableLocation(QStandardPaths.CacheLocation)
    facts["app_local_data"] = QStandardPaths.writableLocation(QStandardPaths.AppLocalDataLocation)
    facts["aumi"] = process_aumi()
    facts["vc_runtime"] = loaded_vc_runtime()
    facts["window_title"] = iface.mainWindow().windowTitle()
    native = QgsGui.nativePlatformInterface()
    facts["native_notifications"] = bool(native.capabilities() & QgsNative.NativeDesktopNotifications)
    settings = QgsNative.NotificationSettings()
    settings.transient = True
    result = native.showDesktopNotification("IMAN Terra", "Notificacao de teste da fatia 047", settings)
    facts["notification_successful"] = bool(result.successful)
    write_facts()


QTimer.singleShot(2000, collect)
