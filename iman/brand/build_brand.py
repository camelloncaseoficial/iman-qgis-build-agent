# -*- coding: utf-8 -*-
"""Gera, a partir da fonte unica de marca (BL-4), o que o build do QGIS precisa dela.

    python3 iman/brand/build_brand.py --out <pasta> --header <arquivo.h>
    python3 iman/brand/build_brand.py --measure <qgis_pt_BR.ts>   # confere a curadoria contra o .qm do QGIS

Entradas (versionadas): iman/brand/brand.json, iman/brand/i18n/curadoria_pt_BR.json, a trava do plugin embarcado
(iman/plugin/plugin.lock.json, so o id) e o resources/qgis_global_settings.ini do proprio QGIS.

Saidas (fora do repo, em --out):
  - iman_<locale>.ts: a traducao sobreposta (D-IMAN-041, regra 2), so com as mensagens das classes aplicativo e
    versao da curadoria e as superficies do Bloco D ('extra'); o Build-Qgis.ps1 compila com o lrelease fixado;
  - qgis_global_settings.ini: o do QGIS com a checagem de versao desligada e o SRC padrao de projeto novo (trocados
    no lugar), mais o idioma padrao, o feed de noticias desligado, os enderecos do menu Ajuda, o SRC de camada sem
    SRC (fatia 049) e o plugin embarcado ligado por padrao (fatia 051); sem tema de interface desde a fatia 063;
  - --header: iman_brand.h, os textos de marca para o C++ (Bloco D), a versao do produto e, desde a fatia 059, a
    paleta da marca (IMAN_COLOR_*; do brand.json desde a fatia 064, que deixou de ler o style.qss). So e regravado
    se o conteudo mudou, para nao recompilar a toa.

Marcadores dos textos da curadoria: {product}, {PRODUCT}, {engine}, {org}, {url}.
"""
import argparse
import io
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
BRAND = os.path.join(HERE, "brand.json")
CURATION = os.path.join(HERE, "i18n", "curadoria_pt_BR.json")
PLUGIN_LOCK = os.path.join(REPO, "iman", "plugin", "plugin.lock.json")
QGIS_GLOBAL_SETTINGS = os.path.join(REPO, "resources", "qgis_global_settings.ini")

TRANSLATED_CLASSES = ("aplicativo", "versao", "bloco-d")
# D-IMAN-034: travessao e meia-risca nao entram em texto escrito por nos
FORBIDDEN = (chr(0x2014), chr(0x2013))
# chave do feed de noticias do QGIS: QgsNewsFeedParser::keyForFeed("https://feed.qgis.org/"), secao core
NEWS_FEED_KEY = "httpsfeedqgisorg\\disabled"


def load_json(path):
    with io.open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def tokens(brand):
    return {
        "{product}": brand["product_name"],
        "{PRODUCT}": brand["product_name"].upper(),
        "{engine}": brand["engine_label"],
        "{org}": brand["organization_name"],
        "{url}": brand["product_url"],
    }


def expand(text, toks):
    for k, v in toks.items():
        text = text.replace(k, v)
    left = re.findall(r"\{(?:product|PRODUCT|engine|org|url)\}", text)
    if left:
        raise SystemExit("marcador sem valor: %s" % left)
    return text


def overlay_entries(curation):
    for e in curation["messages"]:
        if e["class"] in TRANSLATED_CLASSES:
            yield e
    for e in curation.get("extra", []):
        yield e


def write_ts(path, brand, curation):
    toks = tokens(brand)
    contexts = {}
    for e in overlay_entries(curation):
        text = expand(e["text"], toks)
        bad = [c for c in FORBIDDEN if c in text]
        if bad:
            raise SystemExit("travessao ou meia-risca na traducao de %s: %r" % (e["context"], text))
        contexts.setdefault(e["context"], []).append((e["source"], e.get("comment"), text))
    root = ET.Element("TS", {"version": "2.1", "language": brand["default_locale"]})
    for name in sorted(contexts):
        ctx = ET.SubElement(root, "context")
        ET.SubElement(ctx, "name").text = name
        for source, comment, text in contexts[name]:
            msg = ET.SubElement(ctx, "message")
            ET.SubElement(msg, "source").text = source
            if comment:
                ET.SubElement(msg, "comment").text = comment
            ET.SubElement(msg, "translation").text = text
    body = ET.tostring(root, encoding="unicode")
    with io.open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write('<?xml version="1.0" encoding="utf-8"?>\n<!DOCTYPE TS>\n')
        fh.write(body)
        fh.write("\n")
    return sum(len(v) for v in contexts.values())


