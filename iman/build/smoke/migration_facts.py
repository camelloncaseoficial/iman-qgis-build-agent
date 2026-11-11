# Fatos da migracao do projeto REURB pelo plugin embarcado (fatia 061, T2, T3 e T4), rodado pelo proprio QGIS via
# --code (Test-PluginMigration.ps1), sempre com perfil descartavel e projeto descartavel, nunca dado real.
#   IMAN_MIG_PHASE=seed: com o plugin que a arvore embarca (0.3.1 na 051), cria pelo servico do proprio plugin um
#     projeto REURB em IMAN_MIG_WORKSPACE, com um lote, uma pessoa sem documento e o vinculo dela ao lote;
#   IMAN_MIG_PHASE=open: com o plugin desta arvore, reabre o GeoPackage pelo mesmo caminho do botao "Reabrir projeto"
#     do painel (o ProjectViewModel le pelo OpenReurbProjectService, que migra, e ativa), e le a aba Pessoas.
# So coleta fatos (contagens pelo sqlite, versao do schema, arquivos .bak, aba Pessoas, metadados do plugin) e
# capturas: quem julga e o Test-PluginMigration.ps1. Cada passo que quebra vira fato em "errors".
import glob
import json
import os
import sqlite3
import traceback

from qgis.core import QgsProject
from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtWidgets import QApplication, QTableWidget, QTabWidget
from qgis.utils import iface, plugins

out_dir = os.environ["IMAN_MIG_OUT"]
phase = os.environ["IMAN_MIG_PHASE"]
plugin_id = os.environ["IMAN_MIG_PLUGIN_ID"]
workspace = os.environ["IMAN_MIG_WORKSPACE"]
label = os.environ.get("IMAN_MIG_LABEL", phase)
PERSON_NAME = "Pessoa de Teste 061"
PROJECT_NAME = "Projeto de Teste 061"
result = {"phase": phase, "errors": {}}


def run(name, step):
    try:
        step()
    except Exception:
        result["errors"][name] = traceback.format_exc()


def gpkg_facts(path):
    """Versao do schema e contagens, direto no arquivo (o GeoPackage e sqlite)."""
    con = sqlite3.connect(path)
    try:
        cur = con.cursor()
        facts = {"path": path}
        row = cur.execute("SELECT value FROM reurb_project WHERE key='schema_version'").fetchone()
        facts["schema_version"] = row[0] if row else None
        for table in ("lotes", "pessoas", "lote_pessoa"):
            facts[table] = cur.execute("SELECT count(*) FROM %s" % table).fetchone()[0]
        facts["person_names"] = [r[0] for r in cur.execute("SELECT name FROM pessoas ORDER BY name")]
        facts["pessoas_columns"] = [r[1] for r in cur.execute("PRAGMA table_info(pessoas)")]
        return facts
    finally:
        con.close()


def content_digest(path):
    """SHA-256 do conteudo de todas as tabelas (sqlite_master e linhas por rowid), so leitura. A copia de seguranca
    nao sai byte a byte igual a semente: o GDAL tira o arquivo do modo WAL ao abri-lo, antes da copia, e isso muda o
    cabecalho do SQLite (bytes 18, 19, 27 e 95, medido na 061), sem mudar dado."""
    import hashlib

    con = sqlite3.connect("file:%s?mode=ro" % path.replace("\\", "/"), uri=True)
    try:
        h = hashlib.sha256()
        master = con.execute("SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name").fetchall()
        h.update(repr(master).encode("utf-8"))
        for (name,) in con.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").fetchall():
            for row in con.execute('SELECT * FROM "%s" ORDER BY rowid' % name):
                h.update(repr(row).encode("utf-8"))
        return h.hexdigest()
    finally:
        con.close()


def find_gpkg():
    found = sorted(glob.glob(os.path.join(workspace, "*.gpkg")))
    return found[0] if found else None


def backups():
    return sorted(os.path.basename(p) for p in glob.glob(os.path.join(workspace, "*.bak*")))


def plugin_meta():
    from qgis.utils import pluginMetadata

    meta = {"version": pluginMetadata(plugin_id, "version"), "author": pluginMetadata(plugin_id, "author"),
            "name": pluginMetadata(plugin_id, "name"), "active": plugin_id in plugins}
    # o que o gerenciador de complementos mostra (a mesma base que a lista "Instalados")
    try:
        from pyplugin_installer.installer_data import plugins as registry

        registry.rebuild()
        entry = registry.all().get(plugin_id)
        if entry:
            meta["manager"] = {"name": entry.get("name"), "version_installed": entry.get("version_installed"),
                               "author_name": entry.get("author_name"), "installed": entry.get("installed")}
    except Exception:
        meta["managerError"] = traceback.format_exc()
    result["plugin"] = meta


