# -*- coding: utf-8 -*-
"""Mede o splash gerado do SVG e os icones recortados do master (laudo da fatia 069, criterios A2 e A3).

    python3 iman/brand/measure_splash.py --out <pasta> [--before <commit>]

Rodar com o python3 da raiz OSGeo4W fixada (o4w_env): Pillow e PyQt5 (QtSvg do Qt do produto). Rodado a mao, fora do
build e do gate. Escreve na pasta as imagens e o facts.json; exit 1 se algum criterio cair.

A2, o PNG: renderiza o master com render_splash.py (com as fontes do repo, e sem os <text>) e mede, em cada uma das
seis regioes de texto (tiradas das posicoes do proprio SVG), os pixels que o texto muda; fora delas, o texto nao pode
mudar nada. Visto falhando: o mesmo master pelo QtSvg sozinho, sem as fontes do repo (--no-fonts) e com as fontes
instaladas no Windows (--fonts-dir), cada um contra a renderizacao de referencia, regiao por regiao, e o mosaico das
regioes ampliadas para olhar a letra.

A3, os icones: qgis_icon.svg e providerQgis.svg de antes (--before) e de agora, rasterizados pelo QtSvg (quem os le no
produto) em 16, 32 e 256 px, comparados pixel a pixel. Visto falhando: o recorte do master novo com o enquadramento de
antes (sem o FRAME_SHIFT), contra o de antes.
"""
import argparse
import io
import json
import os
import shutil
import subprocess
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import derive_assets  # noqa: E402
import render_splash  # noqa: E402

UNITS_PER_PX = 26458.32 / render_splash.WIDTH
# as seis linhas de texto de apoio: id do <text> no master -> nome no laudo
TEXT_LINES = [
    ("text-002", "ceara"),
    ("text-001", "versao-institucional"),
    ("text-004", "regularizacao"),
    ("text-005", "powered-by"),
    ("text-006", "qgis"),
    ("Vers\u00e3o", "versao-v0-4-0"),
]
INK = 16           # diferenca por canal a partir da qual o pixel conta como mudado
ICON_SIZES = (16, 32, 256)
ICONS = ("qgis_icon.svg", "providerQgis.svg")
# o o4w_env troca o PATH e tira o git dele: o git do sistema, por --git, pelo PATH ou no lugar padrao do Git for Windows
GIT_DEFAULT = r"C:\Program Files\Git\cmd\git.exe"


def pixels(img):
    return img.get_flattened_data() if hasattr(img, "get_flattened_data") else img.getdata()


def text_regions():
    import re
    with io.open(render_splash.MASTER, "r", encoding="utf-8") as fh:
        svg = fh.read()
    sizes = {}
    for name, body in re.findall(r"\.(fnt\d+)\s*\{([^}]*)\}", svg):
        sizes[name] = float(re.search(r"font-size:([\d.]+)px", body).group(1))
    regions = {}
    for g in re.finditer(r'<g transform="matrix\(1 0 0 1 ([-\d.]+) ([-\d.]+)\)">(.*?)</g>', svg, re.S):
        tx, ty = float(g.group(1)), float(g.group(2))
        for x, y, tid, cls, txt in re.findall(
                r'<text x="([\d.]+)" y="([\d.]+)" id="([^"]+)" class="([^"]+)">([^<]*)</text>', g.group(3)):
            fs = sizes[cls.split()[1]]
            box = (float(x) + tx, float(y) + ty - 0.85 * fs, float(x) + tx + 0.75 * fs * max(1, len(txt)),
                   float(y) + ty + 0.3 * fs)
            old = regions.get(tid)
            regions[tid] = box if not old else (min(old[0], box[0]), min(old[1], box[1]), max(old[2], box[2]),
                                                max(old[3], box[3]))
    out = {}
    for tid, name in TEXT_LINES:
        if tid not in regions:
            raise SystemExit("linha de texto %s nao esta no master" % tid)
        x0, y0, x1, y1 = regions[tid]
        out[name] = (int(x0 / UNITS_PER_PX) - 2, int(y0 / UNITS_PER_PX) - 2, int(x1 / UNITS_PER_PX) + 3,
                     int(y1 / UNITS_PER_PX) + 3)
    return out


