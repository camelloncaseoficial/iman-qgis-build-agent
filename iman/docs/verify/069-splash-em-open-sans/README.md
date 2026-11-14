# Laudo 069: o splash novo do Corel, com os textos de apoio em Open Sans, e o PNG gerado do SVG

Briefing `qgis-build #069` (2026-11-14). Decisões: D-IMAN-040 (adendo de 2026-11-14 sobre o splash e a emenda do mesmo
dia ao item 1), D-IMAN-041 (regra 6), D-IMAN-025, D-IMAN-034. Branch `feat/069-splash-em-open-sans`, base
`origin/develop` em `7fbb9a7b71` (merge do PR #14, `#067`). Build medido: `23fd9892b3` (HEAD dos commits de código).

Fatia de marca: troca do asset aprovado e derivação. Nada da arte foi mexido: o PNG é a rasterização do master como
ele está (a única escolha, o fundo branco sob a arte translúcida, está medida na seção "Fundo").

## O que mudou

| Arquivo | O quê |
|---|---|
| `iman/brand/assets/splash-iman-terra.svg` | cópia byte a byte de `../iman-product-architect/docs/IMAN Terra.svg` (export do Corel pelo sponsor em 2026-11-14) |
| `iman/brand/assets/splash-iman-terra.png` | 1000x480 RGBA de 8 bits, todo opaco, gerado do SVG pelo `render_splash.py` |
| `iman/brand/render_splash.py` | novo: o gerador do PNG (rodado à mão, fora do build e do gate) |
| `iman/brand/derive_assets.py` | o enquadramento fixo desce 10 unidades nos dois eixos (`FRAME_SHIFT = -10`) e o marcador do símbolo passa a `fil30` |
| `iman/brand/derived/`, `images/splash/splash.png`, `images/icons/qgis_icon.svg`, `images/themes/default/providerQgis.svg` | regerados pelo `derive_assets.py` |
| `iman/brand/README.md`, `iman/PATCHES.md`, `iman/notices/THIRD_PARTY_NOTICES.md` | SHA-256 e origem novos; o bloco gerado dos notices com a 069 (`Update-Notices.ps1`) |
| testes | novos, fora do gate: `iman/brand/measure_splash.py` (A2 e A3) e `iman/build/Measure-SplashFont.ps1` + `smoke/splash_font.py` (A6, a fonte efetiva da mensagem) |

Nenhum teste, guarda ou smoke pré-existente mudou. Procurei SHA literal do splash e dos ícones em `iman/build`,
`iman/installer` e `iman/brand` (`.ps1`, `.py`, `.json`, `.tsv`): nenhum; o `marca:splash` e o `C1:splash` leem o
`derived/splash.png` por cálculo. Arquivos do QGIS tocados: só os três de imagem, que já estavam no patchset.

## Conferências antes de copiar (STOP)

- **SHA do master:** `f15bca9db1277ce9c57f262ecd9baf8f5e921caba0c505cdd66a356f6b4b48ee`, o do briefing (`a1-a4/a1-a4.txt`).
- **Símbolo:** o grupo do símbolo do master novo tem os mesmos 14 paths do antigo, na mesma ordem, com os mesmos
  comandos; toda coordenada absoluta é a antiga menos 10 (desvio máximo 0,0000), as relativas são iguais; as cores são
  as mesmas (`white`, `#00AFF0`, `#00A85A`, `none`) e o degradê da folha (`id0` no novo, `id1` no antigo) tem as mesmas
  paradas, com os pontos deslocados -10. No master novo, `fil28` é `#00AFF0`; o degradê da folha é `fil30`.
- **Renderizador sem rede com as fontes do repo:** havia (o Edge da bancada); nada foi baixado nem instalado.

## Como o PNG é gerado (`render_splash.py`)

Rodado com o `python3` da raiz OSGeo4W (3.12.13, Pillow 12.3.0), `python3 iman/brand/render_splash.py`:

- **Renderizador:** Microsoft Edge 157.0.4341.46 (o da bancada; não há Chrome), sem cabeça, com um perfil temporário
  próprio, só a página local; a rodada fecha sozinha e só o PID que ela abriu seria encerrado num estouro de tempo.
- **Página:** XHTML com o SVG em linha (sem o prólogo XML nem o DOCTYPE, que pede a DTD externa). O XML preserva o
  `xml:space="preserve"` do Corel.
- **Fontes:** as três famílias que o master pede, por `@font-face` com os TTF de `iman/brand/fonts/` (Open Sans 3.003
  do `#067`) embutidos em `data:` ("Open Sans" normal = `OpenSans-Regular.ttf`, "Open Sans" bold = `OpenSans-Bold.ttf`,
  "Open Sans Semibold" 600 = `OpenSans-SemiBold.ttf`). Fonte por `file://` cai no CORS do navegador; `data:` não. As
  `@font-face` do próprio master apontam para as fontes SVG que o Corel embute (`format(svg)`): o Edge as descarta
  (não aparecem no `document.fonts`). Antes da captura, uma rodada `--dump-dom` confere que as três faces da página
  carregaram: `Open Sans|normal|loaded;Open Sans|bold|loaded;Open Sans Semibold|600|loaded`.
- **Escala:** a página é desenhada em 4000x1920 (4 vezes) e reduzida para 1000x480 com LANCZOS (Pillow).
- **Saída:** `d2fc627608fb7e2d333ce54e86e6bd983018bbc4e16ac3ea8e03b426ad23b5dc`, cerca de 3 s.

### Fundo

O master não tem fundo opaco: o degradê do fundo (`id4`) tem `stop-opacity` 0,847 e embaixo dele só há um quadro preto
de 10 unidades na borda. Sozinho, o SVG sai com alfa de 221 a 255. O PNG de hoje é todo opaco (alfa 255 nos 480000
pixels; o `main.cpp` usa a máscara do pixmap), sem região transparente a repetir.

Para saber sobre o que o Corel exportou o raster de antes, renderizei o SVG de antes do mesmo jeito e comparei com o
PNG de antes:

| Composto sobre | Diferença por canal: mediana | p90 | p99 | máximo |
|---|---|---|---|---|
| branco | 1 | 3 | 51 | 187 |
| preto | 16 | 31 | 49 | 187 |
| nada (transparente) | 14 | 26 | 49 | 187 |

O p99 e o máximo são as letras (o raster de antes era Arial, e o SVG de antes renderizado aqui usa a Open Sans). O
PNG de antes era, portanto, o SVG sobre a página branca. O PNG novo é composto sobre o mesmo branco, em 4000x1920, antes
da redução, e sai todo opaco, como o de antes. Não é retoque da arte: é a página em que o Corel a exportava, medida.

## A1 O master

`iman/brand/assets/splash-iman-terra.svg` = `f15bca9d...b4b48ee`, igual ao `docs/IMAN Terra.svg` do arquiteto
(`a1-a4/a1-a4.txt`). **OK.**

## A2 O PNG

`a2-a3/`, rodado por `python3 iman/brand/measure_splash.py --out <pasta>` (12 s com o A3).

- 1000x480, `RGBA`, alfa 255 a 255; o PNG commitado é igual pixel a pixel à renderização de referência da rodada.
- Seis regiões, tiradas das posições dos `<text>` do próprio master (`regions_px` no `facts.json`). Pixel mudado:
  diferença acima de 16 em algum canal. A coluna "o texto muda" compara o PNG com o mesmo master sem os `<text>`
  (`a2-splash-sem-texto.png`); as outras comparam com a referência.

| Linha | O texto muda | Sem as fontes do repo | Fontes instaladas no Windows (1.10) | QtSvg sozinho |
|---|---|---|---|---|
| "CEARÁ · SIRGAS 2000 · UTM 24S" | 836 | 599 | 32 | 142 |
| "VERSÃO INSTITUCIONAL · LTR" | 783 | 616 | 55 | 28 |
| "REGULARIZAÇÃO FUNDIÁRIA · CADASTRO TERRITORIAL" | 2876 | 2215 | 701 | 2784 |
| "POWERED BY" | 336 | 0 | 0 | 49 |
| "QGIS" | 504 | 365 | 0 | 500 |
| "v0.4.0 · LTR" | 267 | 184 | 3 | 47 |

Fora das seis regiões, tirar o texto muda 0 pixel. **OK.**

**Visto falhando** (`a2-regioes-ampliadas.png`, as seis regiões em 3x, uma linha por variante):

- **QtSvg sozinho** (`a2-falhando-qtsvg.png`, o Qt 5.15.13 do produto): "REGULARIZAÇÃO FUNDIÁRIA · CADASTRO
  TERRITORIAL" sai como "RE R O D R D RO ERR OR" (as outras letras somem) e o "QGIS" some inteiro (a região dele é
  igual à do PNG sem texto: 0 pixel de diferença).
