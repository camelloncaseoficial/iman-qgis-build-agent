# Destaque (item e texto selecionados) por regiao (fatia 064, A2), rodado pelo proprio QGIS via --code
# (Invoke-HighlightCaptures.ps1), no build, no QGIS oficial e na arvore instalada, com perfil novo e janela maximizada.
# Para cada regiao, um item selecionado e a cor medida NA CAPTURA (pixels fisicos da tela): a cor mais comum do
# retangulo do item selecionado (o fundo do destaque) e quantos pixels estao perto da cor do texto selecionado da
# paleta (o texto). Recorte de cada regiao para o laudo. So coleta fatos: quem julga e o Invoke-HighlightCaptures.ps1.
import json
import os
from collections import Counter

from qgis.core import QgsApplication, QgsProject
from qgis.PyQt.QtCore import QItemSelectionModel, QPoint, QRect, Qt, QTimer
from qgis.PyQt.QtGui import QColor, QPalette
from qgis.PyQt.QtWidgets import QAbstractSpinBox, QApplication, QComboBox, QDockWidget, QTableView, QTreeView
from qgis.utils import iface

out_dir = os.environ["IMAN_HIGHLIGHT_OUT"]
project_path = os.environ.get("IMAN_HIGHLIGHT_PROJECT", "")
ALGORITHM = "native:buffer"
facts = {"captures": {}, "regions": {}}
state = {}


def run(step):
    try:
        step()
    except Exception as err:
        facts.setdefault("errors", {})[step.__name__] = repr(err)


def window_crop(widget, margin=0):
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


def palette_colors():
    palette = QApplication.palette()
    return {
        "Active": [palette.color(QPalette.Active, QPalette.Highlight).name().upper(),
                   palette.color(QPalette.Active, QPalette.HighlightedText).name().upper()],
        "Inactive": [palette.color(QPalette.Inactive, QPalette.Highlight).name().upper(),
                     palette.color(QPalette.Inactive, QPalette.HighlightedText).name().upper()],
    }


def _distance(a, b):
    return abs(a.red() - b.red()) + abs(a.green() - b.green()) + abs(a.blue() - b.blue())


def measure(widget, rect, capture=None, zoom=3):
    """Cor do destaque no retangulo (coordenadas logicas do widget), medida na imagem da tela."""
    image = window_crop(widget).toImage()
    dpr = image.devicePixelRatio() or 1.0
    r = QRect(int(rect.x() * dpr), int(rect.y() * dpr), max(int(rect.width() * dpr), 1), max(int(rect.height() * dpr), 1))
    r = r.intersected(QRect(0, 0, image.width(), image.height()))
    pixels = [image.pixel(x, y) for x in range(r.left(), r.right() + 1) for y in range(r.top(), r.bottom() + 1)]
    info = {"rect": [rect.x(), rect.y(), rect.width(), rect.height()], "pixels": len(pixels), "focus": widget.hasFocus(),
            "windowActive": widget.window().isActiveWindow()}
    if not pixels:
        info["background"] = None
        return info
    counts = Counter(pixels)
    background = QColor(counts.most_common(1)[0][0])
    info["background"] = background.name().upper()
    info["backgroundShare"] = round(counts.most_common(1)[0][1] / len(pixels), 3)
    # o Fusion pinta a selecao das arvores com um degrade vertical em torno da cor da paleta: a media da faixa (os
    # pixels a ate 30 da cor mais comum) e a cor do destaque; a mais comum e so uma linha do degrade
    band = [QColor(p) for p in pixels if _distance(QColor(p), background) <= 30]
    if band:
        mean = QColor(round(sum(c.red() for c in band) / len(band)), round(sum(c.green() for c in band) / len(band)),
                      round(sum(c.blue() for c in band) / len(band)))
        info["backgroundMean"] = mean.name().upper()
        info["backgroundBand"] = [min(c.name().upper() for c in band), max(c.name().upper() for c in band)]
    # pixels perto das duas cores de texto selecionado da paleta (Active e Inactive): o texto desenhado
    texts = {QColor(c).name().upper() for c in (palette_colors()["Active"][1], palette_colors()["Inactive"][1])}
    near = 0
    for p in pixels:
        c = QColor(p)
        for t in texts:
            tc = QColor(t)
            if abs(c.red() - tc.red()) + abs(c.green() - tc.green()) + abs(c.blue() - tc.blue()) < 90:
                near += 1
                break
    info["textPixels"] = near
    if capture:
        crop = window_crop(widget).copy(r.adjusted(-int(8 * dpr), -int(4 * dpr), int(8 * dpr), int(4 * dpr)))
        save(crop, capture, zoom)
    return info


