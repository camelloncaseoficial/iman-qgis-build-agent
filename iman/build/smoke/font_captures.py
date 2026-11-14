# Fonte da interface (fatia 067, A1 e A3 a A7), rodado pelo proprio QGIS via --code (Invoke-FontCaptures.ps1), no
# build da develop (ANTES) e no desta branch (DEPOIS), sempre com perfil novo e as mesmas janelas nos mesmos tamanhos.
# So coleta fatos e capturas; nada e corrigido. Por tela:
#   - a captura da janela de cima (pixels fisicos);
#   - todo texto visivel dela, com o que ele precisa e o que tem (largura ou altura, em pixels logicos) e o retangulo
#     na janela: rotulos, botoes, caixas de selecao, titulos de grupo, abas, caixas de lista, caixas de numero,
#     cabecalhos de tabela, itens de listas e arvores e titulos de paineis. "corta" quando o texto nao cabe e o Qt o
#     recorta; "reticencias" quando o Qt o abrevia; "fora-da-vista" quando a aba fica alem da barra.
# Com IMAN_FONT_REFERENCE (o font.json de uma rodada anterior), compara: textos com problema so nesta rodada, so na
# outra e nas duas, por tela, com o recorte de cada texto novo nas duas capturas (a3-NN-antes.png e a3-NN-depois.png).
# A4: largura de avanco dos algarismos, o campo de coordenadas com a coordenada mais larga do Ceara em EPSG:31984 e o
# cursor passando pelo mapa (eventos de mouse sinteticos no mapa, o cursor do usuario nao se mexe).
# A5: o menu Projeto e a pagina Geral das Opcoes ampliados 400% sem suavizar.
# A6: o titulo de um QGroupBox (font-weight 600 do QGIS) e um negrito: familia, estilo e peso resolvidos, e se o
# desenho do peso pedido e o da face real (comparacao pixel a pixel com a face SemiBold e com a Bold).
# A7: a fonte padrao de rotulo novo de camada e de rotulo novo no compositor de impressao.
import json
import os
import re

from qgis.core import (
    QgsCoordinateReferenceSystem,
    QgsLayoutItemLabel,
    QgsPalLayerSettings,
    QgsPointXY,
    QgsPrintLayout,
    QgsProject,
    QgsRectangle,
    QgsSettings,
    QgsTextFormat,
)
from qgis.PyQt import sip
from qgis.PyQt.QtCore import QEvent, QPoint, QPointF, QRect, Qt, QTimer
from qgis.PyQt.QtGui import (
    QColor,
    QFont,
    QFontDatabase,
    QFontInfo,
    QFontMetrics,
    QFontMetricsF,
    QImage,
    QMouseEvent,
    QPainter,
    QRawFont,
    QTextDocumentFragment,
)
from qgis.PyQt.QtWidgets import (
    QAbstractButton,
    QAbstractItemView,
    QAbstractSpinBox,
    QAction,
    QApplication,
    QCheckBox,
    QComboBox,
    QDialog,
    QDockWidget,
    QGroupBox,
    QHeaderView,
    QLabel,
    QLineEdit,
    QListWidget,
    QMenu,
    QPushButton,
    QRadioButton,
    QStackedWidget,
    QStatusBar,
    QStyle,
    QStyleOptionButton,
    QStyleOptionComboBox,
    QStyleOptionGroupBox,
    QTabBar,
    QTableView,
    QTabWidget,
    QToolButton,
    QTreeView,
    QWidget,
)
from qgis.utils import iface

out_dir = os.environ["IMAN_FONT_OUT"]
project_path = os.environ.get("IMAN_FONT_PROJECT", "")
reference_path = os.environ.get("IMAN_FONT_REFERENCE", "")
window = iface.mainWindow()
facts = {"screens": {}, "captures": {}, "errors": {}}
state = {}
WINDOW_SIZE = (1536, 960)
# o ponto do 049p (theme_facts.py) e o retangulo do Ceara em EPSG:31984 (SIRGAS 2000 / UTM 24S), com folga: Leste de
# 230 000 a 700 000 e Norte de 9 120 000 a 9 700 000 (o estado vai de cerca de 41,4 a 37,2 graus oeste e de 2,8 a 7,9
# graus sul)
POINT_049P = (555519.9, 9585490.5)
CEARA = QgsRectangle(230000, 9120000, 700000, 9700000)
SAMPLE_TEXT = "Propriedades da camada 0123456789"
UUID = re.compile(r"\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\}")


def run(step):
    try:
        step()
    except Exception as err:
        facts["errors"][step.__name__] = repr(err)


def save_pixmap(pixmap, name):
    if pixmap is None or pixmap.isNull():
        return None
    pixmap.save(os.path.join(out_dir, name))
    facts["captures"][name] = [pixmap.width(), pixmap.height()]
    return name


def top_level(class_name=None, object_name=None):
    for w in QApplication.topLevelWidgets():
        if not w.isVisible():
            continue
        if class_name and w.metaObject().className() != class_name:
            continue
        if object_name and w.objectName() != object_name:
            continue
        return w
    return None


# ---------------------------------------------------------------- fonte

def font_file_names(font):
    """Nomes 1, 2 e 5 (familia, estilo e versao) da tabela name do arquivo que o Qt usa para desenhar a fonte
    (QRawFont): separa a Open Sans embarcada (3.003) de uma Open Sans instalada no Windows (a desta bancada e 1.10)."""
    try:
        data = bytes(QRawFont.fromFont(font).fontTable("name"))
        if len(data) < 6:
            return None
        count = int.from_bytes(data[2:4], "big")
        storage = int.from_bytes(data[4:6], "big")
        names = {}
        for i in range(count):
            rec = data[6 + 12 * i: 18 + 12 * i]
            platform, _, language, name_id, length, offset = (int.from_bytes(rec[j:j + 2], "big") for j in range(0, 12, 2))
            if name_id in (1, 2, 5) and platform == 3 and language == 0x409:
                names[name_id] = data[storage + offset: storage + offset + length].decode("utf-16-be", "replace")
        return {"family": names.get(1), "style": names.get(2), "version": names.get(5)}
    except Exception as err:
        return {"error": repr(err)}


