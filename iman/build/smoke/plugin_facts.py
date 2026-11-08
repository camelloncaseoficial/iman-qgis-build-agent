# Fatos do plugin embarcado (fatia 051), rodado pelo proprio QGIS via --code (Test-PluginBoot.ps1).
# So coleta fatos e grava plugin.json (e as capturas); quem julga e o Test-PluginBoot.ps1, contra a trava.
#   IMAN_PLUGIN_OUT       pasta de saida
#   IMAN_PLUGIN_ID        id da pasta do plugin (da trava)
#   IMAN_PLUGIN_WIZARD    "1": abre o assistente de projeto REURB pelo painel do plugin e cria um projeto em
#                         IMAN_PLUGIN_WORKSPACE (pasta descartavel, criada vazia pelo script de fora)
# O assistente e o do plugin na tag (ui/wizard.py, CreateProjectDialog): os campos sao lidos e preenchidos pelos
# atributos do dialogo; o OK passa pela validacao do proprio plugin.
import json
import os
import sys
import traceback

import qgis.utils
from qgis.core import Qgis, QgsApplication, QgsMessageLog, QgsProject, QgsSettings
from qgis.PyQt.QtCore import QSettings, QTimer
from qgis.PyQt.QtWidgets import QAction, QApplication, QDialog, QDialogButtonBox, QDockWidget, QToolBar
from qgis.utils import iface

out_dir = os.environ["IMAN_PLUGIN_OUT"]
plugin_id = os.environ["IMAN_PLUGIN_ID"]
want_wizard = os.environ.get("IMAN_PLUGIN_WIZARD") == "1"
workspace = os.environ.get("IMAN_PLUGIN_WORKSPACE", "")
result = {"version": Qgis.version(), "errors": {}}
log = []


def on_message(message, tag, level):
    if level >= Qgis.Warning or "python" in (tag or "").lower():
        log.append({"tag": tag, "level": int(level), "message": message[:2000]})


QgsApplication.messageLog().messageReceived.connect(on_message)


def collect_boot():
    settings = QgsSettings()
    user_ini = QSettings(settings.fileName(), QSettings.IniFormat)
    module = sys.modules.get(plugin_id)
    plugin_object = qgis.utils.plugins.get(plugin_id)
    toolbar_name = getattr(type(plugin_object), "TOOLBAR_OBJECT_NAME", None) if plugin_object else None
    toolbar = iface.mainWindow().findChild(QToolBar, toolbar_name) if toolbar_name else None
    result["boot"] = {
        "active_plugins": sorted(qgis.utils.active_plugins),
        "active": plugin_id in qgis.utils.active_plugins,
        "available": plugin_id in qgis.utils.available_plugins,
        "module_file": getattr(module, "__file__", None),
        "module_version": getattr(module, "__version__", None),
        "metadata": {k: qgis.utils.pluginMetadata(plugin_id, k) for k in ("name", "version", "author", "email")},
        "plugin_paths": list(qgis.utils.plugin_paths),
        "sys_plugin_path": getattr(qgis.utils, "sys_plugin_path", None),
        "home_plugin_path": QgsApplication.qgisSettingsDirPath() + "python/plugins",
        "setting_effective": settings.value("PythonPlugins/%s" % plugin_id),
        "setting_in_user_ini": user_ini.contains("PythonPlugins/%s" % plugin_id),
        "setting_user_value": user_ini.value("PythonPlugins/%s" % plugin_id),
        "watchdog_left": user_ini.contains("PythonPlugins/watchDogTimestamp/%s" % plugin_id),
        "user_ini": settings.fileName(),
        "toolbar": {
            "object_name": toolbar_name,
            "found": toolbar is not None,
            "visible": bool(toolbar and toolbar.isVisible()),
            "title": toolbar.windowTitle() if toolbar else None,
            "actions": len(toolbar.actions()) if toolbar else 0,
        },
        "message_bar": [
            {"title": w.title(), "text": w.text()} for w in iface.messageBar().items()
        ],
    }
    # o log ate aqui e o do arranque; o do assistente fica em result["log"], separado
    result["boot"]["log"] = list(log)
    if toolbar is not None and toolbar.isVisible():
        toolbar.grab().save(os.path.join(out_dir, "toolbar.png"))


