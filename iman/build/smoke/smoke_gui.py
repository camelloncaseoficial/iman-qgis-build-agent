# Smoke de GUI, rodado pelo proprio QGIS via --code (Invoke-Smoke.ps1), no build e no QGIS oficial.
# Abre o .qgz, espera o canvas, coleta os fatos de comportamento e de marca, grava gui.json e as capturas e fecha.
# So coleta fatos: quem decide o que passa e o Invoke-Smoke.ps1, contra iman/brand/brand.json.
import hashlib
import json
import os
import re

from qgis.core import (
    Qgis,
    QgsApplication,
    QgsLayoutExporter,
    QgsLayoutItemMap,
    QgsLayoutPoint,
    QgsLayoutSize,
    QgsPrintLayout,
    QgsProject,
    QgsSettings,
    QgsUnitTypes,
)
from qgis.PyQt.QtCore import QCoreApplication, QFile, QIODevice, QObject, QTimer, QUrl, pyqtSlot
from qgis.PyQt.QtGui import QDesktopServices
from qgis.PyQt.QtWidgets import QAction
from qgis.utils import iface

out_dir = os.environ["IMAN_SMOKE_OUT"]
project_path = os.environ["IMAN_SMOKE_PROJECT"]
work_dir = os.path.dirname(project_path)
result = {"version": Qgis.version(), "dev_version": Qgis.devVersion()}
result["window_title_at_start"] = iface.mainWindow().windowTitle()

# recursos compilados e arquivos que carregam (ou carregavam) o logo do QGIS
RESOURCES = [
    ":/images/icons/qgis_icon.svg",
    ":/images/icons/qgis-icon-16x16.png",
    ":/images/icons/qgis-icon-60x60.png",
    ":/images/splash/splash.png",
    ":/images/themes/default/providerQgis.svg",
    ":/images/icons/qgis-full.png",
]
# mensagens que a sobreposicao da marca precisa alcancar (contexto, fonte)
MESSAGES = [
    ("QgisApp", "QGIS"),
    ("QgisApp", "QGIS - %1 ('%2')"),
    ("QgisApp", "QGIS Ready!"),
    ("QgisApp", "QGIS version"),
    ("MainWindow", "QGIS Home Page"),
    ("MainWindow", "Exit QGIS"),
    ("MainWindow", "Donate to QGIS"),
    ("QgsAbout", "About QGIS"),
]
# acoes do menu Ajuda: a URL que cada uma abriria
HELP_ACTIONS = [
    "mActionQgisHomePage",
    "mActionReportaBug",
    "mActionNeedSupport",
    "mActionDonate",
    "mActionGetInvolved",
    "mActionSponsors",
]


class UrlCatcher(QObject):
    """Recebe a URL que a acao mandaria ao navegador, sem abrir o navegador."""

    def __init__(self):
        super().__init__()
        self.urls = []

    @pyqtSlot(QUrl)
    def catch(self, url):
        self.urls.append(url.toString())


def resource_sha256(path):
    f = QFile(path)
    if not f.open(QIODevice.ReadOnly):
        return None
    data = bytes(f.readAll())
    f.close()
    return hashlib.sha256(data).hexdigest()


def file_sha256(path):
    try:
        with open(path, "rb") as fh:
            return hashlib.sha256(fh.read()).hexdigest()
    except OSError:
        return None


def collect_brand():
    result["translation"] = QgsApplication.instance().translation()
    settings = QgsSettings()
    result["settings"] = {
        "locale/userLocale": settings.value("locale/userLocale", ""),
        "locale/overrideFlag": settings.value("locale/overrideFlag", False, type=bool),
        "qgis/checkVersion": settings.value("qgis/checkVersion", True, type=bool),
        "qgis/allowVersionCheck": settings.value("qgis/allowVersionCheck", True, type=bool),
        "core/httpsfeedqgisorg/disabled": settings.value(
            "httpsfeedqgisorg/disabled", False, type=bool, section=QgsSettings.Core
        ),
        "cache/directory": settings.value("cache/directory", ""),
    }
    result["translations"] = {
        "%s|%s" % (ctx, src): QCoreApplication.translate(ctx, src) for ctx, src in MESSAGES
    }
    result["resources"] = {path: resource_sha256(path) for path in RESOURCES}
    result["app_icon_path"] = QgsApplication.appIconPath()
    result["app_icon_sha256"] = file_sha256(QgsApplication.appIconPath())
    window = iface.mainWindow()
    check_version = window.findChild(QAction, "mActionCheckQgisVersion")
    result["check_version_action_visible"] = check_version.isVisible() if check_version else None
    catcher = UrlCatcher()
    for scheme in ("http", "https"):
        QDesktopServices.setUrlHandler(scheme, catcher, "catch")
    urls = {}
    try:
        for name in HELP_ACTIONS:
            action = window.findChild(QAction, name)
            catcher.urls = []
            if action is not None:
                action.trigger()
            urls[name] = {"text": action.text() if action else None, "urls": list(catcher.urls)}
    finally:
        for scheme in ("http", "https"):
            QDesktopServices.unsetUrlHandler(scheme)
    result["help_actions"] = urls