def font_facts(font):
    info = QFontInfo(font)
    return {"family": font.family(), "pointSizeF": font.pointSizeF(), "pixelSize": font.pixelSize(), "weight": font.weight(),
            "bold": font.bold(), "resolvedFamily": info.family(), "resolvedStyle": info.styleName(),
            "resolvedWeight": info.weight(), "resolvedPointSizeF": info.pointSizeF(), "resolvedPixelSize": info.pixelSize(),
            "file": font_file_names(font)}


def step_font():
    font = QApplication.font()
    db = QFontDatabase()
    family = font.family()
    metrics = QFontMetricsF(font)
    digits = {str(d): metrics.horizontalAdvance(str(d)) for d in range(10)}
    screen = QApplication.primaryScreen()
    facts["font"] = {
        "app": font_facts(font),
        "styles": db.styles(family),
        "familiesOpenSansOrSegoe": sorted(f for f in db.families() if f.lower().startswith(("open sans", "segoe ui"))),
        # as fontes por classe do tema da plataforma (o QApplication::setFont sem classe as limpa)
        "perClass": {c: font_facts(QApplication.font(c)) for c in ("QMenu", "QMenuBar", "QStatusBar", "QMessageBox", "QTipLabel",
                                                                     "QHeaderView", "QDockWidgetTitle", "QLabel", "QGroupBox")},
        "digitAdvances": digits,
        "digitsEqual": len(set(round(v, 4) for v in digits.values())) == 1,
        "screen": {"devicePixelRatio": screen.devicePixelRatio(), "logicalDpi": screen.logicalDotsPerInch(),
                   "physicalDpi": screen.physicalDotsPerInch()},
        "env": {k: os.environ.get(k) for k in ("QT_ENABLE_HIGHDPI_SCALING", "QT_FONT_DPI", "QT_SCALE_FACTOR")},
    }


# ---------------------------------------------------------------- auditoria do texto

def plain(text):
    if Qt.mightBeRichText(text):
        text = QTextDocumentFragment.fromHtml(text).toPlainText()
    return text.replace("&&", "\0").replace("&", "").replace("\0", "&")


def rect_in(widget, top, rect=None):
    rect = rect if rect is not None else widget.rect()
    origin = widget.mapTo(top, rect.topLeft())
    return [origin.x(), origin.y(), rect.width(), rect.height()]


def entry(top, widget, sub, text, needed, available, kind, rect=None, axis="largura"):
    return {"cls": widget.metaObject().className(), "name": widget.objectName(), "sub": sub, "text": text[:120],
            "needed": round(float(needed), 1), "available": round(float(available), 1), "axis": axis,
            "issue": float(needed) > float(available) + 0.5, "kind": kind, "rect": rect_in(widget, top, rect)}


def check_label(top, w):
    if w.pixmap() is not None and not w.pixmap().isNull():
        return []
    text = w.text()
    if not text.strip():
        return []
    if w.wordWrap():
        return [entry(top, w, "", plain(text), w.heightForWidth(w.width()), w.height(), "corta", axis="altura")]
    return [entry(top, w, "", plain(text), w.sizeHint().width(), w.width(), "corta")]


def check_button(top, w):
    text = plain(w.text())
    if not text.strip():
        return []
    style = w.style()
    fm = QFontMetrics(w.font())
    icon = 0 if w.icon().isNull() else w.iconSize().width() + 4
    if isinstance(w, (QCheckBox, QRadioButton)):
        opt = QStyleOptionButton()
        opt.initFrom(w)
        opt.text = w.text()
        opt.icon = w.icon()
        opt.iconSize = w.iconSize()
        element = QStyle.SE_CheckBoxContents if isinstance(w, QCheckBox) else QStyle.SE_RadioButtonContents
        contents = style.subElementRect(element, opt, w)
        return [entry(top, w, "", text, fm.horizontalAdvance(text) + icon, contents.width(), "corta")]
    if isinstance(w, QPushButton):
        opt = QStyleOptionButton()
        opt.initFrom(w)
        opt.text = w.text()
        opt.icon = w.icon()
        opt.iconSize = w.iconSize()
        if w.menu() is not None:
            opt.features |= QStyleOptionButton.HasMenu
        contents = style.subElementRect(QStyle.SE_PushButtonContents, opt, w)
        menu = style.pixelMetric(QStyle.PM_MenuButtonIndicator, opt, w) if w.menu() is not None else 0
        return [entry(top, w, "", text, fm.horizontalAdvance(text) + icon + menu, contents.width(), "corta")]
    if isinstance(w, QToolButton):
        if w.toolButtonStyle() == Qt.ToolButtonIconOnly:
            return []
        return [entry(top, w, "", text, w.sizeHint().width(), w.width(), "corta")]
    return []


def check_group(top, w):
    title = plain(w.title())
    if not title.strip():
        return []
    opt = QStyleOptionGroupBox()
    opt.initFrom(w)
    opt.text = w.title()
    opt.lineWidth = 1
    opt.midLineWidth = 0
    opt.textAlignment = w.alignment()
    opt.subControls = QStyle.SC_GroupBoxFrame | QStyle.SC_GroupBoxLabel
    if w.isCheckable():
        opt.subControls |= QStyle.SC_GroupBoxCheckBox
    label = w.style().subControlRect(QStyle.CC_GroupBox, opt, QStyle.SC_GroupBoxLabel, w)
    return [entry(top, w, "titulo", title, label.x() + label.width(), w.width(), "corta", rect=label)]


def check_tabs(top, w):
    out = []
    fm = QFontMetrics(w.font())
    space = w.style().pixelMetric(QStyle.PM_TabBarTabHSpace, None, w)
    for i in range(w.count()):
        if hasattr(w, "isTabVisible") and not w.isTabVisible(i):
            continue
        text = plain(w.tabText(i))
        if not text.strip():
            continue
        r = w.tabRect(i)
        icon = 0 if w.tabIcon(i).isNull() else w.iconSize().width() + 4
        if r.right() > w.width() or r.left() < 0:
            out.append(entry(top, w, "aba %d" % i, text, r.right() + 1, w.width(), "fora-da-vista", rect=r))
        else:
            kind = "reticencias" if w.elideMode() != Qt.ElideNone else "corta"
            out.append(entry(top, w, "aba %d" % i, text, fm.horizontalAdvance(text) + icon + space, r.width(), kind, rect=r))
    return out