def write_global_settings(path, brand, plugin_id):
    with io.open(QGIS_GLOBAL_SETTINGS, "r", encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    version_check = "true" if brand["qgis_version_check"] else "false"
    # chaves que o ini do QGIS ja tem, trocadas no lugar: (secao, chave) -> valor
    in_place = {
        ("qgis", "checkVersion"): version_check,
        ("qgis", "allowVersionCheck"): version_check,
        ("app", "projections\\defaultProjectCrs"): brand["default_project_crs"],
        ("app", "projections\\newProjectCrsBehavior"): brand["new_project_crs_behavior"],
    }
    # chaves que o ini do QGIS nao tem e que vao no fim, em secao propria: se ele passar a te-las, duplicaria.
    # Sem UI/UITheme desde a fatia 063 (emenda de 2026-11-12 ao D-IMAN-040): o tema e o do QGIS. A chave fica ausente,
    # como no QGIS oficial, e nao "default": o main.cpp le UI/UITheme sem valor padrao e, com o valor vazio, usa o
    # estilo fusion, o mesmo do oficial; com "default", ficaria o estilo da plataforma, outra cara
    appended = {("Projections", "layerDefaultCrs"), ("PythonPlugins", plugin_id)}
    replaced = []
    present = []
    group = None
    for i, line in enumerate(lines):
        m = re.match(r"^\[(.+)\]$", line)
        if m:
            group = m.group(1)
            continue
        for section, key in in_place:
            if group == section and line.startswith(key + "="):
                lines[i] = "%s=%s" % (key, in_place[(section, key)])
                replaced.append((section, key))
        for section, key in appended:
            if group == section and line.startswith(key + "="):
                present.append((section, key))
    if sorted(replaced) != sorted(in_place):
        raise SystemExit("qgis_global_settings.ini do QGIS mudou: chaves trocadas no lugar achadas %s" % sorted(replaced))
    if present:
        raise SystemExit("qgis_global_settings.ini do QGIS mudou: ja tem %s" % sorted(present))
    while lines and lines[-1] == "":
        lines.pop()
    urls = {k: brand[v] for k, v in brand["help_urls"].items()}
    lines += [
        "",
        "# Chaves da marca do produto, geradas de iman/brand/brand.json por iman/brand/build_brand.py",
        "[locale]",
        "overrideFlag=true",
        "userLocale=%s" % brand["default_locale"],
        "",
        "[core]",
        "%s=%s" % (NEWS_FEED_KEY, "false" if brand["qgis_news_feed"] else "true"),
        "",
        "[qgis]",
    ] + ["%s=%s" % (k, urls[k]) for k in sorted(urls)] + [
        "",
        "# SRC de camada sem SRC: lida sem a secao app (Projections/layerDefaultCrs em qgsproject.cpp e qgisapp.cpp)",
        "[Projections]",
        "layerDefaultCrs=%s" % brand["layer_default_crs"],
        "",
        "# plugin embarcado ligado por padrao (fatia 051; id da trava iman/plugin/plugin.lock.json): QgsSettings::value",
        "# cai aqui quando o perfil nao tem a chave; a escolha gravada pelo usuario no perfil vence",
        "[PythonPlugins]",
        "%s=true" % plugin_id,
        "",
    ]
    with io.open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))


def c_string(value):
    """Literal C com os bytes UTF-8 em octal fora do ASCII: independe do charset com que o MSVC le o fonte."""
    out = []
    for b in value.encode("utf-8"):
        if b in (0x22, 0x5C):
            out.append("\\" + chr(b))
        elif 0x20 <= b < 0x7F:
            out.append(chr(b))
        else:
            out.append("\\%03o" % b)
    return '"%s"' % "".join(out)


