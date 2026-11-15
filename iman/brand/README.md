# Fonte unica de marca (BL-4)

Tudo o que e texto ou imagem de marca do produto nasce aqui. O build le daqui; nenhum arquivo do QGIS tem o nome do
produto escrito a mao. Mudar o nome e mudar `brand.json` e recompilar (A2 do briefing `qgis-build #044`).

| Arquivo | O que e | Quem le |
|---|---|---|
| `brand.json` | nome e versao do produto (`product_version`, desde a 047), organizacao, endereco, rotulo do motor ("motor QGIS"), idioma padrao, feed e checagem de versao; e o nome interno (`internal_organization_name`, `internal_organization_domain`, `internal_application_name`, D-IMAN-043), que da a pasta do perfil, do cache e dos crashes, a chave de registro e o AUMI, separado do nome de exibicao; desde a 049, os SRC padrao de projeto novo e de camada sem SRC (`default_project_crs`, `new_project_crs_behavior`, `layer_default_crs`); desde a 058, a cor do texto de carregamento do splash (`splash_text_color`, `#RRGGBB`, que vai ao `iman_brand.h` como `IMAN_SPLASH_TEXT_COLOR`); desde a 066, o raio das quinas do `QPushButton` em pixels logicos (`button_radius_px`, inteiro de 1 a 16, hoje 4, o dobro do raio 2 do Fusion medido no laudo 066), que vai ao `iman_brand.h` como numero (`IMAN_BUTTON_RADIUS_PX`) e e desenhado por `src/app/iman/imanappstyle.cpp`. Da 049 a 058 tinha tambem o tema de interface padrao (`ui_theme`), que saiu na 063 (emenda de 2026-11-12 ao D-IMAN-040): o produto usa o tema default do QGIS, e o `qgis_global_settings.ini` gerado nao escolhe tema, como o do QGIS oficial; desde a 064, a paleta da marca D-IMAN-026 (`palette`, os 18 tokens, `token` -> `#RRGGBB`), que o `build_brand.py` valida e escreve como `IMAN_COLOR_*` no `iman_brand.h`: usada pela pagina inicial e pelo Sobre (059; a pagina inicial pinta o `bg` pela folha propria dela) e pela paleta do Qt (`src/app/iman/imanpalette.cpp`): o destaque (064, `brand-2` e `panel`), o fundo das janelas (065, papel `Window` = `bg`) e os botoes e abas (066, papel `Button` = `panel-2`); desde a 067, a familia da fonte da interface (`font_family`, hoje `Open Sans`, o nome que os TTF de `fonts/` declaram), que vai ao `iman_brand.h` como `IMAN_FONT_FAMILY` e e aplicada por `src/app/iman/imanfont.cpp` | `build_brand.py`, o smoke (`iman/build/Invoke-Smoke.ps1`), o instalador (`iman/installer/Build-Installer.ps1`) e o `Test-ThemeDefaults.ps1` |
| `i18n/curadoria_pt_BR.json` | as 275 mensagens do `qgis_pt_BR.qm` com "QGIS" na traducao, cada uma numa classe (aplicativo, versao, projeto, duvida), e o texto final das que mudam, com marcadores (`{product}`, `{engine}`, `{org}`, `{url}`); mais as superficies do Bloco D (`extra`) | `build_brand.py` |
| `build_brand.py` | gera no build `iman_brand.h`, `iman_pt_BR.ts` e `qgis_global_settings.ini`; com `--measure` confere a curadoria contra o `.qm` do QGIS | `iman/build/Build-Qgis.ps1` |
| `theme/IMAN Terra/style.qss` | o tema da distro (fatia 049): copia do QSS aprovado na distro congelada (`df761da`), sem as regras da camada de marca. Desde a 058, campos sem padding, aba selecionada sem negrito, botao fora das barras com borda, borda dos campos border-strong e barras com os espacos do QGIS oficial (B1 a B5, cabecalho do arquivo). **Fora do build desde a 063** (emenda de 2026-11-12 ao D-IMAN-040): fica aqui como referencia, com a paleta do cabecalho (a fonte da paleta, desde a 064, e o `brand.json`); regra de aparencia nova volta uma por vez, por briefing, pela paleta do Qt no C++ e nunca por QSS (emenda de 2026-11-13) | ninguem no build (desde a 064 nem a paleta e lida daqui): o `iman/build/Build-Qgis.ps1` remove a pasta que um build anterior deixou em `resources\themes`; `iman/build/Test-ThemeQss.ps1` segue guardando raio, D1, D2, D4, zero hex orfao e B1 a B5 sobre o arquivo do repositorio |
| `fonts/` | desde a 067, a fonte da interface: os seis TTF estaticos da Open Sans 3.003 e o `OFL.txt` dela (origem abaixo); a familia que o C++ aplica e a `font_family` do `brand.json` (`IMAN_FONT_FAMILY` no `iman_brand.h`) | `src/app/iman/imanfonts.qrc` (compilado no `qgis_app`) e `src/app/iman/imanfont.cpp`, que os registra so para o processo, com o tema default |
| `assets/` | assets aprovados, copiados da distro congelada (abaixo) | `derive_assets.py` |
| `derived/` | o que substitui o logo do QGIS no fonte, derivado dos assets | `derive_assets.py` copia para a arvore do QGIS; o smoke compara com o recurso compilado |
| `derive_assets.py` | deriva `derived/` e copia para a arvore do QGIS; `--check` so confere | humano, ao trocar um asset |
| `render_splash.py` | desde a 069, gera `assets/splash-iman-terra.png` do master `assets/splash-iman-terra.svg`, com as fontes de `fonts/` (origem do PNG, abaixo) | humano, ao trocar o master, antes do `derive_assets.py` |
| `measure_splash.py` | desde a 069, mede o PNG gerado (cada linha de texto presente, com e sem as fontes do repo, contra o QtSvg) e os icones recortados (antes e depois, pelo QtSvg); o laudo 069 | humano, ao trocar o master |

