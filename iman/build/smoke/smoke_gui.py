# Smoke de GUI, rodado pelo proprio QGIS via --code (Invoke-Smoke.ps1).
# Abre o .qgz, espera o canvas, grava gui.json e as capturas e fecha o QGIS.
import json
import os

from qgis.core import Qgis, QgsProject
from qgis.PyQt.QtCore import QTimer
from qgis.utils import iface

out_dir = os.environ["IMAN_SMOKE_OUT"]
project_path = os.environ["IMAN_SMOKE_PROJECT"]
result = {"version": Qgis.version(), "dev_version": Qgis.devVersion()}


def load_project():
    project = QgsProject.instance()
    result["project_read"] = project.read(project_path)
    result["layers"] = [
        {
            "name": lyr.name(),
            "valid": lyr.isValid(),
            "features": lyr.featureCount(),
            "crs": lyr.crs().authid(),
        }
        for lyr in project.mapLayers().values()
    ]
    iface.mapCanvas().zoomToFullExtent()
    iface.mapCanvas().refreshAllLayers()
    QTimer.singleShot(5000, capture_and_exit)


def capture_and_exit():
    window = iface.mainWindow()
    result["window_visible"] = window.isVisible()
    result["window_title"] = window.windowTitle()
    result["window_size"] = [window.width(), window.height()]
    window.grab().save(os.path.join(out_dir, "gui.png"))
    iface.mapCanvas().saveAsImage(os.path.join(out_dir, "canvas.png"))
    with open(os.path.join(out_dir, "gui.json"), "w", encoding="utf-8") as fh:
        json.dump(result, fh, indent=2)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


QTimer.singleShot(3000, load_project)
