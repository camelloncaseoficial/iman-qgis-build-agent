# Fonte unica de marca (BL-4)

Tudo o que e texto ou imagem de marca do produto nasce aqui. O build le daqui; nenhum arquivo do QGIS tem o nome do
produto escrito a mao. Mudar o nome e mudar `brand.json` e recompilar (A2 do briefing `qgis-build #044`).

| Arquivo | O que e | Quem le |
|---|---|---|
| `brand.json` | nome do produto, organizacao, endereco, rotulo do motor ("motor QGIS"), idioma padrao, feed e checagem de versao. A versao do produto ainda nao existe e nao esta aqui | `build_brand.py` e o smoke (`iman/build/Invoke-Smoke.ps1`) |
| `i18n/curadoria_pt_BR.json` | as 275 mensagens do `qgis_pt_BR.qm` com "QGIS" na traducao, cada uma numa classe (aplicativo, versao, projeto, duvida), e o texto final das que mudam, com marcadores (`{product}`, `{engine}`, `{org}`, `{url}`); mais as superficies do Bloco D (`extra`) | `build_brand.py` |
| `build_brand.py` | gera no build `iman_brand.h`, `iman_pt_BR.ts` e `qgis_global_settings.ini`; com `--measure` confere a curadoria contra o `.qm` do QGIS | `iman/build/Build-Qgis.ps1` |
| `assets/` | assets aprovados, copiados da distro congelada (abaixo) | `derive_assets.py` |
| `derived/` | o que substitui o logo do QGIS no fonte, derivado dos assets | `derive_assets.py` copia para a arvore do QGIS; o smoke compara com o recurso compilado |
| `derive_assets.py` | deriva `derived/` e copia para a arvore do QGIS; `--check` so confere | humano, ao trocar um asset |

Comandos (com o `python3` da raiz OSGeo4W fixada, a mesma do build):

```
python3 iman/brand/derive_assets.py --check
python3 iman/brand/build_brand.py --measure <qgis_pt_BR.ts convertido do .qm pelo lconvert>
```

## Assets aprovados (origem)

Copiados de `../iman-qgis-distro-agent/app/assets/` (distro congelada, `HEAD` `59ac0ce`, ultimo commit dos quatro
arquivos `c275590`, 2026-09-09: a arte oficial ingerida na fatia distro #021). So assets aprovados entram aqui
(D-IMAN-040); nada do QSS, do plugin de marca ou do launcher da distro.

| Arquivo | SHA-256 | Nota |
|---|---|---|
| `assets/icon-iman-terra.ico` | `f9d2c6ed2ae68f6812fc865e6b8743913f3114d8029b0ae8d9632a7fb9d9b581` | ICO 16/24/32/48/64/128/256, transparente (`regenerate-icons.py` da distro) |
| `assets/iman-symbol.png` | `f0a1b5c9a79dde659bdb82f5e1aa1bb86728fa84419c4e7c3263f0cf61a2df00` | simbolo oficial 512x512 (favicon set do Instituto IMAN) |
| `assets/splash-iman-terra.png` | `aa403d13adf373a32aef83c4fb99c70a4bb41038d199fefdd428bf4dbe4ff877` | splash 1000x480, reduzido do master raster do Corel; traz "POWERED BY QGIS" |
| `assets/splash-iman-terra.svg` | `6d15685775d9c3313b23f2a1af84e8e25394fe90f9e9f5bae97aced0ea0a7421` | master vetorial (export do Corel, MD5 `32a43bb2b8babae2d0868b89f27cfbe7`, o do README da distro). So o simbolo e recortado dele; o texto do SVG nao e rasterizado (o QtSvg apaga glifos, ver o README da distro) |

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

Os SVG tem o mesmo `viewBox` e os mesmos `path` do `providerQgis.svg` do tema da distro; muda o tamanho nominal
(o do arquivo do QGIS que cada um substitui).

## O que nao troca (D-IMAN-039, regra 2; BL-1)

`qgis-full.png` e os icones do "Sobre", a medalha de "Membros de Suporte" (`mActionHelpSponsors.png`), os icones de
tipo de arquivo (`qgis-qgs.ico` e irmaos, fatia do instalador) e a imagem padrao da decoracao do mapa
(`qgis-icon-minimal-black.svg`).