def splash_text_color(brand):
    """#RRGGBB, que o QColor(const char *) do Qt le; outro formato para o build em vez de virar uma cor invalida."""
    value = brand["splash_text_color"]
    if not re.match(r"^#[0-9A-Fa-f]{6}$", value):
        raise SystemExit("splash_text_color tem de ser #RRGGBB: %r" % value)
    return value.upper()


def color_macro(token):
    """Nome da macro do iman_brand.h para um token da paleta: brand-2 -> IMAN_COLOR_BRAND_2."""
    return "IMAN_COLOR_" + token.upper().replace("-", "_")


def tokens_used_by_cpp():
    """Tokens da paleta que o C++ do IMAN usa (IMAN_COLOR_* em src/app/iman), lidos do fonte: a lista nao e escrita a
    mao, para nao ficar para tras quando uma tela nova usar outro token."""
    used = set()
    root = os.path.join(REPO, "src", "app", "iman")
    for name in sorted(os.listdir(root)) if os.path.isdir(root) else []:
        if name.endswith((".cpp", ".h")):
            with io.open(os.path.join(root, name), "r", encoding="utf-8") as fh:
                used.update(re.findall(r"\bIMAN_COLOR_([A-Z0-9_]+)\b", fh.read()))
    return used


def brand_palette(brand):
    """Paleta D-IMAN-026 da marca, do brand.json (chave 'palette', token -> '#RRGGBB'; fatia 064). Antes da 064 ela
    era lida do cabecalho do style.qss de iman/brand/theme, que desde a 063 fica fora do build e desde a 064 nao e
    mais lido aqui. Falha alto se um valor nao for #RRGGBB ou se faltar token que o C++ usa (IMAN_COLOR_*): a pagina
    inicial e o Sobre (fatia 059) e o destaque da paleta do Qt (fatia 064) pintam so com estes tokens."""
    palette = brand.get("palette")
    if not isinstance(palette, dict) or not palette:
        raise SystemExit("brand.json sem a paleta (chave 'palette', token -> '#RRGGBB')")
    out = {}
    for token, value in palette.items():
        if not re.match(r"^[a-z][a-z0-9-]*$", token):
            raise SystemExit("token de paleta invalido no brand.json: %r" % token)
        if not isinstance(value, str) or not re.match(r"^#[0-9A-Fa-f]{6}$", value):
            raise SystemExit("cor do token %s no brand.json nao e #RRGGBB: %r" % (token, value))
        out[token] = value.upper()
    defined = {color_macro(t)[len("IMAN_COLOR_"):] for t in out}
    missing = sorted(tokens_used_by_cpp() - defined)
    if missing:
        raise SystemExit("paleta do brand.json sem tokens usados pelo C++ (src/app/iman): %s"
                         % ", ".join("IMAN_COLOR_" + m for m in missing))
    return out


