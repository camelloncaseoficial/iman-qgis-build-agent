# Botoes e abas (fatia 066), rodado pelo proprio QGIS via --code (Invoke-ButtonCaptures.ps1), no build, no QGIS oficial
# e na arvore instalada, com perfil novo e janela maximizada. So coleta fatos e capturas; quem julga e o .ps1.
#
#   paths    Fase A: o caminho do desenho de cada componente. Um QProxyStyle de gravacao (sobre um fusion novo) e posto
#            no componente (setStyle, so nele) e anota cada drawPrimitive/drawControl/drawComplexControl que o desenho
#            dele chama, com o widget passado. Diz quem passa pelo PE_PanelButtonCommand (o painel do botao) e com que
#            widget: o raio da fatia so pode valer para o widget QPushButton.
#   radius   o raio das quinas do QPushButton desenhado pelo estilo da aplicacao, nos estados normal, hover,
#            pressionado, desabilitado, padrao, com foco e com menu, medido no canal alfa do desenho sobre fundo
#            transparente, na escala da tela: a area que falta em cada quina e a de um quarto de circulo de raio r
#            (A = r^2 (1 - pi/4)), menos meia caneta (o contorno de 1 px e centrado na borda do desenho); e o raio de
#            referencia mais parecido (drawRoundedRect com o mesmo traco, raio de 0,5 a 8 em passos de 0,25).
#            Calibracao: o mesmo estimador sobre as referencias de raio conhecido. Fora das quinas, o desenho do estilo
#            da aplicacao e comparado pixel a pixel com o do fusion puro (igual = nada alem das quinas mudou).
#   components  os outros componentes (A5 iii), num dialogo de teste com tamanho fixo, sem foco nem hover, capturados
#            pelo grab(): caixa de selecao, botao de ferramenta com e sem menu, botao de cor, caixa numerica, campo, aba,
#            cabecalho, caixa de grupo, barra de rolagem, barra de progresso (e o QPushButton, que deve mudar).
#   regions  A2: a cor medida na captura de cada regiao que o Fusion pinta a partir do papel Button (cor mais comum e
#            media da faixa em torno dela, como no #065), e as cores que o Fusion deriva do Button, lidas do
#            qfusionstyle_p_p.h do Qt 5.15.13 (buttonColor, linhas 132 a 138; tabFrameColor, 126 a 130).
#   compare  com IMAN_BUTTONS_REFERENCE (a pasta de outra rodada): cada captura de componente e de botao comparada
#            pixel a pixel com a da referencia, e as regioes com as cores dela.
import json
import math
import os

import numpy as np
from qgis.core import QgsApplication, QgsProject, QgsSettings
from qgis.gui import QgsColorButton, QgsCollapsibleGroupBox
from qgis.PyQt.QtCore import QPoint, QRect, QRectF, Qt, QTimer
from qgis.PyQt.QtGui import QBrush, QColor, QCursor, QImage, QPainter, QPalette, QPen, qGray
from qgis.PyQt.QtWidgets import (
    QAbstractSpinBox,
    QApplication,
    QCheckBox,
    QComboBox,
    QDialog,
    QDialogButtonBox,
    QDockWidget,
    QGridLayout,
    QGroupBox,
    QLabel,
    QLineEdit,
    QMenu,
    QProgressBar,
    QProxyStyle,
    QPushButton,
    QRadioButton,
    QScrollBar,
    QSpinBox,
    QStyle,
    QStyleFactory,
    QStyleOptionButton,
    QStyleOptionSlider,
    QStyleOptionSpinBox,
    QStyleOptionToolButton,
    QTabBar,
    QTableView,
    QTableWidget,
    QTabWidget,
    QTextEdit,
    QToolButton,
    QTreeView,
    QWidget,
)
from qgis.utils import iface

out_dir = os.environ["IMAN_BUTTONS_OUT"]
project_path = os.environ.get("IMAN_BUTTONS_PROJECT", "")
reference_dir = os.environ.get("IMAN_BUTTONS_REFERENCE", "")
ALGORITHM = "native:buffer"
BUTTON_SIZE = (120, 32)  # multiplos de 4: na escala 1,25 da bancada, a borda do desenho cai em pixel inteiro
STATES = ("normal", "hover", "pressed", "disabled", "default", "focus", "menu")
facts = {"captures": {}, "paths": {}, "radius": {}, "components": {}, "regions": {}}
state = {}


def run(step):
    try:
        step()
    except Exception as err:
        facts.setdefault("errors", {})[step.__name__] = repr(err)


def enum_names(prefix):
    names = {}
    for name in sorted(dir(QStyle)):
        if name.startswith(prefix) and not name.endswith("CustomBase"):
            names.setdefault(int(getattr(QStyle, name)), name)
    return names


