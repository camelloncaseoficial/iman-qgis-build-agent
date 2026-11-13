# Fundo das janelas por regiao (fatia 065, A2), rodado pelo proprio QGIS via --code (Invoke-WindowCaptures.ps1), no
# build, no QGIS oficial e na arvore instalada, com perfil novo e janela maximizada.
# Para cada regiao, a cor do fundo medida NA CAPTURA (pixels fisicos): a cor mais comum da area (sem as listas,
# arvores, tabelas e campos de dentro dela, que sao do papel Base), a fatia dela e a media da faixa em torno dela (o
# Fusion pinta barras e titulos com degrade a partir do Window, como no #064); e a cor da borda de um campo e de um
# quadro da regiao (o pixel mais escuro da borda esquerda, na altura do meio). Recorte de cada regiao para o laudo.
# So coleta fatos: quem julga e o Invoke-WindowCaptures.ps1.
import json
import os

import numpy as np
from qgis.core import QgsApplication, QgsProject
from qgis.PyQt.QtCore import QPoint, QRect, Qt, QTimer
from qgis.PyQt.QtGui import QColor, QImage, QPalette
from qgis.PyQt.QtWidgets import (
    QAbstractItemView,
    QAbstractSpinBox,
    QApplication,
    QComboBox,
    QDockWidget,
    QFrame,
    QGroupBox,
    QLineEdit,
    QListWidget,
    QPlainTextEdit,
    QStackedWidget,
    QStatusBar,
    QTableView,
    QTabWidget,
    QTreeView,
    QTextEdit,
    QToolBar,
    QWidget,
)
from qgis.utils import iface

out_dir = os.environ["IMAN_WINDOW_OUT"]
project_path = os.environ.get("IMAN_WINDOW_PROJECT", "")
ALGORITHM = "native:buffer"
BASE_TYPES = (QAbstractItemView, QLineEdit, QAbstractSpinBox, QTextEdit, QPlainTextEdit, QComboBox)
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


def save(pixmap, name):
    if pixmap is None or pixmap.isNull():
        return
    pixmap.save(os.path.join(out_dir, name))
    facts["captures"][name] = [pixmap.width(), pixmap.height()]


