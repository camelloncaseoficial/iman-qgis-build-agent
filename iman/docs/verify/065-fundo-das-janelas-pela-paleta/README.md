# Laudo 065: o fundo das janelas passa ao cinza esverdeado IMAN, pela paleta do Qt

Briefing `qgis-build #065` (D-IMAN-040, emendas de 2026-11-12 e 2026-11-13, com o adendo da segunda mudança;
D-IMAN-026; D-IMAN-025; D-IMAN-034). Branch `feat/065-fundo-das-janelas-pela-paleta`, nascida de `develop`
`7531597800` (merge do PR #11, `#064`). Máquina: Windows 11 Pro em espanhol, tela em escala 125%. Medições de
2026-11-13.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (lido no código, não
medido, com o motivo), **N/E** (não executado).

**Builds medidos:**
- ANTES: `7531597800`, a `develop` intacta, compilada no começo da sessão (`QGIS code revision 7531597800`).
- DEPOIS: `269aa0f2cd` (`QGIS code revision` do binário, `smoke-build/summary.json`).

Os commits depois do DEPOIS mudam só este laudo e a memória da Crew.

**Como o sponsor abre:** `pwsh -NoProfile -File iman/build/Start-ImanTerra.ps1` (o build desta branch, perfil novo).
Nenhum instalador nesta fatia. Nos textos da evidência, o caminho do perfil do Windows virou `%USERPROFILE%`. As
capturas da janela escondem o painel Navegador.

## Veredito

**A1 a A9 medidos; o gate roda depois do PR aberto (resultado no `/deliver`).**

- Sem tema escolhido, o papel `Window` é `#EBEEE8` (token `bg`) nos grupos `Active`, `Inactive` e `Disabled`. É o
  único papel que mudou: 3 de 60 linhas da paleta inteira (A1). A folha de estilo da aplicação segue com tamanho 0, e
  o destaque do `#064` está igual.
- Das 12 regiões de janela do A2, 10 ficam em `#EBEEE8` e uma em `#E8EBE5` (as Opções, a 3 níveis). A barra de
  ferramentas sai no degradê do Fusion a partir do novo `Window`. Uma região não muda: o painel da aba Log do
  Processamento, que o Fusion pinta com o papel `Button` (achado 1).
- As regiões de `Base` ficam brancas, exceto a caixa de lista aberta, que segue o `Window` (achado 2).
- Contraste WCAG do texto sobre o fundo: queda de 2,7% (normal) e de 2,6% (desabilitado), abaixo dos 10% (A4).
- As 13 setas: o mesmo rect e a mesma tinta do build da `develop`. As abas do Processamento: mesmos tamanhos e mesmo
  texto, com o contorno levemente esverdeado (A3, achado 3).
- O tema de fábrica escolhido pelo usuário fica intacto, igual ao QGIS oficial (A5).
- Página inicial da 059: igual. "Sobre": o fundo do diálogo passou a `#EBEEE8` (A6).
- Check novo `A7:fundo-iman`: visto falhando na `develop`, verde nesta branch. `iman_brand.h` idêntico ao da
  `develop`. Nada mais regride, e o QGIS oficial ficou intocado (guarda OK em toda rodada).

Nenhum STOP disparou (ver "STOPs"). Nenhum `setStyleSheet` novo, nenhuma regra QSS nova, nenhum papel além do
`Window`. Arquivo do QGIS tocado: só o ponto de chamada que já existia (`src/app/main.cpp`), no `iman/PATCHES.md`.
Testes existentes alterados: só acréscimo (`Test-ThemeDefaults.ps1`, check `A7:fundo-iman`; `theme_facts.py`, o
despejo da paleta inteira).

## O que mudou

| Onde | O quê |
|---|---|
| `src/app/iman/imanpalette.{h,cpp}` | `ImanPalette::applyHighlight` virou `ImanPalette::apply`. Além do destaque do `#064` (sem mudança), aplica `Window` = `IMAN_COLOR_BG` nos grupos `Active`, `Inactive` e `Disabled`, no mesmo `QApplication::setPalette`, com a mesma condição (só o tema `default`). Nenhum hex no C++. |
| `src/app/main.cpp` | A mesma linha de chamada, com o nome novo (`ImanPalette::apply( theme )`), e o comentário dela. |
| `iman/PATCHES.md` | As linhas do `main.cpp` e do `imanpalette` com o nome novo e a fatia 065. O parágrafo "Cores" já cobria a mudança e ficou como estava. |
| `iman/brand/README.md` | Quem usa o token `bg`: a página inicial (pela folha própria dela) e, desde a 065, o fundo das janelas pela paleta do Qt. |
| `iman/build/Test-ThemeDefaults.ps1` | Acréscimo do check `A7:fundo-iman` (o esperado vem de `palette.bg` do `brand.json`) e de uma frase no cabeçalho. |
| `iman/build/smoke/theme_facts.py` | Acréscimo da chave `paletteAll`: os 20 papéis dos três grupos, em `#AARRGGBB`. A chave `palette` do `#064` ficou. |
| `iman/build/Invoke-WindowCaptures.ps1`, `smoke/window_regions.py` (novos) | A2: o fundo e as bordas por região, medidos na captura. |
| `iman/build/Measure-PaletteContrast.ps1` (novo) | A4: o contraste WCAG do texto normal e do desabilitado sobre o fundo, nas cores da paleta, ANTES e DEPOIS. |
| `iman/build/Measure-HighlightCases.ps1`, `smoke/highlight_cases.py` | Acréscimo, para o A5: o `Window` por grupo e o fundo desenhado num diálogo de teste, em cada medida. |

**Forma (escolha da Crew, item 1): uma única função, `apply`.** Motivos:
- O ponto de chamada segue com uma linha, como o briefing pede, sem uma segunda chamada no `main.cpp`.
- Um único `setPalette` no arranque, em vez de dois seguidos: um evento de troca de paleta a menos para cada widget,
  e a ordem entre as duas mudanças não importa.
- A condição (só o tema `default`) fica num lugar só. A próxima mudança de paleta entra no mesmo lugar.

Custo: o nome mudou (`applyHighlight` para `apply`), e o `PATCHES.md` acompanha.

## A1: só o `Window` mudou (medido)

`Test-ThemeDefaults.ps1 -ProfileState New`, perfil novo, nos dois builds; o `theme_facts.py` despeja a paleta inteira
de `qApp->palette()` (chave `paletteAll`). O diff (`bateria/a1-paleta-diff.txt`):

```
- Active Window #FFF0F0F0
+ Active Window #FFEBEEE8
- Inactive Window #FFF0F0F0
+ Inactive Window #FFEBEEE8
- Disabled Window #FFF0F0F0
+ Disabled Window #FFEBEEE8

papeis diferentes: 3 de 60 (3 grupos x 20 papeis)
```

No DEPOIS, tema `default` e folha de tamanho 0 (`T1:tema-padrao` OK). O destaque do `#064` está igual
(`A7:destaque-iman` OK nos dois builds, com os mesmos valores). Evidência: `tema-padrao/`.

## A2: o fundo por região (medido)

`Invoke-WindowCaptures.ps1`, perfil novo, janela maximizada, nos dois builds. A cor do fundo é a média da faixa em
torno da cor mais comum da área, como no `#064` (o Fusion pinta barras e títulos em degradê). As listas, árvores,
tabelas e campos de dentro de cada área ficam de fora, porque são do papel `Base`. A borda é o pixel mais escuro da
borda esquerda do campo ou do quadro, na altura do meio. Tolerância: 4 níveis por canal.

| Região | Papel esperado | Fundo ANTES | Fundo DEPOIS | Diferença do esperado | Borda do campo ANTES / DEPOIS | Borda do quadro ANTES / DEPOIS | Resultado |
|---|---|---|---|---|---|---|---|
| Janela: barra de menus (`menuBar`) | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | - | - | `#EBEEE8` |
| Janela: barra de ferramentas (`toolBar`) | `Window` | `#F6F6F6` | `#F0F2ED` | 5 | - | - | degradê do `Window` (ver abaixo) |
| Janela: barra de status (`statusBar`) | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | `#ABABAB` / `#A8AAA6` | - | `#EBEEE8` |
| Camadas: título do painel (`layersTitle`) | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | - | - | `#EBEEE8` |
| Camadas: área em volta da árvore (`layersPanel`) | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | - | `#B9B9B9` / `#B5B8B3` | `#EBEEE8` |
| Propriedades da camada: página Simbologia | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | `#ABABAB` / `#A8AAA6` | `#B9B9B9` / `#B5B8B3` | `#EBEEE8` |
| Propriedades da camada: o diálogo | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | - | - | `#EBEEE8` |
| Opções: página Geral | `Window` | `#EDEDED` | `#E8EBE5` | 3 | `#ABABAB` / `#A8AAA6` | `#D8D8D8` / `#D4D6D2` | dentro da tolerância |
| Algoritmo: aba Parâmetros | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | `#ABABAB` / `#A8AAA6` | - | `#EBEEE8` |
| Algoritmo: aba Log (em volta do texto) | `Window` | `#FCFCFC` | `#FCFCFC` | 20 | - | `#B9B9B9` / `#B5B8B3` | **não muda** (achado 1) |
| Algoritmo: o diálogo | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | - | - | `#EBEEE8` |
| Tabela de atributos: a janela, sem a tabela | `Window` | `#F0F0F0` | `#EBEEE8` | 0 | - | - | `#EBEEE8` |
| Menu aberto | `Base` | `#FFFFFF` | `#FFFFFF` | 0 | - | - | branco |
| Caixa de lista aberta | `Base` | `#F0F0F0` | `#EBEEE8` | 23 | - | - | **segue o `Window`** (achado 2) |
| Campo de texto (`leText` do algoritmo) | `Base` | `#FFFFFF` | `#FFFFFF` | 0 | `#ABABAB` / `#A8AAA6` | - | branco |
| Tabela de atributos | `Base` | `#FFFFFF` | `#FFFFFF` | 0 | - | - | branco |
| Algoritmo: o texto do Log | `Base` | `#FFFFFF` | `#FFFFFF` | 0 | - | - | branco |
| Propriedades da camada: lista lateral | própria do QGIS | `#5D5D5D` | `#5C5D5C` | - | - | - | só medida (ver abaixo) |
| Opções: árvore lateral | própria do QGIS | `#5D5D5D` | `#5C5D5C` | - | - | - | só medida (ver abaixo) |

Leitura:
- **Barra de ferramentas:** o Fusion pinta um degradê que clareia a partir do `Window`. No ANTES, a média da faixa
  já ficava 6 níveis acima do `Window` (`#F6F6F6` sobre `#F0F0F0`); no DEPOIS fica 5 acima (`#F0F2ED` sobre
  `#EBEEE8`). É "o degradê dele" do critério; a régua de 4 níveis do roteiro a marca como fora.
- **Opções, página Geral:** o QGIS desenha a página com um tom um pouco mais escuro que o `Window`, nos dois builds
  (`#EDEDED` sobre `#F0F0F0`; `#E8EBE5` sobre `#EBEEE8`).
- **Bordas (hipótese `V.4`, confirmada):** o contorno de campos e quadros é uma cor derivada do `Window`, mais
  escura. Com o `Window` novo, as bordas ficam levemente esverdeadas: `#ABABAB` para `#A8AAA6` nos campos, `#B9B9B9`
  para `#B5B8B3` nas listas e árvores.
- **Listas laterais das Propriedades e das Opções:**
  - **De onde vem a cor:** a folha do próprio QGIS (`src/app/qgisappstylesheet.cpp`, linhas 74 a 106) pinta essas
    listas de cinza escuro nos dois builds. O `mOptionsListFrame` é `rgba(69, 69, 69, 220)`, semitransparente.
  - **A mudança de um nível** (`#5D5D5D` para `#5C5D5C`) vem do `Window` novo, visto através da transparência.
  - **O item selecionado da lista** usa `palette(window)` na mesma folha, então passa a `#EBEEE8`, igual à página ao
    lado. Isso foi lido no código e é visível nas capturas `a2-3` e `a2-4`.
  - Não é `Base` nem região de janela: só medida, sem veredito.
- **Hipóteses do briefing:**
  - **Confirmada:** barra de menus, barras de ferramentas e títulos de painel seguem o `Window`, com degradê na barra
    de ferramentas.
  - **Confirmada:** o menu aberto segue branco.
  - **Não confirmada:** a caixa de lista aberta segue o `Window` (achado 2).

Capturas: `fundo-antes-7531597800/` e `fundo-depois-269aa0f2cd/` (`a2-1` a `a2-7`, com `window.json` e
`result.json`).

## A3: os controles do Qt não mudam (medido)

`Invoke-ArrowCaptures.ps1` nos dois builds. Comparação (`bateria/a3-setas-comparacao.txt`):

| Controle | Rect e tinta | Fundo em volta ANTES / DEPOIS |
|---|---|---|
| Botão com menu (seleção) | iguais | `#F7F7F7` / `#EEF1EB` (a barra de ferramentas, que segue o `Window`) |
| Árvore do painel Camadas (2 setas) | iguais | `#FFFFFF` / `#FFFFFF` |
| Barra de rolagem (2 setas) | iguais | `#FBFBFB` / `#FBFBFB` |
| Árvore da caixa de ferramentas (5 setas) | iguais | `#FFFFFF` / `#FFFFFF` |
| Caixa de lista | igual | `#FCFCFC` / `#FCFCFC` |
| Caixa de número (2 setas) | iguais | `#FCFCFC` e `#F0F0F0` / iguais |
| Abas do Processamento | tamanhos e larguras de texto iguais; tinta da faixa 892 para 893 | `#FCFCFC` / `#FCFCFC` |

As 13 setas têm o mesmo rect e a mesma tinta. As abas do Processamento não são seta, e a medida delas conta a tinta da
faixa inteira das abas: subiu 1 pixel em 4320. Localizado pixel a pixel (`bateria/a3-setas-comparacao.txt`, fim):
- Mudaram só o fundo (`#F0F0F0` para `#EBEEE8`) e os cinzas do contorno e do degradê das abas, agora cinza
  esverdeado, com no máximo 8 níveis por canal.
- Nenhum pixel de letra mudou (0 pixels escuros).
- É a hipótese `V.4` do briefing: o contorno das abas é derivado do `Window`. Um pixel de contorno passou do limiar da
  contagem de tinta. Não é seta que some nem que muda de rect ou de tinta, por isso não tratei como STOP; ver
  achado 3.

## A4: leitura (medido)

`Measure-PaletteContrast.ps1` sobre a paleta dos dois builds (`bateria/a4-contraste.txt`), fórmula WCAG 2.x:

| Texto | ANTES | DEPOIS | Variação |
|---|---|---|---|
| Normal: `WindowText` `#000000` sobre `Window` | 18,43:1 (sobre `#F0F0F0`) | 17,93:1 (sobre `#EBEEE8`) | -2,7% |
| Desabilitado: `Disabled WindowText` `#787878` sobre `Disabled Window` | 3,87:1 (sobre `#F0F0F0`) | 3,77:1 (sobre `#EBEEE8`) | -2,6% |

Nenhuma queda passa de 10%. Nota: o texto desabilitado já ficava abaixo de 4,5:1 no ANTES; é a cor que o estilo do
Qt entrega no Windows, e esta fatia não mexe nela.

## A5: escolha do usuário (medido)

`Measure-HighlightCases.ps1`, perfil descartável, com a medida do `Window` (acréscimo desta fatia). Evidência:
`casos/`.

| Caso | Build desta branch: tema / estilo / `Window` (3 grupos) / fundo desenhado | QGIS oficial | Esperado | Resultado |
|---|---|---|---|---|
| (a) perfil novo | `default` (folha 0) / Fusion / `#EBEEE8` / `#EBEEE8` | (não pedido) | `#EBEEE8` | **cumprido** |
| (b) `Night Mapping` em Opções, reabre | `Night Mapping` (folha 37487) / `#535353` / `#323232` | `Night Mapping` (folha 37327) / `#535353` / `#323232` | tema de fábrica intacto | **cumprido**: cores iguais às do oficial; a paleta IMAN não entra |
| (d) estilo `windowsvista` em Opções, reabre | `default` / `QWindowsVistaStyle` / `#EBEEE8` / `#EBEEE8` | (não pedido) | relatar como for | **relatado**: o `windowsvista` pinta o fundo com o `Window` da paleta, então o fundo IMAN vale nele. O destaque segue `#CCE8FF`, como medido no `#064` |

No caso (b), o tamanho da folha difere do oficial em 160 caracteres, igual ao `#064` (`casos/oficial-b` e
`casos/build-b` do laudo 064). Isso vem de antes desta fatia e não muda nenhuma cor medida.

## A6: as telas do `#059` (medido)

`Invoke-HomeCaptures.ps1` nos dois builds; comparação em `bateria/a6-telas-059-comparacao.txt`.

- **Página inicial: igual.** A captura inteira muda porque a janela principal em volta (barras, painel Camadas)
  passou a `#EBEEE8`. Dentro da área da página, no perfil sem recentes (`01`), os 1.116.734 pixels `#EBEEE8` do ANTES
  continuam iguais. Só mudou o selo de versão (o commit, `x 1666-1862, y 208-243`). Com recentes (`02`, `03`), também
  mudam os caminhos dos projetos recentes, que levam o carimbo de hora da pasta da rodada. É dado do teste, não da
  tela.
- **"Sobre o IMAN Terra":** o fundo do diálogo passou de `#F0F0F0` a `#EBEEE8` (301.379 pixels). A caixa de aviso
  (`#E5E8E2` para `#E4E8E0`), as bordas (`#C4C4C4` para `#C1C3C0`, `#B9B9B9` para `#B5B8B3`) e o contorno suavizado
  do logo mudam 1 a 4 níveis, porque se misturam ao fundo novo. A folha própria do Sobre não foi tocada; as cores
  dela que não se misturam ao fundo estão iguais.
- **"Sobre o QGIS" (`QgsAbout`):** o fundo do diálogo passou a `#EBEEE8`; a lista lateral escura do QGIS vai de
  `#5D5D5D` a `#5C5D5C`, pelo mesmo motivo das Opções.

Capturas lado a lado: `telas-059-antes-7531597800/` e `telas-059-depois-269aa0f2cd/`.

## A7: a guarda do fundo, vista falhando (medido)

`Test-ThemeDefaults.ps1`, check novo `A7:fundo-iman` (o esperado é `#FF` + `palette.bg` do `brand.json`, nos três
grupos). Saídas (`bateria/a7-guarda-fundo.txt`):

```
develop 7531597800, perfil novo:
A7:destaque-iman  OK      {"Active":{"Highlight":"#1E7A4D",...},"Inactive":{...}}
A7:fundo-iman     FALHOU  {"expected":"#FFEBEEE8","Window":{"Active":"#FFF0F0F0","Inactive":"#FFF0F0F0","Disabled":"#FFF0F0F0"}}
tema e padroes Build/new FALHOU

esta branch 269aa0f2cd, perfil novo e perfil semeado:
A7:destaque-iman  OK
A7:fundo-iman     OK      {"expected":"#FFEBEEE8","Window":{"Active":"#FFEBEEE8","Inactive":"#FFEBEEE8","Disabled":"#FFEBEEE8"}}
tema e padroes Build/new OK
tema e padroes Build/seeded OK
```

Na `develop`, só o `A7:fundo-iman` falha; os demais checks passam. O `A7:destaque-iman` do `#064` passa nos dois.

## A8: nada mais muda (medido)

| Verificação | Resultado | Evidência |
|---|---|---|
| `Invoke-Smoke.ps1` | 19 de 19 OK, revisão `269aa0f2cd` | `smoke-build/summary.json` |
| `Test-Patchset.ps1` | OK, 21 de 21 | `bateria/patchset.txt` |
| `Test-ThemeQss.ps1` | 14 de 14 | `bateria/tema-qss.txt` |
| `Test-ThemeDefaults.ps1` | OK no perfil novo e no semeado | `tema-padrao/depois-perfil-*` |
| `Invoke-HighlightCaptures.ps1` (destaque do `#064`) | as seis regiões em `#1E7A4D`, com texto | `destaque-depois-269aa0f2cd/` |
| Guarda do QGIS oficial | OK em toda rodada (ANTES, DEPOIS, casos e o controle no oficial) | o `result.json` de cada rodada |
| `iman_brand.h` | idêntico ao da `develop` (sha256 `c4b8f57d...da661` nos dois), 18 `IMAN_COLOR_*`, nenhum token novo; o build também diz "cabecalho sem mudanca" | `bateria/a8-cabecalho.txt` |

## A9: travessão e meia-risca (medido)

Contados por arquivo, nas linhas acrescentadas por esta branch, este laudo incluído. Zero U+2013 em todos os
arquivos. Zero U+2014 em código, comentário, roteiro, documento e memória.

Na evidência medida do programa ficam U+2014 de títulos de janela que o próprio QGIS monta. Ficam como medidos:
- **3 U+2014 em `smoke-build/summary.json`:** o título da janela principal (`src/app/qgisapp.cpp:604`), a flag
  aberta citada no briefing.
- **1 U+2014 em cada `window.json` e `result.json` de `fundo-antes-7531597800/` e `fundo-depois-269aa0f2cd/`:** o
  título do diálogo de Propriedades da camada ("Layer Properties - points [U+2014] Simbologia"). O
  `QgsOptionsDialogBase` o monta com `QChar( 0x2014 )` (`src/gui/qgsoptionsdialogbase.cpp:754`). É a mesma família
  da flag acima, em outro arquivo do QGIS.

## STOPs

- **`P0.10`:** respeitado; só houve acréscimos aos testes existentes.
- **Seta ou controle que muda:** nenhuma seta mudou. As abas do Processamento: mesmos tamanhos e mesmo texto, com 1
  pixel de contorno a mais na contagem de tinta, pelo contorno derivado do `Window` previsto na `V.4` (achado 3).
- **Outro papel:**
  - Nenhum papel além do `Window` foi mexido.
  - Duas regiões não ficam como o critério espera: a aba Log (`Button`) e a caixa de lista aberta (`Window`). As duas
    estão relatadas com a medida e a captura, sem correção.
  - Acertar a aba Log exigiria mexer no `Button`, o caso deste STOP: não mexi.
- **QSS:** nenhum `setStyleSheet` novo, nenhuma regra nova.
- **Arquivo do QGIS:** só o ponto de chamada que já existia (`main.cpp`).
- **Cor fora da paleta:** nenhum hex novo no C++ nem no `brand.json`.
- **Resto da marca:** smoke, guarda, `T*` e o destaque iguais.
- **Perfil do usuário:** nenhuma escrita de chave por código.
- **Instalação:** nada instalado, nenhum instalador gerado; o QGIS oficial só foi lido (caso b de controle).

## Achados para o sponsor

1. **A aba Log do diálogo de algoritmo não muda (`#FCFCFC`).**
   - **Medido:** o painel das abas (`QTabWidget`) não segue o `Window`. O `Window` mudou e o painel ficou `#FCFCFC`
     nos dois builds. A aba Parâmetros parece `#EBEEE8` porque a área de rolagem dela cobre o painel com o `Window`.
   - **Relatado** (função `getTabFrameColor` do Fusion do Qt 5.15, citada de memória; a fonte do Qt não está nesta
     máquina): o Fusion tira essa cor do papel `Button`, clareada. Bate com a medida: `#F0F0F0` clareado dá `#FCFCFC`.
   - **Efeito:** os painéis de aba do produto ficam um pouco mais claros que o fundo da janela.
   - **Para acertar**, seria preciso mexer no `Button`: mudança de outro papel, fatia própria se o sponsor quiser.
2. **A caixa de lista aberta segue o `Window`, não fica branca.**
   - **Medido:** a lista aberta de um `QComboBox` sai com o fundo do papel `Window`. Já era `#F0F0F0` (o `Window` do
     ANTES) e virou `#EBEEE8`. O mecanismo no Qt não foi lido; a medida mostra que é o `Window`, não o `Base`.
   - O menu aberto da barra de menus segue branco.
   - A hipótese do briefing ("seguem brancos, `Base`") não se confirmou para a caixa de lista.
   - O destaque verde do item corrente segue igual (A8).
3. **Bordas e contornos levemente esverdeados.** Campos, quadros, listas e abas têm o contorno derivado do `Window`
   (`#ABABAB` para `#A8AAA6`, `#B9B9B9` para `#B5B8B3`), no máximo 8 níveis por canal. É a hipótese `V.4`, medida. Na
   medida das abas do A3 isso deu 1 pixel a mais de tinta, sem mudança de forma nem de texto.
4. **O "Sobre" ganha o fundo `#EBEEE8`.** Ver A6; a folha própria dele não foi tocada.

## Teto honesto (`V.3`)

A paleta pinta o que o estilo desenha com o `Window`. Não pinta:
- a tela do mapa (cor do projeto, branca);
- a barra de título do Windows;
- widget com cor ou folha própria do QGIS (as listas laterais escuras das Propriedades, das Opções e do "Sobre o
  QGIS"; a página inicial e o Sobre, que já pintam o `bg` pela folha deles);
- o que o Fusion deriva de outro papel (o painel das abas, achado 1).

Com o `windowsvista` escolhido em Opções, o fundo IMAN vale (caso d), mas o destaque não (medido no `#064`).

## Evidência

| Pasta ou arquivo | Conteúdo |
|---|---|
| `fundo-antes-7531597800/`, `fundo-depois-269aa0f2cd/` | A2: capturas por região, `window.json` (fatos) e `result.json` (veredito) |
| `tema-padrao/visto-falhando-develop-7531597800/`, `tema-padrao/depois-perfil-novo/`, `tema-padrao/depois-perfil-semeado/` | A1 e A7: `theme.json` (com `paletteAll`) e `result.json` |
| `setas-antes-7531597800/`, `setas-depois-269aa0f2cd/` | A3: capturas e `arrows.json` |
| `telas-059-antes-7531597800/`, `telas-059-depois-269aa0f2cd/` | A6: início, Sobre e Sobre o QGIS |
| `destaque-depois-269aa0f2cd/` | A8: o destaque do `#064` nas seis regiões |
| `casos/build-a`, `casos/build-b`, `casos/build-d`, `casos/oficial-b` | A5 |
| `smoke-build/summary.json` | A8: o smoke do build DEPOIS |
| `bateria/` | `a1-paleta-diff.txt`, `a3-setas-comparacao.txt`, `a4-contraste.txt`, `a6-telas-059-comparacao.txt`, `a7-guarda-fundo.txt`, `a8-cabecalho.txt`, `patchset.txt`, `tema-qss.txt` |
| `SHA256SUMS.txt` | sha256 de cada arquivo desta pasta, exceto ele mesmo |

## Como reproduzir

```
pwsh -NoProfile -File iman/build/Invoke-ImanBuild.ps1 -Offline -SkipTools
pwsh -NoProfile -File iman/build/Test-ThemeDefaults.ps1 -ProfileState New
pwsh -NoProfile -File iman/build/Invoke-WindowCaptures.ps1
pwsh -NoProfile -File iman/build/Invoke-ArrowCaptures.ps1
pwsh -NoProfile -File iman/build/Invoke-HomeCaptures.ps1
pwsh -NoProfile -File iman/build/Measure-HighlightCases.ps1 -Case b
pwsh -NoProfile -File iman/build/Measure-PaletteContrast.ps1 -Before <theme.json da develop> -After <theme.json desta branch>
```

Rodar cada um no build da `develop` e no desta branch e comparar as saídas.