def write_header(path, brand):
    defs = [
        ("IMAN_PRODUCT_NAME", brand["product_name"]),
        ("IMAN_PRODUCT_VERSION", brand["product_version"]),
        ("IMAN_ORGANIZATION_NAME", brand["organization_name"]),
        ("IMAN_ORGANIZATION_FULL_NAME", brand["organization_full_name"]),
        ("IMAN_PRODUCT_URL", brand["product_url"]),
        ("IMAN_ENGINE_LABEL", brand["engine_label"]),
        ("IMAN_DEFAULT_LOCALE", brand["default_locale"]),
        # nome interno (D-IMAN-043): perfil, cache, crashes, registro e AUMI; nao e texto de exibicao
        ("IMAN_INTERNAL_ORGANIZATION_NAME", brand["internal_organization_name"]),
        ("IMAN_INTERNAL_ORGANIZATION_DOMAIN", brand["internal_organization_domain"]),
        ("IMAN_INTERNAL_APPLICATION_NAME", brand["internal_application_name"]),
        # cor do texto de carregamento do splash (fatia 058, C1); o qgisapp.cpp a usa no lugar do Qt::black
        ("IMAN_SPLASH_TEXT_COLOR", splash_text_color(brand)),
    ]
    # paleta da marca (fatia 059; do brand.json desde a 064): IMAN_COLOR_BRAND_2, IMAN_COLOR_TEXT_MUTED, ...
    defs += [(color_macro(k), v) for k, v in sorted(brand_palette(brand).items())]
    text = "\n".join(
        ["// Gerado por iman/brand/build_brand.py a partir de iman/brand/brand.json. Nao editar.",
         "// Textos de marca e nome interno do produto para o C++ (UTF-8; use QString::fromUtf8).",
         "#ifndef IMAN_BRAND_H",
         "#define IMAN_BRAND_H"]
        + ["#define %s %s" % (k, c_string(v)) for k, v in defs]
        + ["#endif", ""])
    if os.path.exists(path):
        with io.open(path, "r", encoding="ascii", newline="") as fh:
            if fh.read() == text:
                return False
    with io.open(path, "w", encoding="ascii", newline="\n") as fh:
        fh.write(text)
    return True


def measure(ts_from_qm, curation):
    """Confere a curadoria contra o .qm do QGIS (convertido em .ts pelo lconvert): mesmas mensagens, mesmo texto."""
    root = ET.parse(ts_from_qm).getroot()
    found = []
    contexts = set()
    for c in root.findall("context"):
        name = c.findtext("name")
        for m in c.findall("message"):
            tr = m.find("translation")
            texts = [x.text or "" for x in tr.findall("numerusform")] if m.get("numerus") == "yes" else [tr.text or ""]
            if any("QGIS" in t for t in texts):
                found.append((name, m.findtext("source") or "", m.findtext("comment"), texts[0]))
                contexts.add(name)
    cur = {(e["context"], e["source"], e.get("comment")): e for e in curation["messages"]}
    errors = []
    for name, source, comment, text in found:
        e = cur.get((name, source, comment))
        if e is None:
            errors.append("fora da curadoria: [%s] %r" % (name, source[:80]))
        elif e["qgis"] != text:
            errors.append("traducao do QGIS mudou: [%s] %r" % (name, source[:80]))
    keys = {(n, s, c) for n, s, c, _ in found}
    for k in cur:
        if k not in keys:
            errors.append("na curadoria e nao no .qm: [%s] %r" % (k[0], k[1][:80]))
    by_class = {}
    for e in curation["messages"]:
        by_class[e["class"]] = by_class.get(e["class"], 0) + 1
    print("mensagens do .qm com QGIS na traducao: %d, em %d contextos" % (len(found), len(contexts)))
    print("curadoria: %d mensagens; por classe: %s" % (len(cur), ", ".join("%s %d" % kv for kv in sorted(by_class.items()))))
    for err in errors:
        print("  " + err)
    print("CURADORIA %s" % ("FALHOU" if errors else "OK"))
    return 1 if errors else 0


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--out")
    ap.add_argument("--header")
    ap.add_argument("--measure")
    args = ap.parse_args(argv)
    brand = load_json(BRAND)
    curation = load_json(CURATION)
    if args.measure:
        return measure(args.measure, curation)
    if not args.out or not args.header:
        ap.error("--out e --header sao obrigatorios")
    os.makedirs(args.out, exist_ok=True)
    ts = os.path.join(args.out, "iman_%s.ts" % brand["default_locale"])
    n = write_ts(ts, brand, curation)
    plugin_id = load_json(PLUGIN_LOCK)["id"]
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", plugin_id):
        raise SystemExit("id do plugin invalido na trava: %r" % plugin_id)
    write_global_settings(os.path.join(args.out, "qgis_global_settings.ini"), brand, plugin_id)
    changed = write_header(args.header, brand)
    print("marca: %s; %d mensagens em %s; cabecalho %s" % (
        brand["product_name"], n, ts, "regravado" if changed else "sem mudanca"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
