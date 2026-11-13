# Laudo 064: o destaque volta verde IMAN, pela paleta do Qt e não por QSS

Briefing `qgis-build #064` (D-IMAN-040, emendas de 2026-11-12 e 2026-11-13; D-IMAN-026; D-IMAN-025; D-IMAN-034).
Branch `feat/064-destaque-iman-pela-paleta`, nascida de `develop` `5ad96bf92d` (merge do PR #10). Máquina: Windows 11
Pro em espanhol, tela em escala 125%. Medições de 2026-11-13.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (lido no código, não
medido, com o motivo), **N/E** (não executado).

**Builds medidos:**
- ANTES: `5ad96bf92d`, a `develop` intacta, compilada no começo da sessão.
- DEPOIS: `90be6f900f` (`QGIS code revision` do binário).

Os commits depois do DEPOIS mudam só os roteiros de medição (`b6e8450639`), este laudo e a memória.

**Como o sponsor abre:** `pwsh -NoProfile -File iman/build/Start-ImanTerra.ps1` (o build desta branch, perfil novo).
Nenhum instalador nesta fatia. Nos textos da evidência, o caminho do perfil do Windows virou `%USERPROFILE%`. As
capturas da janela escondem o painel Navegador.

## Veredito

**A1 a A8 medidos; o gate roda depois do PR aberto (resultado no `/deliver`).**

- Sem tema escolhido, o destaque é `#1E7A4D` com texto `#FFFFFF`, pela paleta do Qt, nos grupos `Active` e `Inactive`.
  A folha de estilo da aplicação segue com tamanho 0.
- As seis regiões do A2 ficam verdes, com texto branco legível.
- Setas e controles: as mesmas medidas do build da `develop`.
- O tema de fábrica escolhido pelo usuário fica intacto.
- `iman_brand.h`: idêntico ao da `develop`.
- Nada mais regride. O QGIS oficial ficou intocado (guarda OK em toda rodada).

Nenhum STOP disparou. Nenhum `setStyleSheet` novo e nenhuma regra QSS nova. Arquivos do QGIS tocados: só o ponto de
chamada (`src/app/main.cpp`) e o `src/app/CMakeLists.txt`, os dois no `iman/PATCHES.md`. Testes existentes alterados:
só acréscimo (`Test-ThemeDefaults.ps1`, check `A7`; `theme_facts.py`, os fatos da paleta).

Achados que o sponsor precisa ver estão no fim: o caso (d) do A4, os contornos de foco e o botão padrão do Sobre.

## O que mudou

| Onde | O quê |
|---|---|
| `iman/docs/verify/059-.../README.md`, `SHA256SUMS.txt` (item 0, commit `fbbe0a7116`) | O patch de 2026-11-12: as citações com travessão viraram `[travessão]`, e a seção T4 diz o que foi medido. Só o hash do README mudou no `SHA256SUMS.txt`, gerado do mesmo jeito. |
| `iman/brand/brand.json` | Chave nova `palette`: os 18 tokens do cabeçalho do `style.qss`, mesmos nomes e valores, na mesma ordem. |
| `iman/brand/build_brand.py` | `brand_palette()` lê a paleta do `brand.json`, valida cada token e cada `#RRGGBB` e falha alto se faltar token usado pelo C++. Os tokens usados vêm de uma varredura das `IMAN_COLOR_*` em `src/app/iman`, sem lista escrita à mão. O `style.qss` deixou de ser lido. |
| `iman/brand/theme/IMAN Terra/style.qss` | Só o comentário do cabeçalho: a fonte da paleta é o `brand.json` desde a 064. Regras e paleta sem mudança (`Test-ThemeQss.ps1` 14 de 14). |
| `src/app/iman/imanpalette.{h,cpp}` (novos) | `ImanPalette::applyHighlight( uiTheme )`: com o tema `default` (vazio, `default` ou tema inexistente, a regra do `QgsApplication::setUITheme`), aplica `Highlight` = `IMAN_COLOR_BRAND_2` e `HighlightedText` = `IMAN_COLOR_PANEL` nos grupos `Active` e `Inactive`, por `QApplication::setPalette`. Nenhum hex no C++. Exportada do `qgis_app` (`APP_EXPORT`), porque o `main.cpp` vai no executável. |
| `src/app/main.cpp` | O include e uma chamada, logo depois do `QApplication::setStyle` do arranque (que repõe a paleta do estilo). |
| `src/app/CMakeLists.txt` | O `imanpalette.cpp` no `qgis_app`. |
| `iman/PATCHES.md` | `main.cpp` (novo), `CMakeLists.txt` (linha atualizada), os dois arquivos novos e um parágrafo "Cores". |
| `iman/brand/README.md` | Onde mora a paleta e quem a usa. |
| `iman/build/Test-ThemeDefaults.ps1` | Acréscimo do check `A7:destaque-iman`. |
| `iman/build/smoke/theme_facts.py` | Acréscimo dos fatos da paleta (no tema de partida e em cada troca do `T9`). |
| `iman/build/Invoke-HighlightCaptures.ps1`, `smoke/highlight_regions.py` (novos) | A2: o destaque por região, medido na captura. |
| `iman/build/Measure-HighlightCases.ps1`, `smoke/highlight_cases.py` (novos) | A4: os quatro casos, pela janela de Opções, como o usuário faz. |

**A chave `palette` (escolha da Crew, item 1):**
- Objeto `token -> "#RRGGBB"`, com os nomes do D-IMAN-026 como estão no cabeçalho do `style.qss` e no design system
  da distro (`brand-2`, `text-muted`).
- Assim o nome que o designer usa é o mesmo do arquivo, e a macro sai dele por regra fixa (`brand-2` vira
  `IMAN_COLOR_BRAND_2`).
- Um objeto (e não uma lista) não deixa haver token repetido.
- A ordem é a do cabeçalho, para ler os dois lado a lado.

## A1 O destaque no build, perfil novo (medido)

`tema-padrao/depois-perfil-novo/result.json` (`Test-ThemeDefaults.ps1 -Target Build -ProfileState New`, build
`90be6f900f`):

```
T1:tema-padrao             OK  {"themeName":"default","styleSheetLength":0,"qtStyle":"QgsAppStyle","qtStyleBase":"QFusionStyle","settingUITheme":null,"settingQgisStyle":"fusion","userIniHasUITheme":false}
A7:destaque-iman           OK  {"expected":{"Highlight":"#1E7A4D","HighlightedText":"#FFFFFF"},"palette":{"Active":{"Highlight":"#1E7A4D","HighlightedText":"#FFFFFF"},"Inactive":{"Highlight":"#1E7A4D","HighlightedText":"#FFFFFF"},"Disabled":{"Highlight":"#0078D7","HighlightedText":"#FFFFFF"}}}
```

`Active` e `Inactive` em verde e branco. O `Disabled` fica como o estilo entrega (`#0078D7`, briefing). Tema
`default`, folha 0: a 063 segue valendo.

## A2 O destaque por região (medido)

`Invoke-HighlightCaptures.ps1`, perfil novo, janela maximizada. Pastas: ANTES `destaque-antes-5ad96bf92d/`, DEPOIS
`destaque-depois-90be6f900f/`, controle `destaque-oficial/`.

A cor é medida na captura, em pixels físicos. O Fusion pinta a seleção das árvores com um degradê vertical em torno da
cor da paleta, de `#1D784C` a `#1E7E4F` para `#1E7A4D` (Camadas e Processamento). Por isso a cor da região é a média
da faixa em torno da mais comum, e o veredito aceita até 4 níveis por canal. A rodada do ANTES usou a primeira versão
do roteiro, que só tinha a mais comum; o oficial, medido com a versão final, dá a mesma cor.

| Região | Captura (DEPOIS) | ANTES | DEPOIS | Oficial | Texto selecionado no DEPOIS |
|---|---|---|---|---|---|
| Painel Camadas, camada selecionada | `a2-1-camadas-item.png` | `#0078D7` | `#1D7A4D` (faixa do degradê; mais comum `#1E7D4F`) | `#097EDA` | branco, legível (488 px de texto) |
| Processamento, algoritmo selecionado | `a2-2-processamento-item.png` | `#0B80DC` | `#1E7A4D` (mais comum `#1E7C4E`) | `#1082DC` | branco, legível (408 px) |
| Tabela de atributos, linha selecionada | `a2-3-tabela-linha.png` | `#0078D7` | `#1E7A4D` | `#0078D7` | branco, legível (12 px, a célula "a") |
| Menu Projeto aberto, item ativo | `a2-4-menu-item.png`, `a2-4-menu-aberto.png` | `#0078D7` | `#1E7A4D` | `#0078D7` | branco, legível (283 px) |
| Caixa de lista aberta (`native:buffer`), item corrente | `a2-5-lista-aberta-item.png` | `#0078D7` | `#1E7A4D` | `#0078D7` | branco, legível (30 px) |
| Texto selecionado no campo da distância | `a2-6-texto-selecionado.png` | `#0078D7` | `#1E7A4D` | `#0078D8` | branco, legível (66 px) |

**Critério do briefing: verde `#1E7A4D` com texto branco no DEPOIS em todas. Cumprido.** Nenhuma região ficou fora.
Legibilidade conferida também nas imagens.

Notas de método:
- A tabela de atributos segue a seleção de feições da camada (`QgsFeatureSelectionModel`), então a linha foi
  selecionada pela feição. A cor dela vem da folha que o próprio QGIS já montava (`qgisappstylesheet.cpp`,
  `QTableView { selection-background-color: <Highlight da paleta> }`, "Fix selection color on losing focus"). Ela
  passa a verde porque a paleta muda antes de a `QgisApp` nascer. Nenhuma regra QSS nova.
- A caixa de lista é a do estilo de ponta do `native:buffer`, não a de SRC (o briefing dá a de SRC como exemplo).
  Toda caixa de lista aberta usa a mesma lista.

## A3 Os controles do Qt não mudam (medido)

`Invoke-ArrowCaptures.ps1` contra os dois builds, perfil novo. Pastas: `setas-antes-5ad96bf92d/`,
`setas-depois-90be6f900f/`. Comparação em `bateria/setas-comparacao.txt`:

```
toolButtonMenu     visivel antes True depois True; medidas iguais: True
layerTreeBranches  visivel antes True depois True; medidas iguais: True
scrollBar          visivel antes True depois True; medidas iguais: True
toolboxBranches    visivel antes True depois True; medidas iguais: True
comboBox           visivel antes True depois True; medidas iguais: True
spinBox            visivel antes True depois True; medidas iguais: True
processingTabs     visivel antes True depois True; medidas iguais: True
RESULTADO: todas as medidas iguais
```

Retângulo da seta e tinta idênticos, controle a controle.

## A4 Escolha do usuário e troca em tempo de execução (medido)

`Measure-HighlightCases.ps1`, perfil descartável. As trocas foram feitas pela janela Opções > Geral, mudando a caixa e
clicando OK, como o usuário faz. "Desenhado" é a cor do item selecionado de uma lista de teste, medida na imagem (com
o degradê do Fusion: `#1E7D4F` é a faixa de `#1E7A4D`).

| Caso | Build desta branch: tema / paleta `Highlight` / desenhado | QGIS oficial (controle) | Esperado | Resultado |
|---|---|---|---|---|
| (a) perfil novo | `default` / `#1E7A4D` / `#1E7D4F` | `default` / `#0078D7` / `#0E81DC` | verde | **cumprido** |
| (b) `Night Mapping` em Opções, reabre | `Night Mapping` (folha 37487) / `#D7801A` / `#0F6E00` | `Night Mapping` / `#D7801A` / `#0F6E00` | tema de fábrica intacto | **cumprido**: igual ao oficial, a paleta IMAN não entra |
| (c) `default` para `Night Mapping` e volta, sem reabrir | `default` nas três medidas / `#1E7A4D` / `#1E7D4F`; `UI/UITheme` gravado `Night Mapping` e depois `default` | `default` nas três / `#0078D7` | verde no `default` | **cumprido**, ver abaixo |
| (d) troca o estilo do Qt em Opções (`Fusion` para `windowsvista`), reabre | `default` / `QWindowsVistaStyle` / paleta `#1E7A4D` / **desenhado `#CCE8FF`** | `QWindowsVistaStyle` / paleta `#0078D7` / desenhado `#CCE8FF` | (sem expectativa no briefing) | **relatado**: o estilo nativo do Windows não usa o `Highlight` |

Evidência: `casos/build-{a,b,c,d}/result.json` e `casos/oficial-{b,c,d}/result.json`.

**Sobre o caso (c), medido no código e na tela:** no QGIS 3.44 a troca de tema em Opções não vale na hora.
- O slot `QgsOptions::uiThemeChanged` existe (`qgsoptions.cpp:1441`), mas não está ligado a nada.
- O rótulo da caixa diz "reinício do QGIS necessário" (`qgsoptions.cpp:229`).
- O OK só grava `UI/UITheme` (`qgsoptions.cpp:1472`). A interface fica como estava até reabrir, no oficial também.
- Por isso o "volta para o default sem reabrir" não passa por nenhuma troca de paleta, e o destaque segue verde.
- Reabrir depois de voltar ao `default` dá o caso (a), com `UI/UITheme=default` gravado: `isDefaultTheme` aceita o
  valor, e o destaque é verde (`casos/build-c`, terceira medida, e A1).

**Sobre o caso (d), achado:** com o estilo `windowsvista` escolhido pelo usuário, a paleta do produto continua com
`#1E7A4D`, mas o estilo nativo do Windows desenha a seleção das listas com a cor do tema do Windows (`#CCE8FF`) e
ignora o `Highlight`. O oficial faz igual. Isso fica no teto honesto: o conserto não cabe no ponto de chamada e não
será feito com QSS. A escolha de estilo é do usuário, e o produto sai em `fusion`, como o oficial.

## A5 As telas do #059 não mudam (medido)

`bateria/a5-iman-color.txt`: o `iman_brand.h` gerado pela `develop` `5ad96bf92d` (paleta lida do `style.qss`) contra o
do build desta branch (paleta do `brand.json`):

```
saida do diff: 0 (0 = vazio)
linhas IMAN_COLOR_ nos dois: 18 e 18
iman_brand.h inteiro: diff 0 (0 = identico)
```

Capturas da página inicial e do Sobre: `telas-059-antes-5ad96bf92d/` e `telas-059-depois-90be6f900f/`
(`Invoke-HomeCaptures.ps1`). Comparação pixel a pixel em `bateria/telas-059-comparacao.txt`, e as regiões que mudaram
localizadas:

- **Página inicial:** só muda o selo de versão, que mostra o commit do build ("versão 0.4.0 · 5ad96bf92d" e
  "· 90be6f900f"). Cores, cartões, recentes e rodapé iguais.
- **Sobre o IMAN Terra:**
  - a linha da versão (o commit);
  - a borda do botão padrão "Sobre o QGIS", que passa de azul (`#41ADFF`) a verde escuro (`#18623E`).

  Essa borda não é cor da tela da 059: é o Fusion desenhando o botão padrão e o contorno de foco com a cor de
  `Highlight` da paleta. O mesmo acontece em todo diálogo do QGIS (o contorno de foco dos campos no "Abrir projeto",
  no nome do novo layout e no `QgsAbout`). As `IMAN_COLOR_*` e a folha própria das duas telas não mudam.

## A6 Nada mais muda (medido)

| Verificação | Resultado | Evidência |
|---|---|---|
| `Invoke-Smoke.ps1` no build `90be6f900f` | 19 de 19 OK: versão, provedores, plugins, `native:buffer`, GUI e `.qgz`, as dez `marca:*`, `controle:sobre`, `dados-do-produto` e a guarda | `smoke-build/summary.json` |
| `Test-Patchset.ps1` | 21 de 21: os 18 de antes, mais o `main.cpp` e os dois `imanpalette` | `bateria/patchset.txt` |
| `Test-ThemeQss.ps1` | 14 de 14, sobre o arquivo do repositório | `bateria/tema-qss.txt` |
| `Test-ThemeDefaults.ps1`, perfis novo e semeado | OK em todos os checks, com o `A7` | `tema-padrao/depois-perfil-{novo,semeado}/result.json` |
| `build_brand.py` com paleta inválida | falha alto nos três casos provados (cor que não é `#RRGGBB`, token usado pelo C++ faltando, sem a chave) | `bateria/build-brand-falhas.txt` |
| Guarda do QGIS oficial | OK em toda rodada | `guard` em cada `result.json` |

## A7 Guarda do destaque vista falhando (medido)

Check novo `A7:destaque-iman` no `Test-ThemeDefaults.ps1` (só acréscimo).

**Visto falhando** contra o build da `develop` `5ad96bf92d`
(`tema-padrao/visto-falhando-develop-5ad96bf92d/result.json`):

```
A7:destaque-iman           FALHOU  {"expected":{"Highlight":"#1E7A4D","HighlightedText":"#FFFFFF"},"palette":{"Active":{"Highlight":"#0078D7","HighlightedText":"#FFFFFF"},"Inactive":{"Highlight":"#F0F0F0","HighlightedText":"#000000"},"Disabled":{"Highlight":"#0078D7",...}}}
tema e padroes Build/new FALHOU
```

Só o `A7` cai: os outros checks passam no mesmo build. **Verde** contra o build desta branch: as linhas do A1 (perfil
novo) e `tema-padrao/depois-perfil-semeado/result.json` (perfil semeado), com `tema e padroes Build/new OK` e
`Build/seeded OK`.

## A8 Sem travessão (medido)

U+2014 e U+2013 contados nas linhas acrescentadas de `git diff 5ad96bf92d..HEAD`, por arquivo, com o item 0 e este
laudo incluídos: zero em todos os arquivos, salvo um: `smoke-build/summary.json`, com 3 U+2014 e zero U+2013. São títulos de
janela medidos do programa (`"smoke [U+2014] IMAN Terra [iman-smoke]"`, duas vezes, e `"Projeto sem título
[U+2014] IMAN Terra [iman-smoke]"`), que o QGIS monta em `src/app/qgisapp.cpp:604`; a flag é do sponsor, em aberto.
Ficam como evidência medida. O item 0 (laudo da 059), o código, os scripts, o `brand.json`, o `PATCHES.md`, a
memória e este laudo: zero e zero.

## Teto honesto (V.3)

A paleta pinta o que o Fusion desenha com `Highlight`: os itens selecionados de lista, árvore, tabela e menu, a caixa
de lista aberta e o texto selecionado (A2). Também pinta o contorno de foco e o botão padrão (A5).

Não pinta:
- a seleção de feições no mapa (a cor de seleção do projeto, amarela);
- widget que o QGIS desenha com cor própria;
- a barra de título do Windows;
- as cores próprias das telas da 059;
- a seleção desenhada pelo estilo nativo do Windows quando o usuário escolhe `windowsvista` ou `Windows` em Opções
  (A4, caso d);
- a paleta de um tema de fábrica escolhido pelo usuário (A4, caso b, por desenho).

## Achados

1. **Caso (d) do A4:** com o estilo `windowsvista` escolhido em Opções, a seleção sai na cor do tema do Windows, e não
   no verde. É comportamento do estilo nativo (o oficial também ignora a paleta). Relatado, sem conserto.
2. **O destaque também colore o contorno de foco e o botão padrão** em todo diálogo, inclusive o botão "Sobre o QGIS"
   do Sobre da 059 (A5). É efeito direto do papel `Highlight` no Fusion.
3. **No QGIS 3.44 a troca de tema em Opções só vale ao reabrir** (o `uiThemeChanged` não está ligado). O caso (c) do
   briefing não troca a paleta em tempo de execução, em nenhum build.
4. **Seleção com a janela inativa:** o oficial pinta a seleção de cinza (`#F0F0F0`, grupo `Inactive`) quando a janela
   perde o foco. O produto mantém o verde nos dois grupos, como o briefing pede.

## Bancada

- Tempos:
  - build da `develop` (sem a 064) cerca de 4 min mais o install;
  - build desta branch 147 s mais install 319 s;
  - destaque cerca de 30 s por rodada;
  - casos 10 a 30 s;
  - capturas da 059 cerca de 50 s.
- Nada instalado. O QGIS oficial só foi aberto nas rodadas de controle, só para leitura e com perfil descartável.
