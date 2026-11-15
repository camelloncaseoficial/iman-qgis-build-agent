# Splash real (fatia 069, A6), rodado pelo proprio QGIS via --code (Measure-SplashFont.ps1), sem --nologo. O --code
# roda (main.cpp, QgsPythonRunner::runFile) antes do splash->finish: o QSplashScreen do main.cpp ainda existe. Grava em
# splash.json a fonte com que ele escreve a mensagem (a fonte do widget, que o QPainter do QSplashScreen usa), a
# familia resolvida, o arquivo que desenha (nomes 1 e 5 da tabela name do QRawFont: a Open Sans embarcada e a 3.003;
# a instalada no Windows desta bancada e a 1.10) e a mensagem; e o splash como esta (grab) com uma mensagem de
# teste escrita pelo mesmo showMessage do QgisApp, para ver a letra. So coleta; nada e corrigido. Fecha o QGIS no fim.
import json
import os

from qgis.PyQt.QtCore import Qt, QTimer
from qgis.PyQt.QtGui import QColor, QFontInfo, QRawFont
from qgis.PyQt.QtWidgets import QApplication, QSplashScreen
from qgis.utils import iface

out_dir = os.environ["IMAN_SPLASH_OUT"]
facts = {"errors": []}


def name_record(font, name_id):
    try:
        data = bytes(QRawFont.fromFont(font).fontTable("name"))
        count, storage = int.from_bytes(data[2:4], "big"), int.from_bytes(data[4:6], "big")
        for i in range(count):
            rec = [int.from_bytes(data[6 + 12 * i + j: 8 + 12 * i + j], "big") for j in range(0, 12, 2)]
            if rec[0] == 3 and rec[2] == 0x409 and rec[3] == name_id:
                return data[storage + rec[5]: storage + rec[5] + rec[4]].decode("utf-16-be", "replace")
    except Exception as err:  # noqa: BLE001
        facts["errors"].append("name %d: %s" % (name_id, err))
    return None


def font_facts(font):
    info = QFontInfo(font)
    return {"family": font.family(), "pointSizeF": font.pointSizeF(), "pixelSize": font.pixelSize(),
            "weight": font.weight(), "resolvedFamily": info.family(), "resolvedStyle": info.styleName(),
            "resolvedPixelSize": info.pixelSize(), "fileFamily": name_record(font, 1),
            "fileVersion": name_record(font, 5)}


def collect():
    try:
        splashes = [w for w in QApplication.topLevelWidgets() if isinstance(w, QSplashScreen)]
        facts["splashCount"] = len(splashes)
        facts["appFont"] = font_facts(QApplication.font())
        if splashes:
            s = splashes[0]
            facts["visible"] = s.isVisible()
            facts["size"] = [s.width(), s.height()]
            facts["devicePixelRatio"] = s.devicePixelRatioF()
            facts["message"] = s.message()
            facts["font"] = font_facts(s.font())
            s.grab().save(os.path.join(out_dir, "a6-splash-mensagem-do-qgis.png"))
            # a mensagem de teste, com acentos e algarismos, no lugar e na cor (#FFFFFF, o splash_text_color) do QgisApp
            test = "Carregando complementos... Restaurando a interface. QGIS 0123456789 ÁÇÃÉÕ"
            s.showMessage(test, Qt.AlignHCenter | Qt.AlignBottom, QColor("#FFFFFF"))
            QApplication.processEvents()
            s.grab().save(os.path.join(out_dir, "a6-splash-mensagem-de-teste.png"))
            facts["testMessage"] = test
    except Exception as err:  # noqa: BLE001
        facts["errors"].append(repr(err))
    with open(os.path.join(out_dir, "splash.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, ensure_ascii=False, indent=2)
    QTimer.singleShot(1500, iface.actionExit().trigger)


collect()