- **Sem as fontes do repo** (`--no-fonts`, `a2-falhando-sem-fontes-do-repo.png`): o Edge cai nas famílias instaladas
  no Windows desta bancada (a Open Sans 1.10 de 2019, que não é da Crew, memória da 067): o "QGIS" e a linha
  "REGULARIZAÇÃO..." saem com o traço mais fino que o Bold da referência, e as linhas em SemiBold trocam de desenho.
  O "POWERED BY" (Regular) sai igual, porque a Regular 1.10 instalada desenha esses glifos igual à 3.003 nesse
  tamanho. Não medi numa máquina sem a Open Sans instalada.
- **Com as fontes instaladas no Windows declaradas** (`--fonts-dir C:\Windows\Fonts`, só medição): até 701 pixels
  mudam por linha, o que mostra que o arquivo de fonte declarado é o que desenha.

## A3 Os ícones

`a2-a3/a3-*`: o `qgis_icon.svg` e o `providerQgis.svg` de antes (`7fbb9a7b71`) e de agora, rasterizados pelo QtSvg (quem
os lê no produto) em 16, 32 e 256 px, sobre transparente, comparados pixel a pixel. `a3-icones-lado-a-lado.png`.

| Ícone | 16 px | 32 px | 256 px |
|---|---|---|---|
| `qgis_icon.svg`, antes x depois | 0 pixel diferente | 0 | 0 |
| `providerQgis.svg`, antes x depois | 0 | 0 | 0 |
| sem o ajuste de -10, antes x falhando | 157 pixels (máx. 255) | 418 (máx. 255) | 6244 (máx. 255) |

