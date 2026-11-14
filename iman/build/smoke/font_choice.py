# Fonte da interface com a escolha do usuario (fatia 067, A2), rodado pelo proprio QGIS via --code
# (Measure-FontChoice.ps1), com perfil descartavel que passa de uma abertura para a outra. Executa uma lista de passos
# (IMAN_FONT_STEPS, separados por ';'):
#   measure          a fonte da aplicacao e a do menu (familia, tamanho, o arquivo que desenha: nomes 1 e 5 da tabela
#                    name pelo QRawFont), as chaves /app/fontFamily, /app/fontPointSize e UI/UITheme do perfil;
#   options          abre Opcoes > Geral, le o que o usuario ve no quadro da fonte ("Qt padrao" ou a outra, a caixa e
#                    o tamanho) e captura a pagina; cancela;
#   font=<familia>   em Opcoes > Geral marca a outra fonte, escolhe a familia na caixa e clica OK, como o usuario;
#   font=DEFAULT     em Opcoes > Geral marca "Qt padrao" e clica OK (o "restaurar padrao" do briefing);
#   theme=<nome>     em Opcoes > Geral troca o tema da interface e clica OK.
# O QgsOptions so salva pelo OK da caixa de botoes (qgsoptions.cpp, saveOptions); fonte e tema valem ao reabrir.
import json
import os

from qgis.core import QgsSettings
from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtGui import QFont, QFontInfo, QRawFont
from qgis.PyQt.QtWidgets import (
    QAbstractSpinBox,
    QApplication,
    QComboBox,
    QDialogButtonBox,
    QFontComboBox,
    QRadioButton,
    QStackedWidget,
    QWidget,
)
from qgis.utils import iface

out_dir = os.environ["IMAN_FONT_OUT"]
steps = [s.strip() for s in os.environ.get("IMAN_FONT_STEPS", "measure").split(";") if s.strip()]
facts = {"steps": steps, "measures": [], "actions": [], "options": []}


def file_names(font):
    try:
        data = bytes(QRawFont.fromFont(font).fontTable("name"))
        count, storage = int.from_bytes(data[2:4], "big"), int.from_bytes(data[4:6], "big")
        names = {}
        for i in range(count):
            rec = [int.from_bytes(data[6 + 12 * i + j: 8 + 12 * i + j], "big") for j in range(0, 12, 2)]
            if rec[0] == 3 and rec[2] == 0x409 and rec[3] in (1, 5):
                names[rec[3]] = data[storage + rec[5]: storage + rec[5] + rec[4]].decode("utf-16-be", "replace")
        return {"family": names.get(1), "version": names.get(5)}
    except Exception as err:
        return {"error": repr(err)}


def font_fact(font):
    info = QFontInfo(font)
    return {"family": font.family(), "pointSizeF": font.pointSizeF(), "resolvedFamily": info.family(), "file": file_names(font)}


def measure(label):
    settings = QgsSettings()
    facts["measures"].append({
        "label": label,
        "app": font_fact(QApplication.font()),
        "menu": font_fact(QApplication.font("QMenu")),
        "statusBar": font_fact(QApplication.font("QStatusBar")),
        "appFontFamily": settings.value("/app/fontFamily", None),
        "appFontPointSize": settings.value("/app/fontPointSize", None),
        "uiTheme": settings.value("UI/UITheme", None),
        "styleSheetLength": len(QApplication.instance().styleSheet()),
    })


def options_dialog():
    for w in QApplication.topLevelWidgets():
        if w.metaObject().className() == "QgsOptions" and w.isVisible():
            return w
    return None


def show_general(dialog):
    stack = dialog.findChild(QStackedWidget, "mOptionsStackedWidget")
    page = dialog.findChild(QWidget, "mOptionsPageGeneral")
    while page is not None and page.parent() is not stack:
        page = page.parent()
    if stack is not None and page is not None:
        stack.setCurrentWidget(page)
    dialog.resize(1100, 760)
    QApplication.processEvents()


def read_options(n):
    dialog = options_dialog()
    fact = {"found": dialog is not None}
    if dialog is not None:
        show_general(dialog)
        qt = dialog.findChild(QRadioButton, "mFontFamilyRadioQt")
        custom = dialog.findChild(QRadioButton, "mFontFamilyRadioCustom")
        combo = dialog.findChild(QFontComboBox, "mFontFamilyComboBox")
        spins = [s for s in dialog.findChildren(QAbstractSpinBox) if s.objectName() == "spinFontSize"]
        fact.update({
            "qtDefaultChecked": qt.isChecked() if qt else None,
            "customChecked": custom.isChecked() if custom else None,
            "combo": combo.currentText() if combo else None,
            "comboEnabled": combo.isEnabled() if combo else None,
            "size": spins[0].text() if spins else None,
        })
        name = "opcoes-geral-%d.png" % n
        dialog.grab().save(os.path.join(out_dir, name))
        fact["capture"] = name
        dialog.reject()
    facts["options"].append(fact)


def set_in_options(kind, value):
    dialog = options_dialog()
    action = {"kind": kind, "requested": value, "found": dialog is not None}
    if dialog is not None:
        show_general(dialog)
        if kind == "font":
            qt = dialog.findChild(QRadioButton, "mFontFamilyRadioQt")
            custom = dialog.findChild(QRadioButton, "mFontFamilyRadioCustom")
            combo = dialog.findChild(QFontComboBox, "mFontFamilyComboBox")
            if value == "DEFAULT":
                qt.setChecked(True)
            else:
                custom.setChecked(True)
                combo.setCurrentFont(QFont(value))
            QApplication.processEvents()
            action["after"] = {"qtDefaultChecked": qt.isChecked(), "combo": combo.currentText()}
        else:
            combo = dialog.findChild(QComboBox, "cmbUITheme")
            combo.setCurrentIndex(combo.findText(value))
            QApplication.processEvents()
            action["after"] = combo.currentText()
        boxes = [b for b in dialog.findChildren(QDialogButtonBox) if b.button(QDialogButtonBox.Ok) is not None]
        ok = boxes[0].button(QDialogButtonBox.Ok) if boxes else None
        action["clickedOk"] = ok is not None
        if ok is not None:
            ok.click()
        else:
            dialog.accept()
        QApplication.processEvents()
        settings = QgsSettings()
        action["saved"] = {"appFontFamily": settings.value("/app/fontFamily", None), "uiTheme": settings.value("UI/UITheme", None)}
    facts["actions"].append(action)


def run_step(i):
    if i >= len(steps):
        finish()
        return
    step = steps[i]
    try:
        if step == "measure":
            measure("passo %d" % i)
        elif step == "options":
            QTimer.singleShot(2500, lambda: read_options(i))
            iface.showOptionsDialog(iface.mainWindow(), "mOptionsPageGeneral")
        else:
            kind, value = step.split("=", 1)
            QTimer.singleShot(2500, lambda: set_in_options(kind, value))
            iface.showOptionsDialog(iface.mainWindow(), "mOptionsPageGeneral")
    except Exception as err:
        facts.setdefault("errors", {})["passo %d" % i] = repr(err)
    QTimer.singleShot(1000, lambda: run_step(i + 1))


def finish():
    with open(os.path.join(out_dir, "choice.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    iface.actionExit().trigger()


QTimer.singleShot(3000, lambda: run_step(0))
