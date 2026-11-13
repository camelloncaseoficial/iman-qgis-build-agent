# Setas dos controles do Qt (fatia 063, A2), rodado pelo proprio QGIS via --code (Invoke-ArrowCaptures.ps1), no build,
# no QGIS oficial e na arvore instalada, sempre com perfil novo e janela maximizada.
# Para cada controle: o retangulo da seta que o estilo em uso informa (subControlRect, com o widget, e por isso ja com
# o style.qss do tema, se houver) e a "tinta" dentro dele: pixels que diferem da cor mais comum do retangulo. Seta
# desenhada tem tinta; seta sumida, nenhuma. Captura de cada controle, recortada da janela dele (o grab() de widget de
# fundo transparente sai sobre preto, fatia 058) e ampliada 4x para o laudo.
# So coleta fatos e capturas: quem julga e o Invoke-ArrowCaptures.ps1. Passo que quebra vira fato em "errors".
import json
import os
from collections import Counter

from qgis.core import QgsApplication, QgsProject, QgsSettings
from qgis.PyQt.QtCore import QPoint, QRect, Qt, QTimer
from qgis.PyQt.QtGui import QColor, QFont, QFontMetrics
from qgis.PyQt.QtWidgets import (
    QAbstractSpinBox,
    QApplication,
    QComboBox,
    QDockWidget,
    QScrollBar,
    QStyle,
    QStyleOptionComboBox,
    QStyleOptionSlider,
    QStyleOptionSpinBox,
    QStyleOptionToolButton,
    QTabBar,
    QToolBar,
    QToolButton,
    QTreeView,
)
from qgis.utils import iface

out_dir = os.environ["IMAN_ARROWS_OUT"]
project_path = os.environ.get("IMAN_ARROWS_PROJECT", "")
ALGORITHM = "native:buffer"
facts = {"captures": {}, "controls": {}}
state = {}


def run(step):
    try:
        step()
    except Exception as err:
        facts.setdefault("errors", {})[step.__name__] = repr(err)


def window_crop(widget, margin=0):
    """O widget recortado da janela dele, com uma margem: a imagem que a tela mostra."""
    top = widget.window()
    origin = widget.mapTo(top, QPoint(0, 0))
    area = QRect(origin.x() - margin, origin.y() - margin, widget.width() + 2 * margin, widget.height() + 2 * margin)
    return top.grab(area.intersected(top.rect()))


def save(pixmap, name, zoom=1):
    if pixmap is None or pixmap.isNull():
        return
    if zoom > 1:
        pixmap = pixmap.scaled(pixmap.width() * zoom, pixmap.height() * zoom, Qt.KeepAspectRatio, Qt.FastTransformation)
    pixmap.save(os.path.join(out_dir, name))
    facts["captures"][name] = [pixmap.width(), pixmap.height()]


def ink(widget, rect, inset=2):
    """Pixels do retangulo (coordenadas logicas do widget, encolhido de 'inset') que diferem da cor mais comum dele. A
    imagem do grab esta em pixels fisicos (escala da tela, 125% nesta bancada): o retangulo e levado a ela."""
    if rect is None or rect.isEmpty():
        return {"rect": None, "ink": 0, "pixels": 0}
    r = rect.adjusted(inset, inset, -inset, -inset)
    if r.width() <= 0 or r.height() <= 0:
        r = rect
    image = window_crop(widget).toImage()
    dpr = image.devicePixelRatio() or 1.0
    logical = r
    r = QRect(int(r.x() * dpr), int(r.y() * dpr), max(int(round(r.width() * dpr)), 1), max(int(round(r.height() * dpr)), 1))
    pixels = []
    for x in range(max(r.left(), 0), min(r.right() + 1, image.width())):
        for y in range(max(r.top(), 0), min(r.bottom() + 1, image.height())):
            pixels.append(image.pixel(x, y))
    if not pixels:
        return {"rect": [logical.x(), logical.y(), logical.width(), logical.height()], "ink": 0, "pixels": 0}
    base = QColor(Counter(pixels).most_common(1)[0][0])
    count = 0
    for p in pixels:
        c = QColor(p)
        if abs(c.red() - base.red()) + abs(c.green() - base.green()) + abs(c.blue() - base.blue()) > 60:
            count += 1
    return {"rect": [logical.x(), logical.y(), logical.width(), logical.height()], "scale": dpr, "ink": count,
            "pixels": len(pixels), "background": base.name()}


def describe(widget):
    return {
        "class": widget.metaObject().className(),
        "objectName": widget.objectName(),
        "size": [widget.width(), widget.height()],
        "visible": widget.isVisible(),
    }