O texto do SVG muda (o `viewBox` e as coordenadas descem 10; o degradê passa de `id1` a `id0`); o desenho não. **OK.**

**Visto falhando:** sem o ajuste (o enquadramento de antes sobre o master novo), o ícone de 256 px sai deslocado para
cima e para a esquerda: o centróide do alfa vai de (131,500; 133,815) para (130,780; 133,096), 0,72 px nos dois eixos
(10 unidades num quadro de 3560, em 256 px), e a borda direita do globo é cortada.

## A4 O `derive_assets.py --check`

`a1-a4/a1-a4.txt`: na ponta, `ASSETS OK (9 derivados)`, exit 0. Com o `derived/splash.png` trocado pelo de antes,
`DIVERGE: splash.png nao e a derivacao de splash-iman-terra.png`, `ASSETS FALHOU`, exit 1; restaurado, OK de novo.
**OK.**

## A5 O smoke de marca

`smoke-build/smoke.txt`: build incremental offline + `Invoke-Smoke.ps1` do HEAD `23fd9892b3` (5 min 44 s com o smoke).
Os 18 checks OK, entre eles:

- `marca:splash` OK: o recurso compilado `:/images/splash/splash.png` = `d2fc6276...ad23b5dc` = `derived/splash.png`;
- `marca:splash-texto` OK: a cor da marca no `qgisapp.cpp` e no `iman_brand.h`;
- `marca:icones` OK. **OK.**

## A6 O splash real, antes e depois