def changed(a, b, box=None):
    from PIL import ImageChops
    d = ImageChops.difference(a.convert("RGB"), b.convert("RGB"))
    if box:
        d = d.crop(box)
    px = list(pixels(d))
    return sum(1 for p in px if max(p) > INK), max((max(p) for p in px), default=0)


def qt_app():
    from PyQt5.QtGui import QGuiApplication
    return QGuiApplication.instance() or QGuiApplication(["measure_splash"])


def qtsvg_render(svg_bytes, width, height, path):
    from PyQt5.QtCore import QByteArray, QRectF, Qt
    from PyQt5.QtGui import QImage, QPainter
    from PyQt5.QtSvg import QSvgRenderer
    qt_app()
    renderer = QSvgRenderer(QByteArray(svg_bytes))
    if not renderer.isValid():
        raise SystemExit("o QtSvg nao leu o SVG")
    img = QImage(width, height, QImage.Format_ARGB32)
    img.fill(Qt.transparent)
    p = QPainter(img)
    p.setRenderHint(QPainter.Antialiasing)
    p.setRenderHint(QPainter.SmoothPixmapTransform)
    renderer.render(p, QRectF(0, 0, width, height))
    p.end()
    img.save(path)
    return path


def splash_by_qtsvg(path):
    from PIL import Image
    w, h = render_splash.WIDTH * render_splash.SCALE, render_splash.HEIGHT * render_splash.SCALE
    with open(render_splash.MASTER, "rb") as fh:
        qtsvg_render(fh.read(), w, h, path)
    big = Image.open(path).convert("RGBA")
    small = Image.alpha_composite(Image.new("RGBA", big.size, render_splash.PAGE), big)
    small.resize((render_splash.WIDTH, render_splash.HEIGHT), Image.LANCZOS).save(path)


def run_render(out, *extra):
    cmd = [sys.executable, os.path.join(HERE, "render_splash.py"), "--out", out] + list(extra)
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode:
        raise SystemExit("render_splash falhou: %s %s" % (res.stdout, res.stderr))
    return res.stdout


def mosaic(images, regions, path, zoom=3):
    from PIL import Image, ImageDraw
    pad, label_w = 6, 150
    rows = []
    for name, box in regions.items():
        crops = [(label, im.crop(box)) for label, im in images]
        w = max(c.width for _, c in crops) * zoom
        rows.append((name, crops, w, box[3] - box[1]))
    width = label_w + max(r[2] for r in rows) + pad
    height = sum((r[3] * zoom + pad) * len(images) + 14 for r in rows)
    canvas = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(canvas)
    y = 0
    for name, crops, _, h in rows:
        draw.text((2, y), name, fill="black")
        y += 14
        for label, crop in crops:
            draw.text((2, y + 2), label, fill="black")
            canvas.paste(crop.convert("RGB").resize((crop.width * zoom, crop.height * zoom), Image.NEAREST),
                         (label_w, y))
            y += h * zoom + pad
    canvas.save(path)


