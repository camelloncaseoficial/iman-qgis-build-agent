# Fatos do tema padrao e dos padroes de projeto (fatia 049), rodado pelo proprio QGIS via --code
# (Test-ThemeDefaults.ps1), no build, no QGIS oficial e na arvore instalada, sempre com perfil descartavel.
# So coleta fatos e capturas: quem decide o que passa e o Test-ThemeDefaults.ps1, contra iman/brand/brand.json.
# Cada passo que quebra vira fato em "errors", nao derruba a rodada.
import json
import os

from qgis.core import QgsApplication, QgsPointXY, QgsProject, QgsSettings
from qgis.PyQt import sip
from qgis.PyQt.QtCore import QPoint, Qt, QTimer
from qgis.PyQt.QtGui import QColor, QFontMetrics
from qgis.PyQt.QtWidgets import (
    QAbstractButton,
    QApplication,
    QComboBox,
    QDockWidget,
    QLineEdit,
    QRadioButton,
    QScrollBar,
    QStackedWidget,
    QStatusBar,
    QStyle,
    QStyleOptionFrame,
    QTabBar,
    QToolBar,
    QToolTip,
    QWidget,
)
from qgis.gui import QgsProjectionSelectionWidget
from qgis.utils import iface

out_dir = os.environ["IMAN_THEME_OUT"]
project_path = os.environ.get("IMAN_THEME_PROJECT", "")
captures = os.environ.get("IMAN_THEME_CAPTURES", "0") == "1"
facts = {"captures": {}}
# o mesmo ponto das capturas da distro (#022): Leste e Norte de SIRGAS 2000 / UTM 24S
COORDINATE = QgsPointXY(555519.9, 9585490.5)


def save(widget, name):
    if captures and widget is not None:
        widget.grab().save(os.path.join(out_dir, name))
        facts["captures"][name] = [widget.width(), widget.height()]


def run(step):
    try:
        step()
    except Exception as err:
        facts.setdefault("errors", {})[step.__name__] = repr(err)


def ink(widget):
    """Pixels que diferem da cor do canto: um botao sem icone desenhado tem tinta zero."""
    image = widget.grab().toImage()
    if image.isNull() or image.width() == 0:
        return {"ink": 0, "pixels": 0}
    base = QColor(image.pixel(0, 0))
    count = 0
    for x in range(image.width()):
        for y in range(image.height()):
            c = QColor(image.pixel(x, y))
            if abs(c.red() - base.red()) + abs(c.green() - base.green()) + abs(c.blue() - base.blue()) > 60:
                count += 1
    return {"ink": count, "pixels": image.width() * image.height()}


def step_theme():
    settings = QgsSettings()
    themes = QgsApplication.uiThemes()
    facts["theme"] = {
        "themeName": QgsApplication.themeName(),
        "styleSheetLength": len(QApplication.instance().styleSheet()),
        "qtStyle": QApplication.style().metaObject().className(),
        "uiThemes": sorted(themes.keys()),
        "themePaths": {k: v for k, v in themes.items() if v},
        "defaultThemesFolder": QgsApplication.defaultThemesFolder(),
        "userThemesFolder": QgsApplication.userThemesFolder(),
        "settingUITheme": settings.value("UI/UITheme", None),
    }


def step_crs_start():
    settings = QgsSettings()
    project = QgsProject.instance()
    facts["crs"] = {
        "atStart": project.crs().authid(),
        "defaultProjectCrs": settings.value("projections/defaultProjectCrs", None, section=QgsSettings.App),
        "newProjectCrsBehavior": settings.value("projections/newProjectCrsBehavior", None, section=QgsSettings.App),
        "layerDefaultCrs": settings.value("Projections/layerDefaultCrs", None),
        "unknownCrsBehavior": settings.value("projections/unknownCrsBehavior", None, section=QgsSettings.App),
        "defaultCrsForNewLayers": project.defaultCrsForNewLayers().authid(),
    }


def step_crs_new_project():
    iface.newProject(False)
    QApplication.processEvents()
    facts["crs"]["afterNewProject"] = QgsProject.instance().crs().authid()
    facts["crs"]["afterNewProjectDescription"] = QgsProject.instance().crs().description()


def step_distro_key():
    # a chave que a distro gravava ([app] projections\layerDefaultCrs): com um valor distinto, o QGIS a le?
    settings = QgsSettings()
    probe = "EPSG:5880"
    before = QgsProject.instance().defaultCrsForNewLayers().authid()
    settings.setValue("projections/layerDefaultCrs", probe, section=QgsSettings.App)
    during = QgsProject.instance().defaultCrsForNewLayers().authid()
    settings.remove("projections/layerDefaultCrs", section=QgsSettings.App)
    settings.setValue("Projections/layerDefaultCrs", probe)
    with_read_key = QgsProject.instance().defaultCrsForNewLayers().authid()
    settings.remove("Projections/layerDefaultCrs")
    facts["distroLayerKey"] = {
        "probe": probe,
        "before": before,
        "withDistroKey_app_projections_layerDefaultCrs": during,
        "withKey_Projections_layerDefaultCrs": with_read_key,
        "after": QgsProject.instance().defaultCrsForNewLayers().authid(),
    }