def combo_arrow(combo):
    opt = QStyleOptionComboBox()
    opt.initFrom(combo)
    opt.rect = combo.rect()
    opt.editable = combo.isEditable()
    opt.frame = combo.hasFrame()
    opt.subControls = QStyle.SC_All
    return combo.style().subControlRect(QStyle.CC_ComboBox, opt, QStyle.SC_ComboBoxArrow, combo)


def spin_arrows(spin):
    opt = QStyleOptionSpinBox()
    opt.initFrom(spin)
    opt.rect = spin.rect()
    opt.buttonSymbols = spin.buttonSymbols()
    opt.frame = spin.hasFrame()
    opt.stepEnabled = QAbstractSpinBox.StepUpEnabled | QAbstractSpinBox.StepDownEnabled
    opt.subControls = QStyle.SC_SpinBoxUp | QStyle.SC_SpinBoxDown | QStyle.SC_SpinBoxFrame | QStyle.SC_SpinBoxEditField
    style = spin.style()
    return (style.subControlRect(QStyle.CC_SpinBox, opt, QStyle.SC_SpinBoxUp, spin),
            style.subControlRect(QStyle.CC_SpinBox, opt, QStyle.SC_SpinBoxDown, spin))


def tool_button_arrow(button):
    opt = QStyleOptionToolButton()
    opt.initFrom(button)
    opt.rect = button.rect()
    opt.features = QStyleOptionToolButton.MenuButtonPopup | QStyleOptionToolButton.HasMenu
    opt.subControls = QStyle.SC_ToolButton | QStyle.SC_ToolButtonMenu
    opt.icon = button.icon()
    opt.iconSize = button.iconSize()
    opt.toolButtonStyle = button.toolButtonStyle()
    return button.style().subControlRect(QStyle.CC_ToolButton, opt, QStyle.SC_ToolButtonMenu, button)


def scroll_arrows(bar):
    opt = QStyleOptionSlider()
    opt.initFrom(bar)
    opt.rect = bar.rect()
    opt.orientation = bar.orientation()
    opt.minimum = bar.minimum()
    opt.maximum = bar.maximum()
    opt.sliderPosition = bar.sliderPosition()
    opt.sliderValue = bar.value()
    opt.singleStep = bar.singleStep()
    opt.pageStep = bar.pageStep()
    opt.upsideDown = bar.invertedAppearance()
    opt.subControls = QStyle.SC_All
    style = bar.style()
    return (style.subControlRect(QStyle.CC_ScrollBar, opt, QStyle.SC_ScrollBarSubLine, bar),
            style.subControlRect(QStyle.CC_ScrollBar, opt, QStyle.SC_ScrollBarAddLine, bar))


def branch_arrow(tree, index):
    """A faixa da seta de expandir de um item de topo: da borda esquerda da area de itens ate o texto."""
    item = tree.visualRect(index)
    return QRect(0, item.top(), max(item.left(), tree.indentation()), item.height())


def step_theme():
    settings = QgsSettings()
    style = QApplication.style()
    base = style.baseStyle() if hasattr(style, "baseStyle") else None
    facts["theme"] = {
        "themeName": QgsApplication.themeName(),
        "styleSheetLength": len(QApplication.instance().styleSheet()),
        "qtStyle": style.metaObject().className(),
        "qtStyleBase": base.metaObject().className() if base is not None else None,
        "settingUITheme": settings.value("UI/UITheme", None),
        "settingQgisStyle": settings.value("qgis/style", None),
    }


def step_load_project():
    if project_path:
        facts["projectRead"] = QgsProject.instance().read(project_path)
        iface.mapCanvas().zoomToFullExtent()
    window = iface.mainWindow()
    # o Navegador lista as unidades da maquina (com nome e e-mail de conta): fora das capturas do laudo publico
    browser = window.findChild(QDockWidget, "Browser")
    if browser is not None:
        browser.hide()
    # um grupo com a camada do fixture, para a arvore do painel Camadas ter a seta de expandir
    root = QgsProject.instance().layerTreeRoot()
    layers = root.findLayers()
    if layers:
        group = root.insertGroup(0, "Grupo de teste 063")
        clone = layers[0].clone()
        group.addChildNode(clone)
        root.removeChildNode(layers[0])
        group.setExpanded(True)
        closed = root.addGroup("Grupo fechado 063")
        closed.addLayer(clone.layer())
        closed.setExpanded(False)
    window.showMaximized()
    QApplication.processEvents()


def step_main_window():
    window = iface.mainWindow()
    save(window.grab(), "01-janela.png")
    facts["window"] = [window.width(), window.height(), window.isMaximized()]