def seed():
    from iman_plugin.application.create_project_service import CreateReurbProjectService
    from iman_plugin.application.commit_feature_service import CommitParcelService
    from iman_plugin.application.dto import CreateProjectRequest
    from iman_plugin.application.enrichment_dto import PersonRecord
    from iman_plugin.application.person_link_service import PersonLinkService
    from iman_plugin.application.vectorization_dto import FeatureContext, ParcelDraft
    from iman_plugin.infrastructure.processors.geometry_ops import QgisGeometryGuard, QgisGeometryMeasurer
    from iman_plugin.infrastructure.processors.qgis_workspace_loader import QgisWorkspaceLoader
    from iman_plugin.infrastructure.repositories.feature_repository import QgisFeatureRepository
    from iman_plugin.infrastructure.repositories.geopackage_enrichment_repository import GeoPackageEnrichmentRepository
    from iman_plugin.infrastructure.repositories.geopackage_project_store import GeoPackageProjectStore

    request = CreateProjectRequest(
        name=PROJECT_NAME, municipality_name="Municipio de Teste", municipality_state="CE",
        crs_authid="EPSG:31984", responsible_name="Responsavel de Teste", responsible_registration="0000",
        workspace_dir=workspace)
    created = CreateReurbProjectService(GeoPackageProjectStore(), QgisWorkspaceLoader()).execute(request)
    if not created.ok:
        raise RuntimeError("criar projeto: %s" % (created.error,))
    summary = created.value
    ctx = FeatureContext(project_id=summary.name, project_crs_authid=summary.crs_authid, gpkg_path=summary.gpkg_path)
    wkt = "POLYGON((500000 9580000, 500020 9580000, 500020 9580030, 500000 9580030, 500000 9580000))"
    parcel = CommitParcelService(QgisGeometryGuard(), QgisGeometryMeasurer(), QgisFeatureRepository()).execute(
        ParcelDraft(geometry_wkt=wkt, source_crs_authid=summary.crs_authid, parcel_number="001"), ctx)
    if not parcel.ok:
        raise RuntimeError("lote: %s" % (parcel.error,))
    # pessoa sem documento (o briefing proibe CPF ou CNPJ valido)
    linked = PersonLinkService(GeoPackageEnrichmentRepository()).create_and_link(
        ctx, PersonRecord(name=PERSON_NAME, person_type="fisica"), parcel.value.feature_id, "proprietario", True)
    if not linked.ok:
        raise RuntimeError("pessoa e vinculo: %s" % (linked.error,))
    result["seed"] = {"project": summary.name, "gpkg": summary.gpkg_path, "parcel_id": parcel.value.feature_id,
                      "person_id": linked.value[0], "link_id": linked.value[1]}


def open_project():
    plugin = plugins[plugin_id]
    plugin._toggle_dock(True)
    QApplication.processEvents()
    dock = plugin._dock
    vm = dock._vm
    gpkg = find_gpkg()
    result["before"] = gpkg_facts(gpkg)
    result["before"]["contentDigest"] = content_digest(gpkg)
    result["backupsBefore"] = backups()
    # o mesmo que o botao "Reabrir projeto": le (migrando, se precisar) e ativa no painel
    read = vm._open_service.read(gpkg)
    result["read"] = {"ok": read.ok, "error": None if read.ok else repr(read.error)}
    vm._on_project_read(read)
    QApplication.processEvents()
    result["after"] = gpkg_facts(gpkg)
    result["backupsAfter"] = backups()
    result["backupDigests"] = {b: content_digest(os.path.join(workspace, b)) for b in result["backupsAfter"]}
    tabs =dock.findChild(QTabWidget, "imanTabs")
    info = {"found": tabs is not None}
    if tabs is not None:
        info["texts"] = [tabs.tabText(i) for i in range(tabs.count())]
        idx = next((i for i in range(tabs.count()) if tabs.tabText(i).replace("&", "") == "Pessoas"), -1)
        info["personsIndex"] = idx
        info["personsEnabled"] = idx >= 0 and tabs.isTabEnabled(idx)
        if idx >= 0:
            tabs.setCurrentIndex(idx)
            QApplication.processEvents()
    panel = getattr(dock, "_persons_panel", None)
    if panel is not None:
        plist = panel.viewmodel.person_list
        info["mode"] = plist.mode
        info["counter"] = plist.counter
        info["rows"] = len(plist.rows)
    table = dock.findChild(QTableWidget, "imanPersonsTable")
    if table is not None:
        info["tableRows"] = table.rowCount()
        info["tableNames"] = [table.item(r, 0).text() for r in range(table.rowCount()) if table.item(r, 0)]
    result["personsTab"] = info
    dock.grab().save(os.path.join(out_dir, "dock-pessoas-%s.png" % label))


def finish():
    run("plugin_meta", plugin_meta)
    try:
        QgsProject.instance().clear()
    except Exception:
        result["errors"]["clear"] = traceback.format_exc()
    with open(os.path.join(out_dir, "migration-%s.json" % label), "w", encoding="utf-8") as fh:
        json.dump(result, fh, indent=2, ensure_ascii=False)
    QgsProject.instance().setDirty(False)
    iface.actionExit().trigger()


def start():
    result["pluginLoaded"] = plugin_id in plugins
    if phase == "seed":
        run("seed", seed)
        gpkg = find_gpkg()
        if gpkg:
            run("facts", lambda: result.__setitem__("after", gpkg_facts(gpkg)))
    else:
        run("open", open_project)
    QTimer.singleShot(1500, finish)


QTimer.singleShot(3000, start)
