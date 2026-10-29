# -*- coding: utf-8 -*-
"""Deriva, dos assets aprovados em iman/brand/assets/, os arquivos de imagem que trocam o logo do QGIS no fonte.

    python3 iman/brand/derive_assets.py           # escreve iman/brand/derived/ e copia para a arvore do QGIS
    python3 iman/brand/derive_assets.py --check   # so confere; exit 1 se algo divergir

Rodar com o python3 da raiz OSGeo4W fixada (Pillow 12.3.0, do lock): e o mesmo ambiente do build.

DERIVACAO, NUNCA DESENHO (D-IMAN-041, regra 6). Cada derivado sai de um asset aprovado por uma destas operacoes:
  - copia: o arquivo aprovado como esta;
  - escala: o simbolo iman-symbol.png reamostrado com LANCZOS, sem margem, como o regenerate-icons.py da distro
    (../iman-qgis-distro-agent/app/assets/regenerate-icons.py, RESPIRO = 0);
  - recorte vetorial: o grupo do simbolo (folha + globo) recortado do splash-iman-terra.svg, sem redesenho, como o
    derive-theme-icons.py da distro (../iman-qgis-distro-agent/app/assets/derive-theme-icons.py, fatia distro #041),
    com o mesmo enquadramento medido.

Nao re-colore nada: a arte e arbitrada (README dos assets da distro, 2026-09-09).
"""
import io
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
ASSETS = os.path.join(HERE, "assets")
DERIVED = os.path.join(HERE, "derived")

# Enquadramento do simbolo no master, em unidades do master: o medido pela distro (derive-theme-icons.py):
# caixa da tinta x 2859,8..6269,6 e y 3740,0..7230,0, quadrado de lado 3560 centrado nela.
CENTER_X = (2859.82 + 6269.61) / 2
CENTER_Y = (3740.0 + 7230.0) / 2
SIDE = 3560.0
VIEWBOX = "%.2f %.2f %.0f %.0f" % (CENTER_X - SIDE / 2, CENTER_Y - SIDE / 2, SIDE, SIDE)
SYMBOL_MARKER_CLASS = "fil28"  # o degrade da folha: so o simbolo usa

# derivado em iman/brand/derived -> (operacao, asset de origem, parametro, arquivo do QGIS que ele substitui)
# Sem arquivo do QGIS (None): o derivado vai so para o instalador (iman/installer), nao para a arvore do QGIS.
TARGETS = [
    ("qgis.ico", "copia", "icon-iman-terra.ico", None, "src/app/qgis.ico"),
    ("splash.png", "copia", "splash-iman-terra.png", None, "images/splash/splash.png"),
    ("qgis-icon-16x16.png", "escala", "iman-symbol.png", 16, "images/icons/qgis-icon-16x16.png"),
    ("qgis-icon-60x60.png", "escala", "iman-symbol.png", 60, "images/icons/qgis-icon-60x60.png"),
    ("qgis_icon.svg", "recorte", "splash-iman-terra.svg", 256, "images/icons/qgis_icon.svg"),
    ("providerQgis.svg", "recorte", "splash-iman-terra.svg", 16, "images/themes/default/providerQgis.svg"),
    # icones de tipo de arquivo do "Abrir com" (fatia 047): o icone aprovado do produto, um arquivo por tipo
    ("iman-terra-qgs.ico", "copia", "icon-iman-terra.ico", None, None),
    ("iman-terra-qgz.ico", "copia", "icon-iman-terra.ico", None, None),
    ("iman-terra-qlr.ico", "copia", "icon-iman-terra.ico", None, None),
]


def _css_fills(svg):
    style = re.search(r"<style[^>]*>(.*?)</style>", svg, re.S)
    if not style:
        raise SystemExit("master sem <style>")
    fills = {}
    for name, body in re.findall(r"\.(fil\d+)\s*\{([^}]*)\}", style.group(1)):
        m = re.search(r"fill\s*:\s*([^;]+)", body)
        if m:
            fills[name] = m.group(1).strip()
    return fills


