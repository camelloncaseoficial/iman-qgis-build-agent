# Capturas e cliques do prototipo da fatia 059 (pagina inicial e "Sobre o IMAN Terra"), rodado pelo build via --code
# (Invoke-HomeCaptures.ps1), com perfil descartavel. Cada passo grava PNG em IMAN_SMOKE_OUT e o que leu em
# home-captures.json; um passo que quebra vira fato, nunca para a rodada. So coleta fatos: o laudo os le.
import json
import os
import traceback

from qgis.core import Qgis, QgsApplication, QgsProject, QgsSettings
from qgis.PyQt.QtCore import QCoreApplication, QEvent, QPoint, QPointF, QRect, Qt, QTimer, QUrl
from qgis.PyQt.QtGui import QColor, QFont, QImage, QMouseEvent, QPainter
from qgis.PyQt.QtWidgets import (
    QAction,
    QApplication,
    QDockWidget,
    QFrame,
    QLabel,
    QListView,
    QListWidget,
    QMenu,
    QPushButton,
    QStackedWidget,
    QTabWidget,
    QTextBrowser,
    QWidget,
)
from qgis.utils import iface

out_dir = os.environ["IMAN_SMOKE_OUT"]
projects = [p for p in os.environ["IMAN_HOME_PROJECTS"].split(";") if p]
distro_shots = os.environ.get("IMAN_DISTRO_SHOTS", "")
facts = {"steps": {}, "errors": {}, "message_log": []}
window = iface.mainWindow()
current_step = ["arranque"]


def log_message(message, tag, level):
    # o registro de mensagens do QGIS durante a rodada, com o passo em que cada mensagem chegou
    if level >= Qgis.Warning or "Python" in tag:
        facts["message_log"].append({"step": current_step[0], "tag": tag, "level": int(level), "message": message[:4000]})


QgsApplication.messageLog().messageReceived.connect(log_message)