def step_tool_button():
    # botao de barra com menu: o de selecao de feicoes (seta de lista ao lado do icone); o QGIS monta a lista dele com
    # addAction, sem setMenu (qgisapp.cpp, 'mouse select tool button')
    window = iface.mainWindow()
    candidates = []
    for bar in window.findChildren(QToolBar):
        if not bar.isVisible():
            continue
        for b in bar.findChildren(QToolButton):
            if b.isVisible() and b.popupMode() == QToolButton.MenuButtonPopup and (b.menu() is not None or len(b.actions()) > 1):
                action = b.defaultAction().objectName() if b.defaultAction() is not None else ""
                candidates.append((0 if action == "mActionSelectFeatures" else 1, bar.objectName(), b))
    candidates.sort(key=lambda c: c[0])
    info = {"candidates": [[c[1], c[2].defaultAction().objectName() if c[2].defaultAction() else ""] for c in candidates]}
    if candidates:
        _, bar_name, button = candidates[0]
        info.update(describe(button))
        info["toolbar"] = bar_name
        info["action"] = button.defaultAction().objectName() if button.defaultAction() is not None else None
        info["toolTip"] = button.toolTip()[:60]
        info["arrow"] = ink(button, tool_button_arrow(button))
        save(window_crop(button, 2), "02-botao-com-menu.png", 4)
    facts["controls"]["toolButtonMenu"] = info


def step_layer_tree():
    # setas de expandir da arvore do painel Camadas (um grupo aberto, um fechado)
    dock = iface.mainWindow().findChild(QDockWidget, "Layers")
    dock.show()
    dock.raise_()
    QApplication.processEvents()
    tree = iface.layerTreeView()
    model = tree.model()
    rows = []
    for row in range(model.rowCount()):
        index = model.index(row, 0)
        if model.rowCount(index) > 0:
            entry = {"text": model.data(index), "expanded": tree.isExpanded(index)}
            entry.update(ink(tree.viewport(), branch_arrow(tree, index), 0))
            rows.append(entry)
    facts["controls"]["layerTreeBranches"] = {"view": describe(tree), "indentation": tree.indentation(), "rows": rows}
    save(window_crop(dock), "03-painel-camadas.png")
    first = tree.visualRect(model.index(0, 0))
    strip = window_crop(tree.viewport()).copy(QRect(0, first.top(), min(tree.viewport().width(), 220), first.height() * 4))
    save(strip, "03b-setas-da-arvore.png", 3)


def toolbox_branches(tree, model):
    rows = []
    for row in range(model.rowCount()):
        index = model.index(row, 0)
        rect = tree.visualRect(index)
        if model.rowCount(index) > 0 and rect.top() >= 0 and rect.bottom() < tree.viewport().height() and len(rows) < 4:
            entry = {"text": model.data(index), "expanded": tree.isExpanded(index)}
            entry.update(ink(tree.viewport(), branch_arrow(tree, index), 0))
            rows.append(entry)
    return rows


def step_toolbox():
    # barra de rolagem: a da caixa de ferramentas do Processamento, com um provedor aberto (lista longa)
    dock = iface.mainWindow().findChild(QDockWidget, "ProcessingToolbox")
    if dock is None:
        facts["controls"]["scrollBar"] = {"found": False}
        return
    dock.show()
    dock.raise_()
    QApplication.processEvents()
    tree = dock.findChild(QTreeView)
    model = tree.model()
    # as setas dos provedores fechados, antes de abrir um (depois, os de baixo saem da area visivel)
    branches = toolbox_branches(tree, model)
    for row in range(model.rowCount()):
        index = model.index(row, 0)
        if model.rowCount(index) > 20:
            tree.expand(index)
            break
    QApplication.processEvents()
    bars = [b for b in tree.findChildren(QScrollBar) if b.isVisible() and b.orientation() == Qt.Vertical]
    info = {"found": bool(bars)}
    if bars:
        bar = bars[0]
        up, down = scroll_arrows(bar)
        info.update(describe(bar))
        info["range"] = [bar.minimum(), bar.maximum()]
        info["up"] = ink(bar, up)
        info["down"] = ink(bar, down)
        save(window_crop(bar, 1), "04-barra-de-rolagem.png", 3)
    info["toolboxBranches"] = branches + [b for b in toolbox_branches(tree, model) if b["expanded"]]
    facts["controls"]["scrollBar"] = info
    save(window_crop(dock), "04b-caixa-de-ferramentas.png")


