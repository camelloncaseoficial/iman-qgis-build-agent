# -*- coding: utf-8 -*-
"""Gera o splash raster (assets/splash-iman-terra.png) do master vetorial aprovado (assets/splash-iman-terra.svg).

    python3 iman/brand/render_splash.py                     # escreve assets/splash-iman-terra.png
    python3 iman/brand/render_splash.py --out x.png         # escreve em outro lugar (laudo)
    python3 iman/brand/render_splash.py --without-text --out x.png   # o mesmo master sem os <text> (laudo, A2)
    python3 iman/brand/render_splash.py --fonts-dir <pasta> --out x.png   # outras fontes no lugar das do repo (laudo)
    python3 iman/brand/render_splash.py --no-fonts --out x.png       # sem as fontes do repo (visto falhando, laudo)

Rodado a mao, como o derive_assets.py, fora do build e do gate (briefing qgis-build #069). Depois dele, rodar o
derive_assets.py, que copia o PNG para derived/ e para a arvore do QGIS.

RASTERIZACAO, NUNCA DESENHO (D-IMAN-041, regra 6; emenda de 2026-11-14 ao adendo do D-IMAN-040): o SVG e lido como
esta e posto em linha numa pagina XHTML; nada da arte muda (cor, posicao, texto, recorte).

- Renderizador: o Edge (ou o Chrome) da bancada, sem cabeca, com um perfil temporario proprio e so a pagina local; sem
  rede. Nunca o QtSvg: ele apaga glifos (README da marca).
- Letras: o master pede as familias "Open Sans" (normal e bold) e "Open Sans Semibold" (600). As tres sao declaradas
  por @font-face com os TTF de iman/brand/fonts/ (Open Sans 3.003, fatia 067) embutidos em data:, nunca a fonte
  instalada na maquina. As declaracoes vem depois do SVG: as @font-face do proprio master apontam para as fontes SVG
  embutidas pelo Corel (format(svg)), que o navegador nao le, e as ultimas declaradas valem.
- Antes da captura, uma rodada --dump-dom confere que as tres faces da pagina carregaram (document.fonts).
- A pagina e desenhada em SCALE vezes 1000x480 e reduzida para 1000x480 com LANCZOS (Pillow).
- Fundo: o master nao tem fundo opaco (o degrade do fundo tem stop-opacity 0,847 e nada embaixo). O PNG de hoje e todo
  opaco e era o export raster do Corel sobre a pagina branca: medido na fatia 069, o PNG de antes e o SVG de antes
  renderizado aqui e composto sobre branco diferem 1 por canal na mediana (sobre preto, 16). A captura sai
  transparente e e composta sobre PAGE (branco) antes da reducao; o script falha se sobrar alfa abaixo de 255.
"""
import argparse
import base64
import glob
import hashlib
import html
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "assets")
FONTS = os.path.join(HERE, "fonts")
MASTER = os.path.join(ASSETS, "splash-iman-terra.svg")
OUTPUT = os.path.join(ASSETS, "splash-iman-terra.png")

WIDTH, HEIGHT = 1000, 480
SCALE = 4
PAGE = (255, 255, 255, 255)  # a pagina do export do Corel (medido na fatia 069)
# familia e peso pedidos pelo master (classes .fnt*) -> TTF de iman/brand/fonts/
FACES = [
    ("Open Sans", "normal", "OpenSans-Regular.ttf"),
    ("Open Sans", "bold", "OpenSans-Bold.ttf"),
    ("Open Sans Semibold", "600", "OpenSans-SemiBold.ttf"),
]
BROWSERS = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
]
TIMEOUT_S = 120


def sha256(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()


def find_browser(explicit):
    for path in [explicit] if explicit else BROWSERS:
        if path and os.path.isfile(path):
            return path
    raise SystemExit("nenhum Edge ou Chrome na bancada (passe --browser)")


def browser_version(exe):
    # o Edge e o Chrome guardam os binarios numa pasta com o numero da versao, ao lado do executavel
    versions = [os.path.basename(p) for p in glob.glob(os.path.join(os.path.dirname(exe), "*"))
                if re.fullmatch(r"\d+\.\d+\.\d+\.\d+", os.path.basename(p))]
    return max(versions, key=lambda v: [int(x) for x in v.split(".")]) if versions else "desconhecida"


def svg_body(master, without_text):
    with io.open(master, "r", encoding="utf-8") as fh:
        svg = fh.read()
    start = svg.find("<svg")
    if start < 0:
        raise SystemExit("master sem <svg>")
    svg = svg[start:]  # sem o prologo XML nem o DOCTYPE (a DTD externa nao e lida)
    if without_text:
        svg, count = re.subn(r"<text\b[^>]*>.*?</text>", "", svg, flags=re.S)
        if not count:
            raise SystemExit("master sem <text>")
    return svg


def font_faces(fonts_dir):
    rules, used = [], []
    for family, weight, filename in FACES:
        path = os.path.join(fonts_dir, filename)
        if not os.path.isfile(path):
            raise SystemExit("fonte ausente: %s" % path)
        with open(path, "rb") as fh:
            data = base64.b64encode(fh.read()).decode("ascii")
        rules.append('@font-face { font-family: "%s"; font-style: normal; font-weight: %s; '
                     'src: url(data:font/ttf;base64,%s) format("truetype"); }' % (family, weight, data))
        used.append((family, weight, path))
    return "\n".join(rules), used


PROBE = """
<script><![CDATA[
(async function () {
  var wanted = %s;
  await Promise.all(wanted.map(function (w) { return document.fonts.load(w[1] + ' 100px "' + w[0] + '"'); }));
  await document.fonts.ready;
  var faces = [];
  document.fonts.forEach(function (f) { faces.push(f.family.replace(/"/g, '') + '|' + f.weight + '|' + f.status); });
  document.getElementById('probe').textContent = 'FACES ' + faces.join(';');
})();
]]></script>
"""


def page(svg, faces_css, probe, faces):
    css = "html, body { margin: 0; padding: 0; overflow: hidden; background: transparent; }\n" \
          "body > svg { display: block; width: 100vw; height: 100vh; }\n" + faces_css
    parts = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<html xmlns="http://www.w3.org/1999/xhtml"><head><meta charset="utf-8"/><title>splash</title></head><body>',
        svg,
        "<style>%s</style>" % css,
    ]
    if probe:
        wanted = "[%s]" % ",".join('["%s","%s"]' % (f, w) for f, w, _ in faces)
        parts.append('<pre id="probe"></pre>' + PROBE % wanted)
    parts.append("</body></html>")
    return "\n".join(parts)