def check_combo(top, w):
    if w.isEditable():
        return []
    text = w.currentText()
    if not text.strip():
        return []
    opt = QStyleOptionComboBox()
    opt.initFrom(w)
    opt.editable = False
    opt.currentText = text
    opt.currentIcon = w.itemIcon(w.currentIndex())
    opt.iconSize = w.iconSize()
    opt.frame = w.hasFrame()
    field = w.style().subControlRect(QStyle.CC_ComboBox, opt, QStyle.SC_ComboBoxEditField, w)
    icon = 0 if opt.currentIcon.isNull() else w.iconSize().width() + 4
    return [entry(top, w, "", text, QFontMetrics(w.font()).horizontalAdvance(text) + icon + 2, field.width(), "corta", rect=field)]


def check_spin(top, w):
    text = w.text()
    edits = [e for e in w.findChildren(QLineEdit) if e.parent() is w]
    if not text.strip() or not edits:
        return []
    edit = edits[0]
    margins = edit.textMargins()
    available = edit.width() - margins.left() - margins.right() - 4
    return [entry(top, w, "", text, QFontMetrics(edit.font()).horizontalAdvance(text), available, "corta", rect=edit.geometry())]


def check_header(top, w):
    if w.orientation() != Qt.Horizontal or w.model() is None:
        return []
    out = []
    fm = QFontMetrics(w.font())
    margin = 2 * w.style().pixelMetric(QStyle.PM_HeaderMargin, None, w)
    for logical in range(w.count()):
        if w.isSectionHidden(logical) or w.sectionSize(logical) <= 0:
            continue
        text = w.model().headerData(logical, Qt.Horizontal, Qt.DisplayRole)
        if not isinstance(text, str) or not text.strip():
            continue
        x = w.sectionViewportPosition(logical)
        if x >= w.width():
            continue
        mark = w.style().pixelMetric(QStyle.PM_HeaderMarkSize, None, w) if w.isSortIndicatorShown() and w.sortIndicatorSection() == logical else 0
        kind = "reticencias" if w.textElideMode() != Qt.ElideNone else "corta"
        out.append(entry(top, w, "coluna %d" % logical, text, fm.horizontalAdvance(text) + margin + mark, w.sectionSize(logical), kind,
                         rect=QRect(x, 0, w.sectionSize(logical), w.height())))
    return out


