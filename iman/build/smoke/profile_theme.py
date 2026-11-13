# Tema, folha de estilo e estilo do Qt que um perfil faz o QGIS usar (fatia 063, A1 e A3), rodado pelo proprio QGIS via
# --code (Measure-ProfileTheme.ps1). So coleta fatos e sai; quem julga e o laudo. Nada e gravado no perfil por este
# script: o que o .ini tiver depois da rodada e o que o proprio QGIS gravou.
import json
import os

from qgis.core import QgsApplication, QgsSettings
from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtWidgets import QApplication, QStyleFactory
from qgis.utils import iface

out_dir = os.environ["IMAN_PROFILE_OUT"]
facts = {}


def collect():
    try:
        settings = QgsSettings()
        style = QApplication.style()
        base = style.baseStyle() if hasattr(style, "baseStyle") else None
        facts.update({
            "themeName": QgsApplication.themeName(),
            "styleSheetLength": len(QApplication.instance().styleSheet()),
            "qtStyle": style.metaObject().className(),
            "qtStyleBase": base.metaObject().className() if base is not None else None,
            "qtStyleBaseName": base.objectName() if base is not None else None,
            "qtStyleKeys": QStyleFactory.keys(),
            "uiThemes": sorted(QgsApplication.uiThemes().keys()),
            "settingUITheme": settings.value("UI/UITheme", None),
            "settingQgisStyle": settings.value("qgis/style", None),
        })
    except Exception as err:
        facts["error"] = repr(err)
    with open(os.path.join(out_dir, "profile.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    iface.actionExit().trigger()


QTimer.singleShot(3000, collect)