PE = enum_names("PE_")
CE = enum_names("CE_")
CC = enum_names("CC_")


# ---------------------------------------------------------------------------------------------------------- imagens
def to_array(image):
    image = image.convertToFormat(QImage.Format_ARGB32_Premultiplied) if image.format() != QImage.Format_ARGB32_Premultiplied else image
    ptr = image.constBits()
    ptr.setsize(image.bytesPerLine() * image.height())
    array = np.frombuffer(ptr, np.uint32).reshape(image.height(), image.bytesPerLine() // 4)[:, : image.width()]
    return array.copy()


def rgb_array(pixmap_or_image):
    image = pixmap_or_image.toImage() if hasattr(pixmap_or_image, "toImage") else pixmap_or_image
    image = image.convertToFormat(QImage.Format_RGB32)
    ptr = image.constBits()
    ptr.setsize(image.bytesPerLine() * image.height())
    array = np.frombuffer(ptr, np.uint32).reshape(image.height(), image.bytesPerLine() // 4)[:, : image.width()]
    return array.copy() & 0xFFFFFF, (image.devicePixelRatio() or 1.0)


def hexrgb(value):
    return "#%06X" % (int(value) & 0xFFFFFF)


def channels(values):
    values = values.astype(np.int64)
    return (values >> 16) & 0xFF, (values >> 8) & 0xFF, values & 0xFF


def save_image(image, name):
    image.save(os.path.join(out_dir, name))
    facts["captures"][name] = [image.width(), image.height()]


def window_crop(widget, margin=0):
    top = widget.window()
    origin = widget.mapTo(top, QPoint(0, 0))
    area = QRect(origin.x() - margin, origin.y() - margin, widget.width() + 2 * margin, widget.height() + 2 * margin)
    return top.grab(area.intersected(top.rect()))


def color_stats(values, band=30):
    """Cor mais comum, a fatia dela e a media da faixa em torno dela (o Fusion pinta botoes e abas em degrade)."""
    values = values.ravel()
    if values.size == 0:
        return {"background": None}
    colors, counts = np.unique(values, return_counts=True)
    top = colors[np.argmax(counts)]
    info = {"background": hexrgb(top), "backgroundShare": round(float(counts.max()) / values.size, 3), "pixels": int(values.size)}
    r, g, b = channels(values)
    tr, tg, tb = channels(np.array([top]))
    near = (np.abs(r - tr[0]) + np.abs(g - tg[0]) + np.abs(b - tb[0])) <= band
    mean = (int(round(r[near].mean())), int(round(g[near].mean())), int(round(b[near].mean())))
    info["backgroundMean"] = "#%02X%02X%02X" % mean
    band_values = values[near]
    info["backgroundBand"] = [hexrgb(band_values.min()), hexrgb(band_values.max())]
    info["bandShare"] = round(float(near.sum()) / values.size, 3)
    return info


def measure_rect(widget, rect=None, inset=0, ring=None):
    """Cor da area do widget na captura da janela (pixels fisicos): o retangulo logico 'rect' (padrao, o widget todo)
    encolhido de 'inset'; com 'ring' = (de, ate), so a faixa entre essas distancias da borda (logicas)."""
    array, dpr = rgb_array(window_crop(widget))
    r = rect if rect is not None else QRect(0, 0, widget.width(), widget.height())
    r = r.adjusted(inset, inset, -inset, -inset)
    x0, y0 = max(int(round(r.x() * dpr)), 0), max(int(round(r.y() * dpr)), 0)
    x1, y1 = int(round((r.x() + r.width()) * dpr)), int(round((r.y() + r.height()) * dpr))
    crop = array[y0:y1, x0:x1]
    if ring is not None and crop.size:
        h, w = crop.shape
        yy, xx = np.mgrid[0:h, 0:w]
        dist = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy)) / dpr
        crop = crop[(dist >= ring[0]) & (dist < ring[1])]
    info = color_stats(crop)
    info["rect"] = [r.x(), r.y(), r.width(), r.height()]
    return info


# ------------------------------------------------------------------------------- cores que o Fusion deriva do Button
def fusion_button_color(palette, group=QPalette.Active):
    """QFusionStylePrivate::buttonColor (qfusionstyle_p_p.h:132-138 do Qt 5.15.13), com a divisao inteira do C++."""
    color = QColor(palette.color(group, QPalette.Button))
    val = qGray(color.rgb())
    color = color.lighter(100 + max(1, int((180 - val) / 6)))
    color.setHsv(color.hue(), int(color.saturation() * 0.75), color.value())
    return color