def measure_a2(out, facts):
    from PIL import Image
    regions = text_regions()
    files = {
        "referencia": os.path.join(out, "a2-splash-fontes-do-repo.png"),
        "sem-texto": os.path.join(out, "a2-splash-sem-texto.png"),
        "sem-fontes-do-repo": os.path.join(out, "a2-falhando-sem-fontes-do-repo.png"),
        "fontes-instaladas": os.path.join(out, "a2-fontes-instaladas-no-windows.png"),
        "qtsvg": os.path.join(out, "a2-falhando-qtsvg.png"),
    }
    log = run_render(files["referencia"])
    run_render(files["sem-texto"], "--without-text")
    run_render(files["sem-fontes-do-repo"], "--no-fonts")
    run_render(files["fontes-instaladas"], "--fonts-dir", r"C:\Windows\Fonts")
    splash_by_qtsvg(files["qtsvg"])
    im = {k: Image.open(v).convert("RGBA") for k, v in files.items()}
    asset = Image.open(render_splash.OUTPUT).convert("RGBA")
    ref = im["referencia"]
    a2 = {"render_log": log.splitlines(), "regions_px": regions, "ink_threshold": INK,
          "asset_equals_reference": changed(asset, ref)[0] == 0 and asset.size == ref.size,
          "asset": {"size": list(asset.size), "mode": Image.open(render_splash.OUTPUT).mode,
                    "alpha": list(asset.getchannel("A").getextrema())},
          "lines": {}}
    for name, box in regions.items():
        row = {"text_changes_px": changed(ref, im["sem-texto"], box)[0]}
        for k in ("sem-fontes-do-repo", "fontes-instaladas", "qtsvg"):
            n, mx = changed(ref, im[k], box)
            row["%s_vs_referencia_px" % k] = n
            row["%s_vs_referencia_max" % k] = mx
            row["%s_vs_sem_texto_px" % k] = changed(im[k], im["sem-texto"], box)[0]
        a2["lines"][name] = row
    # fora das seis regioes, tirar o texto nao muda nada
    from PIL import ImageChops, ImageDraw
    mask = Image.new("L", ref.size, 255)
    draw = ImageDraw.Draw(mask)
    for box in regions.values():
        draw.rectangle(box, fill=0)
    d = ImageChops.difference(ref.convert("RGB"), im["sem-texto"].convert("RGB"))
    outside = sum(1 for p, m in zip(pixels(d), pixels(mask)) if m and max(p) > INK)
    a2["text_changes_outside_regions_px"] = outside
    a2["ok"] = (a2["asset_equals_reference"] and a2["asset"]["size"] == [1000, 480] and a2["asset"]["mode"] == "RGBA"
                and a2["asset"]["alpha"] == [255, 255] and outside == 0
                and all(r["text_changes_px"] > 0 for r in a2["lines"].values()))
    a2["seen_failing"] = {
        k: any(r["%s_vs_referencia_px" % k] > 0 for r in a2["lines"].values())
        for k in ("sem-fontes-do-repo", "qtsvg")}
    mosaic([(k, im[k]) for k in ("referencia", "sem-texto", "sem-fontes-do-repo", "fontes-instaladas", "qtsvg")],
           regions, os.path.join(out, "a2-regioes-ampliadas.png"))
    facts["A2"] = a2
    return a2["ok"] and all(a2["seen_failing"].values())


def symbol_without_shift(size):
    saved = derive_assets.VIEWBOX
    try:
        cx, cy = derive_assets.CENTER_X - derive_assets.FRAME_SHIFT, derive_assets.CENTER_Y - derive_assets.FRAME_SHIFT
        derive_assets.VIEWBOX = "%.2f %.2f %.0f %.0f" % (cx - derive_assets.SIDE / 2, cy - derive_assets.SIDE / 2,
                                                         derive_assets.SIDE, derive_assets.SIDE)
        return derive_assets.symbol_svg(size)
    finally:
        derive_assets.VIEWBOX = saved