Comandos (com o `python3` da raiz OSGeo4W fixada, a mesma do build):

```
python3 iman/brand/derive_assets.py --check
python3 iman/brand/render_splash.py          # so ao trocar o master do splash; depois, o derive_assets.py
python3 iman/brand/build_brand.py --measure <qgis_pt_BR.ts convertido do .qm pelo lconvert>
```

## A marca fica fora da GPL

A GPL cobre o codigo. O nome e a marca IMAN e IMAN Terra, e a logo de folha e globo (o splash, os icones e o simbolo
desta pasta), pertencem ao Instituto IMAN e nao sao licenciados pela GPL; o uso deles depende de autorizacao do
Instituto IMAN. (Emenda de 2026-10-30 (b) ao D-IMAN-040, fatia 051; o mesmo aviso vai no `THIRD_PARTY_NOTICES.md`
instalado, secao 7.)

## Assets aprovados (origem)

Copiados de `../iman-qgis-distro-agent/app/assets/` (distro congelada, `HEAD` `59ac0ce`, ultimo commit dos quatro
arquivos `c275590`, 2026-09-09: a arte oficial ingerida na fatia distro #021). Desde a 069, o splash (o SVG e o PNG)
vem de outra origem: a arte nova do sponsor (abaixo). So assets aprovados entram aqui
(D-IMAN-040); nada do plugin de marca ou do launcher da distro. O QSS da distro veio depois, na fatia 049 (`theme/`, acima), pela emenda de 2026-10-29 ao D-IMAN-040.

| Arquivo | SHA-256 | Nota |
|---|---|---|
| `assets/icon-iman-terra.ico` | `f9d2c6ed2ae68f6812fc865e6b8743913f3114d8029b0ae8d9632a7fb9d9b581` | ICO 16/24/32/48/64/128/256, transparente (`regenerate-icons.py` da distro) |
| `assets/iman-symbol.png` | `f0a1b5c9a79dde659bdb82f5e1aa1bb86728fa84419c4e7c3263f0cf61a2df00` | simbolo oficial 512x512 (favicon set do Instituto IMAN) |
| `assets/splash-iman-terra.png` | `d2fc627608fb7e2d333ce54e86e6bd983018bbc4e16ac3ea8e03b426ad23b5dc` | desde a 069, splash 1000x480 RGBA de 8 bits, todo opaco, gerado do master SVG por `render_splash.py` (origem abaixo); traz "POWERED BY QGIS" |
| `assets/splash-iman-terra.svg` | `f15bca9db1277ce9c57f262ecd9baf8f5e921caba0c505cdd66a356f6b4b48ee` | desde a 069, master vetorial novo: export do Corel pelo sponsor em 2026-11-14 (`../iman-product-architect/docs/IMAN Terra.svg`, copia byte a byte, MD5 `69acaaca3defb7dcbf6dfe45adea4327`). E a origem do PNG (todo o desenho, com o texto) e dos recortes do simbolo |

### O splash da fatia 069 (origem)

Arte refeita pelo sponsor no Corel (adendo de 2026-11-14 ao D-IMAN-040 e emenda do mesmo dia ao item 1): o logotipo
"IMAN Terra" e o simbolo ficam; os textos de apoio passam a Open Sans; sai o "Inicializando ambiente geoespacial..."
gravado (a mensagem de carga e a do QGIS, na mesma faixa); a versao gravada passa a "v0.4.0 · LTR" e a faixa de cima a
"VERSAO INSTITUCIONAL · LTR". O sponsor entregou so o SVG; o PNG e rasterizacao do master, sem mexer no desenho
(derivacao por escala, D-IMAN-041, regra 6, pela emenda de 2026-11-14). Reexportar a arte a cada `product_version` e
rotina do sponsor.

O PNG sai de `python3 iman/brand/render_splash.py`, com o `python3` da raiz OSGeo4W (Pillow 12.3.0):

- **Renderizador:** Microsoft Edge 157.0.4341.46 da bancada, sem cabeca, com perfil temporario proprio, so a pagina
  local, sem rede. O SVG vai em linha numa pagina XHTML, sem o prologo XML nem o DOCTYPE. Nunca o QtSvg sozinho: no
  laudo 069 ele apaga letras de "REGULARIZACAO..." e o "QGIS" inteiro.
- **Fontes:** as tres familias que o master pede, por `@font-face` com os TTF desta pasta (`fonts/`, Open Sans 3.003)
  embutidos em `data:`: "Open Sans" normal = `OpenSans-Regular.ttf`, "Open Sans" bold = `OpenSans-Bold.ttf`, "Open
  Sans Semibold" 600 = `OpenSans-SemiBold.ttf`. As `@font-face` do proprio master apontam para as fontes SVG que o
  Corel embute (`format(svg)`), que o navegador nao le e descarta; o script confere antes da captura que as tres faces
  da pagina carregaram (`document.fonts`).
- **Escala:** desenhado em 4000x1920 (4 vezes), composto sobre branco e reduzido para 1000x480 com LANCZOS.
- **Fundo:** o degrade do fundo do master tem `stop-opacity` 0,847 e nada embaixo; o PNG de antes era o export raster
  do Corel sobre a pagina branca (medido na 069: o PNG de antes e o SVG de antes renderizado aqui, sobre branco,
  diferem 1 por canal na mediana; sobre preto, 16). O PNG novo e composto sobre o mesmo branco e sai todo opaco, como
  o de antes (o `main.cpp` usa a mascara do pixmap).

## Fonte da interface (origem, fatia 067)

A familia escolhida pelo sponsor (adendo de 2026-11-14 ao D-IMAN-040; a "fonte do sistema" do D-IMAN-026 caiu na
emenda do mesmo dia) e a **Open Sans**, sob a SIL Open Font License 1.1 (`fonts/OFL.txt`, copia em
`iman/notices/licencas/open-sans-OFL.txt`). Baixados uma vez, sem modificacao, do repositorio oficial
`googlefonts/opensans`, commit `6cbc400d4855abee59d85c4ed871d510399bce7b` (a ponta do `main` em 2026-11-14), pasta
`fonts/ttf` (os estaticos; o mesmo repositorio tem a versao variavel em `fonts/variable`, que nao entra). URL de cada
arquivo: `https://raw.githubusercontent.com/googlefonts/opensans/<commit>/fonts/ttf/<arquivo>` e
`.../<commit>/OFL.txt`. Versao da fonte (nome 5 da tabela `name`): `Version 3.003; ttfautohint (v1.8.4)`, nos seis.
O hash de blob do git de cada TTF e o mesmo que a API do GitHub da para o arquivo no commit.

| Arquivo | Estilo (nomes 1 e 2; 16 e 17 quando ha) | Peso OS/2 | SHA-256 |
|---|---|---|---|
| `fonts/OpenSans-Regular.ttf` | Open Sans, Regular | 400 | `c53aceea2dcf5b4098099c0c4d0a061d17e178a049317b42a422b1a9f7f8eb59` |
| `fonts/OpenSans-Italic.ttf` | Open Sans, Italic | 400 | `93bc1bb6abf4e6b7c75d7131714061d5b57cc478abcabe4cb3519bb38fb917aa` |
| `fonts/OpenSans-SemiBold.ttf` | Open Sans SemiBold, Regular; Open Sans, SemiBold | 600 | `4a413711684a9dd564ef0f1c10cb62b5d9f7eb6df2cff962f5341a6ecd5f64ae` |
| `fonts/OpenSans-SemiBoldItalic.ttf` | Open Sans SemiBold, Italic; Open Sans, SemiBold Italic | 600 | `c646a9aefc0e964f66487260639e375685328a6280856faea3e012c43fe9c56d` |
| `fonts/OpenSans-Bold.ttf` | Open Sans, Bold | 700 | `27da758f4dcac9a65abe914c13b463b42982b9909bc65713424099f4810bd1e6` |
| `fonts/OpenSans-BoldItalic.ttf` | Open Sans, Bold Italic | 700 | `d672a770037104b6af45e1336b3d3c1729c8aea940f81e010f5a8a7319c29a21` |
| `fonts/OFL.txt` | licenca | | `01cd5ffb3a528c219a86e49a814c6c53bd8a69b9a3c305dd237074ba1c811af7` |

Trocar a fonte e trocar os TTF desta pasta, a lista do `imanfonts.qrc` e a `font_family` do `brand.json`, e
registrar a licenca nova em `iman/notices/`.

## Derivados

Derivacao, nunca desenho (D-IMAN-041, regra 6): copia, escala LANCZOS sem margem ou recorte do grupo vetorial do
simbolo, sem re-colorir. Enquadramento do recorte: o medido pela distro (`derive-theme-icons.py`, fatia distro #041),
deslocado -10 em x e em y desde a 069 (o master novo perdeu 10 unidades de borda em cada lado; o simbolo e o mesmo,
path a path, deslocado igual). O grupo do simbolo e achado pelo degrade da folha, a classe `fil30` no master novo.

| Derivado | Operacao | Origem | Substitui no QGIS | SHA-256 |
|---|---|---|---|---|
| `derived/qgis.ico` | copia | `icon-iman-terra.ico` | `src/app/qgis.ico` | `f9d2c6ed2ae68f6812fc865e6b8743913f3114d8029b0ae8d9632a7fb9d9b581` |
| `derived/splash.png` | copia | `splash-iman-terra.png` | `images/splash/splash.png` | `d2fc627608fb7e2d333ce54e86e6bd983018bbc4e16ac3ea8e03b426ad23b5dc` |
| `derived/qgis-icon-16x16.png` | escala 16 | `iman-symbol.png` | `images/icons/qgis-icon-16x16.png` | `04b36b5089c15fc849043278f7f0d553a414b21d2961bc7f1542aef68ddd8eb1` |
| `derived/qgis-icon-60x60.png` | escala 60 | `iman-symbol.png` | `images/icons/qgis-icon-60x60.png` | `0cf45f63bd510575332b9628ae69d3a6175bc3914a58c2099548708f49c0efb4` |
| `derived/qgis_icon.svg` | recorte, 256 | `splash-iman-terra.svg` | `images/icons/qgis_icon.svg` | `780a13eb3d9cdeced8c24aaeeccc0de796f9faa3e230c5dd6e28061ccc1a1c5d` |
| `derived/providerQgis.svg` | recorte, 16 | `splash-iman-terra.svg` | `images/themes/default/providerQgis.svg` | `3366cf9b9fae4ef696db28a3d77143cc7499253a8f53e05c4dfdff2a1421aea0` |
| `derived/iman-terra-qgs.ico`, `iman-terra-qgz.ico`, `iman-terra-qlr.ico` | copia | `icon-iman-terra.ico` | nada no QGIS: icones de tipo de arquivo do "Abrir com" do instalador (fatia 047) | `f9d2c6ed2ae68f6812fc865e6b8743913f3114d8029b0ae8d9632a7fb9d9b581` |

Ate a 068, os SVG tinham o mesmo `viewBox` e os mesmos `path` do `providerQgis.svg` do tema da distro; desde a 069, os
dois estao deslocados -10 em x e em y (o mesmo desenho, laudo 069). Muda o tamanho nominal
(o do arquivo do QGIS que cada um substitui).

## O que nao troca (D-IMAN-039, regra 2; BL-1)

`qgis-full.png` e os icones do "Sobre", a medalha de "Membros de Suporte" (`mActionHelpSponsors.png`), os icones de
tipo de arquivo do QGIS (`qgis-qgs.ico` e irmaos: o "Abrir com" do produto usa os `iman-terra-*.ico` de `derived/`,
fatia 047) e a imagem padrao da decoracao do mapa (`qgis-icon-minimal-black.svg`).