def step_options():
    # o dialogo Opcoes e modal: le e captura de dentro dele, por um timer armado antes de abrir
    QTimer.singleShot(2500, read_options)
    iface.showOptionsDialog(iface.mainWindow(), "mOptionsPageCRS")


def read_options():
    dialog = None
    for w in QApplication.topLevelWidgets():
        if w.metaObject().className() == "QgsOptions" and w.isVisible():
            dialog = w
    if dialog is None:
        facts["options"] = {"found": False}
        return
    info = {"found": True}
    try:
        # o sip devolve os seletores de SRC do dialogo como QWidget: o cast da a classe deles
        for key, name in (("projectGlobalCrs", "leProjectGlobalCrs"), ("layerGlobalCrs", "leLayerGlobalCrs")):
            widget = dialog.findChild(QWidget, name)
            info[key] = sip.cast(widget, QgsProjectionSelectionWidget).crs().authid() if widget is not None else None
        for name in ("radProjectUseCrsOfFirstLayer", "radProjectUseDefaultCrs"):
            radio = dialog.findChild(QRadioButton, name)
            info[name] = {"checked": radio.isChecked(), "text": radio.text()} if radio is not None else None
        combo = dialog.findChild(QComboBox, "cmbUITheme")
        info["cmbUITheme"] = {"current": combo.currentText(), "items": [combo.itemText(i) for i in range(combo.count())]} if combo else None
        stack = dialog.findChild(QStackedWidget, "mOptionsStackedWidget")
        crs_page = dialog.findChild(QWidget, "mOptionsPageCRS")
        general_page = dialog.findChild(QWidget, "mOptionsPageGeneral")
        if stack is not None and crs_page is not None:
            stack.setCurrentWidget(_page_of(stack, crs_page))
            QApplication.processEvents()
            save(dialog, "07-opcoes-src.png")
        if stack is not None and general_page is not None:
            stack.setCurrentWidget(_page_of(stack, general_page))
            QApplication.processEvents()
            save(dialog, "08-opcoes-geral.png")
            bars = [b for b in dialog.findChildren(QScrollBar) if b.isVisible() and b.orientation() == Qt.Vertical]
            if bars:
                save(bars[0], "11-barra-de-rolagem.png")
                info["scrollBarWidth"] = bars[0].width()
    except Exception as err:
        info["error"] = repr(err)
    facts["options"] = info
    dialog.reject()


def _page_of(stack, widget):
    while widget is not None and widget.parent() is not stack:
        widget = widget.parent()
    return widget


def step_load_project():
    if project_path:
        facts["projectRead"] = QgsProject.instance().read(project_path)
        iface.mapCanvas().zoomToFullExtent()
    window = iface.mainWindow()
    window.showNormal()
    window.resize(1536, 960)
    if captures:
        # o Navegador lista as unidades da maquina (com nome e e-mail de conta): fora das capturas do laudo publico
        window.findChild(QDockWidget, "Browser").hide()
    QApplication.processEvents()
    # a coordenada e a dica entram aqui, antes da espera: a barra de status refaz o layout e a dica aparece no
    # proximo ciclo de eventos (capturadas logo depois de criadas, as duas saiam incompletas)
    iface.mapCanvas().xyCoordinates.emit(COORDINATE)
    QToolTip.showText(window.mapToGlobal(QPoint(300, 300)), "Dica do IMAN Terra: SIRGAS 2000 / UTM 24S", window)


def step_main_window():
    save(iface.mainWindow(), "01-janela.png")
    save(iface.mainWindow().menuBar(), "03-barra-de-menus.png")
    toolbar = iface.mainWindow().findChild(QToolBar, "mFileToolBar")
    save(toolbar, "04-barra-de-ferramentas.png")


def step_menu():
    bar = iface.mainWindow().menuBar()
    menu = bar.actions()[0].menu()
    menu.popup(bar.mapToGlobal(QPoint(0, bar.height())))
    QApplication.processEvents()
    save(menu, "02-menu-aberto.png")
    facts["menuTitle"] = bar.actions()[0].text()
    menu.hide()


def step_dock():
    # D1: o botao de fechar tem icone desenhado; D4: a faixa de titulo cabe o texto
    dock = iface.mainWindow().findChild(QDockWidget, "Layers")
    dock.show()
    dock.raise_()
    QApplication.processEvents()
    buttons = {}
    for b in dock.findChildren(QAbstractButton):
        if b.objectName() in ("qt_dockwidget_closebutton", "qt_dockwidget_floatbutton"):
            entry = {"visible": b.isVisible(), "size": [b.width(), b.height()], "iconNull": b.icon().isNull()}
            entry.update(ink(b))
            buttons[b.objectName()] = entry
    title_height = dock.widget().geometry().top() if dock.widget() is not None else None
    font = dock.font()
    font.setWeight(60)
    metrics = QFontMetrics(font)
    facts["dock"] = {
        "title": dock.windowTitle(),
        "buttons": buttons,
        "titleBarHeight": title_height,
        "titleFontHeight": metrics.height(),
        "titleTextWidth": metrics.horizontalAdvance(dock.windowTitle()),
        "dockWidth": dock.width(),
    }
    title = dock.grab().copy(0, 0, dock.width(), max(title_height or 0, 1) + 4)
    if captures:
        title.save(os.path.join(out_dir, "05-dock-titulo.png"))
        facts["captures"]["05-dock-titulo.png"] = [title.width(), title.height()]
    save(dock, "05b-dock-inteiro.png")


