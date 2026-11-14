# Laudo 067: a interface do IMAN Terra em Open Sans, embarcada e aplicada no C++

Briefing `qgis-build #067` (2026-11-14). Decisões: D-IMAN-040 (adendo de 2026-11-14 da fonte), D-IMAN-026 (emenda de
2026-11-14), D-IMAN-025, D-IMAN-034. Branch `feat/067-fonte-open-sans`, base `origin/develop` em `481614b1c8` (merge do
PR #13, `#066`).

Fatia de protótipo medido: nada foi corrigido além do que o briefing pede e da decisão do sponsor tomada na sessão
(seção "Decisão do sponsor na sessão"). O sponsor decide no smoke se a Open Sans fica.

## O que mudou

| Arquivo | O quê |
|---|---|
| `iman/brand/fonts/` | os seis TTF estáticos da Open Sans 3.003 (Regular, Italic, SemiBold, SemiBold Italic, Bold, Bold Italic) e o `OFL.txt` |
| `src/app/iman/imanfonts.qrc` | o recurso `:/iman/fonts` com os seis TTF, compilado no `qgis_app` (AUTORCC) |
| `src/app/iman/imanfont.h`, `imanfont.cpp` | `ImanFont::apply( theme )`: só com o tema `default`, registra os TTF do recurso (`QFontDatabase::addApplicationFont`); se todos registrarem e a família da marca aparecer, aplica a família na fonte da aplicação com o tamanho atual e devolve as fontes por classe do tema do Windows com a mesma família e o tamanho de cada uma; se algo falhar, desfaz os registros, fica a fonte do sistema e deixa mensagem no log |
| `src/app/main.cpp` | uma chamada a `ImanFont::apply( theme )` logo depois do `ImanPalette::apply`, antes do bloco do QGIS que aplica a fonte escolhida em Opções (`main.cpp:1560` em diante na branch), e o include |
| `src/app/CMakeLists.txt` | duas linhas na lista do `qgis_app`: `iman/imanfont.cpp` e `iman/imanfonts.qrc` |
| `iman/brand/brand.json`, `build_brand.py` | `font_family: "Open Sans"`, gerada como `IMAN_FONT_FAMILY` no `iman_brand.h` (sem nome de fonte solto no C++) |
| `iman/notices/` | a Open Sans no `THIRD_PARTY_NOTICES.md` (seção 5) e o `licencas/open-sans-OFL.txt` |
| `iman/PATCHES.md`, `iman/brand/README.md` | os arquivos novos e mudados; a origem e o SHA-256 dos TTF |
| testes | `theme_facts.py` e `Test-ThemeDefaults.ps1` só com acréscimo (A8); novos: `Invoke-FontCaptures.ps1` + `smoke/font_captures.py` (A1, A3 a A7) e `Measure-FontChoice.ps1` + `smoke/font_choice.py` (A2) |

Nenhum `setStyleSheet`, nenhuma regra QSS, nenhum `setPointSize` diferente do tamanho que a fonte já tinha, nenhuma
chave de perfil gravada pelo código, nada instalado no Windows. Arquivos do QGIS tocados: só o `main.cpp` e o
`src/app/CMakeLists.txt`.

Diff do `iman_brand.h` gerado (A9): só a família a mais.

```
 #define IMAN_SPLASH_TEXT_COLOR "#FFFFFF"
+#define IMAN_FONT_FAMILY "Open Sans"
 #define IMAN_COLOR_ACCENT "#2B8FD6"
```

## Decisão do sponsor na sessão (tamanho por classe)

Aplicar a família como o briefing descreve (`QApplication::setFont` com o tamanho da fonte da aplicação) faz o Qt 5.15
apagar as fontes por classe que o tema do Windows dá. Medido na primeira versão (commit `77783c23ea`, rodada
`font-depois-20261114-100528`): menus, barra de menus, barra de status, títulos de painel, dicas e caixas de mensagem
passavam de **Segoe UI 9 pt** para **Open Sans 7,8 pt** (o menu Projeto ficou 393 px de largura contra 428 no ANTES,
`variante-literal/`). O QGIS oficial faz o mesmo quando o usuário escolhe uma fonte em Opções. Perguntado na sessão, o
sponsor escolheu **manter o tamanho por classe**: o `ImanFont` guarda as fontes por classe antes do `setFont` e as
devolve com a família da marca e o tamanho de cada uma (commit `bf202202d1`). Todas as medidas abaixo são desse build,
salvo onde dito.

| Classe | ANTES (develop) | Primeira versão (`77783c23ea`) | Final (`bf202202d1`) |
|---|---|---|---|
| `QMenu`, `QMenuBar`, `QStatusBar`, `QMessageBox`, `QTipLabel`, `QDockWidgetTitle` | Segoe UI 9 pt | Open Sans 7,8 pt | Open Sans 9 pt |
| fonte da aplicação (`QLabel`, `QGroupBox`, `QHeaderView` e o resto) | MS Shell Dlg 2 7,8 pt | Open Sans 7,8 pt | Open Sans 7,8 pt |

Com Open Sans 9 pt, o menu Projeto mede 351x489 px contra 342x470 no ANTES (Camada 472x710 contra 456x682; Vetor 274x125
contra 261x120): a Open Sans é mais larga e mais alta que a Segoe UI no mesmo tamanho.

## Achado da bancada: a Open Sans já está instalada nesta máquina

`C:\Windows\Fonts` tem a Open Sans **1.10** (13 arquivos de 2019-04-18: Regular, Semibold, Bold, ExtraBold, Light,
Condensed e itálicos), anterior a esta sessão e não instalada por ela. Por isso "a família é Open Sans" não prova
sozinho que o produto usa a fonte embarcada. As medidas leem, pelo `QRawFont` da fonte em uso, os nomes 1 e 5 da tabela
`name` do arquivo que o Qt desenha: a embarcada diz `Version 3.003; ttfautohint (v1.8.4)`, a do sistema `Version 1.10`.
Em toda medida do DEPOIS, a fonte da aplicação, as por classe, o título de grupo, o negrito e a SemiBold saem do
arquivo **3.003**: a fonte embarcada registra e é a desenhada, sem depender da instalada. A prova numa máquina sem a
Open Sans é a VM limpa (BL-7), que esta fatia não roda (lacuna declarada abaixo). O STOP "a fonte só funciona instalada"
não se aplica: nada foi instalado e o registro do recurso funciona.

A lista de estilos que o `QFontDatabase` devolve para "Open Sans" mistura as duas: `Regular, Bold, Bold Italic, Italic,
SemiBold, SemiBold Italic` (as embarcadas) e `Condensed Light Italic, Extrabold Italic, Light Italic, Semibold Italic`
(as do sistema). Numa máquina sem a Open Sans instalada ficam só as seis embarcadas.

Na `develop`, a fonte da aplicação é "MS Shell Dlg 2", que o Windows desenha com o arquivo da **Tahoma** 7.05 (não a
Segoe UI, como supunha o briefing); a Segoe UI 9 pt é só a das classes da tabela acima.

## A1 A fonte efetiva

Pelo `theme_facts.py` (acréscimo `font`), perfil novo, depois do `QgisApp` no ar:

| | `develop` (`theme-build-new-20261114-094901`) | branch (`theme-build-new-20261114-103900`) |
|---|---|---|
| família de `QApplication::font()` | MS Shell Dlg 2 | **Open Sans** |
| família resolvida (`QFontInfo`) | MS Shell Dlg 2 | Open Sans |
| arquivo que desenha (nome 5) | Tahoma, Version 7.05 | Open Sans, Version 3.003; ttfautohint (v1.8.4) |
| `pointSizeF` | 7,8 | **7,8** (igual) |
| estilos do `QFontDatabase` | Normal, Negrita | Regular, Bold, Bold Italic, Italic, SemiBold, SemiBold Italic, Condensed Light Italic, Extrabold Italic, Light Italic, Semibold Italic |

Arquivos: `a8-guarda/theme-*.json` (chave `theme.font`).

## A2 Escolha do usuário

`Measure-FontChoice.ps1`, um perfil descartável reaberto; as escritas no perfil são as do próprio diálogo de Opções,
pelo OK (`dados/escolha-*.json`, `dados/night-*.json`, `a2-escolha/`).

| Abertura | `develop` | branch |
|---|---|---|
| (a) perfil novo | MS Shell Dlg 2 7,8 (Tahoma); menu Segoe UI 9 | **Open Sans 7,8 (3.003); menu Open Sans 9**; Opções mostra "Qt padrão" marcado e "Open Sans" na caixa |
| (b) Arial escolhida em Opções > Geral, OK, reaberto | Arial 7,8; menu Arial 7,8 | **Arial 7,8; menu Arial 7,8**: a escolha do usuário manda |
| "Qt padrão" marcado, OK, reaberto | segue Arial; `/app/fontFamily=Arial` | segue **Arial**; `/app/fontFamily=Arial` |
| (c) perfil novo, Night Mapping escolhido, OK, reaberto | MS Shell Dlg 2 7,8 (Tahoma); menu Segoe UI 9 | **MS Shell Dlg 2 7,8 (Tahoma); menu Segoe UI 9**: a fonte do sistema, sem Open Sans |

O "restaurar padrão" não restaura, nos dois builds: comportamento do QGIS. Depois de reaberto com a Arial, o
`QgisAppStyleSheet` toma a fonte já aplicada como padrão (`qgisappstylesheet.cpp:195`), então Opções mostra "Qt padrão"
marcado com Arial na caixa, e marcar "Qt padrão" e dar OK não muda nada (`qgsoptions.cpp:1886-1893`): a chave
`/app/fontFamily=Arial` fica. Na branch é igual à `develop`; não foi mexido (arquivo do QGIS). Com Night Mapping depois
da Arial (abertura 4 da sequência de escolha), a Arial continua, como na `develop`.

## A3 Texto cortado

`Invoke-FontCaptures.ps1`: perfil novo, as mesmas janelas nos mesmos tamanhos (janela principal 1536x960; Opções e
Propriedades 1100x760; fontes de dados 1000x700; Processamento flutuando 420x700; algoritmo 900x720; tabela 800x320;
calculadora 900x700; salvar como 760x760; complementos 1000x700; compositor 1400x900; painel REURB flutuando 440x800;
Sobre 760x760). 31 telas (todas as do briefing; "Mapa" das Opções medido nas duas páginas do 3.44, "Tela & Legenda" e
"Ferramentas de mapa"; Rótulos também com "Rótulos individuais"). Para cada texto visível, o que ele precisa e o que tem:
rótulos, botões, caixas de seleção, títulos de grupo, abas, caixas de lista, caixas de número, cabeçalhos de tabela,
itens de listas e árvores e títulos de painel (o método está no cabeçalho do `smoke/font_captures.py`). Menus não entram
na conta: o Qt os dimensiona pelo texto (capturas `04` a `06`).

Contagem (ANTES `font-antes-20261114-103203`, DEPOIS `font-depois-20261114-103355`):

| | ANTES | DEPOIS | só no DEPOIS | só no ANTES | nos dois |
|---|---:|---:|---:|---:|---:|
| escala da bancada (125%) | 44 | 49 | 5 | 0 | 44 |
| 96 DPI (A5) | 44 | 49 | 5 | 0 | 44 |

Os 5 "só no DEPOIS" são **um texto só**, o mesmo item da árvore lateral das Opções, contado nas cinco páginas medidas:

| # | Tela | Texto | O que acontece | Precisa / tem (px) ANTES | DEPOIS | Captura |
|---|---|---|---|---|---|---|
| 1 | Opções (as cinco páginas) | "Fontes de dados" (árvore lateral) | **corta**: o "s" final encosta na borda | 115 / 116 | 120 / 116 | `a3-recortes/a3-01-antes.png`, `a3-01-depois.png`; `a3-telas/lado-07-opcoes-geral.png` |

Nos dois builds, e pior no DEPOIS (o que já cortava corta mais):

| Tela | Texto | ANTES | DEPOIS |
|---|---|---|---|
| Opções, árvore lateral | "SRC e Transformações", "Tratamento SRC", "Transformações de coordenada", "SRC Definido Pelo Usuário", "Ferramentas de mapa", "Editor de Código" | 122, 112, 199, 167, 143, 118 de 116/96 | 131, 118, 212, 174, 151, 121 |
| Propriedades da camada, lista lateral | "Formulário de Atributos", "Armazenamento Auxiliar" | 166, 170 de 136 | 173, 178 |
| Propriedades > Simbologia, estilos | "dot  black", "topo hospital" (reticências) | 154, 172 de 125 | 156, 176 |
| Painel REURB > Confrontações, cabeçalho | "Azimute (°)" | 63 de 60 (o ")" aparece cortado na borda) | 65 de 60: **o ")" some** (`a3-telas/lado-29-reurb-confrontacoes.png`) |
| Painel REURB > Confrontações, cabeçalho | "Confrontante" | 74 de 60 | 79 de 60 |

Nenhum texto some nem passa a ganhar reticências só no DEPOIS. As telas lado a lado (ANTES à esquerda) estão em
`a3-telas/lado-<tela>.png`, uma por tela. Ruído descontado: o id de item do compositor (`{uuid}`) muda a cada rodada e
fica fora da comparação; itens de painéis atrás de outra aba, fora da janela, não contam.

O que a conta não pega e a captura mostra: as linhas ficam mais altas (Open Sans tem mais entrelinha), então diálogos
de tamanho fixo mostram menos conteúdo antes da rolagem (Opções > Geral: a última linha, "Enable project's embedded
Python code", sai da área visível; a página rola). O texto do gerenciador de complementos (HTML) não muda.

## A4 A coordenada

Largura de avanço dos algarismos 0 a 9 na fonte da aplicação (7,8 pt), `QFontMetricsF`:

| | 0 a 9 |
|---|---|
| ANTES (MS Shell Dlg 2, Tahoma) | 5,453125 px cada, **iguais** |
| DEPOIS (Open Sans 3.003 Regular) | 5,703125 px cada, **iguais** |

Os algarismos padrão da Open Sans têm largura fixa: qualquer coordenada com o mesmo número de dígitos tem o mesmo
texto em largura. A "mais larga" do Ceará em `EPSG:31984` é qualquer uma com Leste de 6 e Norte de 7 dígitos; a medida
usa o canto do retângulo do estado com folga (Leste 230 000 a 700 000, Norte 9 120 000 a 9 700 000), `699999,99999
9699999,99999`, e o ponto do 049p.

| | Texto | Campo (largura fixa) | Disponível | Precisa | Cabe |
|---|---|---:|---:|---:|---|
| ANTES, zoom das feições | `699999,99999  9699999,99999` | 167 | 161 | 151,53 | sim |
| DEPOIS, zoom das feições | `699999,99999  9699999,99999` | **171** | 165 | 155,84 | **sim** |
| DEPOIS, ponto do 049p | `555519,90000  9585490,50000` | 171 | 165 | 155,84 | sim |

O QGIS calcula a largura do campo pela fonte; com a Open Sans ele cresce 4 px e o texto inteiro cabe, como no `049p`
(`T3:D2-coordenada` do `Test-ThemeDefaults` verde, 156 de 165). Cursor passando pelo mapa (21 movimentos sintéticos de
canto a canto com o Ceará inteiro na tela, sem mexer no cursor do usuário): todos cabem; o campo alterna entre duas
larguras conforme o número de dígitos do texto (ANTES 94 e 101, DEPOIS 97 e 103), igual nos dois builds. Capturas:
`a4-a6-*/a4-barra-de-status-mais-larga.png`, `a4-campo-de-coordenadas.png` e `-x4.png`.

## A5 Nitidez

Ambiente: escala do Windows da bancada **125%** (o Qt vê `devicePixelRatio` 1,25, DPI lógico 96). Não mexi na
configuração do sponsor. Para medir em 100%, uma segunda rodada abre o produto com `QT_ENABLE_HIGHDPI_SCALING=0` e
`QT_FONT_DPI=96` (só no processo da rodada): o Qt registra escala 1 e DPI 96, e a fonte da aplicação sai com 10 px,
o tamanho de pixel da escala de 100%. É uma aproximação do 100% real (o resto do Windows segue em 125%).

| | 125% | 96 DPI (100%) |
|---|---|---|
| menu Projeto, 400% sem suavizar | `a4-a6-antes/a5-menu-projeto-x4.png`, `a4-a6-depois/a5-menu-projeto-x4.png` | `a5-96dpi/a5-menu-projeto-x4-antes.png`, `-depois.png` |
| Opções > Geral, 400% sem suavizar | `a4-a6-*/a5-opcoes-geral-x4.png` | `a5-96dpi/a5-opcoes-geral-x4-antes.png`, `-depois.png` |

Leitura das ampliações (visual, sem número): nos dois builds o texto sai com ClearType (franja colorida nas bordas). A
Segoe UI e a Tahoma têm hastes verticais de largura constante, alinhadas à grade; a Open Sans (hinting automático do
ttfautohint) tem hastes menos regulares e curvas mais cinzentas em 96 DPI, e por isso parece um pouco menos nítida no
tamanho de 100%. Em 125% a diferença diminui. O sponsor julga no smoke.

## A6 Pesos

Título de `QGroupBox` ("Substituir Sistema Local", Opções > Geral) e um negrito, pelo `QFontInfo` e pelo nome do
arquivo que desenha:

| | ANTES | DEPOIS |
|---|---|---|
| título do grupo (QSS do QGIS `font-weight: 600`) | peso Qt 75, Tahoma Bold | peso Qt **75**, Open Sans **Bold** (3.003) |
| negrito (`QFont::Bold`) | peso 75, Tahoma Bold | peso 75, Open Sans Bold (3.003) |
| peso 600 pedido em C++ (`QFont::DemiBold`, 63) | Tahoma Regular (a Tahoma não tem SemiBold) | Open Sans SemiBold (3.003), a face real |

O 600 do QSS **não chega ao SemiBold**: o Qt 5 converte o número do CSS dividindo por 8 (600/8 = 75 = `QFont::Bold`), nos
dois builds. O título do grupo sai do **Bold real**, não sintetizado: o desenho do título é idêntico, pixel a pixel, ao
do negrito, e diferente do da SemiBold. Quem pede `QFont::DemiBold` recebe a SemiBold real: desenho idêntico ao da
família "Open Sans SemiBold" (nome 1 do arquivo). Capturas: `a4-a6-*/a6-titulo-do-grupo-x4.png` e `a6-pesos-x4.png`
(linhas, de cima para baixo: regular, DemiBold, QSS 600, negrito e, no DEPOIS, a face SemiBold).

## A7 Conteúdo de projeto (medido, não mudado)

| Fonte padrão de | ANTES | DEPOIS |
|---|---|---|
| (i) rótulo novo de camada (`QgsPalLayerSettings`; o formulário "Rótulos individuais") | Open Sans 10 pt (o padrão do QGIS; nesta bancada desenhado pela 1.10 instalada) | **Open Sans 10 pt** (desenhado pela 3.003 embarcada) |
| (ii) rótulo novo no compositor (`QgsLayoutItemLabel`; `LayoutDesigner/defaultFont` vazio) | MS Shell Dlg 2 7,8 pt | **Open Sans 7,8 pt** |
| `QgsTextFormat()` e `QFont()` sem família | MS Shell Dlg 2 | Open Sans |

(i) não muda de família: o QGIS já usa "Open Sans" como padrão de rótulo de camada. (ii) muda: **achado para o sponsor**.
Um rótulo novo de compositor passa a gravar "Open Sans" no projeto; aberto num QGIS sem a Open Sans instalada, ele troca
de fonte (na `develop` gravava "MS Shell Dlg 2", que todo Windows tem). O mesmo vale para todo texto do QGIS que nasce
de `QgsTextFormat()` ou `QFont()` sem família. Capturas: `a3-telas/lado-16-propriedades-rotulos-simples.png` e
`lado-27-compositor-rotulo.png`; números em `dados/font-*.json` (`labelDefaults`). Nada foi corrigido.

As telas IMAN do `#059` (página inicial e Sobre, folha própria em px) mudaram de família sozinhas: MS Shell Dlg 2 para
Open Sans, nos mesmos tamanhos em px (`screens.01-pagina-inicial.homeLabelFonts`, `screens.02-sobre-iman.labelFonts`).
Nenhum texto delas corta, nos dois builds. Não foi mexido.

## A8 Guarda vista falhando

`Test-ThemeDefaults.ps1`, check novo `A8:fonte-iman` (só acréscimo; a versão do arquivo vai no detalhe):

```
develop (481614b1c8), perfil novo, 2026-11-14 09:49:
[09:49:19] A7:destaque-iman           OK
[09:49:19] A7:fundo-iman              OK
[09:49:19] A7:botoes-iman             OK
[09:49:19] A7:estilo-iman             OK
[09:49:19] A8:fonte-iman              FALHOU  {"expected":"Open Sans","family":"MS Shell Dlg 2","resolvedFamily":"MS Shell Dlg 2","resolvedStyle":"","pointSizeF":7.8,"styles":["Normal","Negrita"]}
[09:49:22] guard                      OK  "GUARD OK: ... identicos ao retrato de 2026-11-14T09:49:01 (37627 itens)"

branch (bf202202d1), perfil novo e perfil semeado, 2026-11-14 10:39:
[10:39:17] A7:destaque-iman           OK
[10:39:17] A7:fundo-iman              OK
[10:39:17] A7:botoes-iman             OK
[10:39:17] A7:estilo-iman             OK
[10:39:17] A8:fonte-iman              OK  {"expected":"Open Sans","family":"Open Sans","resolvedFamily":"Open Sans","resolvedStyle":"","pointSizeF":7.8,"fileVersion":"Version 3.003; ttfautohint (v1.8.4)", ...}
[10:39:20] tema e padroes Build/new OK
[10:39:37] A8:fonte-iman              OK  (idem)
[10:39:39] tema e padroes Build/seeded OK
```

Todos os checks do `Test-ThemeDefaults` verdes nos dois perfis da branch (`a8-guarda/result-*.json`).

## A9 Nada mais muda

| Verificação | Resultado |
|---|---|
| `Test-ThemeDefaults.ps1`, perfil novo e semeado | OK, todos os checks (A8 acima) |
| paleta inteira (`paletteAll`, 60 papéis) | idêntica à da `develop` (`theme-*.json`) |
| `T3:D2-coordenada`, `T3:D4-titulo-dock` | OK (D2: 156 de 165 px; D4: faixa de título 19 px para 14 de altura de texto, 12 na develop; `a8-guarda/result-*.json`) |
| `Test-ThemeQss.ps1` | TEMA QSS OK (14 de 14) |
| `Test-Patchset.ps1` | PATCHSET OK (26 arquivos do QGIS alterados desde `final-3_44_13`, 26 listados) |
| `Invoke-Smoke.ps1` | **smoke Build OK** na revisão `a51852b0ca` (build incremental do HEAD de código e testes, 10:43): version, providers (426 algoritmos), plugins, `native:buffer`, gui+qgz, projeto salvo, as dez `marca:*`, `controle:sobre`, dados do produto e guarda, todos OK (`smoke-build/summary.json`) |
| `Update-Notices.ps1 -Check` | em dia (153 entradas; o bloco do patchset regenerado, ver "Além do escopo") |
| guarda do QGIS oficial | OK em toda rodada de medida (ver abaixo) |
| diff do `iman_brand.h` | só a família a mais (acima) |

**Guarda:** a primeira rodada da sessão (09:47) e uma rodada de captura (09:54) falharam na guarda por mudanças nos
dados do QGIS oficial que não vieram das rodadas: às 08:54-08:56 (antes da sessão) e às 09:56 o QGIS oficial do usuário
foi aberto (perfil, `bookmarks.xml` e o cache de rede com o feed `https://feed.qgis.org/?lang=es`; o produto roda em
pt_BR e tem o feed desligado). Como o script prevê (ressalva R1: o retrato vale para uma rodada), o retrato foi tirado
de novo antes de cada rodada seguinte; todas as rodadas usadas neste laudo terminaram com a guarda OK.

## A10 Licença

- Origem: `https://github.com/googlefonts/opensans`, commit `6cbc400d4855abee59d85c4ed871d510399bce7b` (ponta do
  `main` em 2026-11-14), pasta `fonts/ttf` (estáticos; a variável fica em `fonts/variable` e não entra); URL de cada
  arquivo `https://raw.githubusercontent.com/googlefonts/opensans/<commit>/fonts/ttf/<arquivo>`. Versão (nome 5):
  `Version 3.003; ttfautohint (v1.8.4)`. Nenhum dos seis tem tabela `fvar` (estáticos).
- SHA-256 conferido na máquina (`sha256sum`), e o hash de blob do git de cada arquivo igual ao que a API do GitHub dá
  no commit:

| Arquivo | SHA-256 |
|---|---|
| `OpenSans-Regular.ttf` | `c53aceea2dcf5b4098099c0c4d0a061d17e178a049317b42a422b1a9f7f8eb59` |
| `OpenSans-Italic.ttf` | `93bc1bb6abf4e6b7c75d7131714061d5b57cc478abcabe4cb3519bb38fb917aa` |
| `OpenSans-SemiBold.ttf` | `4a413711684a9dd564ef0f1c10cb62b5d9f7eb6df2cff962f5341a6ecd5f64ae` |
| `OpenSans-SemiBoldItalic.ttf` | `c646a9aefc0e964f66487260639e375685328a6280856faea3e012c43fe9c56d` |
| `OpenSans-Bold.ttf` | `27da758f4dcac9a65abe914c13b463b42982b9909bc65713424099f4810bd1e6` |
| `OpenSans-BoldItalic.ttf` | `d672a770037104b6af45e1336b3d3c1729c8aea940f81e010f5a8a7319c29a21` |
| `OFL.txt` (e `iman/notices/licencas/open-sans-OFL.txt`) | `01cd5ffb3a528c219a86e49a814c6c53bd8a69b9a3c305dd237074ba1c811af7` |

- `THIRD_PARTY_NOTICES.md`, seção 5, "Fonte Open Sans (a fonte da interface)", e a menção na seção 1; o
  `open-sans-OFL.txt` vai para `licencas\` da instalação pelo caminho que o instalador já usa (`*.txt`).

## A11 Travessão e meia-risca

Linhas acrescentadas desde `481614b1c8` (`git diff 481614b1c8 -U0`, arquivos de texto; os PNG e TTF ficam de fora),
contadas por arquivo com este laudo incluído. Zero U+2013 em todos. U+2014 só em arquivos de evidência medida do programa:

| Arquivo | Linhas acrescentadas | U+2014 | U+2013 |
|---|---:|---:|---:|
| `iman/PATCHES.md` | 5 | 0 | 0 |
| `iman/brand/README.md` | 26 | 0 | 0 |
| `iman/brand/brand.json` | 1 | 0 | 0 |
| `iman/brand/build_brand.py` | 13 | 0 | 0 |
| `iman/brand/fonts/OFL.txt` | 88 | 0 | 0 |
| `iman/build/Invoke-FontCaptures.ps1` | 99 | 0 | 0 |
| `iman/build/Measure-FontChoice.ps1` | 77 | 0 | 0 |
| `iman/build/Test-ThemeDefaults.ps1` | 7 | 0 | 0 |
| `iman/build/smoke/font_captures.py` | 1112 | 0 | 0 |
| `iman/build/smoke/font_choice.py` | 169 | 0 | 0 |
| `iman/build/smoke/theme_facts.py` | 36 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/README.md` (este laudo) | 387 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/a8-guarda/result-branch-perfil-novo.json` | 301 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/a8-guarda/result-branch-perfil-semeado.json` | 301 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/a8-guarda/result-develop-perfil-novo-visto-falhando.json` | 292 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/a8-guarda/theme-branch-perfil-novo.json` | 267 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/a8-guarda/theme-branch-perfil-semeado.json` | 267 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/a8-guarda/theme-develop-perfil-novo-visto-falhando.json` | 258 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/escolha-antes-abertura-1.json` | 70 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/escolha-antes-abertura-2.json` | 70 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/escolha-antes-abertura-3.json` | 67 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/escolha-antes-abertura-4.json` | 54 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/escolha-depois-abertura-1.json` | 70 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/escolha-depois-abertura-2.json` | 70 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/escolha-depois-abertura-3.json` | 67 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/escolha-depois-abertura-4.json` | 54 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/font-antes-96dpi.json` | 17300 | 14 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/font-antes.json` | 17209 | 14 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/font-depois-96dpi.json` | 17337 | 14 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/font-depois.json` | 17337 | 14 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/night-antes-abertura-1.json` | 56 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/night-antes-abertura-2.json` | 54 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/night-depois-abertura-1.json` | 56 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/night-depois-abertura-2.json` | 54 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/result-font-antes-96dpi.json` | 22 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/result-font-antes.json` | 22 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/result-font-depois-96dpi.json` | 29 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/dados/result-font-depois.json` | 29 | 0 | 0 |
| `iman/docs/verify/067-fonte-open-sans/smoke-build/summary.json` | 252 | 3 | 0 |
| `iman/notices/THIRD_PARTY_NOTICES.md` | 28 | 0 | 0 |
| `iman/notices/licencas/open-sans-OFL.txt` | 88 | 0 | 0 |
| `src/app/CMakeLists.txt` | 2 | 0 | 0 |
| `src/app/iman/imanfont.cpp` | 106 | 0 | 0 |
| `src/app/iman/imanfont.h` | 43 | 0 | 0 |
| `src/app/iman/imanfonts.qrc` | 12 | 0 | 0 |
| `src/app/main.cpp` | 4 | 0 | 0 |

Os 14 U+2014 de cada `font.json` e os 3 do `smoke-build/summary.json` são títulos de janela que o QGIS monta, todos
medidos e não escritos pela Crew:

- a janela principal (`qgisapp.cpp:604`, `QChar( 0x2014 )` entre o projeto e o produto, a flag aberta do `D-IMAN-034`);
- os diálogos de opções e as Propriedades da camada (`qgsoptionsdialogbase.cpp:754`, `QChar( 0x2014 )` entre o título e a
  página);
- a tabela de atributos (`qgsattributetabledialog.cpp:458`, no texto traduzido do QGIS) e a calculadora de campo
  (`src/gui/vector/qgsfieldcalculator.cpp:167`, idem).

## Lacunas declaradas

- **VM limpa (BL-7):** não rodou. Esta fatia não gera instalador. A prova de que a fonte vale sem a Open Sans instalada
  é o arquivo desenhado (3.003, embarcado) nesta bancada, que tem a 1.10 instalada; numa máquina sem ela, falta ver.
- **A5 em 100% real:** medido por aproximação (escala do Qt desligada e DPI de fonte 96), sem mudar a escala do Windows.
- **Nitidez:** julgamento visual das ampliações, sem métrica.
- **Rodadas que caíram por bug do script de medida** (não do produto): duas quedas do QGIS da `develop` ao auditar a
  árvore das Opções (o `internalPointer` de um índice de proxy, no Python) e duas no Sobre (um `mapTo` para um widget que
  não era ancestral). Os relatórios de crash foram tirados da pasta do produto e guardados nas pastas das rodadas; os
  diálogos de crash dessas rodadas foram fechados pelo PID. O script foi corrigido; as rodadas do laudo são posteriores.

## Além do escopo

- `Update-Notices.ps1` regenerou o bloco do patchset do `THIRD_PARTY_NOTICES.md`, que estava sem os arquivos das
  fatias 059 a 066 (o `-Check` acusava desatualizado antes desta fatia).
- O tamanho por classe (decisão do sponsor na sessão, acima).

## Arquivos

- `a3-telas/`: as 31 telas lado a lado, ANTES à esquerda.
- `a3-recortes/`: o texto novo cortado, nas duas capturas.
- `a4-a6-antes/`, `a4-a6-depois/`: coordenada, ampliações do A5 em 125% e pesos.
- `a5-96dpi/`: ampliações em 96 DPI.
- `a2-escolha/`: Opções > Geral em cada abertura da escolha do usuário.
- `a8-guarda/`: `result.json` e `theme.json` do `Test-ThemeDefaults` (develop visto falhando; branch perfil novo e
  semeado).
- `variante-literal/`: o menu Projeto no ANTES, na primeira versão (`setFont` sem classe) e no final.
- `dados/`: os `font.json` das quatro rodadas de captura, os `choice.json` de cada abertura e os `result.json`.
- `smoke-build/`: o resumo do smoke.
- `SHA256SUMS.txt`: o hash de cada arquivo desta pasta.

Caminhos da pasta pessoal nos JSON trocados por `%USERPROFILE%`.