def check_view(top, w):
    if isinstance(w, (QTableView, QHeaderView)) or w.model() is None:
        return []
    viewport = w.viewport()
    if viewport.width() <= 0:
        return []
    fm = QFontMetrics(w.font())
    seen = set()
    out = []
    y = 0
    model = w.model()
    columns = model.columnCount(w.rootIndex()) if isinstance(w, QTreeView) else 1
    while y < viewport.height() and len(seen) < 80:
        index = w.indexAt(QPoint(min(viewport.width() // 2, 60), y))
        if not index.isValid():
            y += 4
            continue
        row_rect = w.visualRect(index)
        for column in range(max(columns, 1)):
            cell = index.sibling(index.row(), column)
            if not cell.isValid():
                continue
            # chave pela posicao na tela (o internalPointer de um indice de proxy derruba o Python)
            r = w.visualRect(cell)
            key = (r.top(), r.left(), column)
            if key in seen:
                continue
            seen.add(key)
            text = cell.data(Qt.DisplayRole)
            if not isinstance(text, str) or not text.strip():
                continue
            icon = w.iconSize().width() if w.iconSize().width() > 0 else 16
            decoration = icon + 6 if cell.data(Qt.DecorationRole) is not None else 0
            visible = min(r.right() + 1, viewport.width()) - r.left()
            kind = "reticencias" if w.textElideMode() != Qt.ElideNone and r.right() < viewport.width() else "corta"
            out.append(entry(top, viewport, "linha %d col %d" % (cell.row(), cell.column()), text.split("\n")[0],
                             fm.horizontalAdvance(text.split("\n")[0]) + decoration + 6, visible, kind, rect=r))
        y = max(row_rect.bottom() + 1, y + 4)
    return out


def check_dock(top, w):
    title = w.windowTitle()
    if not title.strip() or w.isFloating():
        return []
    buttons = [b for b in w.findChildren(QAbstractButton) if b.parent() is w and b.isVisible()]
    right = min([b.x() for b in buttons] + [w.width()])
    margin = w.style().pixelMetric(QStyle.PM_DockWidgetTitleMargin, None, w)
    return [entry(top, w, "titulo", title, QFontMetrics(w.font()).horizontalAdvance(title), right - 2 * margin, "reticencias",
                  rect=QRect(0, 0, right, max(w.widget().y() if w.widget() else 18, 1)))]


def same(a, b):
    """O mesmo objeto C++ (o sip pode dar dois objetos Python para o mesmo widget, e o 'is' falha)."""
    return a is not None and b is not None and sip.unwrapinstance(a) == sip.unwrapinstance(b)


def on_screen(widget, top):
    area = QRect(widget.mapTo(top, QPoint(0, 0)), widget.size())
    clip = top.rect()
    parent = widget.parentWidget()
    # para na janela: o mapTo com um widget que nao e ancestral derruba o Qt
    while parent is not None and not parent.isWindow():
        clip = clip.intersected(QRect(parent.mapTo(top, QPoint(0, 0)), parent.size()))
        parent = parent.parentWidget()
    return not area.intersected(clip).isEmpty()


def audit(top, root=None):
    root = root if root is not None else top
    widgets = [root] + root.findChildren(QWidget)
    out = []
    for w in widgets:
        # so o que esta na tela: o retangulo do widget, recortado pelo de cada pai ate a janela, tem de sobrar (um painel
        # atras de outra aba ou um widget rolado para fora fica de fora; o cabecalho de uma tabela, na margem do
        # viewport, fica)
        if not w.isVisible() or not same(w.window(), top) or not on_screen(w, top):
            continue
        try:
            if isinstance(w, QLabel):
                out += check_label(top, w)
            elif isinstance(w, QAbstractButton) and not isinstance(w.parent(), QTabBar):
                out += check_button(top, w)
            elif isinstance(w, QGroupBox):
                out += check_group(top, w)
            elif isinstance(w, QTabBar):
                out += check_tabs(top, w)
            elif isinstance(w, QComboBox):
                out += check_combo(top, w)
            elif isinstance(w, QAbstractSpinBox):
                out += check_spin(top, w)
            elif isinstance(w, QHeaderView):
                out += check_header(top, w)
            elif isinstance(w, QAbstractItemView):
                out += check_view(top, w)
            if isinstance(w, QDockWidget):
                out += check_dock(top, w)
        except Exception as err:
            facts["errors"].setdefault("audit", []).append("%s %s: %r" % (w.metaObject().className(), w.objectName(), err))
    # chave estavel entre builds: tela, classe, nome, parte e texto, com o numero da ocorrencia
    counts = {}
    for e in out:
        base = "%s|%s|%s|%s" % (e["cls"], e["name"], e["sub"], e["text"])
        counts[base] = counts.get(base, 0) + 1
        e["key"] = "%s#%d" % (base, counts[base])
    return out


def screen(name, top, root=None, pixmap=None, extra=None):
    """Captura a janela de cima e audita o texto dela; a captura e a referencia dos retangulos (pixels logicos)."""
    QApplication.processEvents()
    # a janela de cima de verdade (a tabela de atributos do 3.44 vai dentro de um conteiner do QGIS)
    top = top.window()
    pixmap = pixmap if pixmap is not None else top.grab()
    capture = save_pixmap(pixmap, "%s.png" % name)
    texts = audit(top, root)
    facts["screens"][name] = {"capture": capture, "size": [top.width(), top.height()], "dpr": pixmap.devicePixelRatio() or 1.0,
                              "title": top.windowTitle(), "texts": texts, "issues": sum(1 for t in texts if t["issue"])}
    if extra:
        facts["screens"][name].update(extra)
    state.setdefault("pixmaps", {})[name] = pixmap


# ---------------------------------------------------------------- telas

def step_home():
    window.showNormal()
    window.resize(*WINDOW_SIZE)
    # o Navegador lista as unidades da maquina (com nome e e-mail de conta): fora das capturas do laudo publico
    browser = window.findChild(QDockWidget, "Browser")
    if browser is not None:
        browser.hide()
    QApplication.processEvents()
    home = window.findChild(QWidget, "imanHomePage")
    labels = [l for l in home.findChildren(QLabel) if l.isVisible()][:6] if home is not None else []
    screen("01-pagina-inicial", window, extra={"homeLabelFonts": {l.objectName() or l.text()[:30]: font_facts(l.font()) for l in labels}})


def step_about():
    window.findChild(QAction, "mActionAbout").trigger()
    QApplication.processEvents()
    dialog = top_level(object_name="imanAboutDialog")
    if dialog is None:
        facts["errors"]["about"] = "imanAboutDialog ausente"
        return
    dialog.resize(760, 760)
    QApplication.processEvents()
    labels = [l for l in dialog.findChildren(QLabel) if l.isVisible() and l.objectName()][:6]
    screen("02-sobre-iman", dialog, extra={"labelFonts": {l.objectName(): font_facts(l.font()) for l in labels}})
    dialog.close()


def step_load_project():
    if project_path:
        facts["projectRead"] = QgsProject.instance().read(project_path)
        iface.mapCanvas().zoomToFullExtent()
    window.showNormal()
    window.resize(*WINDOW_SIZE)
    browser = window.findChild(QDockWidget, "Browser")
    if browser is not None:
        browser.hide()
    QApplication.processEvents()


def step_main_window():
    screen("03-janela", window)
    status = window.findChild(QStatusBar)
    save_pixmap(status.grab(), "03-barra-de-status.png")


def step_menus():
    bar = window.menuBar()
    for i, name in enumerate(("mProjectMenu", "mLayerMenu", "mVectorMenu")):
        menu = window.findChild(QMenu, name)
        if menu is None:
            facts["errors"]["menu-%s" % name] = "ausente"
            continue
        rect = bar.actionGeometry(menu.menuAction())
        menu.popup(bar.mapToGlobal(rect.bottomLeft()))
        QApplication.processEvents()
        menu.setActiveAction(None)
        QApplication.processEvents()
        pixmap = menu.grab()
        label = ("04-menu-projeto", "05-menu-camada", "06-menu-vetor")[i]
        save_pixmap(pixmap, label + ".png")
        facts["screens"][label] = {"capture": label + ".png", "size": [menu.width(), menu.height()], "title": menu.title(),
                                   "texts": [], "issues": 0, "menuFont": font_facts(menu.font()),
                                   "items": [a.text() for a in menu.actions() if a.isVisible() and not a.isSeparator()]}
        if i == 0:
            # A5: o comeco do menu Projeto, ampliado 400% sem suavizar
            zoom(pixmap, QRect(0, 0, 240, 120), "a5-menu-projeto-x4.png")
        menu.hide()
        QApplication.processEvents()


def zoom(pixmap, logical, name):
    dpr = pixmap.devicePixelRatio() or 1.0
    area = QRect(int(logical.x() * dpr), int(logical.y() * dpr), int(logical.width() * dpr), int(logical.height() * dpr))
    crop = pixmap.copy(area.intersected(QRect(0, 0, pixmap.width(), pixmap.height())))
    crop.setDevicePixelRatio(1.0)
    big = crop.scaled(crop.width() * 4, crop.height() * 4, Qt.IgnoreAspectRatio, Qt.FastTransformation)
    save_pixmap(big, name)


def page_of(stack, widget):
    while widget is not None and widget.parent() is not stack:
        widget = widget.parent()
    return widget


def show_page(dialog, name):
    stack = dialog.findChild(QStackedWidget, "mOptionsStackedWidget")
    target = dialog.findChild(QWidget, name)
    page = page_of(stack, target) if stack is not None and target is not None else None
    if page is None:
        return False
    index = stack.indexOf(page)
    lst = dialog.findChild(QListWidget, "mOptionsListWidget")
    tree = dialog.findChild(QTreeView, "mOptionsTreeView")
    if lst is not None and lst.isVisible() and index < lst.count():
        lst.setCurrentRow(index)
    stack.setCurrentIndex(index)
    QApplication.processEvents()
    return True


OPTION_PAGES = (("07-opcoes-geral", "mOptionsPageGeneral"), ("08-opcoes-sistema", "mOptionsPageSystem"),
                ("09-opcoes-mapa-e-legenda", "mOptionsPageMapCanvas"), ("10-opcoes-ferramentas-de-mapa", "mOptionsPageMapTools"),
                ("11-opcoes-src", "mOptionsPageCRS"))


def step_options():
    QTimer.singleShot(3000, read_options)
    iface.showOptionsDialog(window, "mOptionsPageGeneral")


def read_options():
    dialog = top_level("QgsOptions")
    if dialog is None:
        facts["errors"]["options"] = "QgsOptions ausente"
        return
    try:
        dialog.resize(1100, 760)
        QApplication.processEvents()
        for name, page in OPTION_PAGES:
            if not show_page(dialog, page):
                facts["errors"]["options-" + page] = "pagina ausente"
                continue
            screen(name, dialog)
            if page == "mOptionsPageGeneral":
                stack = dialog.findChild(QStackedWidget, "mOptionsStackedWidget")
                origin = stack.mapTo(dialog, QPoint(0, 0))
                zoom(state["pixmaps"][name], QRect(origin.x(), origin.y(), 360, 160), "a5-opcoes-geral-x4.png")
                weights(dialog)
                font_choice_widgets(dialog)
    except Exception as err:
        facts["errors"]["read_options"] = repr(err)
    dialog.reject()


def font_choice_widgets(dialog):
    facts["optionsFont"] = {}
    for name in ("mFontFamilyRadioQt", "mFontFamilyRadioCustom"):
        w = dialog.findChild(QRadioButton, name)
        facts["optionsFont"][name] = {"checked": w.isChecked(), "text": w.text()} if w is not None else None
    combo = dialog.findChild(QComboBox, "mFontFamilyComboBox")
    facts["optionsFont"]["mFontFamilyComboBox"] = combo.currentText() if combo is not None else None


# ---------------------------------------------------------------- A6: pesos

def render(font, text=SAMPLE_TEXT):
    fm = QFontMetrics(font)
    image = QImage(fm.horizontalAdvance(text) + 8, fm.height() + 4, QImage.Format_RGB32)
    image.fill(QColor("#FFFFFF"))
    painter = QPainter(image)
    painter.setFont(font)
    painter.setPen(QColor("#000000"))
    painter.drawText(4, fm.ascent() + 2, text)
    painter.end()
    return image


def weights(dialog):
    groups = [g for g in dialog.findChildren(QGroupBox) if g.isVisible() and g.title().strip()]
    info = {}
    if groups:
        group = groups[0]
        info["groupBox"] = {"title": plain(group.title()), "name": group.objectName(), "font": font_facts(group.font())}
        opt = QStyleOptionGroupBox()
        opt.initFrom(group)
        opt.text = group.title()
        opt.subControls = QStyle.SC_GroupBoxLabel
        label = group.style().subControlRect(QStyle.CC_GroupBox, opt, QStyle.SC_GroupBoxLabel, group)
        pixmap = group.grab(label.adjusted(-4, -2, 4, 2))
        pixmap.setDevicePixelRatio(1.0)
        save_pixmap(pixmap.scaled(pixmap.width() * 4, pixmap.height() * 4, Qt.IgnoreAspectRatio, Qt.FastTransformation), "a6-titulo-do-grupo-x4.png")
    base = QFont(QApplication.font())
    db = QFontDatabase()
    candidates = {"regular": QFont(base)}
    for label, weight in (("peso-600-qt-demibold", QFont.DemiBold), ("peso-qss-600", 75), ("negrito", QFont.Bold)):
        f = QFont(base)
        f.setWeight(weight)
        candidates[label] = f
    # a face SemiBold real, pelo nome de familia que o arquivo declara para o Windows (nome 1)
    for family in ("%s SemiBold" % base.family(), "%s Semibold" % base.family()):
        if family in db.families():
            f = QFont(base)
            f.setFamily(family)
            f.setWeight(QFont.Normal)
            candidates["face-semibold-real"] = f
            break
    images = {k: render(f) for k, f in candidates.items()}
    compare = {}
    for a in ("peso-600-qt-demibold", "peso-qss-600"):
        compare[a] = {b: images[a] == images[b] for b in images if b != a}
    info["candidates"] = {k: font_facts(f) for k, f in candidates.items()}
    info["sameDrawing"] = compare
    if "groupBox" in info:
        title_weight = info["groupBox"]["font"]["weight"]
        info["groupBoxWeightIs"] = [k for k, f in candidates.items() if f.weight() == title_weight and k != "face-semibold-real"]
    # tira com as amostras, uma por linha, ampliada 400%
    height = sum(i.height() for i in images.values())
    width = max(i.width() for i in images.values())
    strip = QImage(width, height, QImage.Format_RGB32)
    strip.fill(QColor("#FFFFFF"))
    painter = QPainter(strip)
    y = 0
    order = []
    for k, image in images.items():
        painter.drawImage(0, y, image)
        y += image.height()
        order.append(k)
    painter.end()
    strip.scaled(width * 4, height * 4, Qt.IgnoreAspectRatio, Qt.FastTransformation).save(os.path.join(out_dir, "a6-pesos-x4.png"))
    info["stripOrder"] = order
    facts["weights"] = info


# ---------------------------------------------------------------- propriedades da camada

LAYER_PAGES = (("12-propriedades-fonte", "mOptsPage_Source"), ("13-propriedades-simbologia", "mOptsPage_Style"),
               ("14-propriedades-rotulos", "mOptsPage_Labels"), ("15-propriedades-campos", "mOptsPage_SourceFields"))


def step_layer_properties():
    layers = list(QgsProject.instance().mapLayers().values())
    if not layers:
        facts["errors"]["layerProperties"] = "sem camada"
        return
    QTimer.singleShot(3000, read_layer_properties)
    iface.showLayerProperties(layers[0], "mOptsPage_Source")


def read_layer_properties():
    dialog = top_level("QgsVectorLayerProperties")
    if dialog is None:
        facts["errors"]["layerProperties"] = "QgsVectorLayerProperties ausente"
        return
    try:
        dialog.resize(1100, 760)
        QApplication.processEvents()
        for name, page in LAYER_PAGES:
            if not show_page(dialog, page):
                facts["errors"]["layer-" + page] = "pagina ausente"
                continue
            screen(name, dialog)
        # A7 (i): rotulos simples numa camada sem rotulo; a fonte que o formulario mostra (nada e aplicado: o dialogo
        # e cancelado)
        mode = dialog.findChild(QComboBox, "mLabelModeComboBox")
        if mode is not None:
            mode.setCurrentIndex(1)
            QApplication.processEvents()
            fonts = [c for c in dialog.findChildren(QComboBox, "mFontFamilyCmbBx")]
            facts.setdefault("labelDefaults", {})["layerLabelsForm"] = {
                "mode": mode.currentText(),
                "fontCombo": fonts[0].currentText() if fonts else None,
            }
            screen("16-propriedades-rotulos-simples", dialog)
    except Exception as err:
        facts["errors"]["read_layer_properties"] = repr(err)
    dialog.reject()


# ---------------------------------------------------------------- gerenciador de fontes de dados

def step_data_sources():
    # o timer antes de abrir: se o dialogo for modal, a chamada so volta quando ele fecha
    QTimer.singleShot(2500, read_data_sources)
    iface.openDataSourceManagerPage("ogr")


def read_data_sources():
    dialog = top_level("QgsDataSourceManagerDialog")
    if dialog is None:
        facts["errors"]["dataSources"] = "QgsDataSourceManagerDialog ausente"
        return
    try:
        dialog.resize(1000, 700)
        QApplication.processEvents()
        screen("17-fontes-vetor", dialog)
        lst = dialog.findChild(QListWidget, "mOptionsListWidget")
        rows = [i for i in range(lst.count()) if "WMS" in lst.item(i).text()] if lst is not None else []
        if rows:
            lst.setCurrentRow(rows[0])
            QApplication.processEvents()
            screen("18-fontes-wms", dialog)
        else:
            facts["errors"]["dataSources-wms"] = "item WMS ausente"
    except Exception as err:
        facts["errors"]["read_data_sources"] = repr(err)
    dialog.close()


# ---------------------------------------------------------------- processamento

def step_toolbox():
    dock = window.findChild(QDockWidget, "ProcessingToolbox")
    if dock is None:
        facts["errors"]["toolbox"] = "ProcessingToolbox ausente"
        return
    dock.show()
    dock.setFloating(True)
    dock.resize(420, 700)
    dock.raise_()
    QApplication.processEvents()
    screen("19-processamento-caixa", dock)
    state["toolbox"] = dock


def step_algorithm():
    import processing

    dock = state.pop("toolbox", None)
    if dock is not None:
        dock.setFloating(False)
        dock.hide()
    dialog = processing.createAlgorithmDialog("native:buffer")
    dialog.resize(900, 720)
    dialog.show()
    dialog.raise_()
    QApplication.processEvents()
    tabs = dialog.findChild(QTabWidget, "mTabWidget")
    tabs.setCurrentIndex(0)
    screen("20-algoritmo-parametros", dialog)
    tabs.setCurrentIndex(1)
    screen("21-algoritmo-log", dialog)
    dialog.close()


# ---------------------------------------------------------------- tabela, calculadora, salvar como

def step_attribute_table():
    layers = list(QgsProject.instance().mapLayers().values())
    table = iface.showAttributeTable(layers[0]) if layers else None
    QApplication.processEvents()
    if table is None:
        facts["errors"]["attributeTable"] = "sem tabela"
        return
    table.resize(800, 320)
    QApplication.processEvents()
    screen("22-tabela-de-atributos", table)
    table.close()


def step_field_calculator():
    layers = list(QgsProject.instance().mapLayers().values())
    if not layers:
        return
    iface.setActiveLayer(layers[0])
    QTimer.singleShot(2500, lambda: read_modal("QgsFieldCalculator", "23-calculadora-de-campo", (900, 700)))
    window.findChild(QAction, "mActionOpenFieldCalc").trigger()


def step_save_as():
    layers = list(QgsProject.instance().mapLayers().values())
    if not layers:
        return
    iface.setActiveLayer(layers[0])
    QTimer.singleShot(2500, lambda: read_modal("QgsVectorLayerSaveAsDialog", "24-salvar-camada-como", (760, 760)))
    window.findChild(QAction, "mActionLayerSaveAs").trigger()


def step_plugin_manager():
    # direto pela interface do gerenciador (o menu passa pelo instalador Python, que busca os repositorios na rede)
    QTimer.singleShot(3000, lambda: read_modal("QgsPluginManager", "25-gerenciador-de-complementos", (1000, 700)))
    iface.pluginManagerInterface().showPluginManager()


def read_modal(class_name, name, size):
    dialog = top_level(class_name)
    if dialog is None:
        facts["errors"][name] = "%s ausente" % class_name
        return
    try:
        dialog.resize(*size)
        QApplication.processEvents()
        screen(name, dialog)
    except Exception as err:
        facts["errors"][name] = repr(err)
    dialog.reject()


# ---------------------------------------------------------------- compositor

def step_layout():
    project = QgsProject.instance()
    layout = QgsPrintLayout(project)
    layout.initializeDefaults()
    layout.setName("Fonte 067")
    project.layoutManager().addLayout(layout)
    designer = iface.openLayoutDesigner(layout)
    state["layout"] = (layout, designer)
    QApplication.processEvents()
    designer_window = designer.window()
    designer_window.showNormal()
    designer_window.resize(1400, 900)
    QApplication.processEvents()


def step_layout_capture():
    layout, designer = state["layout"]
    designer_window = designer.window()
    screen("26-compositor-vazio", designer_window)
    # A7 (ii): um rotulo novo no compositor; a fonte dele e o padrao do compositor
    label = QgsLayoutItemLabel(layout)
    label.setText("Rotulo novo 067")
    layout.addLayoutItem(label)
    designer.selectItems([label])
    defaults = facts.setdefault("labelDefaults", {})
    defaults["layoutLabel"] = font_facts(label.textFormat().font()) if hasattr(label, "textFormat") else font_facts(label.font())
    defaults["layoutDefaultFontSetting"] = QgsSettings().value("LayoutDesigner/defaultFont", None, section=QgsSettings.Gui)
    QApplication.processEvents()


def step_layout_label_capture():
    layout, designer = state.pop("layout")
    screen("27-compositor-rotulo", designer.window())
    designer.close()
    QgsProject.instance().layoutManager().removeLayout(layout)


def step_label_defaults():
    defaults = facts.setdefault("labelDefaults", {})
    defaults["palLayerSettings"] = font_facts(QgsPalLayerSettings().format().font())
    defaults["textFormat"] = font_facts(QgsTextFormat().font())
    defaults["qfont"] = font_facts(QFont())


# ---------------------------------------------------------------- plugin REURB

def step_reurb():
    docks = [d for d in window.findChildren(QDockWidget) if type(d).__name__ == "ImanDock"]
    if not docks:
        # o plugin cria o painel so quando o usuario o abre (o botao da barra dele)
        from qgis.utils import plugins

        plugin = plugins.get("iman_plugin")
        if plugin is not None:
            plugin._toggle_dock(True)
            QApplication.processEvents()
        docks = [d for d in window.findChildren(QDockWidget) if type(d).__name__ == "ImanDock"]
    if not docks:
        facts["errors"]["reurb"] = "ImanDock ausente"
        return
    dock = docks[0]
    dock.show()
    dock.setFloating(True)
    dock.resize(440, 800)
    dock.raise_()
    QApplication.processEvents()
    tabs = dock.findChild(QTabWidget, "imanTabs")
    for i in range(tabs.count() if tabs is not None else 0):
        tabs.setCurrentIndex(i)
        QApplication.processEvents()
        slug = plain(tabs.tabText(i)).lower().replace(" ", "-").replace("ç", "c").replace("õ", "o").replace("ã", "a")
        screen("%d-reurb-%s" % (28 + i, slug), dock)
    dock.setFloating(False)
    dock.hide()


# ---------------------------------------------------------------- A4: coordenada

def coordinate_field():
    status = window.findChild(QStatusBar)
    for e in status.findChildren(QLineEdit):
        if e.parent() is not None and e.parent().metaObject().className() == "QgsStatusBarCoordinatesWidget":
            return e
    return None


def field_fact(edit):
    margins = edit.textMargins()
    # QLineEdit reserva 2 px de cada lado dentro da area de conteudo (como no theme_facts.py, D2)
    available = edit.width() - 2 * edit.style().pixelMetric(QStyle.PM_DefaultFrameWidth, None, edit) - margins.left() - margins.right() - 4
    text = edit.text()
    needed = QFontMetricsF(edit.font()).horizontalAdvance(text)
    return {"text": text, "width": edit.width(), "minimumWidth": edit.minimumWidth(), "maximumWidth": edit.maximumWidth(),
            "available": available, "needed": round(needed, 2), "fits": needed <= available, "font": edit.font().family()}


def widest_coordinate():
    """A coordenada de texto mais largo dentro do retangulo do Ceara: o primeiro algarismo do Leste de 2 a 6 e o segundo
    do Norte de 1 a 6 (os limites), os demais o algarismo mais largo da fonte do campo."""
    edit = coordinate_field()
    metrics = QFontMetricsF(edit.font())
    adv = {str(d): metrics.horizontalAdvance(str(d)) for d in range(10)}
    wide = max(adv, key=lambda d: (adv[d], d))
    first_e = max("23456", key=lambda d: (adv[d], d))
    second_n = max("123456", key=lambda d: (adv[d], d))
    easting = float(first_e + wide * 5 + "." + wide * 5)
    northing = float("9" + second_n + wide * 5 + "." + wide * 5)
    easting = min(max(easting, CEARA.xMinimum()), CEARA.xMaximum())
    northing = min(max(northing, CEARA.yMinimum()), CEARA.yMaximum())
    return {"advances": adv, "widestDigit": wide, "point": [easting, northing]}


def step_coordinate():
    project = QgsProject.instance()
    project.setCrs(QgsCoordinateReferenceSystem("EPSG:31984"))
    canvas = iface.mapCanvas()
    edit = coordinate_field()
    info = {"fieldFont": font_facts(edit.font()), "widest": widest_coordinate()}
    # o cursor passando pelo mapa, com o Ceara inteiro na tela: eventos de movimento sinteticos no mapa, de canto a
    # canto, sem mexer no cursor do usuario
    canvas.setExtent(CEARA)
    canvas.refresh()
    QApplication.processEvents()
    info["crs"] = canvas.mapSettings().destinationCrs().authid()
    viewport = canvas.viewport()
    moves = []
    for i in range(0, 21):
        pos = QPointF(viewport.width() * i / 20.0, viewport.height() * (20 - i) / 20.0)
        event = QMouseEvent(QEvent.MouseMove, pos, Qt.NoButton, Qt.NoButton, Qt.NoModifier)
        QApplication.sendEvent(viewport, event)
        QApplication.processEvents()
        moves.append(field_fact(edit))
    info["cursorMoves"] = {"extent": "Ceara", "count": len(moves), "widths": sorted(set(m["width"] for m in moves)),
                           "allFit": all(m["fits"] for m in moves), "longest": max(moves, key=lambda m: m["needed"]),
                           "texts": [m["text"] for m in moves]}
    # com o zoom das feicoes do projeto de teste (o do D2 e do 049p): o campo mostra casas decimais
    canvas.zoomToFullExtent()
    canvas.refresh()
    QApplication.processEvents()
    info["zoomedMapUnitsPerPixel"] = canvas.mapUnitsPerPixel()
    samples = {}
    for label, point in (("049p", POINT_049P), ("mais-larga", info["widest"]["point"])):
        canvas.xyCoordinates.emit(QgsPointXY(*point))
        QApplication.processEvents()
        samples[label] = field_fact(edit)
    info["emitted"] = samples
    facts["coordinate"] = info
    state["coordinatePoint"] = info["widest"]["point"]


def step_coordinate_capture():
    canvas = iface.mapCanvas()
    canvas.xyCoordinates.emit(QgsPointXY(*state["coordinatePoint"]))
    QApplication.processEvents()


def step_coordinate_capture_2():
    status = window.findChild(QStatusBar)
    save_pixmap(status.grab(), "a4-barra-de-status-mais-larga.png")
    edit = coordinate_field()
    pixmap = edit.grab()
    save_pixmap(pixmap, "a4-campo-de-coordenadas.png")
    pixmap.setDevicePixelRatio(1.0)
    save_pixmap(pixmap.scaled(pixmap.width() * 4, pixmap.height() * 4, Qt.IgnoreAspectRatio, Qt.FastTransformation), "a4-campo-de-coordenadas-x4.png")
    facts["coordinate"]["captured"] = field_fact(edit)


# ---------------------------------------------------------------- comparacao com a rodada de referencia

def crop_from(image, rect, dpr, name):
    margin = 6
    area = QRect(int((rect[0] - margin) * dpr), int((rect[1] - margin) * dpr), int((rect[2] + 2 * margin) * dpr), int((rect[3] + 2 * margin) * dpr))
    area = area.intersected(QRect(0, 0, image.width(), image.height()))
    if area.isEmpty():
        return None
    piece = image.copy(area)
    piece.save(os.path.join(out_dir, name))
    return name


def compare():
    if not reference_path or not os.path.exists(reference_path):
        return
    with open(reference_path, encoding="utf-8") as fh:
        ref = json.load(fh)
    ref_dir = os.path.dirname(reference_path)
    result = {"reference": os.path.basename(ref_dir), "screens": {}, "new": []}
    n = 0
    for name, now in facts["screens"].items():
        before = ref.get("screens", {}).get(name)
        if before is None:
            result["screens"][name] = {"missingInReference": True}
            continue
        # o id de item do compositor ({uuid}) muda a cada rodada: fora da comparacao, contado a parte
        before_by_key = {t["key"]: t for t in before.get("texts", []) if not UUID.search(t["text"])}
        now_issues = {t["key"]: t for t in now.get("texts", []) if t["issue"] and not UUID.search(t["text"])}
        before_issues = {k for k, t in before_by_key.items() if t["issue"]}
        only_now = [k for k in now_issues if k not in before_issues]
        only_before = [k for k in before_issues if k not in now_issues]
        result["screens"][name] = {"before": len(before_issues), "after": len(now_issues), "onlyAfter": len(only_now),
                                   "onlyBefore": len(only_before), "both": len(before_issues & set(now_issues)),
                                   "onlyBeforeKeys": only_before}
        now_image = state["pixmaps"][name].toImage() if name in state.get("pixmaps", {}) else None
        before_image = QImage(os.path.join(ref_dir, before["capture"])) if before.get("capture") else QImage()
        for key in only_now:
            n += 1
            t = now_issues[key]
            row = {"n": n, "screen": name, "key": key, "cls": t["cls"], "name": t["name"], "sub": t["sub"], "text": t["text"],
                   "kind": t["kind"], "axis": t["axis"], "needed": t["needed"], "available": t["available"]}
            b = before_by_key.get(key)
            if b is not None:
                row["before"] = {"needed": b["needed"], "available": b["available"]}
            if now_image is not None:
                row["cropAfter"] = crop_from(now_image, t["rect"], now["dpr"], "a3-%02d-depois.png" % n)
            if b is not None and not before_image.isNull():
                row["cropBefore"] = crop_from(before_image, b["rect"], before.get("dpr", 1.0), "a3-%02d-antes.png" % n)
            result["new"].append(row)
    result["totals"] = {k: sum(s.get(k, 0) for s in result["screens"].values()) for k in ("before", "after", "onlyAfter", "onlyBefore", "both")}
    # lado a lado de cada tela: ANTES a esquerda, DEPOIS a direita, na mesma escala
    for name, now in facts["screens"].items():
        before = ref.get("screens", {}).get(name)
        if not before or not before.get("capture") or not now.get("capture"):
            continue
        left = QImage(os.path.join(ref_dir, before["capture"]))
        right = QImage(os.path.join(out_dir, now["capture"]))
        if left.isNull() or right.isNull():
            continue
        gap, band = 16, 28
        side = QImage(left.width() + gap + right.width(), band + max(left.height(), right.height()), QImage.Format_RGB32)
        side.fill(QColor("#FFFFFF"))
        painter = QPainter(side)
        painter.setPen(QColor("#000000"))
        painter.drawText(4, 20, "ANTES (develop)")
        painter.drawText(left.width() + gap + 4, 20, "DEPOIS (%s)" % os.path.basename(out_dir))
        painter.drawImage(0, band, left)
        painter.drawImage(left.width() + gap, band, right)
        painter.end()
        side.save(os.path.join(out_dir, "lado-%s.png" % name))
        result["screens"][name]["sideBySide"] = "lado-%s.png" % name
    facts["compare"] = result


# ---------------------------------------------------------------- sequencia

def finish():
    run(compare)
    state.pop("pixmaps", None)
    if not facts["errors"]:
        facts.pop("errors")
    with open(os.path.join(out_dir, "font.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=1, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


# (atraso antes do passo em ms, passo); os modais armam o proprio timer e voltam quando o dialogo fecha
SEQUENCE = [
    (0, step_font), (0, step_home), (800, step_about), (800, step_load_project), (4000, step_main_window),
    (500, step_menus), (500, step_options), (800, step_layer_properties), (800, step_data_sources),
    (4000, step_toolbox), (800, step_algorithm), (800, step_attribute_table), (800, step_field_calculator),
    (800, step_save_as), (800, step_plugin_manager), (800, step_layout), (2500, step_layout_capture),
    (1500, step_layout_label_capture), (800, step_label_defaults), (500, step_reurb), (800, step_coordinate),
    (500, step_coordinate_capture), (1500, step_coordinate_capture_2),
]


def next_step(i=0):
    if i >= len(SEQUENCE):
        finish()
        return
    delay, step = SEQUENCE[i]

    def go():
        run(step)
        next_step(i + 1)

    QTimer.singleShot(delay, go)


QTimer.singleShot(3000, next_step)
