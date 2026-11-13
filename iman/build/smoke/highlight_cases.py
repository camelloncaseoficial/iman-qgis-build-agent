# Destaque com a escolha do usuario e a troca em tempo de execucao (fatia 064, A4), rodado pelo proprio QGIS via
# --code (Measure-HighlightCases.ps1), com perfil descartavel. Executa uma lista de passos (IMAN_CASES_STEPS, separados
# por ';'): 'measure' mede; 'theme=<nome>' e 'style=<nome>' abrem Opcoes > Geral, trocam a caixa do tema ou do estilo
# do Qt como o usuario faria e clicam OK ('style=OTHER' escolhe o primeiro estilo diferente do atual). No QGIS 3.44 a
# troca de tema e de estilo so vale ao reabrir (o rotulo de Opcoes diz "reinicio necessario"; o slot
# QgsOptions::uiThemeChanged nao esta ligado a nada): o que muda na hora e so a chave do perfil.
# Cada medida: tema, folha, estilo do Qt, as chaves do perfil, a paleta (Highlight e HighlightedText) e a cor
# desenhada de verdade: o item selecionado de uma lista de teste, medido na imagem.
# Desde a fatia 065 (A5), tambem o fundo das janelas: o papel Window por grupo e o fundo desenhado num dialogo de teste.
import json
import os
from collections import Counter

from qgis.core import QgsApplication, QgsSettings
from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtGui import QColor, QPalette
from qgis.PyQt.QtWidgets import QApplication, QComboBox, QDialog, QDialogButtonBox, QListWidget
from qgis.utils import iface

out_dir = os.environ["IMAN_CASES_OUT"]
steps = [s.strip() for s in os.environ.get("IMAN_CASES_STEPS", "measure").split(";") if s.strip()]
facts = {"steps": steps, "measures": [], "actions": []}


def drawn_highlight():
    """O item selecionado de uma QListWidget de teste, com a paleta e a folha da aplicacao em vigor."""
    widget = QListWidget()
    widget.addItems(["Camada A", "Camada B", "Camada C"])
    widget.resize(240, 120)
    widget.show()
    widget.setCurrentRow(1)
    widget.setFocus()
    QApplication.processEvents()
    image = widget.grab().toImage()
    dpr = image.devicePixelRatio() or 1.0
    rect = widget.visualItemRect(widget.item(1))
    pixels = [image.pixel(x, y)
              for x in range(int(rect.left() * dpr), int((rect.right() + 1) * dpr))
              for y in range(int(rect.top() * dpr), int((rect.bottom() + 1) * dpr))
              if 0 <= x < image.width() and 0 <= y < image.height()]
    widget.close()
    widget.deleteLater()
    if not pixels:
        return None
    return QColor(Counter(pixels).most_common(1)[0][0]).name().upper()


def drawn_window():
    """O fundo de um QDialog de teste, com a paleta e a folha da aplicacao em vigor (fatia 065, A5)."""
    dialog = QDialog()
    dialog.resize(240, 120)
    dialog.show()
    QApplication.processEvents()
    image = dialog.grab().toImage()
    pixels = [image.pixel(x, y) for x in range(0, image.width(), 2) for y in range(0, image.height(), 2)]
    dialog.close()
    dialog.deleteLater()
    if not pixels:
        return None
    return QColor(Counter(pixels).most_common(1)[0][0]).name().upper()


def measure(label):
    settings = QgsSettings()
    palette = QApplication.palette()
    style = QApplication.style()
    base = style.baseStyle() if hasattr(style, "baseStyle") else None
    facts["measures"].append({
        "label": label,
        "themeName": QgsApplication.themeName(),
        "styleSheetLength": len(QApplication.instance().styleSheet()),
        "qtStyle": style.metaObject().className(),
        "qtStyleBase": base.metaObject().className() if base is not None else None,
        "settingUITheme": settings.value("UI/UITheme", None),
        "settingQgisStyle": settings.value("qgis/style", None),
        "palette": {
            "Active": [palette.color(QPalette.Active, QPalette.Highlight).name().upper(),
                       palette.color(QPalette.Active, QPalette.HighlightedText).name().upper()],
            "Inactive": [palette.color(QPalette.Inactive, QPalette.Highlight).name().upper(),
                         palette.color(QPalette.Inactive, QPalette.HighlightedText).name().upper()],
        },
        "drawnHighlight": drawn_highlight(),
        # fatia 065 (A5): o fundo das janelas, na paleta (Window por grupo) e desenhado num dialogo
        "window": {name: palette.color(group, QPalette.Window).name().upper()
                   for name, group in (("Active", QPalette.Active), ("Inactive", QPalette.Inactive), ("Disabled", QPalette.Disabled))},
        "drawnWindow": drawn_window(),
    })


def set_in_options(kind, value):
    dialog = None
    for w in QApplication.topLevelWidgets():
        if w.metaObject().className() == "QgsOptions" and w.isVisible():
            dialog = w
    action = {"kind": kind, "requested": value, "found": dialog is not None}
    if dialog is not None:
        combo = dialog.findChild(QComboBox, "cmbUITheme" if kind == "theme" else "cmbStyle")
        items = [combo.itemText(i) for i in range(combo.count())] if combo else []
        action["items"] = items
        action["before"] = combo.currentText() if combo else None
        if combo is not None:
            if value == "OTHER":
                value = next((i for i in items if i.lower() != combo.currentText().lower()), combo.currentText())
            combo.setCurrentIndex(combo.findText(value))
            QApplication.processEvents()
            action["after"] = combo.currentText()
        # o QgsOptions so salva pelo OK da caixa de botoes (qgsoptions.cpp:186, saveOptions), nao pelo accept()
        boxes = [b for b in dialog.findChildren(QDialogButtonBox) if b.button(QDialogButtonBox.Ok) is not None]
        ok = boxes[0].button(QDialogButtonBox.Ok) if boxes else None
        action["clickedOk"] = ok is not None
        if ok is not None:
            ok.click()
        else:
            dialog.accept()
    facts["actions"].append(action)


def run_step(i):
    if i >= len(steps):
        finish()
        return
    step = steps[i]
    try:
        if step == "measure":
            measure("passo %d" % i)
            QTimer.singleShot(500, lambda: run_step(i + 1))
            return
        kind, value = step.split("=", 1)
        # o dialogo Opcoes e modal: o timer armado antes de abrir troca a caixa e aceita
        QTimer.singleShot(2500, lambda: set_in_options(kind, value))
        iface.showOptionsDialog(iface.mainWindow(), "mOptionsPageGeneral")
    except Exception as err:
        facts.setdefault("errors", {})["passo %d" % i] = repr(err)
    QTimer.singleShot(1500, lambda: run_step(i + 1))


def finish():
    with open(os.path.join(out_dir, "cases.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    iface.actionExit().trigger()


QTimer.singleShot(3000, lambda: run_step(0))