Perfil novo, alvo Build. ANTES: o build da develop (`a6dc2ad15e`, cuja árvore é igual à de `7fbb9a7b71`), medido
antes de recompilar. DEPOIS: o build `23fd9892b3`. Em cada lado: `Invoke-BrandCaptures.ps1` (`02-splash-real.png`,
`02-splash-mensagem-final.png`, `01-janela.png`), `Measure-ThemeRegions.ps1` (`c1-splash-01..04.png`, o splash
capturado da tela enquanto carrega) e `Measure-SplashFont.ps1` (fonte efetiva e `a6-splash-mensagem-*.png`). Guarda do
QGIS oficial OK em todas as rodadas; nada sobrou na pasta do produto.

- **A arte nova na tela:** `a6-depois/c1-splash-03.png` (da tela, 750x360 físicos na escala 1,25) mostra a arte nova,
  com "VERSÃO INSTITUCIONAL · LTR", "v0.4.0 · LTR" e sem o "Inicializando" gravado.
- **A mensagem do QGIS na faixa de baixo, branca e legível:** "Atualização dos caminhos recentes do projeto" no quadro
  3; `C1:splash` OK, 1056 pixels de texto, luminância mediana 198,5 (clara).
- **A fonte da mensagem** (`a6-depois/fatos.json`, lida no `QSplashScreen` vivo, antes do `splash->finish`): família
  `Open Sans`, 7,8 pt, peso 50 (Regular), resolvida `Open Sans`, 10 px; o arquivo que desenha (nomes 1 e 5 da tabela
  `name` pelo `QRawFont`) é `Open Sans`, `Version 3.003; ttfautohint (v1.8.4)`: a embarcada, não a 1.10 instalada. A
  ordem do `main.cpp` (`ImanFont::apply` antes do `QSplashScreen`) se confirma na tela. A mesma família e o mesmo
  arquivo já valiam no ANTES (`a6-antes/fatos.json`): a mensagem está em Open Sans desde a 067.
  `a6-splash-mensagem-de-teste.png` mostra uma mensagem com acentos e algarismos escrita pelo mesmo `showMessage`, na
  cor `#FFFFFF` do QgisApp.

**Visto falhando:** `a6-antes/c1-splash-03.png` e `a6-antes/a6-splash-mensagem-do-qgis.png`: a arte antiga
("VERSÃO INSTITUCIONAL · CAUCAIA LTR", "v1.0 · LTR") com o "Inicializando ambiente geoespacial..." gravado à esquerda
da mensagem do QGIS; na mensagem de teste, o texto do QGIS passa por cima do "Inicializando". O `C1:splash` do ANTES
compara a tela com o `derived/splash.png` novo (o do repositório no momento da rodada) e por isso conta mais pixels
(2089): a arte antiga difere na faixa toda.

## A7 Placar

O `Invoke-Gate.ps1` registrado (`crew_gate.sh qgis-build`) roda depois do PR aberto; o resultado vai no `/deliver`.

## Fora do escopo, intocado

A cor da mensagem (`splash_text_color`) e o tamanho da janela do splash (600x300 no `main.cpp`); o `iman-symbol.png`, o
`.ico` e os ícones de tipo de arquivo; a versão do produto; o título da janela com U+2014. "POWERED BY QGIS" segue na
arte, e nada do `QgsAbout` mudou.

## Arquivos

`SHA256SUMS.txt` tem o hash de cada arquivo desta pasta.

- `a1-a4/`: A1 e A4 (`a1-a4.txt`).
- `a2-a3/`: os PNG de referência, sem texto e das variantes de falha; `a2-regioes-ampliadas.png`;
  `a2-splash-antes-em-cima-depois-embaixo.png`; os SVG e os PNG dos ícones (antes, depois e sem o ajuste) em 16, 32 e
  256 px; `a3-icones-lado-a-lado.png`; `facts.json`.
- `a6-antes/`, `a6-depois/`: as capturas do splash real e `fatos.json` (fonte efetiva e `C1:splash`).
- `smoke-build/smoke.txt`: as linhas de veredito do smoke.
