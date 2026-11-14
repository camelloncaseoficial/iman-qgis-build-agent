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

Comandos (com o `python3` da raiz OSGeo4W fixada, a mesma do build):

```
python3 iman/brand/derive_assets.py --check
python3 iman/brand/build_brand.py --measure <qgis_pt_BR.ts convertido do .qm pelo lconvert>
```

## A marca fica fora da GPL

A GPL cobre o codigo. O nome e a marca IMAN e IMAN Terra, e a logo de folha e globo (o splash, os icones e o simbolo
desta pasta), pertencem ao Instituto IMAN e nao sao licenciados pela GPL; o uso deles depende de autorizacao do
Instituto IMAN. (Emenda de 2026-10-30 (b) ao D-IMAN-040, fatia 051; o mesmo aviso vai no `THIRD_PARTY_NOTICES.md`
instalado, secao 7.)

## Assets aprovados (origem)

Copiados de `../iman-qgis-distro-agent/app/assets/` (distro congelada, `HEAD` `59ac0ce`, ultimo commit dos quatro
arquivos `c275590`, 2026-09-09: a arte oficial ingerida na fatia distro #021). So assets aprovados entram aqui
(D-IMAN-040); nada do plugin de marca ou do launcher da distro. O QSS da distro veio depois, na fatia 049 (`theme/`, acima), pela emenda de 2026-10-29 ao D-IMAN-040.

| Arquivo | SHA-256 | Nota |
|---|---|---|
| `assets/icon-iman-terra.ico` | `f9d2c6ed2ae68f6812fc865e6b8743913f3114d8029b0ae8d9632a7fb9d9b581` | ICO 16/24/32/48/64/128/256, transparente (`regenerate-icons.py` da distro) |
| `assets/iman-symbol.png` | `f0a1b5c9a79dde659bdb82f5e1aa1bb86728fa84419c4e7c3263f0cf61a2df00` | simbolo oficial 512x512 (favicon set do Instituto IMAN) |
| `assets/splash-iman-terra.png` | `aa403d13adf373a32aef83c4fb99c70a4bb41038d199fefdd428bf4dbe4ff877` | splash 1000x480, reduzido do master raster do Corel; traz "POWERED BY QGIS" |
| `assets/splash-iman-terra.svg` | `6d15685775d9c3313b23f2a1af84e8e25394fe90f9e9f5bae97aced0ea0a7421` | master vetorial (export do Corel, MD5 `32a43bb2b8babae2d0868b89f27cfbe7`, o do README da distro). So o simbolo e recortado dele; o texto do SVG nao e rasterizado (o QtSvg apaga glifos, ver o README da distro) |

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
simbolo, sem re-colorir. Enquadramento do recorte: o medido pela distro (`derive-theme-icons.py`, fatia distro #041).

| Derivado | Operacao | Origem | Substitui no QGIS | SHA-256 |
|---|---|---|---|---|
| `derived/qgis.ico` | copia | `icon-iman-terra.ico` | `src/app/qgis.ico` | `f9d2c6ed2ae68f6812fc865e6b8743913f3114d8029b0ae8d9632a7fb9d9b581` |
| `derived/splash.png` | copia | `splash-iman-terra.png` | `images/splash/splash.png` | `aa403d13adf373a32aef83c4fb99c70a4bb41038d199fefdd428bf4dbe4ff877` |
| `derived/qgis-icon-16x16.png` | escala 16 | `iman-symbol.png` | `images/icons/qgis-icon-16x16.png` | `04b36b5089c15fc849043278f7f0d553a414b21d2961bc7f1542aef68ddd8eb1` |
| `derived/qgis-icon-60x60.png` | escala 60 | `iman-symbol.png` | `images/icons/qgis-icon-60x60.png` | `0cf45f63bd510575332b9628ae69d3a6175bc3914a58c2099548708f49c0efb4` |
| `derived/qgis_icon.svg` | recorte, 256 | `splash-iman-terra.svg` | `images/icons/qgis_icon.svg` | `0f2cc61f6890942a2c28f237c1f20c713a4247baf8e3a22e7a0a7c61383fb50e` |
| `derived/providerQgis.svg` | recorte, 16 | `splash-iman-terra.svg` | `images/themes/default/providerQgis.svg` | `7e83e7ac912e7611a304453d6de54353f30bdbf40182cc53c0a81c14ce1bd9c9` |
| `derived/iman-terra-qgs.ico`, `iman-terra-qgz.ico`, `iman-terra-qlr.ico` | copia | `icon-iman-terra.ico` | nada no QGIS: icones de tipo de arquivo do "Abrir com" do instalador (fatia 047) | `f9d2c6ed2ae68f6812fc865e6b8743913f3114d8029b0ae8d9632a7fb9d9b581` |

Os SVG tem o mesmo `viewBox` e os mesmos `path` do `providerQgis.svg` do tema da distro; muda o tamanho nominal
(o do arquivo do QGIS que cada um substitui).

## O que nao troca (D-IMAN-039, regra 2; BL-1)

`qgis-full.png` e os icones do "Sobre", a medalha de "Membros de Suporte" (`mActionHelpSponsors.png`), os icones de
tipo de arquivo do QGIS (`qgis-qgs.ico` e irmaos: o "Abrir com" do produto usa os `iman-terra-*.ico` de `derived/`,
fatia 047) e a imagem padrao da decoracao do mapa (`qgis-icon-minimal-black.svg`).
