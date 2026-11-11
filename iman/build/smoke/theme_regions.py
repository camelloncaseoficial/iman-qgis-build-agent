# Medidas das regioes do tema que o smoke do sponsor de 2026-11-11 reprovou (fatia 058, B1 a B5), rodado pelo proprio
# QGIS via --code (Measure-ThemeRegions.ps1), no build, no QGIS oficial e na arvore instalada, sempre com perfil
# descartavel. So coleta fatos e capturas, no formato do D2 da fatia 049 (largura util, largura do texto, cabe ou nao):
# quem da o veredito e o Measure-ThemeRegions.ps1. Cada passo que quebra vira fato em "errors", nao derruba a rodada.
import json
import os

from qgis.core import QgsApplication, QgsPointXY, QgsProject
from qgis.PyQt.QtCore import QPoint, QRect, QTimer
from qgis.PyQt.QtGui import QColor, QFont, QFontMetrics
from qgis.PyQt.QtWidgets import (
    QAbstractSpinBox,
    QApplication,
    QComboBox,
    QDockWidget,
    QLineEdit,
    QStatusBar,
    QStyle,
    QStyleOptionFrame,
    QTabBar,
    QToolBar,
    QToolButton,
    QWidget,
)
from qgis.utils import iface

out_dir = os.environ["IMAN_REGIONS_OUT"]
project_path = os.environ.get("IMAN_REGIONS_PROJECT", "")
facts = {"captures": {}}
COORDINATE = QgsPointXY(555519.9, 9585490.5)
ROTATION = 359.9
ALGORITHM = "native:buffer"
state = {}


def save(widget, name):
    if widget is not None:
        widget.grab().save(os.path.join(out_dir, name))
        facts["captures"][name] = [widget.width(), widget.height()]


def run(step):
    try:
        step()
    except Exception as err:
        facts.setdefault("errors", {})[step.__name__] = repr(err)


def rgb(color):
    return "#%02X%02X%02X" % (color.red(), color.green(), color.blue())


def distance(a, b):
    return abs(a.red() - b.red()) + abs(a.green() - b.green()) + abs(a.blue() - b.blue())


def line_edit_room(edit):
    """Area util do texto de um QLineEdit (a mesma conta do D2 da 049) e o que o texto precisa, nas duas direcoes."""
    option = QStyleOptionFrame()
    edit.initStyleOption(option)
    contents = edit.style().subElementRect(QStyle.SE_LineEditContents, option, edit)
    margins = edit.textMargins()
    metrics = edit.fontMetrics()
    text = edit.text()
    # QLineEdit reserva 2 px de cada lado dentro da area de conteudo (QLineEditPrivate::horizontalMargin)
    available = contents.width() - margins.left() - margins.right() - 4
    needed = metrics.horizontalAdvance(text)
    available_height = contents.height() - margins.top() - margins.bottom()
    return {
        "text": text,
        "width": edit.width(),
        "height": edit.height(),
        "contentsWidth": contents.width(),
        "contentsHeight": contents.height(),
        "available": available,
        "needed": needed,
        "fitsWidth": needed <= available,
        "availableHeight": available_height,
        "textHeight": metrics.height(),
        "fitsHeight": metrics.height() <= available_height,
    }


def spin_room(spin):
    info = line_edit_room(spin.lineEdit())
    info.update({
        "class": spin.metaObject().className(),
        "objectName": spin.objectName(),
        "outerWidth": spin.width(),
        "outerHeight": spin.height(),
        "minimumWidth": spin.minimumWidth(),
        "maximumWidth": spin.maximumWidth(),
        "lineEditX": spin.lineEdit().x(),
    })
    return info