def export_pdf():
    project = QgsProject.instance()
    layout = QgsPrintLayout(project)
    layout.initializeDefaults()
    layout.setName("smoke")
    item = QgsLayoutItemMap(layout)
    item.attemptMove(QgsLayoutPoint(10, 10, QgsUnitTypes.LayoutMillimeters))
    item.attemptResize(QgsLayoutSize(200, 150, QgsUnitTypes.LayoutMillimeters))
    item.setLayers(list(project.mapLayers().values()))
    item.zoomToExtent(iface.mapCanvas().fullExtent())
    layout.addLayoutItem(item)
    pdf = os.path.join(out_dir, "layout.pdf")
    status = QgsLayoutExporter(layout).exportToPdf(pdf, QgsLayoutExporter.PdfExportSettings())
    info = {"status": int(status), "file": "layout.pdf"}
    try:
        with open(pdf, "rb") as fh:
            data = fh.read()
        info["creator"] = _pdf_values(data, b"Creator")
        info["producer"] = _pdf_values(data, b"Producer")
        info["xmp_creator_tool"] = _xmp_values(data, "xmp:CreatorTool")
        info["xmp_producer"] = _xmp_values(data, "pdf:Producer")
    except OSError as err:
        info["error"] = str(err)
    result["pdf"] = info


def _pdf_string(raw):
    if raw.startswith(b"\xfe\xff"):
        return raw[2:].decode("utf-16-be", "replace")
    return raw.decode("latin-1")


def _pdf_values(data, key):
    values = []
    for m in re.finditer(rb"/" + key + rb"\s*\(((?:\\.|[^\\)])*)\)", data):
        raw = re.sub(rb"\\(.)", rb"\1", m.group(1))
        values.append(_pdf_string(raw))
    for m in re.finditer(rb"/" + key + rb"\s*<([0-9A-Fa-f\s]*)>", data):
        values.append(_pdf_string(bytes.fromhex(m.group(1).decode().replace(" ", ""))))
    return values


def _xmp_values(data, tag):
    text = data.decode("latin-1")
    values = re.findall(r"<%s>([^<]*)</%s>" % (tag, tag), text)
    values += re.findall(r'%s="([^"]*)"' % tag, text)
    return [v.encode("latin-1").decode("utf-8", "replace") for v in values]


def save_project_copy():
    saved = os.path.join(work_dir, "saved.qgs")
    project = QgsProject.instance()
    ok = project.write(saved)
    version = None
    try:
        with open(saved, "r", encoding="utf-8") as fh:
            m = re.search(r'<qgis [^>]*version="([^"]+)"', fh.read())
            version = m.group(1) if m else None
    except OSError:
        pass
    result["saved_project"] = {"written": ok, "qgis_version_attribute": version}


def load_project():
    project = QgsProject.instance()
    result["project_read"] = project.read(project_path)
    result["layers"] = [
        {
            "name": lyr.name(),
            "valid": lyr.isValid(),
            "features": lyr.featureCount(),
            "crs": lyr.crs().authid(),
        }
        for lyr in project.mapLayers().values()
    ]
    iface.mapCanvas().zoomToFullExtent()
    iface.mapCanvas().refreshAllLayers()
    QTimer.singleShot(5000, capture_and_exit)


def capture_and_exit():
    window = iface.mainWindow()
    result["window_visible"] = window.isVisible()
    result["window_title"] = window.windowTitle()
    result["window_size"] = [window.width(), window.height()]
    window.grab().save(os.path.join(out_dir, "gui.png"))
    iface.mapCanvas().saveAsImage(os.path.join(out_dir, "canvas.png"))
    for step in (collect_brand, export_pdf, save_project_copy):
        try:
            step()
        except Exception as err:  # um passo que quebra vira fato, nao derruba o smoke
            result.setdefault("errors", {})[step.__name__] = repr(err)
    with open(os.path.join(out_dir, "gui.json"), "w", encoding="utf-8") as fh:
        json.dump(result, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


QTimer.singleShot(3000, load_project)