def step_close_reopen_dock():
    # D1 por comportamento: o botao de fechar fecha a dock e a acao do menu a traz de volta
    dock = iface.mainWindow().findChild(QDockWidget, "Layers")
    close = dock.findChild(QAbstractButton, "qt_dockwidget_closebutton")
    close.click()
    QApplication.processEvents()
    closed = not dock.isVisible()
    dock.toggleViewAction().trigger()
    QApplication.processEvents()
    facts["dockCloseReopen"] = {"closedByButton": closed, "reopened": dock.isVisible()}


def step_tabs():
    window = iface.mainWindow()
    layers = window.findChild(QDockWidget, "Layers")
    browser = window.findChild(QDockWidget, "Browser")
    browser.show()
    window.tabifyDockWidget(layers, browser)
    layers.raise_()
    QApplication.processEvents()
    bars = [b for b in window.findChildren(QTabBar) if b.isVisible() and b.count() >= 2]
    if bars:
        save(bars[0], "06-abas.png")
        facts["tabs"] = [bars[0].tabText(i) for i in range(bars[0].count())]


def step_status_bar():
    # D2: a coordenada inteira cabe no campo de largura fixa da barra de status
    status = iface.mainWindow().findChild(QStatusBar)
    coord = None
    for e in status.findChildren(QLineEdit):
        if e.parent() is not None and e.parent().metaObject().className() == "QgsStatusBarCoordinatesWidget":
            coord = e
    info = {"found": coord is not None}
    if coord is not None:
        text = coord.text()
        option = QStyleOptionFrame()
        coord.initStyleOption(option)
        contents = coord.style().subElementRect(QStyle.SE_LineEditContents, option, coord)
        margins = coord.textMargins()
        # QLineEdit reserva 2 px de cada lado dentro da area de conteudo (QLineEditPrivate::horizontalMargin)
        available = contents.width() - margins.left() - margins.right() - 4
        needed = coord.fontMetrics().horizontalAdvance(text)
        info.update({
            "text": text,
            "width": coord.width(),
            "minimumWidth": coord.minimumWidth(),
            "maximumWidth": coord.maximumWidth(),
            "contentsWidth": contents.width(),
            "available": available,
            "needed": needed,
            "fits": needed <= available,
        })
        save(coord, "09b-campo-de-coordenadas.png")
    facts["coordinateField"] = info
    save(status, "09-barra-de-status.png")
    crs_button = [b for b in status.findChildren(QAbstractButton) if b.isVisible() and "EPSG" in b.text()]
    facts["statusBarCrs"] = crs_button[0].text() if crs_button else None


def step_attribute_table():
    layers = list(QgsProject.instance().mapLayers().values())
    if not layers:
        return
    table = iface.showAttributeTable(layers[0])
    QApplication.processEvents()
    if table is not None:
        table.resize(700, 300)
        QApplication.processEvents()
        save(table, "10-tabela-de-atributos.png")
        table.close()


def step_tooltip():
    tips = [w for w in QApplication.topLevelWidgets() if w.metaObject().className() == "QTipLabel" and w.isVisible()]
    if tips:
        save(tips[0], "12-dica.png")
    QToolTip.hideText()


def step_switch_themes():
    # T9: os temas de fabrica seguem escolhiveis; volta ao tema de partida no fim
    start = QgsApplication.themeName()
    result = {}
    for name in ("Blend of Gray", "Night Mapping", start):
        QgsApplication.setUITheme(name)
        QApplication.processEvents()
        result[name] = {"themeName": QgsApplication.themeName(), "styleSheetLength": len(QApplication.instance().styleSheet())}
        if name != start:
            save(iface.mainWindow(), "13-tema-%s.png" % name.lower().replace(" ", "-"))
    facts["switchThemes"] = result


def finish():
    with open(os.path.join(out_dir, "theme.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


def main():
    for step in (step_theme, step_crs_start, step_crs_new_project, step_distro_key, step_options):
        run(step)
    QTimer.singleShot(500, second)


def second():
    for step in (step_load_project,):
        run(step)
    QTimer.singleShot(4000, third)


def third():
    steps = [step_dock, step_close_reopen_dock, step_status_bar]
    if captures:
        steps = [step_tooltip, step_main_window, step_menu] + steps + [step_attribute_table, step_tabs]
    steps.append(step_switch_themes)
    for step in steps:
        run(step)
    finish()


QTimer.singleShot(3000, main)