def border_contrast(widget):
    """Cor do anel de 1 px do widget contra o fundo logo fora dele, lidos da janela renderizada (B3 e B4).

    O grab() do proprio widget nao serve: um botao de fundo transparente sai sobre preto. Le-se o recorte da janela,
    com 3 px de margem, em pixels logicos (a captura sai na escala do Windows e e reduzida a escala 1)."""
    top = widget.window()
    origin = widget.mapTo(top, QPoint(0, 0))
    w, h = widget.width(), widget.height()
    if w < 4 or h < 4:
        return None
    pixmap = top.grab(QRect(origin.x() - 3, origin.y() - 3, w + 6, h + 6))
    image = pixmap.toImage().scaled(w + 6, h + 6)
    px = lambda x, y: QColor(image.pixel(x + 3, y + 3))
    background = px(-2, h // 2)
    ring = [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]
    visible = sum(1 for (x, y) in ring if distance(px(x, y), background) > 30)
    left = px(0, h // 2)
    return {
        "size": [w, h],
        "background": rgb(background),
        "borderLeftMiddle": rgb(left),
        "borderTopMiddle": rgb(px(w // 2, 0)),
        "contrastLeft": distance(left, background),
        "ringVisible": visible,
        "ringPixels": len(ring),
    }


def step_load_project():
    if project_path:
        facts["projectRead"] = QgsProject.instance().read(project_path)
        iface.mapCanvas().zoomToFullExtent()
    window = iface.mainWindow()
    window.showNormal()
    window.resize(1536, 960)
    # o Navegador lista as unidades da maquina (com nome e e-mail de conta): fora das capturas do laudo publico
    browser = window.findChild(QDockWidget, "Browser")
    if browser is not None:
        browser.hide()
    QApplication.processEvents()
    iface.mapCanvas().setRotation(ROTATION)
    iface.mapCanvas().refresh()
    iface.mapCanvas().xyCoordinates.emit(COORDINATE)


def step_status_bar():
    # B1: rotacao (359,9), escala e lupa, cada uma com a conta do D2
    status = iface.mainWindow().findChild(QStatusBar)
    info = {"rotationValue": iface.mapCanvas().rotation()}
    rotation = status.findChild(QAbstractSpinBox, "mRotationEdit")
    info["rotation"] = spin_room(rotation) if rotation is not None else None
    scale_widget = status.findChild(QWidget, "mScaleWidget")
    combo = scale_widget.findChild(QComboBox) if scale_widget is not None else None
    if combo is not None and combo.lineEdit() is not None:
        scale = line_edit_room(combo.lineEdit())
        scale.update({"class": combo.metaObject().className(), "outerWidth": combo.width(), "outerHeight": combo.height(),
                      "minimumWidth": combo.minimumWidth(), "maximumWidth": combo.maximumWidth()})
        info["scale"] = scale
    magnifier = status.findChild(QWidget, "mMagnifierWidget")
    spin = magnifier.findChild(QAbstractSpinBox) if magnifier is not None else None
    info["magnifier"] = spin_room(spin) if spin is not None else None
    facts["statusBar"] = info
    save(status, "b1-barra-de-status.png")
    # recorte do trecho escala, lupa e rotacao
    widgets = [w for w in (scale_widget, magnifier, rotation) if w is not None]
    if widgets:
        left = min(w.mapTo(status, QPoint(0, 0)).x() for w in widgets) - 4
        right = max(w.mapTo(status, QPoint(w.width(), 0)).x() for w in widgets) + 4
        crop = status.grab().copy(QRect(max(left, 0), 0, right - max(left, 0), status.height()))
        crop.save(os.path.join(out_dir, "b1-escala-lupa-rotacao.png"))
        facts["captures"]["b1-escala-lupa-rotacao.png"] = [crop.width(), crop.height()]


def tool_buttons(toolbar):
    buttons = [b for b in toolbar.findChildren(QToolButton) if b.isVisible() and b.parentWidget() is toolbar]
    buttons.sort(key=lambda b: (b.y(), b.x()))
    geometry = [[b.x(), b.y(), b.width(), b.height()] for b in buttons]
    steps = [buttons[i + 1].x() - buttons[i].x() for i in range(len(buttons) - 1) if buttons[i + 1].y() == buttons[i].y()]
    return {
        "objectName": toolbar.objectName(),
        "height": toolbar.height(),
        "iconSize": [toolbar.iconSize().width(), toolbar.iconSize().height()],
        "layoutSpacing": toolbar.layout().spacing() if toolbar.layout() is not None else None,
        "buttons": len(buttons),
        "firstStep": steps[0] if steps else None,
        "steps": steps,
        "firstButton": geometry[0] if geometry else None,
        "geometry": geometry,
    }


def step_toolbars():
    # B5: passo entre dois icones vizinhos e altura das barras "Arquivo de projeto" e de navegacao do mapa
    window = iface.mainWindow()
    info = {}
    for name, capture in (("mFileToolBar", "b5-barra-arquivo-de-projeto.png"), ("mMapNavToolBar", "b5-barra-navegacao.png")):
        toolbar = window.findChild(QToolBar, name)
        if toolbar is None:
            info[name] = None
            continue
        info[name] = tool_buttons(toolbar)
        save(toolbar, capture)
    facts["toolbars"] = info


def measure_tabs(bar):
    """Largura de cada aba e do texto dela nas duas pesagens: normal e negrita (o font-weight 600 do QSS vira QFont.Bold
    no Qt 5, peso 600/8). Quem compara e o Measure-ThemeRegions.ps1: a caixa (padding e borda) e a aba menos o texto
    normal, e a largura util e a aba menos a caixa."""
    normal = QFont(bar.font())
    bold = QFont(bar.font())
    bold.setWeight(QFont.Bold)
    tabs = []
    for i in range(bar.count()):
        text = bar.tabText(i)
        tabs.append({
            "text": text,
            "selected": i == bar.currentIndex(),
            "tabWidth": bar.tabRect(i).width(),
            "tabHeight": bar.tabRect(i).height(),
            "normalWidth": QFontMetrics(normal).horizontalAdvance(text),
            "boldWidth": QFontMetrics(bold).horizontalAdvance(text),
        })
    return tabs


def step_open_dialog():
    import processing

    dialog = processing.createAlgorithmDialog(ALGORITHM)
    dialog.resize(900, 720)
    dialog.show()
    state["dialog"] = dialog
    QApplication.processEvents()


def step_dialog():
    # B2 (abas), B3 (botoes ao lado dos campos) e B4 (borda dos campos) no dialogo do algoritmo, em repouso
    dialog = state["dialog"]
    QApplication.processEvents()
    bars = [b for b in dialog.findChildren(QTabBar) if b.isVisible() and b.count() >= 2]
    info = {"title": dialog.windowTitle(), "size": [dialog.width(), dialog.height()]}
    if bars:
        bar = bars[0]
        info["tabs"] = {"first": measure_tabs(bar)}
        save(bar, "b2-abas-parametros.png")
        save(dialog, "b2-dialogo-parametros.png")
        bar.setCurrentIndex(1)
        QApplication.processEvents()
        info["tabs"]["second"] = measure_tabs(bar)
        save(bar, "b2-abas-registro.png")
        save(dialog, "b2-dialogo-registro.png")
        bar.setCurrentIndex(0)
        QApplication.processEvents()
    QApplication.processEvents()
    buttons = []
    for b in dialog.findChildren(QToolButton):
        if not b.isVisible() or b.width() < 8:
            continue
        if isinstance(b.parentWidget(), (QToolBar, QTabBar)):
            continue
        entry = {
            "class": b.metaObject().className(),
            "objectName": b.objectName(),
            "parentClass": b.parentWidget().metaObject().className() if b.parentWidget() is not None else None,
            "toolTip": b.toolTip()[:60],
            "text": b.text()[:30],
            "autoRaise": b.autoRaise(),
        }
        entry.update(border_contrast(b) or {})
        buttons.append(entry)
    info["toolButtons"] = buttons
    fields = []
    for cls in (QLineEdit, QComboBox, QAbstractSpinBox):
        for w in dialog.findChildren(cls):
            if not w.isVisible() or w.width() < 30:
                continue
            if isinstance(w, QLineEdit) and isinstance(w.parentWidget(), (QComboBox, QAbstractSpinBox)):
                continue
            entry = {"class": w.metaObject().className(), "objectName": w.objectName(), "hasFocus": w.hasFocus()}
            entry.update(border_contrast(w) or {})
            fields.append(entry)
    info["fields"] = fields
    # recorte: o primeiro campo de texto e o primeiro combo, com os botoes ao lado
    facts["dialog"] = info
    combo = next((w for w in dialog.findChildren(QComboBox) if w.isVisible() and w.width() >= 30), None)
    edit = next((w for w in dialog.findChildren(QAbstractSpinBox) if w.isVisible() and w.width() >= 30), None)
    for widget, name in ((combo, "b4-combo-em-repouso.png"), (edit, "b4-campo-em-repouso.png")):
        if widget is None:
            continue
        row = widget.parentWidget()
        while row is not None and row.parentWidget() is not None and row.width() < 300:
            row = row.parentWidget()
        save(row, name)


def step_close_dialog():
    dialog = state.pop("dialog", None)
    if dialog is not None:
        dialog.close()


def finish():
    with open(os.path.join(out_dir, "regions.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


def first():
    run(step_load_project)
    QTimer.singleShot(4000, second)


def second():
    for step in (step_status_bar, step_toolbars, step_open_dialog):
        run(step)
    QTimer.singleShot(2500, third)


def third():
    for step in (step_dialog, step_close_dialog):
        run(step)
    facts["themeName"] = QgsApplication.themeName()
    finish()


QTimer.singleShot(3000, first)