def _symbol_group(svg):
    body_start = svg.find("</defs>")
    marker = svg.find('class="%s"' % SYMBOL_MARKER_CLASS, body_start)
    if body_start < 0 or marker < 0:
        raise SystemExit("o simbolo nao esta no master")
    stack = []
    for m in re.finditer(r"<g\b[^>]*>|</g>", svg[body_start:]):
        pos = body_start + m.start()
        if m.group(0).startswith("</"):
            opened = stack.pop()
            if opened < marker < pos:
                return svg[opened:pos + len("</g>")]
        else:
            stack.append(pos)
    raise SystemExit("nao achei o grupo do simbolo")


def _gradient(svg, gradient_id):
    m = re.search(r'<linearGradient id="%s".*?</linearGradient>' % re.escape(gradient_id), svg, re.S)
    if not m:
        raise SystemExit("degrade %s nao encontrado" % gradient_id)
    text = re.sub(r'style="stop-opacity:1; stop-color:(#[0-9A-Fa-f]{6})"', r'stop-color="\1"', m.group(0))
    return re.sub(r"\s+", " ", text)


def symbol_svg(size):
    with io.open(os.path.join(ASSETS, "splash-iman-terra.svg"), "r", encoding="utf-8") as fh:
        svg = fh.read()
    fills = _css_fills(svg)
    paths = re.findall(r'<path class="(fil\d+)" d="([^"]+)"/>', _symbol_group(svg))
    visible = [(cls, d) for cls, d in paths if fills.get(cls, "none") != "none"]
    if not visible:
        raise SystemExit("o grupo do simbolo nao tem path visivel")
    defs = []
    for cls, _ in visible:
        m = re.match(r"url\(#([^)]+)\)", fills[cls])
        if m and m.group(1) not in [d[0] for d in defs]:
            defs.append((m.group(1), _gradient(svg, m.group(1))))
    out = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        "<!-- Simbolo do produto (folha + globo), recortado sem redesenho de iman/brand/assets/splash-iman-terra.svg",
        "     por iman/brand/derive_assets.py. Nao editar a mao: regerar. -->",
        '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%s">' % (size, size, VIEWBOX),
    ]
    if defs:
        out.append("<defs>%s</defs>" % "".join(d[1] for d in defs))
    for cls, d in visible:
        out.append('<path fill="%s" d="%s"/>' % (fills[cls], d))
    out.append("</svg>")
    return ("\n".join(out) + "\n").encode("utf-8")


def scaled_png(size):
    from PIL import Image
    sym = Image.open(os.path.join(ASSETS, "iman-symbol.png")).convert("RGBA")
    if sym.width != sym.height:
        raise SystemExit("iman-symbol.png deixou de ser quadrado")
    buf = io.BytesIO()
    sym.resize((size, size), Image.LANCZOS).save(buf, format="PNG")
    return buf.getvalue()


def derive(op, source, param):
    if op == "copia":
        with open(os.path.join(ASSETS, source), "rb") as fh:
            return fh.read()
    if op == "escala":
        return scaled_png(param)
    if op == "recorte":
        return symbol_svg(param)
    raise SystemExit("operacao desconhecida: %s" % op)


def read(path):
    try:
        with open(path, "rb") as fh:
            return fh.read()
    except OSError:
        return None


def main(argv):
    check = "--check" in argv
    os.makedirs(DERIVED, exist_ok=True)
    diverged = []
    for name, op, source, param, qgis_path in TARGETS:
        data = derive(op, source, param)
        derived = os.path.join(DERIVED, name)
        tree = os.path.join(REPO, *qgis_path.split("/")) if qgis_path else None
        if check:
            if read(derived) != data:
                diverged.append("%s nao e a derivacao de %s" % (name, source))
            if tree and read(tree) != data:
                diverged.append("%s na arvore do QGIS difere de derived/%s" % (qgis_path, name))
            continue
        with open(derived, "wb") as fh:
            fh.write(data)
        if tree:
            shutil.copyfile(derived, tree)
        print("%-22s %-8s de %-22s -> %s" % (name, op, source, qgis_path or "instalador"))
    if check:
        for d in diverged:
            print("DIVERGE: " + d)
        print("ASSETS %s (%d derivados)" % ("FALHOU" if diverged else "OK", len(TARGETS)))
        return 1 if diverged else 0
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
