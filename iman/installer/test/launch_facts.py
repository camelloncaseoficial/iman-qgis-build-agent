# Fatos do produto aberto pelo atalho (Test-Installed.ps1, fatia 047), rodado pelo proprio QGIS via PYQGIS_STARTUP.
# Espera a janela principal, coleta o nome interno e as pastas que o processo usa, o AUMI, o executavel e o runtime
# do Visual C++ carregados, roda uma tarefa que gera uma notificacao do Windows; grava launch-facts.json em
# IMAN_FACTS_OUT e fecha o QGIS.
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
    # tipos explicitos: sem eles o ctypes trunca o pseudo-handle e os HMODULE de 64 bits para int de 32
    kernel32.GetCurrentProcess.restype = wintypes.HANDLE
    psapi.EnumProcessModules.argtypes = [wintypes.HANDLE, ctypes.POINTER(wintypes.HMODULE), wintypes.DWORD, ctypes.POINTER(wintypes.DWORD)]
    kernel32.GetModuleFileNameW.argtypes = [wintypes.HMODULE, wintypes.LPWSTR, wintypes.DWORD]
    version.GetFileVersionInfoSizeW.argtypes = [wintypes.LPCWSTR, ctypes.POINTER(wintypes.DWORD)]
    version.GetFileVersionInfoW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD, ctypes.c_void_p]
    version.VerQueryValueW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR, ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(wintypes.UINT)]
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
        notify(iface)
    except Exception:
        facts["error"] = traceback.format_exc()
        write_facts()
        QTimer.singleShot(4000, iface.actionExit().trigger)


# Notificacao do Windows pelo caminho do proprio QGIS: uma tarefa visivel que dura mais que
# minTaskLengthForSystemNotification (5 s) faz o QgisApp::onTaskCompleteShowNotify chamar showSystemNotification.
# O QgsNative nao tem binding em Python.
def notify(iface):
    import time
    from qgis.core import QgsApplication, QgsTask

    def work(task):
        time.sleep(6)
        return True

    task = QgsTask.fromFunction("Notificacao de teste da fatia 047", work)
    facts["notification_task"] = task.description()
    notify.task = task  # a tarefa precisa viver ate o fim
    # o objeto C++ da tarefa e apagado quando ela termina: o resultado vem pelos sinais
    task.taskCompleted.connect(lambda: facts.__setitem__("notification_task_result", "completed"))
    task.taskTerminated.connect(lambda: facts.__setitem__("notification_task_result", "terminated"))
    QgsApplication.taskManager().addTask(task)

    def finish():
        try:
            # se a notificacao nativa falha, o QGIS cai na barra de mensagens com o mesmo titulo
            items = iface.messageBar().items()
            facts["message_bar_items"] = [getattr(i, "title", lambda: str(i))() for i in items]
        except Exception:
            facts["error_finish"] = traceback.format_exc()
        finally:
            write_facts()
            QTimer.singleShot(3000, iface.actionExit().trigger)

    notify.finish = finish
    QTimer.singleShot(10000, notify.finish)


def collect_facts(iface):
    from qgis.core import QgsApplication

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
    exe = ctypes.create_unicode_buffer(1024)
    ctypes.WinDLL("kernel32").GetModuleFileNameW(None, exe, 1024)
    facts["process_exe"] = exe.value


QTimer.singleShot(2000, collect)