def fusion_derived(palette):
    button = fusion_button_color(palette)
    return {
        "Button": palette.color(QPalette.Active, QPalette.Button).name().upper(),
        "buttonColor": button.name().upper(),
        # QFusionStylePrivate::tabFrameColor (qfusionstyle_p_p.h:126-130): o painel das abas
        "tabFrameColor": button.lighter(104).name().upper(),
    }


# ------------------------------------------------------------------------------------------------- Fase A: caminhos
class Recorder(QProxyStyle):
    """Estilo de gravacao: o fusion puro, anotando cada chamada de desenho e o widget passado nela."""

    def __init__(self):
        super().__init__(QStyleFactory.create("fusion"))
        self.calls = []

    def _note(self, kind, name, widget):
        cls = widget.metaObject().className() if widget is not None else None
        push = bool(widget is not None and widget.inherits("QPushButton"))
        self.calls.append((kind, name, cls, push))

    def drawPrimitive(self, element, option, painter, widget=None):
        self._note("primitive", PE.get(int(element), str(int(element))), widget)
        super().drawPrimitive(element, option, painter, widget)

    def drawControl(self, element, option, painter, widget=None):
        self._note("control", CE.get(int(element), str(int(element))), widget)
        super().drawControl(element, option, painter, widget)

    def drawComplexControl(self, control, option, painter, widget=None):
        self._note("complex", CC.get(int(control), str(int(control))), widget)
        super().drawComplexControl(control, option, painter, widget)


def a_menu(parent):
    menu = QMenu(parent)
    menu.addAction("Item")
    return menu