def step_load_project():
    if project_path:
        facts["projectRead"] = QgsProject.instance().read(project_path)
        iface.mapCanvas().zoomToFullExtent()
    window = iface.mainWindow()
    # o Navegador lista as unidades da maquina (com nome e e-mail de conta): fora das capturas do laudo publico
    browser = window.findChild(QDockWidget, "Browser")
    if browser is not None:
        browser.hide()
    window.showMaximized()
    window.raise_()
    window.activateWindow()
    QApplication.processEvents()
    facts["theme"] = {
        "themeName": QgsApplication.themeName(),
        "styleSheetLength": len(QApplication.instance().styleSheet()),
        "qtStyle": QApplication.style().metaObject().className(),
        "palette": palette_colors(),
    }


def step_layers():
    # painel Camadas, a camada selecionada
    dock = iface.mainWindow().findChild(QDockWidget, "Layers")
    dock.show()
    dock.raise_()
    view = iface.layerTreeView()
    layers = list(QgsProject.instance().mapLayers().values())
    view.setCurrentLayer(layers[0])
    view.setFocus()
    QApplication.processEvents()
    index = view.currentIndex()
    rect = view.visualRect(index)
    rect.setLeft(max(rect.left(), 0))
    info = {"item": index.data()}
    info.update(measure(view.viewport(), rect, "a2-1-camadas-item.png"))
    facts["regions"]["layers"] = info
    save(window_crop(dock), "a2-1-painel-camadas.png")


def step_toolbox():
    # caixa de ferramentas do Processamento, um algoritmo selecionado
    dock = iface.mainWindow().findChild(QDockWidget, "ProcessingToolbox")
    dock.show()
    dock.raise_()
    QApplication.processEvents()
    tree = dock.findChild(QTreeView)
    model = tree.model()
    child = None
    for row in range(model.rowCount()):
        parent = model.index(row, 0)
        if model.rowCount(parent) > 0:
            tree.expand(parent)
            child = model.index(0, 0, parent)
            break
    info = {"found": child is not None}
    if child is not None:
        tree.selectionModel().setCurrentIndex(child, QItemSelectionModel.ClearAndSelect)
        tree.scrollTo(child)
        tree.setFocus()
        QApplication.processEvents()
        rect = tree.visualRect(child)
        info["item"] = child.data()
        info.update(measure(tree.viewport(), rect, "a2-2-processamento-item.png"))
    facts["regions"]["toolbox"] = info
    save(window_crop(dock), "a2-2-caixa-de-ferramentas.png")


def step_attribute_table():
    # tabela de atributos, uma linha selecionada (o QGIS monta a cor de selecao da QTableView com a paleta,
    # qgisappstylesheet.cpp)
    layers = list(QgsProject.instance().mapLayers().values())
    table_dialog = iface.showAttributeTable(layers[0])
    QApplication.processEvents()
    info = {"found": table_dialog is not None}
    if table_dialog is not None:
        table_dialog.resize(800, 320)
        QApplication.processEvents()
        views = [v for v in table_dialog.findChildren(QTableView) if v.isVisible()]
        if views:
            view = views[0]
            # a linha da tabela segue a selecao de feicoes da camada (QgsFeatureSelectionModel): seleciona a feicao
            first = next(layers[0].getFeatures())
            layers[0].selectByIds([first.id()])
            view.setFocus()
            QApplication.processEvents()
            index = view.model().index(0, max(view.model().columnCount() - 1, 0))
            rect = view.visualRect(index)
            info["view"] = view.metaObject().className()
            info["cell"] = index.data()
            info.update(measure(view.viewport(), rect, "a2-3-tabela-linha.png"))
        save(table_dialog.grab(), "a2-3-tabela-de-atributos.png")
        state["table"] = table_dialog
    facts["regions"]["attributeTable"] = info