def alpha_centroid(img):
    a = img.getchannel("A")
    total = sx = sy = 0
    w = a.width
    for i, v in enumerate(pixels(a)):
        if v:
            total += v
            sx += v * (i % w)
            sy += v * (i // w)
    return (round(sx / total, 3), round(sy / total, 3)) if total else None


def measure_a3(out, before, git, facts):
    from PIL import Image
    a3 = {"before": before, "renderer": "QtSvg (PyQt5, Qt do produto)", "icons": {}}
    ok = True
    failing_seen = True
    for icon, size_nominal in zip(ICONS, (256, 16)):
        old = subprocess.run([git, "-C", REPO, "show", "%s:iman/brand/derived/%s" % (before, icon)],
                             capture_output=True, check=True).stdout
        with open(os.path.join(derive_assets.DERIVED, icon), "rb") as fh:
            new = fh.read()
        noshift = symbol_without_shift(size_nominal)
        stem = icon.rsplit(".", 1)[0]
        for name, data in (("antes", old), ("depois", new), ("falhando-sem-ajuste", noshift)):
            with open(os.path.join(out, "a3-%s-%s.svg" % (stem, name)), "wb") as fh:
                fh.write(data)
        rows = {}
        for size in ICON_SIZES:
            imgs = {}
            for name, data in (("antes", old), ("depois", new), ("falhando-sem-ajuste", noshift)):
                path = os.path.join(out, "a3-%s-%d-%s.png" % (stem, size, name))
                qtsvg_render(data, size, size, path)
                imgs[name] = Image.open(path).convert("RGBA")

            def diff(a, b):
                from PIL import ImageChops
                d = ImageChops.difference(a, b)
                px = list(pixels(d))
                return sum(1 for p in px if max(p)), max((max(p) for p in px), default=0)
            n, mx = diff(imgs["antes"], imgs["depois"])
            fn, fmx = diff(imgs["antes"], imgs["falhando-sem-ajuste"])
            rows[str(size)] = {"pixels_diferentes": n, "max_por_canal": mx,
                               "falhando_pixels_diferentes": fn, "falhando_max_por_canal": fmx,
                               "centroide_alfa_antes": alpha_centroid(imgs["antes"]),
                               "centroide_alfa_depois": alpha_centroid(imgs["depois"]),
                               "centroide_alfa_falhando": alpha_centroid(imgs["falhando-sem-ajuste"])}
            ok = ok and n == 0
            if size == 256:
                failing_seen = failing_seen and fn > 0
        a3["icons"][icon] = rows
    a3["ok"] = ok
    a3["seen_failing_256"] = failing_seen
    facts["A3"] = a3
    return ok and failing_seen


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", required=True)
    ap.add_argument("--before", default="7fbb9a7b71")
    ap.add_argument("--git", default=shutil.which("git") or GIT_DEFAULT)
    a = ap.parse_args(argv)
    os.makedirs(a.out, exist_ok=True)
    facts = {}
    ok2 = measure_a2(a.out, facts)
    ok3 = measure_a3(a.out, a.before, a.git, facts)
    with io.open(os.path.join(a.out, "facts.json"), "w", encoding="utf-8") as fh:
        json.dump(facts, fh, ensure_ascii=False, indent=2)
    for name, row in facts["A2"]["lines"].items():
        print("A2 %-22s texto muda %5d px | sem fontes do repo %5d | instaladas %5d | QtSvg %5d" % (
            name, row["text_changes_px"], row["sem-fontes-do-repo_vs_referencia_px"],
            row["fontes-instaladas_vs_referencia_px"], row["qtsvg_vs_referencia_px"]))
    print("A2 fora das regioes: %d px; asset = referencia: %s" % (
        facts["A2"]["text_changes_outside_regions_px"], facts["A2"]["asset_equals_reference"]))
    for icon, rows in facts["A3"]["icons"].items():
        for size, r in rows.items():
            print("A3 %-17s %3s px: %d px diferentes (max %d) | sem o ajuste: %d px (max %d)" % (
                icon, size, r["pixels_diferentes"], r["max_por_canal"], r["falhando_pixels_diferentes"],
                r["falhando_max_por_canal"]))
    print("A2 %s, visto falhando %s; A3 %s, visto falhando %s" % (
        "OK" if facts["A2"]["ok"] else "FALHOU", facts["A2"]["seen_failing"],
        "OK" if facts["A3"]["ok"] else "FALHOU", facts["A3"]["seen_failing_256"]))
    return 0 if ok2 and ok3 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