def save_facts():
    with open(os.path.join(out_dir, "home-captures.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, ensure_ascii=False, indent=1)


def save(widget, name):
    widget.grab().save(os.path.join(out_dir, name))
    return name


def save_with_popup(name, popup):
    """A janela principal com o menu aberto por cima, na posicao real dele (composicao de duas grab())."""
    image = window.grab().toImage()
    painter = QPainter(image)
    painter.drawImage(window.mapFromGlobal(popup.mapToGlobal(QPoint(0, 0))), popup.grab().toImage())
    painter.end()
    image.save(os.path.join(out_dir, name))
    return name


def side_by_side(ours, distro, name, left_label, right_label):
    """Lado a lado: a captura da distro congelada (referencia) e a deste build, na mesma altura."""
    a = QImage(os.path.join(distro_shots, distro))
    b = QImage(os.path.join(out_dir, ours))
    if a.isNull() or b.isNull():
        return None
    height = 820
    a = a.scaledToHeight(height, Qt.SmoothTransformation)
    b = b.scaledToHeight(height, Qt.SmoothTransformation)
    gap, top = 24, 40
    image = QImage(a.width() + b.width() + 3 * gap, height + top + gap, QImage.Format_RGB32)
    image.fill(QColor("#FFFFFF"))
    painter = QPainter(image)
    font = QFont()
    font.setPixelSize(18)
    font.setBold(True)
    painter.setFont(font)
    painter.setPen(QColor("#1A231D"))
    painter.drawText(QRect(gap, 0, a.width(), top), Qt.AlignVCenter | Qt.AlignLeft, left_label)
    painter.drawText(QRect(2 * gap + a.width(), 0, b.width(), top), Qt.AlignVCenter | Qt.AlignLeft, right_label)
    painter.drawImage(gap, top, a)
    painter.drawImage(2 * gap + a.width(), top, b)
    painter.end()
    image.save(os.path.join(out_dir, name))
    return name


def click(widget, pos=None):
    pos = pos if pos is not None else widget.rect().center()
    press = QMouseEvent(QEvent.MouseButtonPress, QPointF(pos), Qt.LeftButton, Qt.LeftButton, Qt.NoModifier)
    release = QMouseEvent(QEvent.MouseButtonRelease, QPointF(pos), Qt.LeftButton, Qt.NoButton, Qt.NoModifier)
    QApplication.sendEvent(widget, press)
    QApplication.sendEvent(widget, release)


def action(name):
    return window.findChild(QAction, name)


def central():
    for stack in window.findChildren(QStackedWidget):
        if stack.count() > 1 and stack.widget(1) is not None and stack.widget(1).objectName() == "imanHomePage":
            return stack
    return None


def central_state():
    stack = central()
    if stack is None:
        return None
    current = stack.currentWidget()
    return {"index": stack.currentIndex(), "widget": current.metaObject().className(), "objectName": current.objectName()}


def home():
    return window.findChild(QWidget, "imanHomePage")


def label_text(name):
    label = window.findChild(QLabel, name)
    return label.text() if label is not None else None


def close_project():
    QgsProject.instance().setDirty(False)
    action("mActionCloseProject").trigger()
    QApplication.processEvents()


def top_level(class_name):
    return [w for w in QApplication.topLevelWidgets() if w.isVisible() and w.metaObject().className() == class_name]


# ---------------------------------------------------------------- passos

def step_start():
    window.showMaximized()
    facts["window_title"] = window.windowTitle()
    # o Navegador lista as unidades da maquina com o nome e o e-mail das contas: fora da captura que vai para o laudo
    browser = window.findChild(QDockWidget, "Browser")
    if browser is not None:
        browser.hide()
    facts["browser_dock_hidden"] = browser is not None


def step_empty():
    page = home()
    facts["steps"]["inicio_sem_recentes"] = {
        "central": central_state(),
        "eyebrow": label_text("imanHomeEyebrow"),
        "heading": label_text("imanHomeHeading"),
        "subtitle": label_text("imanHomeSubtitle"),
        "version_badge": label_text("imanHomeVersionBadge"),
        "crs_badge": label_text("imanHomeCrsBadge"),
        "cards": [
            {"action": card.property("imanAction"), "texts": [l.text() for l in card.findChildren(QLabel) if l.text()]}
            for card in page.findChildren(QFrame, "imanHomeCard")
        ],
        "empty_state_visible": page.findChild(QLabel, "imanHomeEmpty").isVisible(),
        "empty_state": label_text("imanHomeEmpty"),
        "recent_list_visible": page.findChild(QListView, "imanHomeRecentProjects").isVisible(),
        "templates": [
            page.findChild(QListView, "imanHomeTemplates").model().index(r, 0).data(Qt.UserRole + 1)
            for r in range(page.findChild(QListView, "imanHomeTemplates").model().rowCount())
        ],
        "credits": label_text("imanHomeCredits"),
        "window_size": [window.width(), window.height()],
        "capture": save(window, "01-inicio-sem-recentes.png"),
    }


def card(action_name):
    for c in home().findChildren(QFrame, "imanHomeCard"):
        if c.property("imanAction") == action_name:
            return c
    return None


def step_card_new_project():
    fact = {"before": central_state()}
    click(card("mActionNewProject"))
    QApplication.processEvents()
    fact["after"] = central_state()
    fact["capture"] = save(window, "07a-cartao-novo-projeto.png")
    close_project()
    fact["after_close"] = central_state()
    facts["steps"]["cartao_novo_projeto"] = fact


def handle_modal(fact, name, close):
    def handler():
        modal = QApplication.activeModalWidget()
        fact["modal"] = modal.metaObject().className() if modal else None
        fact["modal_title"] = modal.windowTitle() if modal else None
        if modal:
            fact["capture"] = save(modal, name)
            close(modal)
    return handler


def step_card_open_project():
    fact = {}
    # o dialogo nativo do Windows nao e um QWidget: so o do Qt pode ser fotografado e fechado por este script
    QCoreApplication.setAttribute(Qt.AA_DontUseNativeDialogs, True)
    # o dialogo abre na ultima pasta de projeto (padrao: a pasta pessoal do Windows, que nao vai para o laudo): a dos
    # projetos descartaveis desta rodada
    QgsSettings().setValue("UI/lastProjectDir", os.path.dirname(projects[0]))
    def only_this_run(modal):
        # a barra lateral do dialogo do Qt lista a pasta pessoal pelo nome da conta do Windows: so a pasta da rodada
        if hasattr(modal, "setSidebarUrls"):
            modal.setSidebarUrls([QUrl.fromLocalFile(os.path.dirname(projects[0]))])
            QApplication.processEvents()

    def grab_and_close():
        modal = QApplication.activeModalWidget()
        if modal:
            only_this_run(modal)
        handle_modal(fact, "07b-cartao-abrir-projeto.png", lambda m: m.reject())()

    QTimer.singleShot(1500, grab_and_close)
    click(card("mActionOpenProject"))
    QCoreApplication.setAttribute(Qt.AA_DontUseNativeDialogs, False)
    fact["after"] = central_state()
    facts["steps"]["cartao_abrir_projeto"] = fact


def step_card_data():
    # o gerenciador de fontes de dados abre nao modal (QgisApp::dataSourceManager, show())
    click(card("mActionDataSourceManager"))
    QApplication.processEvents()
    facts["steps"]["cartao_carregar_dados"] = {}
    QTimer.singleShot(1000, guarded(step_card_data_capture))


def step_card_data_capture():
    fact = facts["steps"]["cartao_carregar_dados"]
    dialogs = top_level("QgsDataSourceManagerDialog")
    fact["dialogs"] = [d.windowTitle() for d in dialogs]
    if dialogs:
        # a pagina Navegador, que abre primeiro, lista as unidades da maquina com o nome e o e-mail das contas: a foto
        # e da pagina Vetor do mesmo dialogo
        pages = dialogs[0].findChild(QListWidget, "mOptionsListWidget")
        fact["first_page"] = pages.currentItem().text() if pages else None
        if pages:
            pages.setCurrentRow(1)
            QApplication.processEvents()
            fact["captured_page"] = pages.currentItem().text()
        fact["capture"] = save(dialogs[0], "07c-cartao-carregar-dados.png")
        dialogs[0].close()


def step_card_layout():
    fact = {}

    def accept_name(modal):
        fact["layout_name"] = modal.name() if hasattr(modal, "name") else None
        modal.accept()

    QTimer.singleShot(1500, handle_modal(fact, "07d-cartao-novo-layout-nome.png", accept_name))
    click(card("mActionNewPrintLayout"))
    facts["steps"]["cartao_novo_layout"] = fact
    QTimer.singleShot(2500, guarded(step_card_layout_designer))


def step_card_layout_designer():
    fact = facts["steps"]["cartao_novo_layout"]
    designers = top_level("QgsLayoutDesignerDialog")
    fact["designers"] = [d.windowTitle() for d in designers]
    if designers:
        fact["capture_designer"] = save(designers[0], "07e-cartao-novo-layout-designer.png")
        designers[0].close()
    QApplication.processEvents()
    fact["layouts_in_project"] = len(QgsProject.instance().layoutManager().layouts())
    close_project()
    fact["after_close"] = central_state()


def step_seed_recents():
    fact = {"opened": []}
    for path in projects:
        iface.addProject(path)
        QApplication.processEvents()
        state = central_state()
        fact["opened"].append({"path": os.path.basename(path), "title": QgsProject.instance().title(), "central": state})
        close_project()
    fact["after_close"] = central_state()
    facts["steps"]["recentes_semeados"] = fact


def recent_view():
    return home().findChild(QListView, "imanHomeRecentProjects")


def step_with_recents():
    view = recent_view()
    model = view.model()
    facts["steps"]["inicio_com_recentes"] = {
        "central": central_state(),
        "recents": [
            {"title": model.index(r, 0).data(Qt.UserRole + 1), "path": model.index(r, 0).data(Qt.UserRole + 6)}
            for r in range(model.rowCount())
        ],
        "empty_state_visible": home().findChild(QLabel, "imanHomeEmpty").isVisible(),
        "capture": save(window, "02-inicio-com-recentes.png"),
    }


def step_recent_context_menu():
    view = recent_view()
    rect = view.visualRect(view.model().index(0, 0))
    fact = {}

    def grab_menu():
        menus = [m for m in QApplication.topLevelWidgets() if isinstance(m, QMenu) and m.isVisible()]
        fact["items"] = [a.text() for a in menus[0].actions() if not a.isSeparator()] if menus else None
        if menus:
            fact["capture"] = save_with_popup("02b-recente-menu-de-contexto.png", menus[0])
            menus[0].hide()

    view.customContextMenuRequested.emit(rect.center())
    QApplication.processEvents()
    grab_menu()
    facts["steps"]["recente_menu_de_contexto"] = fact


def step_open_recent():
    view = recent_view()
    index = view.model().index(1, 0)
    title = index.data(Qt.UserRole + 1)
    click(view.viewport(), view.visualRect(index).center())
    QApplication.processEvents()
    iface.mapCanvas().zoomToFullExtent()
    iface.mapCanvas().refresh()
    facts["steps"]["recente_aberto"] = {
        "clicked_title": title,
        "project_title": QgsProject.instance().title(),
        "project_file": os.path.basename(QgsProject.instance().fileName()),
        "layers": len(QgsProject.instance().mapLayers()),
        "central": central_state(),
    }
    QTimer.singleShot(2000, guarded(step_open_recent_capture))


def step_open_recent_capture():
    fact = facts["steps"]["recente_aberto"]
    fact["capture"] = save(window, "08a-recente-aberto-mapa.png")
    close_project()
    fact["after_close"] = central_state()
    fact["capture_after_close"] = save(window, "08b-recente-fechado-volta-a-pagina.png")


def step_small_window():
    window.showNormal()
    QApplication.processEvents()
    frame = window.frameGeometry().size() - window.geometry().size()
    window.resize(1366 - frame.width(), 768 - frame.height())
    window.move(0, 0)


def step_small_window_capture():
    facts["steps"]["inicio_1366x768"] = {
        "frame_size": [window.frameGeometry().width(), window.frameGeometry().height()],
        "client_size": [window.width(), window.height()],
        "capture": save(window, "03-inicio-1366x768.png"),
    }
    window.showMaximized()


def step_help_menu():
    menu = window.findChild(QMenu, "mHelpMenu")
    bar = window.menuBar()
    rect = bar.actionGeometry(menu.menuAction())
    menu.popup(bar.mapToGlobal(rect.bottomLeft()))
    QApplication.processEvents()
    items = [a.text() for a in menu.actions() if a.isVisible() and not a.isSeparator()]
    home_page = action("mActionQgisHomePage")
    facts["steps"]["menu_ajuda"] = {
        "items": items,
        "qgis_home_page_action_exists": home_page is not None,
        "qgis_home_page_text": home_page.text() if home_page else None,
        "qgis_home_page_in_menu": home_page in menu.actions() if home_page else None,
        "qgis_home_page_widgets": [w.objectName() or w.metaObject().className() for w in home_page.associatedWidgets()] if home_page else None,
        "about_text": action("mActionAbout").text(),
        "capture": save_with_popup("04-menu-ajuda.png", menu),
    }
    menu.hide()


def step_about():
    action("mActionAbout").trigger()
    QApplication.processEvents()
    dialogs = [w for w in QApplication.topLevelWidgets() if w.objectName() == "imanAboutDialog" and w.isVisible()]
    fact = {"opened": [d.metaObject().className() for d in dialogs], "qgs_about_visible": bool(top_level("QgsAbout"))}
    if dialogs:
        dialog = dialogs[0]
        dialog.resize(760, 760)
        QApplication.processEvents()
        notices = dialog.findChild(QTextBrowser, "imanAboutNotices")
        bar = notices.verticalScrollBar()
        bar.setValue(bar.maximum() // 2)
        QApplication.processEvents()
        fact.update({
            "title": dialog.windowTitle(),
            "labels": {l.objectName(): l.text() for l in dialog.findChildren(QLabel) if l.objectName()},
            "notices_source": notices.toolTip(),
            "notices_chars": len(notices.toPlainText()),
            "notices_scroll": [bar.value(), bar.maximum()],
            "buttons": [b.text() for b in dialog.findChildren(QPushButton)],
            "capture": save(dialog, "05-sobre-iman-terra.png"),
        })
    facts["steps"]["sobre_iman_terra"] = fact


def step_about_qgis():
    dialogs = [w for w in QApplication.topLevelWidgets() if w.objectName() == "imanAboutDialog" and w.isVisible()]
    fact = {}
    if dialogs:
        button = dialogs[0].findChild(QPushButton, "imanAboutQgisButton")
        fact["button"] = button.text()
        button.click()
        QApplication.processEvents()
    abouts = top_level("QgsAbout")
    fact["qgs_about_opened"] = bool(abouts)
    if abouts:
        about = abouts[0]
        tabs = about.findChild(QTabWidget)
        fact["title"] = about.windowTitle()
        fact["tabs"] = [tabs.tabText(i) for i in range(tabs.count())] if tabs else None
        fact["capture"] = save(about, "06-sobre-o-qgis.png")
        about.close()
    for d in dialogs:
        d.close()
    facts["steps"]["sobre_o_qgis"] = fact


def step_side_by_side():
    facts["lado_a_lado"] = {
        "inicio-sem-recentes": side_by_side("01-inicio-sem-recentes.png", "vitrine-home.png", "lado-a-lado-inicio-sem-recentes.png", "Distro 0.3.0 (referencia)", "Build da fatia 059"),
        "inicio-com-recentes": side_by_side("02-inicio-com-recentes.png", "vitrine-home.png", "lado-a-lado-inicio-com-recentes.png", "Distro 0.3.0 (referencia)", "Build da fatia 059"),
        "inicio-1366x768": side_by_side("03-inicio-1366x768.png", "vitrine-home.png", "lado-a-lado-inicio-1366x768.png", "Distro 0.3.0 (referencia)", "Build da fatia 059, 1366x768"),
        "sobre": side_by_side("05-sobre-iman-terra.png", "vitrine-sobre.png", "lado-a-lado-sobre.png", "Distro 0.3.0 (referencia)", "Build da fatia 059"),
    }


def step_exit():
    save_facts()
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


STEPS = [
    (3000, step_start),
    (2500, step_empty),
    (500, step_card_new_project),
    (1500, step_card_open_project),
    (1500, step_card_data),
    (1500, step_card_layout),
    (6000, step_seed_recents),
    (2000, step_with_recents),
    (500, step_recent_context_menu),
    (500, step_open_recent),
    (5000, step_small_window),
    (2000, step_small_window_capture),
    (2000, step_help_menu),
    (500, step_about),
    (1000, step_about_qgis),
    (1000, step_side_by_side),
    (500, step_exit),
]


def guarded(fn):
    def call():
        try:
            fn()
        except Exception:
            facts["errors"][fn.__name__] = traceback.format_exc()
        save_facts()
    return call


def run(i=0):
    if i >= len(STEPS):
        return
    delay, fn = STEPS[i]

    def go():
        current_step[0] = fn.__name__
        try:
            fn()
        except Exception:
            facts["errors"][fn.__name__] = traceback.format_exc()
        save_facts()
        run(i + 1)

    QTimer.singleShot(delay, go)


run()