def step_close_table():
    table_dialog = state.pop("table", None)
    if table_dialog is not None:
        table_dialog.close()
    layers = list(QgsProject.instance().mapLayers().values())
    if layers:
        layers[0].removeSelection()


def step_menu():
    # menu aberto com um item sob o mouse (o item ativo, que o Qt pinta como sob o mouse)
    bar = iface.mainWindow().menuBar()
    menu = bar.actions()[0].menu()
    menu.popup(bar.mapToGlobal(QPoint(0, bar.height())))
    QApplication.processEvents()
    action = next(a for a in menu.actions() if not a.isSeparator() and a.isEnabled() and a.isVisible())
    menu.setActiveAction(action)
    QApplication.processEvents()
    info = {"menu": bar.actions()[0].text(), "item": action.text()}
    info.update(measure(menu, menu.actionGeometry(action), "a2-4-menu-item.png"))
    facts["regions"]["menu"] = info
    save(menu.grab(), "a2-4-menu-aberto.png")
    menu.hide()


def step_open_dialog():
    import processing

    dialog = processing.createAlgorithmDialog(ALGORITHM)
    dialog.resize(900, 720)
    dialog.show()
    dialog.raise_()
    dialog.activateWindow()
    QApplication.processEvents()
    state["dialog"] = dialog


def step_combo():
    # caixa de lista aberta, um item sob o mouse (o item corrente da lista aberta)
    dialog = state["dialog"]
    combos = [c for c in dialog.findChildren(QComboBox) if c.isVisible() and c.count() >= 3 and not c.isEditable()]
    info = {"found": bool(combos)}
    if combos:
        combo = combos[0]
        combo.showPopup()
        QApplication.processEvents()
        view = combo.view()
        index = view.model().index(1, combo.modelColumn())
        view.setCurrentIndex(index)
        QApplication.processEvents()
        info["combo"] = combo.objectName()
        info["item"] = index.data()
        info.update(measure(view.viewport(), view.visualRect(index), "a2-5-lista-aberta-item.png"))
        save(view.window().grab(), "a2-5-lista-aberta.png")
        combo.hidePopup()
        QApplication.processEvents()
    facts["regions"]["comboPopup"] = info


def step_text_selection():
    # texto selecionado num campo de texto (o campo da distancia do algoritmo)
    dialog = state["dialog"]
    spins = [s for s in dialog.findChildren(QAbstractSpinBox) if s.isVisible() and s.lineEdit() is not None]
    info = {"found": bool(spins)}
    if spins:
        edit = spins[0].lineEdit()
        dialog.activateWindow()
        edit.setFocus()
        edit.selectAll()
        QApplication.processEvents()
        text = edit.text()
        width = edit.fontMetrics().horizontalAdvance(text)
        rect = QRect(3, max(edit.height() // 2 - 4, 0), max(width - 2, 4), 8)
        info["text"] = text
        info["selected"] = edit.selectedText()
        info.update(measure(edit, rect, "a2-6-texto-selecionado.png", 4))
        save(window_crop(spins[0], 4), "a2-6-campo.png", 3)
    facts["regions"]["textSelection"] = info


def step_close_dialog():
    dialog = state.pop("dialog", None)
    if dialog is not None:
        dialog.close()


def finish():
    with open(os.path.join(out_dir, "highlight.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


def first():
    run(step_load_project)
    QTimer.singleShot(4000, second)


def second():
    save(iface.mainWindow().grab(), "a2-0-janela.png")
    for step in (step_layers, step_toolbox, step_attribute_table):
        run(step)
    QTimer.singleShot(1500, third)


def third():
    for step in (step_close_table, step_menu, step_open_dialog):
        run(step)
    QTimer.singleShot(2500, fourth)


def fourth():
    for step in (step_combo, step_text_selection, step_close_dialog):
        run(step)
    finish()


QTimer.singleShot(3000, first)