def to_array(pixmap):
    image = pixmap.toImage().convertToFormat(QImage.Format_RGB32)
    ptr = image.constBits()
    ptr.setsize(image.bytesPerLine() * image.height())
    array = np.frombuffer(ptr, np.uint32).reshape(image.height(), image.bytesPerLine() // 4)[:, : image.width()]
    return array.copy(), (image.devicePixelRatio() or 1.0)


def hexrgb(value):
    return "#%06X" % (int(value) & 0xFFFFFF)


def channels(values):
    values = values.astype(np.int64)
    return (values >> 16) & 0xFF, (values >> 8) & 0xFF, values & 0xFF


def background(widget, exclude=(), band=30):
    """Cor mais comum da area do widget (na janela de cima), sem os filhos de Base, e a media da faixa em torno dela."""
    array, dpr = to_array(window_crop(widget))
    mask = np.ones(array.shape, dtype=bool)
    excluded = []
    for child in exclude:
        if not child.isVisible():
            continue
        origin = child.mapTo(widget, QPoint(0, 0))
        x0, y0 = max(int(origin.x() * dpr), 0), max(int(origin.y() * dpr), 0)
        x1, y1 = int((origin.x() + child.width()) * dpr), int((origin.y() + child.height()) * dpr)
        mask[y0:y1, x0:x1] = False
        excluded.append(child.metaObject().className())
    values = array[mask]
    info = {"size": [widget.width(), widget.height()], "pixels": int(values.size), "excluded": len(excluded)}
    if values.size == 0:
        info["background"] = None
        return info
    colors, counts = np.unique(values, return_counts=True)
    top = colors[np.argmax(counts)]
    info["background"] = hexrgb(top)
    info["backgroundShare"] = round(float(counts.max()) / values.size, 3)
    r, g, b = channels(values)
    tr, tg, tb = channels(np.array([top]))
    near = (np.abs(r - tr[0]) + np.abs(g - tg[0]) + np.abs(b - tb[0])) <= band
    if near.any():
        mean = (int(round(r[near].mean())), int(round(g[near].mean())), int(round(b[near].mean())))
        info["backgroundMean"] = "#%02X%02X%02X" % mean
        band_values = values[near]
        info["backgroundBand"] = [hexrgb(band_values.min()), hexrgb(band_values.max())]
        info["bandShare"] = round(float(near.sum()) / values.size, 3)
    return info


def border(widget):
    """Pixel mais escuro da borda esquerda do widget, no terco do meio da altura: o contorno que o estilo desenha."""
    if widget is None or not widget.isVisible():
        return None
    array, dpr = to_array(window_crop(widget))
    height = array.shape[0]
    strip = array[height // 3: max(2 * height // 3, height // 3 + 1), : max(int(3 * dpr), 1)]
    if strip.size == 0:
        return None
    r, g, b = channels(strip)
    darkest = strip.flat[int(np.argmin((r + g + b).ravel()))]
    return {"class": widget.metaObject().className(), "name": widget.objectName(), "color": hexrgb(darkest)}


def first_visible(parent, kind, test=None):
    for w in parent.findChildren(kind):
        if w.isVisible() and w.width() > 20 and (test is None or test(w)):
            return w
    return None


def base_children(widget):
    return [w for w in widget.findChildren(QWidget) if isinstance(w, BASE_TYPES) and w.isVisible()]


def field_of(parent):
    edit = first_visible(parent, QLineEdit, lambda w: not isinstance(w.parent(), (QAbstractSpinBox, QComboBox)))
    return edit or first_visible(parent, QAbstractSpinBox)


def frame_of(parent):
    """Um quadro desenhado pelo estilo: uma lista ou arvore com moldura, outro QFrame com moldura, ou um grupo aberto."""
    shapes = (QFrame.Box, QFrame.Panel, QFrame.StyledPanel)
    view = first_visible(parent, QAbstractItemView, lambda w: w.frameShape() in shapes and w.height() > 40)
    if view is not None:
        return view
    other = first_visible(parent, QFrame, lambda w: w.frameShape() in shapes and not isinstance(w, BASE_TYPES) and w.height() > 40)
    if other is not None:
        return other
    return first_visible(parent, QGroupBox, lambda w: not (hasattr(w, "isCollapsed") and w.isCollapsed()) and w.height() > 40)


def side_list(dialog):
    """A lista lateral dos dialogos de opcoes do QGIS: QListWidget nas Propriedades, QTreeView nas Opcoes."""
    lst = dialog.findChild(QListWidget, "mOptionsListWidget")
    if lst is None or not lst.isVisible():
        lst = dialog.findChild(QTreeView, "mOptionsTreeView")
    return lst


def region(id_, widget, exclude=(), field=None, frame=None, capture=None, extra=None):
    info = background(widget, exclude)
    info["field"] = border(field)
    info["frame"] = border(frame)
    if extra:
        info.update(extra)
    facts["regions"][id_] = info
    if capture:
        save(window_crop(widget), capture)


def palette_facts():
    palette = QApplication.palette()
    groups = (("Active", QPalette.Active), ("Inactive", QPalette.Inactive), ("Disabled", QPalette.Disabled))
    roles = ("Window", "WindowText", "Base", "Button", "Highlight")
    return {name: {role: palette.color(group, getattr(QPalette, role)).name().upper() for role in roles} for name, group in groups}


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
        "palette": palette_facts(),
    }


def step_main_window():
    # janela principal maximizada: barra de menus, barras de ferramentas e barra de status
    window = iface.mainWindow()
    save(window.grab(), "a2-1-janela.png")
    bar = window.menuBar()
    region("menuBar", bar, capture="a2-1-barra-de-menus.png")
    toolbar = window.findChild(QToolBar, "mFileToolBar")
    region("toolBar", toolbar, capture="a2-1-barra-de-ferramentas.png")
    status = window.findChild(QStatusBar)
    coord = None
    for e in status.findChildren(QLineEdit):
        if e.parent() is not None and e.parent().metaObject().className() == "QgsStatusBarCoordinatesWidget":
            coord = e
    region("statusBar", status, exclude=base_children(status), field=coord, capture="a2-1-barra-de-status.png")


def step_layers():
    # painel Camadas: o titulo do painel e a area em volta da arvore
    dock = iface.mainWindow().findChild(QDockWidget, "Layers")
    dock.show()
    dock.raise_()
    QApplication.processEvents()
    title_height = dock.widget().geometry().top() if dock.widget() is not None else 0
    crop = window_crop(dock)
    dpr = crop.devicePixelRatio() or 1.0
    save(crop.copy(0, 0, crop.width(), max(int(title_height * dpr), 1)), "a2-2-camadas-titulo.png")
    # o titulo: so a faixa de cima da dock
    info = background_strip(dock, title_height)
    info["titleBarHeight"] = title_height
    facts["regions"]["layersTitle"] = info
    view = iface.layerTreeView()
    region("layersPanel", dock.widget(), exclude=base_children(dock.widget()), frame=view, capture="a2-2-painel-camadas.png")


def background_strip(widget, height):
    array, dpr = to_array(window_crop(widget))
    strip = array[: max(int(height * dpr), 1), :]
    colors, counts = np.unique(strip, return_counts=True)
    top = colors[np.argmax(counts)]
    r, g, b = channels(strip.ravel())
    tr, tg, tb = channels(np.array([top]))
    near = (np.abs(r - tr[0]) + np.abs(g - tg[0]) + np.abs(b - tb[0])) <= 30
    mean = (int(round(r[near].mean())), int(round(g[near].mean())), int(round(b[near].mean())))
    return {"background": hexrgb(top), "backgroundShare": round(float(counts.max()) / strip.size, 3),
            "backgroundMean": "#%02X%02X%02X" % mean, "bandShare": round(float(near.sum()) / strip.size, 3)}


def step_layer_properties():
    # Propriedades da camada (modal): lista lateral e pagina Simbologia, lidas por um timer armado antes de abrir
    layers = list(QgsProject.instance().mapLayers().values())
    if not layers:
        facts["regions"]["layerProperties"] = {"found": False}
        return
    QTimer.singleShot(3000, read_layer_properties)
    iface.showLayerProperties(layers[0], "mOptsPage_Symbology")


def _dialog(class_name):
    for w in QApplication.topLevelWidgets():
        if w.metaObject().className() == class_name and w.isVisible():
            return w
    return None


def read_layer_properties():
    dialog = _dialog("QgsVectorLayerProperties")
    if dialog is None:
        facts["regions"]["layerProperties"] = {"found": False}
        return
    try:
        dialog.resize(1100, 760)
        QApplication.processEvents()
        save(dialog.grab(), "a2-3-propriedades-simbologia.png")
        lst = side_list(dialog)
        region("layerPropertiesList", lst, capture="a2-3-propriedades-lista.png", extra={"name": lst.objectName()})
        stack = dialog.findChild(QStackedWidget, "mOptionsStackedWidget")
        page = stack.currentWidget() if stack is not None else dialog
        region("layerPropertiesSymbology", page, exclude=base_children(page), field=field_of(page), frame=frame_of(page),
               capture="a2-3-propriedades-pagina.png", extra={"page": page.objectName()})
        region("layerPropertiesDialog", dialog, exclude=base_children(dialog), extra={"title": dialog.windowTitle()})
    except Exception as err:
        facts.setdefault("errors", {})["read_layer_properties"] = repr(err)
    dialog.reject()


def step_options():
    QTimer.singleShot(3000, read_options)
    iface.showOptionsDialog(iface.mainWindow(), "mOptionsPageGeneral")


def read_options():
    dialog = _dialog("QgsOptions")
    if dialog is None:
        facts["regions"]["options"] = {"found": False}
        return
    try:
        dialog.resize(1100, 760)
        stack = dialog.findChild(QStackedWidget, "mOptionsStackedWidget")
        general = dialog.findChild(QWidget, "mOptionsPageGeneral")
        page = general
        while page is not None and page.parent() is not stack:
            page = page.parent()
        if stack is not None and page is not None:
            stack.setCurrentWidget(page)
        QApplication.processEvents()
        save(dialog.grab(), "a2-4-opcoes-geral.png")
        lst = side_list(dialog)
        region("optionsList", lst, capture="a2-4-opcoes-lista.png", extra={"name": lst.objectName()})
        current = stack.currentWidget() if stack is not None else dialog
        region("optionsGeneral", current, exclude=base_children(current), field=field_of(current), frame=frame_of(current),
               capture="a2-4-opcoes-pagina.png", extra={"page": current.objectName()})
    except Exception as err:
        facts.setdefault("errors", {})["read_options"] = repr(err)
    dialog.reject()


def step_open_dialog():
    import processing

    dialog = processing.createAlgorithmDialog(ALGORITHM)
    dialog.resize(900, 720)
    dialog.show()
    dialog.raise_()
    dialog.activateWindow()
    QApplication.processEvents()
    state["dialog"] = dialog


def step_algorithm():
    # dialogo do algoritmo: abas Parametros e Log
    dialog = state["dialog"]
    tabs = dialog.findChild(QTabWidget, "mTabWidget")
    tabs.setCurrentIndex(0)
    QApplication.processEvents()
    save(dialog.grab(), "a2-5-algoritmo-parametros.png")
    page = tabs.currentWidget()
    region("algorithmParameters", page, exclude=base_children(page), field=field_of(page), frame=frame_of(page),
           extra={"tab": tabs.tabText(0)})
    region("algorithmDialog", dialog, exclude=base_children(dialog), extra={"title": dialog.windowTitle()})
    tabs.setCurrentIndex(1)
    QApplication.processEvents()
    save(dialog.grab(), "a2-5-algoritmo-log.png")
    page = tabs.currentWidget()
    log = first_visible(page, QTextEdit)
    region("algorithmLog", page, exclude=base_children(page), frame=log, extra={"tab": tabs.tabText(1)})
    if log is not None:
        region("algorithmLogText", log.viewport(), extra={"what": "txtLog (Base)"})
    tabs.setCurrentIndex(0)
    QApplication.processEvents()


def step_combo():
    # caixa de lista aberta (esperado: Base)
    dialog = state["dialog"]
    combos = [c for c in dialog.findChildren(QComboBox) if c.isVisible() and c.count() >= 3 and not c.isEditable()]
    if not combos:
        facts["regions"]["comboPopup"] = {"found": False}
        return
    combo = combos[0]
    combo.showPopup()
    QApplication.processEvents()
    view = combo.view()
    view.setCurrentIndex(view.model().index(-1, 0))
    QApplication.processEvents()
    region("comboPopup", view.viewport(), extra={"combo": combo.objectName()})
    save(view.window().grab(), "a2-6-lista-aberta.png")
    combo.hidePopup()
    QApplication.processEvents()


def step_line_edit():
    # um campo de texto (esperado: Base); o interior, sem a borda
    dialog = state["dialog"]
    edit = field_of(dialog)
    if edit is None:
        facts["regions"]["lineEdit"] = {"found": False}
        return
    region("lineEdit", edit, field=edit, capture="a2-7-campo.png", extra={"class": edit.metaObject().className()})


def step_close_dialog():
    dialog = state.pop("dialog", None)
    if dialog is not None:
        dialog.close()


def step_menu():
    # menu aberto (esperado: Base), sem item ativo
    bar = iface.mainWindow().menuBar()
    menu = bar.actions()[0].menu()
    menu.popup(bar.mapToGlobal(QPoint(0, bar.height())))
    QApplication.processEvents()
    menu.setActiveAction(None)
    QApplication.processEvents()
    region("menu", menu, extra={"menu": bar.actions()[0].text()})
    save(menu.grab(), "a2-6-menu-aberto.png")
    menu.hide()


def step_attribute_table():
    # tabela de atributos (esperado: Base), sem linha selecionada
    layers = list(QgsProject.instance().mapLayers().values())
    table_dialog = iface.showAttributeTable(layers[0]) if layers else None
    QApplication.processEvents()
    if table_dialog is None:
        facts["regions"]["attributeTable"] = {"found": False}
        return
    table_dialog.resize(800, 320)
    QApplication.processEvents()
    views = [v for v in table_dialog.findChildren(QTableView) if v.isVisible()]
    if views:
        region("attributeTable", views[0].viewport(), extra={"view": views[0].metaObject().className()})
        region("attributeTableDialog", table_dialog, exclude=base_children(table_dialog))
    save(table_dialog.grab(), "a2-7-tabela-de-atributos.png")
    state["table"] = table_dialog


def step_close_table():
    table_dialog = state.pop("table", None)
    if table_dialog is not None:
        table_dialog.close()


def finish():
    with open(os.path.join(out_dir, "window.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


def first():
    run(step_load_project)
    QTimer.singleShot(4000, second)


def second():
    for step in (step_main_window, step_layers, step_menu, step_attribute_table):
        run(step)
    QTimer.singleShot(1500, third)


def third():
    run(step_close_table)
    # os dois dialogos modais, um depois do outro (o timer de leitura de cada um fecha o dialogo)
    run(step_layer_properties)
    QTimer.singleShot(500, fourth)


def fourth():
    run(step_options)
    QTimer.singleShot(500, fifth)


def fifth():
    run(step_open_dialog)
    QTimer.singleShot(2500, sixth)


def sixth():
    for step in (step_algorithm, step_combo, step_line_edit, step_close_dialog):
        run(step)
    finish()


QTimer.singleShot(3000, first)