def step_layer_properties():
    # caixa de lista (tipo de simbologia) e caixa de numero com setas (rotacao do simbolo), em Propriedades da camada;
    # o dialogo e modal: lido e capturado de dentro dele, por um timer armado antes de abrir
    layer = iface.activeLayer()
    if layer is None:
        layers = list(QgsProject.instance().mapLayers().values())
        layer = layers[0] if layers else None
    if layer is None:
        facts["controls"]["comboBox"] = {"found": False}
        return
    QTimer.singleShot(3000, read_layer_properties)
    iface.showLayerProperties(layer, "mOptsPage_Symbology")


def read_layer_properties():
    dialog = None
    for w in QApplication.topLevelWidgets():
        if w.metaObject().className() == "QgsVectorLayerProperties" and w.isVisible():
            dialog = w
    if dialog is None:
        facts["controls"]["comboBox"] = {"found": False}
        return
    try:
        dialog.resize(1100, 760)
        QApplication.processEvents()
        combo = dialog.findChild(QComboBox, "cboRenderers")
        if combo is None or not combo.isVisible():
            combo = next((c for c in dialog.findChildren(QComboBox) if c.isVisible() and c.width() >= 60), None)
        info = {"found": combo is not None}
        if combo is not None:
            info.update(describe(combo))
            info["text"] = combo.currentText()
            info["arrow"] = ink(combo, combo_arrow(combo))
            save(window_crop(combo, 2), "05-caixa-de-lista.png", 3)
        facts["controls"]["comboBox"] = info
        spins = [s for s in dialog.findChildren(QAbstractSpinBox)
                 if s.isVisible() and s.buttonSymbols() != QAbstractSpinBox.NoButtons and s.width() >= 40]
        rotation = [s for s in spins if "otat" in (s.objectName() + s.toolTip())]
        spin = (rotation or spins or [None])[0]
        sinfo = {"found": spin is not None, "candidates": len(spins)}
        if spin is not None:
            up, down = spin_arrows(spin)
            sinfo.update(describe(spin))
            sinfo["text"] = spin.text()
            sinfo["up"] = ink(spin, up, 1)
            sinfo["down"] = ink(spin, down, 1)
            save(window_crop(spin, 2), "06-caixa-de-numero.png", 4)
        facts["controls"]["spinBox"] = sinfo
        save(dialog.grab(), "05b-propriedades-da-camada.png")
    except Exception as err:
        facts.setdefault("errors", {})["read_layer_properties"] = repr(err)
    dialog.reject()


def measure_tabs(bar):
    tabs = []
    for i in range(bar.count()):
        text = bar.tabText(i)
        rect = bar.tabRect(i)
        metrics = QFontMetrics(QFont(bar.font()))
        tabs.append({
            "text": text,
            "selected": i == bar.currentIndex(),
            "tabWidth": rect.width(),
            "tabHeight": rect.height(),
            "textWidth": metrics.horizontalAdvance(text),
            "visible": rect.width() > 0 and rect.height() > 0,
        })
    return tabs


def step_processing_dialog():
    import processing

    dialog = processing.createAlgorithmDialog(ALGORITHM)
    dialog.resize(900, 720)
    dialog.show()
    QApplication.processEvents()
    state["dialog"] = dialog


def read_processing_dialog():
    dialog = state.pop("dialog", None)
    if dialog is None:
        return
    QApplication.processEvents()
    bars = [b for b in dialog.findChildren(QTabBar) if b.isVisible() and b.count() >= 2]
    info = {"found": bool(bars), "title": dialog.windowTitle()}
    if bars:
        bar = bars[0]
        info["tabs"] = measure_tabs(bar)
        info["ink"] = ink(bar, bar.rect(), 0)
        save(window_crop(bar, 2), "07-abas-do-processamento.png", 2)
        bar.setCurrentIndex(1)
        QApplication.processEvents()
        info["tabsSecond"] = measure_tabs(bar)
        save(window_crop(bar, 2), "07b-abas-do-processamento-registro.png", 2)
        bar.setCurrentIndex(0)
        QApplication.processEvents()
    save(dialog.grab(), "07c-dialogo-do-processamento.png")
    facts["controls"]["processingTabs"] = info
    dialog.close()


def finish():
    with open(os.path.join(out_dir, "arrows.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


def first():
    for step in (step_theme, step_load_project):
        run(step)
    QTimer.singleShot(4000, second)


def second():
    for step in (step_main_window, step_tool_button, step_layer_tree, step_toolbox, step_processing_dialog):
        run(step)
    QTimer.singleShot(2500, third)


def third():
    run(read_processing_dialog)
    QTimer.singleShot(500, fourth)


def fourth():
    # o timer armado em step_layer_properties le e fecha o dialogo em 3 s; se ele for modal, esta chamada so volta
    # depois disso, e a espera do fim cobre os dois casos
    run(step_layer_properties)
    QTimer.singleShot(4500, finish)


QTimer.singleShot(3000, first)