def run_browser(exe, profile, args):
    cmd = [exe, "--headless", "--disable-gpu", "--no-first-run", "--no-default-browser-check",
           "--disable-extensions", "--disable-sync", "--disable-background-networking",
           "--disable-component-update", "--disable-features=msEdgeSidebarV2,Translate",
           "--hide-scrollbars", "--force-device-scale-factor=1", "--user-data-dir=" + profile] + args
    # o processo e so nosso (perfil proprio); em estouro de tempo, o subprocess encerra o PID que ele abriu
    return subprocess.run(cmd, capture_output=True, timeout=TIMEOUT_S)


def render(exe, svg, faces_css, faces, out_png):
    from PIL import Image
    work = tempfile.mkdtemp(prefix="iman-splash-")
    try:
        profile = os.path.join(work, "profile")
        if faces:
            probe_page = os.path.join(work, "probe.xhtml")
            with io.open(probe_page, "w", encoding="utf-8") as fh:
                fh.write(page(svg, faces_css, True, faces))
            dom = run_browser(exe, profile, ["--virtual-time-budget=10000", "--dump-dom",
                                             "file:///" + probe_page.replace("\\", "/")])
            text = html.unescape(dom.stdout.decode("utf-8", "replace"))
            m = re.search(r"FACES ([^<]*)", text)
            if not m:
                raise SystemExit("a pagina nao informou as fontes:\n" + dom.stderr.decode("utf-8", "replace")[-2000:])
            loaded = set()
            for item in m.group(1).split(";"):
                family, weight, status = item.split("|")
                if status == "loaded":
                    loaded.add((family, {"400": "normal", "700": "bold"}.get(weight, weight)))
            missing = [(f, w) for f, w, _ in faces if (f, w) not in loaded]
            print("faces na pagina: " + m.group(1))
            if missing:
                raise SystemExit("faces do repo nao carregaram: %s" % missing)
        shot_page = os.path.join(work, "splash.xhtml")
        with io.open(shot_page, "w", encoding="utf-8") as fh:
            fh.write(page(svg, faces_css, False, faces))
        shot = os.path.join(work, "shot.png")
        run_browser(exe, profile, ["--virtual-time-budget=10000", "--default-background-color=00000000",
                                   "--window-size=%d,%d" % (WIDTH * SCALE, HEIGHT * SCALE),
                                   "--screenshot=" + shot, "file:///" + shot_page.replace("\\", "/")])
        if not os.path.isfile(shot):
            raise SystemExit("o navegador nao gravou a captura")
        big = Image.open(shot).convert("RGBA")
        if big.size != (WIDTH * SCALE, HEIGHT * SCALE):
            raise SystemExit("captura com tamanho %s, esperado %s" % (big.size, (WIDTH * SCALE, HEIGHT * SCALE)))
        print("alfa da arte: %d a %d (antes da pagina)" % big.getchannel("A").getextrema())
        small = Image.alpha_composite(Image.new("RGBA", big.size, PAGE), big).resize((WIDTH, HEIGHT), Image.LANCZOS)
        alpha = small.getchannel("A").getextrema()
        if alpha != (255, 255):
            raise SystemExit("o PNG de hoje e todo opaco; este saiu com alfa %s" % (alpha,))
        small.save(out_png, format="PNG")
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", default=OUTPUT)
    ap.add_argument("--master", default=MASTER)
    ap.add_argument("--browser")
    ap.add_argument("--without-text", action="store_true")
    ap.add_argument("--fonts-dir", default=FONTS)
    ap.add_argument("--no-fonts", action="store_true")
    a = ap.parse_args(argv)
    exe = find_browser(a.browser)
    faces_css, faces = ("", []) if a.no_fonts else font_faces(a.fonts_dir)
    print("master:      %s  sha256 %s" % (os.path.basename(a.master), sha256(a.master)))
    print("renderizador: %s  versao %s" % (os.path.basename(exe), browser_version(exe)))
    for family, weight, path in faces:
        print("fonte:       %-19s %-6s %s  sha256 %s" % (family, weight, os.path.basename(path), sha256(path)))
    if a.no_fonts:
        print("fonte:       nenhuma do repo (--no-fonts)")
    print("escala:      %dx, %dx%d sobre a pagina branca, reduzido com LANCZOS para %dx%d%s" % (
        SCALE, WIDTH * SCALE, HEIGHT * SCALE, WIDTH, HEIGHT, ", sem os <text>" if a.without_text else ""))
    render(exe, svg_body(a.master, a.without_text), faces_css, faces, a.out)
    print("saida:       %s  sha256 %s" % (a.out, sha256(a.out)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