def find_dialog():
    for w in QApplication.topLevelWidgets():
        if isinstance(w, QDialog) and w.isVisible() and type(w).__name__ == "CreateProjectDialog":
            return w
    return None


def fill_and_accept(attempt=0):
    """Roda com o dialogo modal aberto (no laco do exec_): le o SRC proposto, preenche, captura e confirma."""
    dlg = find_dialog()
    if dlg is None:
        if attempt < 40:
            QTimer.singleShot(250, lambda: fill_and_accept(attempt + 1))
        else:
            result["errors"]["wizard"] = "dialogo CreateProjectDialog nao apareceu"
        return
    wiz = result.setdefault("wizard", {})
    try:
        wiz["opened"] = True
        wiz["title"] = dlg.windowTitle()
        wiz["proposed_crs"] = dlg._crs.crs().authid()
        dlg._name.setText("smoke-051")
        dlg._municipality.setText("Municipio Teste")
        dlg._state.setText("CE")
        dlg._responsible.setText("Responsavel Teste")
        dlg._workspace.setText(workspace)
        dlg.grab().save(os.path.join(out_dir, "wizard.png"))
        box = dlg.findChild(QDialogButtonBox)
        box.button(QDialogButtonBox.Ok).click()
        wiz["accepted"] = dlg.result() == QDialog.Accepted
        wiz["error_label"] = dlg._error_label.text() if dlg._error_label.isVisible() else ""
        if not wiz["accepted"]:
            dlg.reject()
    except Exception:
        result["errors"]["wizard"] = traceback.format_exc()
        dlg.reject()


def open_wizard():
    action = iface.mainWindow().findChild(QAction, "imanReurbToggle")
    if action is None:
        result["errors"]["wizard"] = "acao imanReurbToggle ausente"
        return finish()
    action.trigger()
    dock = None
    for d in iface.mainWindow().findChildren(QDockWidget):
        if type(d).__name__ == "ImanDock":
            dock = d
    if dock is None:
        result["errors"]["wizard"] = "painel ImanDock ausente"
        return finish()
    result.setdefault("wizard", {})["dock_visible"] = dock.isVisible()
    QTimer.singleShot(500, fill_and_accept)
    dock._on_create_clicked()  # modal: volta quando o dialogo fecha
    wait_project(dock, 0)


def wait_project(dock, ticks):
    wiz = result.setdefault("wizard", {})
    gpkgs = [f for f in os.listdir(workspace)] if os.path.isdir(workspace) else []
    gpkgs = [f for f in gpkgs if f.lower().endswith(".gpkg")]
    project = QgsProject.instance()
    if (not gpkgs or project.mapLayers() == {}) and ticks < 120 and wiz.get("accepted"):
        QTimer.singleShot(500, lambda: wait_project(dock, ticks + 1))
        return
    wiz["workspace_files"] = sorted(os.listdir(workspace)) if os.path.isdir(workspace) else []
    wiz["gpkg"] = gpkgs
    wiz["project_crs"] = project.crs().authid()
    wiz["layers"] = sorted(lyr.name() for lyr in project.mapLayers().values())
    wiz["seconds_waited"] = ticks * 0.5
    dock.grab().save(os.path.join(out_dir, "dock.png"))
    finish()


def finish():
    result["log"] = log
    with open(os.path.join(out_dir, "plugin.json"), "w", encoding="utf-8") as fh:
        json.dump(result, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


def start():
    try:
        collect_boot()
    except Exception:
        result["errors"]["boot"] = traceback.format_exc()
    if want_wizard and result.get("boot", {}).get("active"):
        try:
            open_wizard()
        except Exception:
            result["errors"]["wizard"] = traceback.format_exc()
            finish()
    else:
        finish()


QTimer.singleShot(3000, start)
