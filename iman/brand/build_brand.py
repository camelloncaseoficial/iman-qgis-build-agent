# -*- coding: utf-8 -*-
"""Gera, a partir da fonte unica de marca (BL-4), o que o build do QGIS precisa dela.

    python3 iman/brand/build_brand.py --out <pasta> --header <arquivo.h>
    python3 iman/brand/build_brand.py --measure <qgis_pt_BR.ts>   # confere a curadoria contra o .qm do QGIS

Entradas (versionadas): iman/brand/brand.json, iman/brand/i18n/curadoria_pt_BR.json e o
resources/qgis_global_settings.ini do proprio QGIS.

Saidas (fora do repo, em --out):
  - iman_<locale>.ts: a traducao sobreposta (D-IMAN-041, regra 2), so com as mensagens das classes aplicativo e
    versao da curadoria e as superficies do Bloco D ('extra'); o Build-Qgis.ps1 compila com o lrelease fixado;
  - qgis_global_settings.ini: o do QGIS com a checagem de versao desligada, mais o idioma padrao, o feed de
    noticias desligado e os enderecos do menu Ajuda;
  - --header: iman_brand.h, os textos de marca para o C++ (Bloco D). So e regravado se o conteudo mudou, para nao
    recompilar a toa.

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


def write_global_settings(path, brand):
    with io.open(QGIS_GLOBAL_SETTINGS, "r", encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    version_check = "true" if brand["qgis_version_check"] else "false"
    replaced = set()
    group = None
    for i, line in enumerate(lines):
        m = re.match(r"^\[(.+)\]$", line)
        if m:
            group = m.group(1)
            continue
        if group == "qgis":
            for key in ("checkVersion", "allowVersionCheck"):
                if line.startswith(key + "="):
                    lines[i] = "%s=%s" % (key, version_check)
                    replaced.add(key)
    if replaced != {"checkVersion", "allowVersionCheck"}:
        raise SystemExit("qgis_global_settings.ini do QGIS mudou: chaves de versao achadas %s" % sorted(replaced))
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
    ] + ["%s=%s" % (k, urls[k]) for k in sorted(urls)] + [""]
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


def write_header(path, brand):
    defs = [
        ("IMAN_PRODUCT_NAME", brand["product_name"]),
        ("IMAN_ORGANIZATION_NAME", brand["organization_name"]),
        ("IMAN_PRODUCT_URL", brand["product_url"]),
        ("IMAN_ENGINE_LABEL", brand["engine_label"]),
        ("IMAN_DEFAULT_LOCALE", brand["default_locale"]),
    ]
    text = "\n".join(
        ["// Gerado por iman/brand/build_brand.py a partir de iman/brand/brand.json. Nao editar.",
         "// Textos de marca do produto para o C++ (UTF-8; use QString::fromUtf8).",
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
    write_global_settings(os.path.join(args.out, "qgis_global_settings.ini"), brand)
    changed = write_header(args.header, brand)
    print("marca: %s; %d mensagens em %s; cabecalho %s" % (
        brand["product_name"], n, ts, "regravado" if changed else "sem mudanca"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
