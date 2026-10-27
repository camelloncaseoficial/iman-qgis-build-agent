# Capturas por regiao para o lado a lado do laudo (A13 do briefing 044), rodado pelo QGIS via --code
# (Invoke-BrandCaptures.ps1), no build e no QGIS oficial, com perfil descartavel.
# Cada passo grava um PNG em IMAN_SMOKE_OUT e o que leu em captures.json; um passo que quebra vira fato.
import json
import os

from qgis.core import QgsApplication, QgsProject, QgsSettings
from qgis.gui import QgsBrowserTreeView
from qgis.PyQt.QtCore import QCoreApplication, Qt, QTimer
from qgis.PyQt.QtGui import QColor, QPixmap
from qgis.PyQt.QtWidgets import QAction, QApplication, QDockWidget, QMenu, QSplashScreen, QTreeView, QTreeWidget
from qgis.utils import iface

out_dir = os.environ["IMAN_SMOKE_OUT"]
project_path = os.environ["IMAN_SMOKE_PROJECT"]
work_dir = os.path.dirname(project_path)
facts = {"title_at_start": iface.mainWindow().windowTitle()}


def save(widget, name):
    path = os.path.join(out_dir, name)
    widget.grab().save(path)
    return name


def step_main():
    QgsProject.instance().read(project_path)
    iface.mapCanvas().zoomToFullExtent()
    facts["title_after_load"] = iface.mainWindow().windowTitle()


def step_window():
    facts["main"] = save(iface.mainWindow(), "01-janela.png")


def step_splash():
    # o splash como o main.cpp o monta (600x300, mesma escala), com a mensagem final que o QgisApp escreve nele
    pixmap = QPixmap(":/images/splash/splash.png").scaled(600, 300, Qt.KeepAspectRatio, Qt.SmoothTransformation)
    splash = QSplashScreen(pixmap)
    message = QCoreApplication.translate("QgisApp", "QGIS Ready!")
    splash.showMessage(message, Qt.AlignHCenter | Qt.AlignBottom, QColor(Qt.black))
    facts["splash_message"] = message
    facts["splash"] = save(splash, "02-splash-mensagem-final.png")


def step_toolbox():
    dock = iface.mainWindow().findChild(QDockWidget, "ProcessingToolbox")
    dock.show()
    dock.raise_()
    dock.resize(380, 600)
    view = dock.findChild(QTreeView)
    if view is not None:
        view.collapseAll()
    facts["toolbox"] = save(dock, "03-processamento.png")


def step_help_menu():
    action = iface.mainWindow().findChild(QAction, "mActionHelpContents")
    menu = None
    for m in iface.mainWindow().findChildren(QMenu):
        if action in m.actions():
            menu = m
            break
    menu.popup(iface.mainWindow().mapToGlobal(iface.mainWindow().rect().center()))
    QApplication.processEvents()
    facts["help_menu_items"] = [a.text() for a in menu.actions() if a.isVisible() and not a.isSeparator()]
    facts["help_menu"] = save(menu, "04-menu-ajuda.png")
    menu.hide()


def step_about():
    iface.mainWindow().findChild(QAction, "mActionAbout").trigger()
    QApplication.processEvents()
    about = [w for w in QApplication.topLevelWidgets() if w.metaObject().className() == "QgsAbout" and w.isVisible()]
    if about:
        facts["about_title"] = about[0].windowTitle()
        facts["about"] = save(about[0], "05-sobre.png")
        about[0].close()


def step_browser():
    iface.browserModel().addFavoriteDirectory(work_dir, "smoke")
    QTimer.singleShot(1500, _browser_expand)


def _browser_expand():
    dock = iface.mainWindow().findChild(QDockWidget, "Browser")
    dock.show()
    dock.raise_()
    view = dock.findChild(QgsBrowserTreeView)
    model = view.model()

    def find(parent, text):
        for row in range(model.rowCount(parent)):
            idx = model.index(row, 0, parent)
            if model.data(idx) and text in model.data(idx):
                return idx
        return None

    fav = None
    for row in range(model.rowCount()):
        idx = model.index(row, 0)
        view.collapse(idx)
        if fav is None and model.rowCount(idx) >= 0 and find(idx, "smoke") is not None:
            fav = idx
    if fav is None:
        fav = model.index(0, 0)
    view.expand(fav)
    smoke = find(fav, "smoke")
    if smoke is not None:
        view.expand(smoke)
    QTimer.singleShot(1500, lambda: facts.__setitem__("browser", save(dock, "06-navegador-qgz.png")))


def step_layer_properties():
    layer = list(QgsProject.instance().mapLayers().values())[0]
    QTimer.singleShot(2500, lambda: _grab_modal("07-propriedades-camada.png", "layer_properties"))
    iface.showLayerProperties(layer)


def step_options_providers():
    QTimer.singleShot(2500, lambda: _grab_options())
    iface.showOptionsDialog(iface.mainWindow(), "processingOptions")


def _grab_options():
    dlg = QApplication.activeModalWidget()
    if dlg is None:
        return
    for tree in dlg.findChildren(QTreeWidget) + dlg.findChildren(QTreeView):
        if tree.isVisible():
            tree.expandToDepth(0)
    QApplication.processEvents()
    facts["options_providers"] = save(dlg, "08-opcoes-processamento-provedores.png")
    dlg.reject()


def _grab_modal(name, key):
    dlg = QApplication.activeModalWidget()
    if dlg is None:
        top = [w for w in QApplication.topLevelWidgets() if w.isVisible() and w is not iface.mainWindow()]
        dlg = top[-1] if top else None
    if dlg is not None:
        facts[key] = save(dlg, name)
        facts[key + "_title"] = dlg.windowTitle()
        dlg.close()


STEPS = [step_main, step_window, step_splash, step_toolbox, step_help_menu, step_about, step_browser,
         step_layer_properties, step_options_providers]


def run(i=0):
    if i >= len(STEPS):
        QTimer.singleShot(3000, finish)
        return
    try:
        STEPS[i]()
    except Exception as err:
        facts.setdefault("errors", {})[STEPS[i].__name__] = repr(err)
    QTimer.singleShot(5000 if i == 0 else 3500, lambda: run(i + 1))


def finish():
    facts["translation"] = QgsApplication.instance().translation()
    with open(os.path.join(out_dir, "captures.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


QTimer.singleShot(3000, run)