def build_components(dialog):
    """Os componentes do A5 (iii) e do caminho, com tamanho fixo e sem foco. Nome -> (widget, alvo do setStyle)."""
    items = {}
    push = QPushButton("Executar", dialog)
    items["pushButton"] = push
    push_menu = QPushButton("Estilo", dialog)
    push_menu.setMenu(a_menu(push_menu))
    items["pushButtonMenu"] = push_menu
    combo = QComboBox(dialog)
    combo.addItems(["Simbolo simples", "Categorizado", "Graduado"])
    items["comboBox"] = combo
    combo_edit = QComboBox(dialog)
    combo_edit.setEditable(True)
    combo_edit.addItems(["editavel", "dois"])
    items["comboBoxEditable"] = combo_edit
    tool = QToolButton(dialog)
    tool.setText("Ferramenta")
    tool.setToolButtonStyle(Qt.ToolButtonTextOnly)
    items["toolButton"] = tool
    tool_auto = QToolButton(dialog)
    tool_auto.setText("Barra")
    tool_auto.setAutoRaise(True)
    items["toolButtonAutoRaise"] = tool_auto
    tool_split = QToolButton(dialog)
    tool_split.setText("Com menu")
    tool_split.setPopupMode(QToolButton.MenuButtonPopup)
    tool_split.setMenu(a_menu(tool_split))
    items["toolButtonMenuPopup"] = tool_split
    tool_instant = QToolButton(dialog)
    tool_instant.setText("Menu")
    tool_instant.setPopupMode(QToolButton.InstantPopup)
    tool_instant.setMenu(a_menu(tool_instant))
    items["toolButtonInstantPopup"] = tool_instant
    color = QgsColorButton(dialog)
    color.setColor(QColor(200, 60, 60))
    items["colorButton"] = color
    spin = QSpinBox(dialog)
    spin.setValue(42)
    items["spinBox"] = spin
    edit = QLineEdit("texto do campo", dialog)
    items["lineEdit"] = edit
    tabs = QTabBar(dialog)
    tabs.addTab("Parametros")
    tabs.addTab("Registro")
    items["tabBar"] = tabs
    tab_widget = QTabWidget(dialog)
    tab_widget.addTab(QLabel("pagina"), "Uma")
    tab_widget.addTab(QLabel("outra"), "Outra")
    items["tabWidget"] = tab_widget
    table = QTableWidget(3, 2, dialog)
    table.setHorizontalHeaderLabels(["nome", "valor"])
    items["header"] = table
    group = QGroupBox("Grupo", dialog)
    QGridLayout(group).addWidget(QLabel("dentro"), 0, 0)
    items["groupBox"] = group
    collapsible = QgsCollapsibleGroupBox("Recolhivel", dialog)
    QGridLayout(collapsible).addWidget(QLabel("dentro"), 0, 0)
    items["collapsibleGroupBox"] = collapsible
    bar = QScrollBar(Qt.Vertical, dialog)
    bar.setRange(0, 100)
    bar.setPageStep(20)
    bar.setValue(30)
    items["scrollBar"] = bar
    progress = QProgressBar(dialog)
    progress.setRange(0, 100)
    progress.setValue(40)
    items["progressBar"] = progress
    check = QCheckBox("Marcar", dialog)
    check.setChecked(True)
    items["checkBox"] = check
    radio = QRadioButton("Opcao", dialog)
    radio.setChecked(True)
    items["radioButton"] = radio
    sizes = {"pushButton": (120, 32), "pushButtonMenu": (120, 32), "comboBox": (160, 28), "comboBoxEditable": (160, 28),
             "toolButton": (100, 28), "toolButtonAutoRaise": (80, 28), "toolButtonMenuPopup": (110, 28),
             "toolButtonInstantPopup": (90, 28), "colorButton": (80, 28), "spinBox": (90, 28), "lineEdit": (160, 28),
             "tabBar": (220, 30), "tabWidget": (220, 90), "header": (220, 120), "groupBox": (160, 80),
             "collapsibleGroupBox": (160, 80), "scrollBar": (18, 160), "progressBar": (160, 24), "checkBox": (110, 24),
             "radioButton": (110, 24)}
    grid = QGridLayout(dialog)
    for i, (name, widget) in enumerate(items.items()):
        widget.setFixedSize(*sizes[name])
        widget.setFocusPolicy(Qt.NoFocus)
        grid.addWidget(widget, i // 4, i % 4)
    return items


def style_targets(name, widget):
    """Onde pr o estilo de gravacao: o proprio widget, e as partes que se desenham sozinhas (cabecalho, botao da caixa
    recolhivel, barra das abas)."""
    if name == "header":
        return [widget.horizontalHeader()]
    if name == "collapsibleGroupBox":
        return [widget] + [b for b in widget.findChildren(QToolButton)]
    if name == "tabWidget":
        return [widget, widget.tabBar()]
    return [widget]


def step_paths():
    dialog = QDialog(iface.mainWindow())
    dialog.setWindowTitle("Caminho do desenho 066")
    items = build_components(dialog)
    dialog.show()
    QApplication.processEvents()
    recorder = Recorder()
    state["recorder"] = recorder
    for name, widget in items.items():
        targets = style_targets(name, widget)
        for t in targets:
            t.setStyle(recorder)
        QApplication.processEvents()
        recorder.calls = []
        widget.grab()
        seen = []
        for call in recorder.calls:
            if call not in seen:
                seen.append(call)
        panel = sorted({c[2] for c in seen if c[1] == "PE_PanelButtonCommand"} - {None})
        facts["paths"][name] = {
            "class": widget.metaObject().className(),
            "calls": [list(c) for c in seen],
            "panelButtonCommand": bool(panel),
            "panelButtonCommandWidgets": panel,
            "panelButtonCommandWithPushButton": any(c[1] == "PE_PanelButtonCommand" and c[3] for c in seen),
        }
    dialog.close()
    dialog.deleteLater()


# ------------------------------------------------------------------------------------------ raio das quinas do botao
def button_option(button, which):
    opt = QStyleOptionButton()
    button.initStyleOption(opt)
    flags = QStyle.State_Enabled | QStyle.State_Active | QStyle.State_Raised
    if which == "hover":
        flags |= QStyle.State_MouseOver
    if which == "pressed":
        flags = QStyle.State_Enabled | QStyle.State_Active | QStyle.State_Sunken
    if which == "disabled":
        flags = QStyle.State_Active | QStyle.State_Raised
    if which == "focus":
        flags |= QStyle.State_HasFocus | QStyle.State_KeyboardFocusChange
    opt.state = flags
    opt.palette = QPalette(button.palette())
    opt.palette.setCurrentColorGroup(QPalette.Disabled if which == "disabled" else QPalette.Active)
    features = QStyleOptionButton.AutoDefaultButton
    if which == "default":
        features |= QStyleOptionButton.DefaultButton
    if which == "menu":
        features |= QStyleOptionButton.HasMenu
    opt.features = features
    return opt


def render_button(style, button, opt, dpr):
    w, h = opt.rect.width(), opt.rect.height()
    image = QImage(int(round(w * dpr)), int(round(h * dpr)), QImage.Format_ARGB32_Premultiplied)
    image.setDevicePixelRatio(dpr)
    image.fill(Qt.transparent)
    painter = QPainter(image)
    style.drawControl(QStyle.CE_PushButton, opt, painter, button)
    painter.end()
    return image


def reference_shape(radius, size, dpr):
    """Referencia de raio conhecido, com o mesmo traco do painel do botao: preenchimento sem caneta e contorno de 1 px,
    no retangulo do botao encolhido de 1 px embaixo e a direita, deslocado meio pixel (o desenho do Fusion)."""
    w, h = size
    image = QImage(int(round(w * dpr)), int(round(h * dpr)), QImage.Format_ARGB32_Premultiplied)
    image.setDevicePixelRatio(dpr)
    image.fill(Qt.transparent)
    p = QPainter(image)
    p.setRenderHint(QPainter.Antialiasing, True)
    p.translate(0.5, -0.5)
    r = QRectF(QRect(0, 0, w, h).adjusted(0, 1, -1, 0))
    p.setPen(Qt.transparent)
    p.setBrush(QBrush(QColor(200, 200, 200)))
    p.drawRoundedRect(r, radius, radius)
    p.setBrush(Qt.NoBrush)
    p.setPen(QPen(QColor(100, 100, 100)))
    p.drawRoundedRect(r, radius, radius)
    p.end()
    return image


def corner_boxes(alpha, k):
    h, w = alpha.shape
    return {
        "topLeft": alpha[:k, :k],
        "topRight": alpha[:k, w - k:][:, ::-1],
        "bottomLeft": alpha[h - k:, :k][::-1, :],
        "bottomRight": alpha[h - k:, w - k:][::-1, ::-1],
    }


def alpha_of(image):
    return ((to_array(image) >> 24) & 0xFF).astype(np.float64)


def outer_radius(box, dpr):
    missing = float((255.0 - box).sum()) / 255.0 / (dpr * dpr)
    return math.sqrt(missing / (1.0 - math.pi / 4.0))


def step_radius():
    app = QApplication.instance()
    dpr = app.devicePixelRatio()
    style = QApplication.style()
    pure = QStyleFactory.create("fusion")
    state["pure"] = pure
    k = int(math.ceil(8 * dpr))
    candidates = [0.5 + 0.25 * i for i in range(31)]
    references = {r: corner_boxes(alpha_of(reference_shape(r, BUTTON_SIZE, dpr)), k) for r in candidates}
    calibration = {}
    for r in (1.0, 2.0, 3.0, 4.0, 5.0, 6.0):
        boxes = corner_boxes(alpha_of(reference_shape(r, BUTTON_SIZE, dpr)), k)
        calibration["%.1f" % r] = round(sum(outer_radius(b, dpr) for b in boxes.values()) / 4 - 0.5, 3)
    holder = QWidget(iface.mainWindow())
    button = QPushButton("Executar", holder)
    button.resize(*BUTTON_SIZE)
    button.setMenu(None)
    window_color = QApplication.palette().color(QPalette.Active, QPalette.Window)
    out = {"scale": dpr, "boxPixels": k, "calibration": calibration, "states": {}}
    for which in STATES:
        opt = button_option(button, which)
        mine = render_button(style, button, opt, dpr)
        ref = render_button(pure, button, opt, dpr)
        alpha = alpha_of(mine)
        boxes = corner_boxes(alpha, k)
        per_corner = {}
        for corner, box in boxes.items():
            fit = min(candidates, key=lambda r: float(np.abs(references[r][corner] - box).sum()))
            per_corner[corner] = {"estimate": round(outer_radius(box, dpr) - 0.5, 3), "fit": fit}
        a, b = to_array(mine), to_array(ref)
        diff = a != b
        mask = np.zeros(diff.shape, dtype=bool)
        mask[:k, :k] = mask[:k, -k:] = mask[-k:, :k] = mask[-k:, -k:] = True
        out["states"][which] = {
            "corners": per_corner,
            "estimate": round(sum(c["estimate"] for c in per_corner.values()) / 4, 3),
            "fit": sorted({c["fit"] for c in per_corner.values()}),
            "diffFromFusionOutsideCorners": int((diff & ~mask).sum()),
            "diffFromFusionInCorners": int((diff & mask).sum()),
        }
        # captura: o botao sobre o fundo da janela (4x) e as quatro quinas lado a lado (12x)
        flat = QImage(mine.width(), mine.height(), QImage.Format_RGB32)
        flat.fill(window_color)
        unscaled = QImage(mine)
        unscaled.setDevicePixelRatio(1.0)  # pixel a pixel: sem isso o desenho na escala 1,25 sai encolhido
        p = QPainter(flat)
        p.drawImage(0, 0, unscaled)
        p.end()
        save_image(flat.scaled(flat.width() * 4, flat.height() * 4, Qt.KeepAspectRatio, Qt.FastTransformation),
                   "a5-botao-%s.png" % which)
        save_image(flat, "raw-botao-%s.png" % which)
        zoom = 12
        strip = QImage((k * 4 + 3) * zoom, k * zoom, QImage.Format_RGB32)
        strip.fill(QColor(255, 255, 255))
        p = QPainter(strip)
        w, h = flat.width(), flat.height()
        for i, (x, y) in enumerate(((0, 0), (w - k, 0), (0, h - k), (w - k, h - k))):
            corner = flat.copy(x, y, k, k).scaled(k * zoom, k * zoom, Qt.KeepAspectRatio, Qt.FastTransformation)
            p.drawImage(i * (k + 1) * zoom, 0, corner)
        p.end()
        save_image(strip, "a5-quinas-%s.png" % which)
    holder.deleteLater()
    facts["radius"] = out


# -------------------------------------------------------------------------------------- componentes do A5 (iii)
def step_components():
    dialog = QDialog(iface.mainWindow())
    dialog.setWindowTitle("Componentes 066")
    items = build_components(dialog)
    dialog.move(40, 40)
    dialog.show()
    dialog.raise_()
    QApplication.processEvents()
    cursor = dialog.mapFromGlobal(QCursor.pos())
    facts["componentsCursorInside"] = dialog.rect().contains(cursor)
    for name, widget in items.items():
        widget.setAttribute(Qt.WA_UnderMouse, False)
        image = widget.grab().toImage()
        save_image(image, "a5c-%s.png" % name)
        facts["components"][name] = {"class": widget.metaObject().className(), "size": [widget.width(), widget.height()],
                                     "image": "a5c-%s.png" % name}
    state["componentsDialog"] = dialog


def step_close_components():
    dialog = state.pop("componentsDialog", None)
    if dialog is not None:
        dialog.close()


# ----------------------------------------------------------------------------------------------- regioes do A2
def first_visible(parent, kind, test=None):
    for w in parent.findChildren(kind):
        if w.isVisible() and w.width() > 10 and (test is None or test(w)):
            return w
    return None


def region(id_, info, widget=None, capture=None, margin=2):
    facts["regions"][id_] = info
    if widget is not None:
        info["class"] = widget.metaObject().className()
        info["text"] = widget.text() if hasattr(widget, "text") and callable(widget.text) else None
        if capture:
            pix = window_crop(widget, margin)
            save_image(pix.toImage().scaled(pix.width() * 3, pix.height() * 3, Qt.KeepAspectRatio, Qt.FastTransformation), capture)


def spin_rects(spin):
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


def scroll_rects(bar):
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
    return (style.subControlRect(QStyle.CC_ScrollBar, opt, QStyle.SC_ScrollBarGroove, bar),
            style.subControlRect(QStyle.CC_ScrollBar, opt, QStyle.SC_ScrollBarSlider, bar))


def tool_menu_rect(button):
    opt = QStyleOptionToolButton()
    opt.initFrom(button)
    opt.rect = button.rect()
    opt.features = QStyleOptionToolButton.MenuButtonPopup | QStyleOptionToolButton.HasMenu
    opt.subControls = QStyle.SC_ToolButton | QStyle.SC_ToolButtonMenu
    return button.style().subControlRect(QStyle.CC_ToolButton, opt, QStyle.SC_ToolButtonMenu, button)


def step_theme():
    settings = QgsSettings()
    style = QApplication.style()
    base = style.baseStyle() if hasattr(style, "baseStyle") else None
    palette = QApplication.palette()
    groups = (("Active", QPalette.Active), ("Inactive", QPalette.Inactive), ("Disabled", QPalette.Disabled))
    facts["theme"] = {
        "themeName": QgsApplication.themeName(),
        "styleSheetLength": len(QApplication.instance().styleSheet()),
        "qtStyle": style.metaObject().className(),
        "qtStyleObjectName": style.objectName(),
        "qtStyleBase": base.metaObject().className() if base is not None else None,
        "settingUITheme": settings.value("UI/UITheme", None),
        "settingQgisStyle": settings.value("qgis/style", None),
        "devicePixelRatio": QApplication.instance().devicePixelRatio(),
        "palette": {n: {role: palette.color(g, getattr(QPalette, role)).name(QColor.HexArgb).upper()
                        for role in ("Button", "ButtonText", "Window", "Highlight")} for n, g in groups},
        "fusionDerived": fusion_derived(palette),
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
    window.showMaximized()
    window.raise_()
    window.activateWindow()
    QApplication.processEvents()


def step_attribute_table():
    layers = list(QgsProject.instance().mapLayers().values())
    table_dialog = iface.showAttributeTable(layers[0]) if layers else None
    QApplication.processEvents()
    if table_dialog is None:
        facts["regions"]["header"] = {"found": False}
        return
    table_dialog.resize(800, 320)
    QApplication.processEvents()
    views = [v for v in table_dialog.findChildren(QTableView) if v.isVisible()]
    if views:
        header = views[0].horizontalHeader()
        x0 = header.sectionViewportPosition(0)
        width = sum(header.sectionSize(i) for i in range(min(header.count(), 3)))
        info = measure_rect(header, QRect(x0, 0, width, header.height()), inset=1)
        region("header", info, header, "a2-cabecalho.png")
    state["table"] = table_dialog


def step_close_table():
    table_dialog = state.pop("table", None)
    if table_dialog is not None:
        table_dialog.close()


def step_toolbox_scrollbar():
    dock = iface.mainWindow().findChild(QDockWidget, "ProcessingToolbox")
    if dock is None:
        facts["regions"]["scrollTrack"] = {"found": False}
        return
    dock.show()
    dock.raise_()
    QApplication.processEvents()
    tree = dock.findChild(QTreeView)
    model = tree.model()
    for row in range(model.rowCount()):
        index = model.index(row, 0)
        if model.rowCount(index) > 20:
            tree.expand(index)
            break
    QApplication.processEvents()
    bars = [b for b in tree.findChildren(QScrollBar) if b.isVisible() and b.orientation() == Qt.Vertical]
    if not bars:
        facts["regions"]["scrollTrack"] = {"found": False}
        return
    bar = bars[0]
    groove, slider = scroll_rects(bar)
    region("scrollHandle", measure_rect(bar, slider, inset=2), bar, "a2-barra-de-rolagem.png", 1)
    below = QRect(groove.x(), slider.bottom() + 3, groove.width(), max(groove.bottom() - slider.bottom() - 6, 1))
    region("scrollTrack", measure_rect(bar, below, inset=2), bar)


def step_layer_properties():
    layers = list(QgsProject.instance().mapLayers().values())
    if not layers:
        facts["regions"]["styleButton"] = {"found": False}
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
        facts["regions"]["styleButton"] = {"found": False}
        return
    try:
        dialog.resize(1100, 760)
        QApplication.processEvents()
        with_menu = [b for b in dialog.findChildren(QPushButton) if b.isVisible() and b.menu() is not None]
        named = [b for b in with_menu if b.text().replace("&", "") in ("Estilo", "Style")]
        style_button = (named or with_menu or [None])[0]
        facts["styleButtonCandidates"] = [b.text() for b in with_menu]
        if style_button is not None:
            region("styleButton", measure_rect(style_button, inset=3), style_button, "a2-botao-estilo.png")
        color = first_visible(dialog, QgsColorButton)
        if color is not None:
            # a amostra de cor ocupa quase todo o botao: o painel do botao aparece na parte do menu, a direita
            region("colorButton", measure_rect(color, tool_menu_rect(color), inset=2), color, "a2-botao-de-cor.png")
        save_image(dialog.grab().toImage(), "a2-propriedades-simbologia.png")
    except Exception as err:
        facts.setdefault("errors", {})["read_layer_properties"] = repr(err)
    dialog.reject()


def step_options():
    QTimer.singleShot(3000, read_options)
    iface.showOptionsDialog(iface.mainWindow(), "mOptionsPageGeneral")


def read_options():
    dialog = _dialog("QgsOptions")
    if dialog is None:
        facts["regions"]["optionsOk"] = {"found": False}
        return
    try:
        dialog.resize(1100, 760)
        QApplication.processEvents()
        box = first_visible(dialog, QDialogButtonBox)
        if box is not None:
            for id_, which, name in (("optionsOk", QDialogButtonBox.Ok, "a2-opcoes-ok.png"),
                                     ("optionsCancel", QDialogButtonBox.Cancel, "a2-opcoes-cancelar.png")):
                b = box.button(which)
                if b is not None:
                    info = measure_rect(b, inset=3)
                    info["isDefault"] = b.isDefault()
                    region(id_, info, b, name)
        save_image(dialog.grab().toImage(), "a2-opcoes.png")
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
    dialog = state["dialog"]
    tabs = dialog.findChild(QTabWidget, "mTabWidget")
    bar = tabs.tabBar()
    tabs.setCurrentIndex(0)
    QApplication.processEvents()
    save_image(dialog.grab().toImage(), "a2-algoritmo-parametros.png")
    region("tabSelected", measure_rect(bar, bar.tabRect(0), inset=3), bar, "a2-abas.png", 3)
    facts["regions"]["tabSelected"]["tab"] = bar.tabText(0)
    region("tabUnselected", measure_rect(bar, bar.tabRect(1), inset=3))
    facts["regions"]["tabUnselected"]["tab"] = bar.tabText(1)
    run_button = first_visible(dialog, QPushButton, lambda b: b.text().replace("&", "") in ("Executar", "Run"))
    if run_button is not None:
        region("runButton", measure_rect(run_button, inset=3), run_button, "a2-botao-executar.png")
    combo = first_visible(dialog, QComboBox, lambda c: not c.isEditable() and c.count() >= 2)
    if combo is not None:
        region("comboClosed", measure_rect(combo, inset=3), combo, "a2-caixa-de-selecao.png")
    spins = [s for s in dialog.findChildren(QAbstractSpinBox) if s.isVisible() and s.buttonSymbols() != QAbstractSpinBox.NoButtons]
    if spins:
        spin = spins[0]
        up, down = spin_rects(spin)
        region("spinButtons", measure_rect(spin, up.united(down), inset=1), spin, "a2-caixa-numerica.png")
    tabs.setCurrentIndex(1)
    QApplication.processEvents()
    save_image(dialog.grab().toImage(), "a2-algoritmo-log.png")
    page = tabs.currentWidget()
    log = first_visible(page, QTextEdit)
    info = measure_rect(page)
    if log is not None:
        # o painel das abas e o que sobra da pagina fora do texto do Log
        array, dpr = rgb_array(window_crop(page))
        mask = np.ones(array.shape, dtype=bool)
        origin = log.mapTo(page, QPoint(0, 0))
        mask[int(origin.y() * dpr):int((origin.y() + log.height()) * dpr), int(origin.x() * dpr):int((origin.x() + log.width()) * dpr)] = False
        info = color_stats(array[mask])
    region("tabPane", info, page)
    facts["regions"]["tabPane"]["tab"] = tabs.tabText(1)
    tabs.setCurrentIndex(0)
    QApplication.processEvents()


def step_close_dialog():
    dialog = state.pop("dialog", None)
    if dialog is not None:
        dialog.close()


# ------------------------------------------------------------------------------------------ comparacao com referencia
def compare_images(name, mask_corners=None):
    mine_path = os.path.join(out_dir, name)
    ref_path = os.path.join(reference_dir, name)
    if not os.path.exists(ref_path) or not os.path.exists(mine_path):
        return {"found": False}
    a = to_array(QImage(mine_path))
    b = to_array(QImage(ref_path))
    if a.shape != b.shape:
        return {"found": True, "sameSize": False, "size": [a.shape[1], a.shape[0]], "referenceSize": [b.shape[1], b.shape[0]]}
    diff = a != b
    out = {"found": True, "sameSize": True, "pixels": int(diff.size), "different": int(diff.sum())}
    if mask_corners:
        k = mask_corners
        mask = np.zeros(diff.shape, dtype=bool)
        mask[:k, :k] = mask[:k, -k:] = mask[-k:, :k] = mask[-k:, -k:] = True
        out["differentInCorners"] = int((diff & mask).sum())
        out["differentOutsideCorners"] = int((diff & ~mask).sum())
    return out


def step_compare():
    if not reference_dir:
        return
    k = facts.get("radius", {}).get("boxPixels")
    comp = {"reference": os.path.basename(os.path.normpath(reference_dir)), "components": {}, "buttons": {}, "regions": {}}
    for name, info in facts["components"].items():
        comp["components"][name] = compare_images(info["image"], k)
    for which in STATES:
        comp["buttons"][which] = compare_images("raw-botao-%s.png" % which, k)
    ref_json = os.path.join(reference_dir, "buttons.json")
    if os.path.exists(ref_json):
        with open(ref_json, encoding="utf-8") as fh:
            ref = json.load(fh)
        comp["referenceTheme"] = ref.get("theme", {}).get("qtStyle")
        comp["referenceRadius"] = {w: s.get("estimate") for w, s in ref.get("radius", {}).get("states", {}).items()}
        for id_, info in facts["regions"].items():
            other = ref.get("regions", {}).get(id_, {})
            comp["regions"][id_] = {"before": other.get("backgroundMean"), "after": info.get("backgroundMean"),
                                    "beforeMostCommon": other.get("background"), "afterMostCommon": info.get("background")}
    facts["compare"] = comp


def finish():
    run(step_compare)
    with open(os.path.join(out_dir, "buttons.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


def first():
    for step in (step_theme, step_load_project):
        run(step)
    QTimer.singleShot(4000, second)


def second():
    for step in (step_paths, step_radius, step_components):
        run(step)
    QTimer.singleShot(1500, third)


def third():
    for step in (step_close_components, step_attribute_table):
        run(step)
    QTimer.singleShot(1500, fourth)


def fourth():
    for step in (step_close_table, step_toolbox_scrollbar):
        run(step)
    # os dois dialogos modais, um depois do outro (o timer de leitura de cada um fecha o dialogo)
    run(step_layer_properties)
    QTimer.singleShot(500, fifth)


def fifth():
    run(step_options)
    QTimer.singleShot(500, sixth)


def sixth():
    run(step_open_dialog)
    QTimer.singleShot(2500, seventh)


def seventh():
    for step in (step_algorithm, step_close_dialog):
        run(step)
    finish()


QTimer.singleShot(3000, first)
