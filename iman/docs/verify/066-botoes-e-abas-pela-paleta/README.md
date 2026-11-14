# Laudo 066: botões e abas no `panel-2` IMAN pela paleta do Qt, e o raio dos botões dobrado

Briefing `qgis-build #066` (D-IMAN-040, emendas de 2026-11-12 e 2026-11-13, com os adendos da segunda e da terceira
mudança; D-IMAN-026; D-IMAN-025; D-IMAN-034). Branch `feat/066-botoes-e-abas-pela-paleta`, nascida de `develop`
`4a97fec449` (merge do PR #12, `#065`). Máquina: Windows 11 Pro em espanhol, tela em escala 125%. Medições de
2026-11-13.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (lido no código, não
medido, com o motivo), **N/E** (não executado).

**Builds medidos** (cada um com o `QGIS code revision` do próprio binário):
- ANTES: `4a97fec449`, a `develop` intacta.
- COR: `ed5468fa16`, só o item 1 (a cor), compilado e medido antes de qualquer código do raio.
- FINAL: `5fd95d905d`, com o item 3 (o raio) (`smoke-build/summary.json`).

Os commits depois do FINAL mudam só os roteiros de teste e de medição (`54ba1988af`, nenhum C++), este laudo e a
memória da Crew.

**Como o sponsor abre:** `pwsh -NoProfile -File iman/build/Start-ImanTerra.ps1` (o build desta branch, perfil novo).
Nenhum instalador nesta fatia. Nos textos da evidência, o caminho do perfil do Windows virou `%USERPROFILE%`. As
capturas da janela escondem o painel Navegador.

## Veredito

**A1 a A10 medidos; o gate roda depois do PR aberto (resultado no `/deliver`).**

- **Cor (item 1):** sem tema escolhido, o papel `Button` é `#F5F7F2` (token `panel-2`) nos grupos `Active`,
  `Inactive` e `Disabled`. É o único papel que mudou: 3 de 60 linhas da paleta (A1). As 13 regiões do A2 mudaram com
  ele, todas pelo desenho do Fusion a partir do novo `Button`.
- **Fase A (item 2):** o Fusion desenha o `QPushButton` com raio 2. O raio alvo é 4. O painel do botão
  (`PE_PanelButtonCommand`) é usado também pelo botão de ferramenta e pelo botão de cor do QGIS, mas sempre com o
  próprio widget deles: dá para restringir o raio ao `QPushButton`.
- **Raio (item 3):** o `QPushButton` sai com raio 4 nos sete estados. Fora das quinas, o desenho é pixel a pixel o do
  Fusion. Nos outros 18 componentes, zero pixel diferente do build da cor (A5).
- **Setas (A3):** o raio não muda nenhuma seta (as 15 iguais entre COR e FINAL). A cor mudou a tinta medida de três
  setas e da faixa das abas, com o rect igual e o desenho da seta igual: decisão do sponsor nesta sessão, seguir como
  achado (achado 2).
- **Contraste (A4):** o texto dos botões ganha contraste: +5,6% (normal) e +5,7% (desabilitado).
- **Escolha do usuário (A6):** com `Night Mapping`, nem a cor nem o raio IMAN (o mesmo do QGIS oficial). Com
  `windowsvista`, o botão é o do Vista, igual ao do QGIS oficial.
- **Guardas (A7):** `A7:botoes-iman` e `A7:estilo-iman` vistos falhando na `develop`, verdes nesta branch, nos perfis
  novo e semeado.
- **Telas da 059 (A8):** a página inicial igual. No "Sobre", os dois botões arredondados, com o contorno verde do botão
  padrão.
- **Nada mais muda (A9):** smoke 19 de 19, patchset 23 de 23, tema 14 de 14, guarda OK em toda rodada. O
  `iman_brand.h` só ganha a linha do raio.

Nenhum STOP disparou sem decisão (ver "STOPs"). Nenhum `setStyleSheet` novo, nenhuma regra QSS. Arquivos do QGIS
tocados: o `src/app/main.cpp` (os dois `new QgsAppStyle` e o comentário da chamada que já existia) e o
`src/app/CMakeLists.txt` (o arquivo novo do IMAN), os dois no `iman/PATCHES.md`. O `qgsproxystyle.*` não foi tocado.

## O que mudou

| Commit | Onde | O quê |
|---|---|---|
| `ed5468fa16` (cor) | `src/app/iman/imanpalette.{h,cpp}` | `Button` = `IMAN_COLOR_PANEL_2` nos grupos `Active`, `Inactive` e `Disabled`, no mesmo laço e no mesmo `setPalette` do `Window` da 065, com a mesma condição (só o tema `default`). Nenhum hex no C++. |
| `ed5468fa16` | `src/app/main.cpp` | Só o comentário da chamada `ImanPalette::apply( theme )` (fatias 064 a 066). |
| `5fd95d905d` (raio) | `src/app/iman/imanappstyle.{h,cpp}` (novos) | `ImanAppStyle`, que herda do `QgsAppStyle` e só sobrescreve o `drawPrimitive`: no `PE_PanelButtonCommand` com widget `QPushButton`, desenha o painel do Fusion com o raio `IMAN_BUTTON_RADIUS_PX`; todo o resto vai para o `QgsAppStyle`. `clone()` próprio. Raio só com o tema `default` e a base fusion. |
| `5fd95d905d` | `src/app/main.cpp` | Os dois `QApplication::setStyle( new QgsAppStyle( ... ) )` do arranque viram `new ImanAppStyle( ..., theme )`, e o include. |
| `5fd95d905d` | `src/app/CMakeLists.txt` | `iman/imanappstyle.cpp` no `qgis_app`. |
| `5fd95d905d` | `iman/brand/brand.json`, `iman/brand/build_brand.py` | `button_radius_px: 4`, validado (inteiro de 1 a 16) e escrito no `iman_brand.h` como número: `#define IMAN_BUTTON_RADIUS_PX 4`. |
| os dois | `iman/PATCHES.md`, `iman/brand/README.md` | As linhas dos arquivos tocados, os arquivos novos, o parágrafo "Forma" e o token `panel-2` e o `button_radius_px`. |
| `54ba1988af` (testes) | `iman/build/Test-ThemeDefaults.ps1` | Acréscimo dos checks `A7:botoes-iman` e `A7:estilo-iman` e de uma frase no cabeçalho. |
| `54ba1988af` | `iman/build/Invoke-ArrowCaptures.ps1`, `smoke/arrow_controls.py` | Acréscimo da seta do botão com menu "Estilo" (`QPushButton`), fora de `result.controls`, que segue com os 7 controles da 063; o `ok` final ganha a condição dela. |
| `54ba1988af` | `iman/build/Invoke-ButtonCaptures.ps1`, `smoke/button_facts.py` (novos) | Fase A, raio, componentes e regiões do papel `Button`, com a comparação com outra rodada (`-Reference`, `-Expect Color/Radius/Same`). |
| `54ba1988af` | `iman/build/Measure-PaletteContrast.ps1` | Acréscimo dos parâmetros `-TextRole` e `-BackgroundRole` (padrão o par da 065). |
| `54ba1988af` | `iman/build/Measure-HighlightCases.ps1`, `smoke/highlight_cases.py` | Acréscimo, para o A6: o `Button` por grupo e um `QPushButton` de teste desenhado pelo estilo em vigor (raio das quinas). |

O `smoke/theme_facts.py` não mudou: ele já grava o nome da classe do estilo no meta-objeto (`qtStyle`) e o da base
(`qtStyleBase`), que o `A7:estilo-iman` usa.

**Forma do raio (escolha da Crew, dentro do item 3).**
- **O desenho é o do Fusion, repetido:** o `qfusionstyle.cpp` do Qt não está na bancada (só os cabeçalhos privados, em
  `osgeo4w/apps/Qt5/include/QtWidgets/5.15.13/QtWidgets/private/`). As cores vêm do `qfusionstyle_p_p.h` (citado com
  linha no `imanappstyle.cpp`), e o desenho pela imagem de cache, do `qstyle_p.h`, linhas 77 a 83 e 93 a 120. O
  degradê e a mistura de cores (`qt_fusion_gradient`, `mergedColors`) foram escritos pelo que a Crew conhece do
  `qfusionstyle.cpp` (relatado) e **conferidos pela medição**: fora das quinas, o desenho do `ImanAppStyle` é igual ao
  do fusion puro em todos os pixels, nos sete estados (`bateria/a5-raio.txt`).
- **O `objectName` segue `QgsAppStyle`:** o `QgsProxyStyle` do QGIS procura esse nome para copiar o estilo da
  aplicação (`src/gui/qgsproxystyle.cpp:29-34`).
- **O `clone()` próprio só vale pelo tipo `ImanAppStyle`:** o `QgsAppStyle::clone()` não é virtual, e o
  `QgsProxyStyle` chama pelo tipo `QgsAppStyle` (relatado, `qgsproxystyle.cpp:33`). Os widgets com `QgsProxyStyle`
  recebem um `QgsAppStyle` sem o raio; nenhum deles é um `QPushButton` (a árvore de camadas, as barras de abas do
  `QgsTabBarProxyStyle` e as listas das simbologias categorizada e graduada, de nuvem de pontos e de diagramas
  empilhados). Mudar isso exigiria mexer no `qgsproxystyle.*` (STOP do briefing): não foi feito.
- **Com o Vista ou outro estilo do Qt:** o raio só vale com a base fusion, cujo desenho este estilo repete; com outra
  base, o `ImanAppStyle` não desenha nada próprio.

## Fase A (item 2): o raio de hoje e o caminho do desenho

Medido no build ANTES (`bateria/a5-fase-a.txt`; `botoes-antes-4a97fec449/buttons.json`).

**O raio que o Fusion desenha no `QPushButton`: 2.** Medido no canal alfa do botão desenhado pelo estilo da aplicação
sobre fundo transparente, na escala da tela (1,25). A área que falta em cada quina é a de um quarto de círculo de raio
r, menos meia caneta (o contorno de 1 px fica centrado na borda). O mesmo estimador sobre referências de raio
conhecido (`drawRoundedRect` com o mesmo traço) dá 2,133 para o raio 2 e 4,152 para o raio 4. O botão do Fusion dá
2,133 nas quatro quinas e nos sete estados, e a referência mais parecida é a de raio 2. **Pelo código:** o
`qfusionstyle.cpp` não está na bancada; o número não vem do código.

**Raio alvo: 4** (o dobro, já inteiro).

**Quem passa pelo painel do botão (`PE_PanelButtonCommand`):** medido com um estilo de gravação posto só no
componente, que anota cada chamada de desenho e o widget dela.

| Componente | Passa pelo painel do botão? | Com que widget |
|---|---|---|
| `QPushButton`, com e sem menu | sim (`CE_PushButtonBevel`) | `QPushButton` |
| `QToolButton` sem menu, com menu ao lado e com menu de clique | sim (`PE_PanelButtonTool`) | `QToolButton` |
| `QgsColorButton` (botão de cor da Simbologia, herda de `QToolButton`) | sim (`PE_PanelButtonTool`) | `QgsColorButton` |
| `QToolButton` de barra (`autoRaise`), em repouso | não | |
| Caixa de seleção fechada e editável, caixa numérica, campo, aba, painel de abas, cabeçalho, caixa de grupo (e a recolhível do QGIS), barra de rolagem, barra de progresso, caixa de marcar, botão de opção | não | |

Conclusão: o raio pode ser restrito ao `QPushButton` pelo widget da chamada. Nenhum STOP. Do QGIS, herda de
`QPushButton` só o `QgsMeshVariableStrokeWidthButton` (`src/gui/mesh/qgsmeshvariablestrokewidthwidget.h:32`): ganha o
raio, como todo `QPushButton` (os botões das caixas de botões dos diálogos também são `QPushButton`).

## A1: só o `Button` mudou

`bateria/a1-paleta-diff.txt`. Paleta inteira (`paletteAll`), perfil novo:

| De | Para | Linhas diferentes |
|---|---|---|
| `develop` `4a97fec449` | COR `ed5468fa16` | 3 de 60: `Button` `#FFF0F0F0` para `#FFF5F7F2` nos três grupos |
| COR `ed5468fa16` | FINAL `5fd95d905d` | 0 de 60 |

Nos três builds: tema `default`, folha de estilo de tamanho 0, `Highlight` `#1E7A4D` e `HighlightedText` `#FFFFFF`.
O estilo é `QgsAppStyle` na `develop` e na COR e `ImanAppStyle` no FINAL, sempre sobre `QFusionStyle`.

## A2: regiões da cor

`bateria/a2-regioes-cor.txt` (ANTES em `botoes-antes-4a97fec449`, DEPOIS em `botoes-cor-ed5468fa16`; recortes
`a2-*.png` nas duas pastas). Média da faixa em volta da cor mais comum, como no `#065`; entre parênteses, a cor mais
comum.

| Região | ANTES | DEPOIS (COR) |
|---|---|---|
| Opções: OK (botão padrão) | `#E2E8E5` (`#DCE4E1`) | `#E6EEE9` (`#E1EAE4`) |
| Opções: Cancelar | `#F5F5F5` (`#F1F1F1`) | `#F9F9F8` (`#F6F7F5`) |
| Propriedades da camada: "Estilo" (botão com menu) | `#F5F5F5` (`#F1F1F1`) | `#F9F9F8` (`#F6F7F5`) |
| Processamento: Executar (botão padrão) | `#E1E8E5` (`#DCE4E1`) | `#E6EEE8` (`#E1EAE4`) |
| Processamento: aba selecionada (Parâmetros) | `#FDFDFD` (`#FEFEFE`) | `#FFFFFF` |
| Processamento: aba não selecionada (Log) | `#E9E9E9` | `#ECECEC` |
| Processamento: painel das abas, aba Log | `#FCFCFC` | `#FFFFFF` |
| Tabela de atributos: cabeçalho | `#F2F2F2` (`#EEEEEE`) | `#F8F9F7` (`#F4F5F2`) |
| Caixa de seleção fechada | `#F4F4F4` (`#F0F0F0`) | `#F9F9F8` (`#F5F6F4`) |
| Caixa numérica: os botões das setas | `#F6F6F6` | `#F9FAF8` |
| Simbologia: botão de cor (a parte do menu, ao lado da amostra) | `#F6F6F6` (`#F8F8F8`) | `#F9F9F8` (`#F6F7F5`) |
| Barra de rolagem: alça | `#F8F8F8` (`#F7F7F7`) | `#FBFCFA` (`#FAFBF9`) |
| Barra de rolagem: trilho | `#E6E6E6` | `#ECEDEA` |

Todas as 13 mudaram, e só o `Button` mudou na paleta (A1): todas seguem o `Button`. Nenhuma fica em `#F5F7F2` exato,
porque o Fusion nunca pinta o `Button` puro: ele parte de `buttonColor`, o `Button` clareado de 1% e com 75% da
saturação (`qfusionstyle_p_p.h:132-138`), `#F8F9F6` com o `#F5F7F2`, e pinta degradês a partir dele. O painel das
abas é `tabFrameColor`, o `buttonColor` clareado de 4% (`qfusionstyle_p_p.h:126-130`): a conta dá `#FCFCFC` com o
`Button` de antes e `#FFFFFF` com o de agora, os dois medidos. Os botões padrão (OK, Executar) misturam o verde do
contorno de destaque, como já faziam.

**Achado 1, o painel das abas fica branco puro.** A aba Log do Processamento (o achado 1 do `#065`) não ficou da cor do
fundo: passou de `#FCFCFC` a `#FFFFFF`, a conta exata do Fusion a partir do `#F5F7F2`. A faixa clara da 065 continua,
agora branca. Para ela sair seria preciso um `Button` mais escuro ou mexer em outro papel (STOP "outro papel"); nada
foi feito, e o smoke do sponsor decide. **Achado 3:** a aba não selecionada muda (`#E9E9E9` para `#ECECEC`), mas fica
cinza neutra, sem o tom verde: medido; a conta do Fusion para ela não está nos cabeçalhos da bancada (relatado).

## A3: setas

`bateria/a3-setas-comparacao.txt` e `bateria/a3-setas-pixels.txt`; capturas em `setas-antes-4a97fec449`,
`setas-cor-ed5468fa16` e `setas-final-5fd95d905d`. Quinze medidas, com a seta nova do botão com menu "Estilo"
(`06b-botao-estilo-com-menu.png`).

| Comparação | Resultado |
|---|---|
| COR contra FINAL (o raio) | **as 15 iguais**, rect e tinta, inclusive a seta do botão "Estilo", que agora tem quinas de raio 4 |
| `develop` contra COR (a cor) | rect igual nas 15; tinta igual em 11; mudou em 3 setas e na faixa das abas |

As que mudaram com a cor:

| Seta | Tinta (pixels) | Fundo em volta |
|---|---|---|
| Botão "Estilo" com menu | 19 para 13 | `#F9F9F9` para `#F7F8F6` |
| Barra de rolagem, para cima | 32 para 27 | `#FBFBFB` para `#FAFBF9` |
| Barra de rolagem, para baixo | 32 para 27 | `#FBFBFB` para `#FAFBF9` |
| Faixa das abas do Processamento (não é seta) | 893 para 855 | `#FCFCFC` para `#FFFFFF` |

**Achado 2.** Pixel a pixel, o desenho da seta não mudou: os 13 pixels escuros da seta do botão e os 29 da barra de
rolagem são os mesmos nos dois builds, e a cobertura da seta (quanto o pixel se afasta do fundo, em fração do pixel
mais escuro) muda no máximo 0,056 por pixel. O que caiu foi uma fileira de pixels de borda quase brancos (`#E5E5E5`,
cobertura perto de 10%), que ficaram a menos de 60 níveis do fundo porque o fundo do botão sob a seta seguiu o novo
`Button`. As abas seguem com os mesmos tamanhos e a mesma largura de texto. O briefing lista "seta que muda de tinta"
como STOP; a Crew parou e perguntou, com estes números, e **o sponsor decidiu nesta sessão seguir e tratar como
achado**. O raio, depois, não mudou nenhuma seta.

## A4: leitura

`bateria/a4-contraste.txt`, nas cores da paleta, perfil novo:

| Par | ANTES (`develop`) | DEPOIS (FINAL) | Variação |
|---|---|---|---|
| `ButtonText` sobre `Button` (Active) | `#000000` sobre `#F0F0F0`: 18,43:1 | `#000000` sobre `#F5F7F2`: 19,47:1 | +5,6% |
| `ButtonText` desabilitado sobre `Button` desabilitado | `#787878` sobre `#F0F0F0`: 3,87:1 | `#787878` sobre `#F5F7F2`: 4,09:1 | +5,7% |
| controle: `WindowText` sobre `Window` (o par da 065) | 17,93:1 e 3,77:1 | 17,93:1 e 3,77:1 | 0% |

Nenhuma queda: o fundo do botão ficou mais claro.

## A5: o raio, só no botão

**(i) Fase A:** acima.

**(ii) As quatro quinas do `QPushButton` nos sete estados** (`a5-quinas-<estado>.png`, as quatro quinas lado a lado
ampliadas 12 vezes; `a5-botao-<estado>.png`, o botão inteiro ampliado 4 vezes; estados `normal`, `hover`, `pressed`,
`disabled`, `default`, `focus` e `menu`), em `botoes-cor-ed5468fa16` e `botoes-final-5fd95d905d`.
`bateria/a5-raio.txt`:

| Estado | COR: raio estimado (referência) | FINAL: raio estimado (referência) | FINAL: diferente do fusion puro fora das quinas |
|---|---|---|---|
| normal, hover, pressionado, desabilitado, padrão, com foco, com menu | 2,133 (2) | 4,152 (4) | 0 px |

4,152 é o que o estimador dá para a referência de raio 4: **raio final medido = alvo**. O padrão segue com o contorno
verde do destaque, o foco com o contorno de foco, o pressionado com o fundo mais escuro e a seta do botão com menu no
lugar (A3), porque o `ImanAppStyle` repete o desenho do Fusion e só troca o raio: fora das quinas, zero pixel
diferente do fusion puro em cada estado.

**(iii) Os outros componentes, COR contra FINAL, pixel a pixel** (`a5c-<componente>.png` nas duas pastas;
`A5iii:outros-componentes-iguais` em `botoes-final-5fd95d905d/result.json`):

| Componente | Pixels diferentes |
|---|---|
| caixa de seleção fechada e editável, botão de ferramenta sem menu, de barra, com menu ao lado e com menu de clique, botão de cor, caixa numérica, campo, barra de abas, painel de abas, cabeçalho, caixa de grupo, caixa recolhível, barra de rolagem, barra de progresso, caixa de marcar, botão de opção (18) | **0 em cada um** |
| `QPushButton` e `QPushButton` com menu (o controle: deve mudar) | 86 de 6000, todos nas quinas |

**Controle de ruído:** duas rodadas do mesmo build (`develop`) dão 0 pixel diferente em tudo
(`bateria/a5-ruido.txt`): a comparação mede o build, não a rodada.

## A6: escolha do usuário

`bateria/a6-casos.txt`; `casos/` (perfil descartável; o tema e o estilo só valem ao reabrir, no 3.44).

| Caso | IMAN Terra (FINAL) | QGIS oficial 3.44.13 (controle, só lido) |
|---|---|---|
| (a) perfil novo | tema `default`, estilo `ImanAppStyle` sobre fusion, `Button` `#F5F7F2` nos três grupos, botão de teste com raio 4,152 | |
| (b) `Night Mapping` escolhido e reaberto | folha de 37487, `Button` `#F0F0F0`, botão desenhado pela folha (`QStyleSheetStyle`), quinas sem arredondamento (estimado -0,5, sem área faltando) | folha de 37327, `Button` `#F0F0F0`, o mesmo botão (-0,5) |
| (d) `windowsvista` escolhido e reaberto | estilo `ImanAppStyle` sobre `QWindowsVistaStyle`, `Button` `#F5F7F2` na paleta, botão do Vista: raio estimado 8,348 (quinas 8,608/8,38/8,38/8,026) | `QgsAppStyle` sobre `QWindowsVistaStyle`, `Button` `#F0F0F0`, o mesmo botão do Vista: 8,348 (as mesmas quatro quinas) |

- (b): nem a cor nem o raio IMAN; o tema de fábrica fica como no QGIS oficial. A folha 160 caracteres maior é a mesma
  diferença desde a 064 (o texto da folha do QGIS com o nome do produto), não desta fatia.
- (d): o `ImanAppStyle` não desenha o botão do Vista (a base não é fusion), e o desenho do tema do Windows é o mesmo do
  QGIS oficial; o 8,348 não é um raio de quina, é o desenho do Vista com as margens dele, igual nos dois. A paleta leva
  o `Button` IMAN, como o `Window` e o destaque da 064 e da 065; o botão do Vista não usa a cor do `Button`.
- A coluna "botão desenhado" do log dos casos (a cor mais comum da captura do botão de teste) não entra no veredito: a
  cor dos botões é medida no A2.

## A7: guardas vistas falhando

`bateria/a7-guardas.txt`; `tema-padrao/`.

| Build | `A7:destaque-iman` | `A7:fundo-iman` | `A7:botoes-iman` | `A7:estilo-iman` |
|---|---|---|---|---|
| `develop` `4a97fec449`, perfil novo | OK | OK | **FALHOU** (`#FFF0F0F0`) | **FALHOU** (`QgsAppStyle`) |
| COR `ed5468fa16`, perfil novo | OK | OK | OK | **FALHOU** (`QgsAppStyle`, como esperado antes do raio) |
| FINAL `5fd95d905d`, perfil novo | OK | OK | OK | OK (`ImanAppStyle` sobre `QFusionStyle`) |
| FINAL `5fd95d905d`, perfil semeado | OK | OK | OK | OK |

No FINAL, todos os checks do `Test-ThemeDefaults.ps1` passam nos dois perfis.

## A8: telas da 059

`bateria/a8-telas-059-comparacao.txt`; capturas em `telas-059-antes-4a97fec449` e `telas-059-final-5fd95d905d`.

- **Página inicial:** dentro da página, só o selo de versão (o commit) e, com recentes, o carimbo de hora da pasta da
  rodada no caminho do projeto. Fora dela, mudam os botões da janela que seguem o `Button`: o botão de ferramenta
  marcado da barra (Mover mapa) e os botões da barra de status. A folha própria da página não foi tocada.
- **"Sobre IMAN Terra":** os dois botões, "Sobre o QGIS" e "Fechar", são `QPushButton` e ficaram com o raio 4 e o
  fundo novo; o "Sobre o QGIS" é o botão padrão e segue com o contorno verde. A folha própria do diálogo só estiliza os
  rótulos, por nome (`src/app/iman/imanaboutdialog.cpp:159-165`): os botões vão para o estilo da aplicação. Mudam
  também as barras de rolagem da lista de licenças, que seguem o `Button`.
- **"Sobre o QGIS":** os botões e as abas seguem o `Button`.

## A9: nada mais muda

| Item | Resultado | Evidência |
|---|---|---|
| `Invoke-Smoke.ps1` no FINAL | OK, 19 de 19, `QGIS code revision 5fd95d905d` | `bateria/smoke.txt`, `smoke-build/summary.json` |
| `Test-Patchset.ps1` | OK, 23 de 23 (21 da 065 mais `imanappstyle.h` e `.cpp`) | `bateria/patchset.txt` |
| `Test-ThemeQss.ps1` | OK, 14 de 14 | `bateria/tema-qss.txt` |
| `Test-ThemeDefaults.ps1` no FINAL | OK no perfil novo e no semeado | `tema-padrao/final-perfil-*` |
| guarda do QGIS oficial | OK em toda rodada (botões, setas, tema, casos, telas, smoke) | o `result.json` de cada pasta |
| `iman_brand.h` | só a linha nova `#define IMAN_BUTTON_RADIUS_PX 4` | `bateria/a9-cabecalho.txt` (o da `develop` com o sha256 `c4b8f57d...da661`, o mesmo do laudo 065) |

## A10: sem travessão

`bateria/a10-travessao.txt`: contado por arquivo nas linhas acrescentadas desta branch (`git diff 4a97fec449`), laudo
incluído. Zero U+2013 em todos. U+2014 só em três arquivos de evidência medida do programa, 3 em cada, todos em
títulos de janela que o QGIS monta:
- `smoke-build/summary.json`: o título da janela principal (`qgisapp.cpp:604`, o U+2014 entre o projeto e
  "IMAN Terra"), 3 vezes;
- `telas-059-*/summary.json`: o título da janela principal (1) e o de dois diálogos de opções do QGIS, o Gerenciador
  de Fonte de Dados e o "Sobre o QGIS" (`qgsoptionsdialogbase.cpp:754`, 2).

Zero no C++, nos roteiros, nos documentos e neste laudo.

## STOPs

| STOP | Situação |
|---|---|
| O raio pega em outro componente | Não. Fase A: restringível pelo widget. A5 (iii): zero pixel diferente fora do `QPushButton`. |
| `P0.10` (teste contra spec) | Honrado. Testes existentes só com acréscimo: `Test-ThemeDefaults.ps1`, `Invoke-ArrowCaptures.ps1` e `arrow_controls.py` (lista fechada do briefing). |
| Seta ou controle que muda | **Disparado pela métrica e decidido pelo sponsor:** a tinta de três setas mudou com a cor (rect e desenho iguais). A Crew parou, perguntou com a análise pixel a pixel, e o sponsor decidiu seguir como achado (achado 2). O raio não muda nenhuma seta. |
| Outro papel | Respeitado. Só o `Button`. O painel das abas branco (achado 1) não foi corrigido por outro papel. |
| QSS | Nenhum `setStyleSheet` novo, nenhuma regra QSS. |
| Arquivo do QGIS | Só o `main.cpp` (os dois `new QgsAppStyle` e o comentário da chamada) e o `CMakeLists.txt` do `qgis_app` (o arquivo novo do IMAN), no `PATCHES.md`. O `qgsproxystyle.*` não foi tocado. |
| Cor fora da paleta | Nenhum hex novo no C++ nem no `brand.json`. Os números do desenho do Fusion repetidos no C++ (124, 102, 104, 110, 115, 130, 90, 140, 125, 160 e a linha branca de 30 de alfa) são os do Fusion, não cores da marca. O raio é o único valor novo da marca. |
| O resto da marca | Smoke 19 de 19 e os checks de tema iguais. |
| Perfil do usuário | Nenhuma escrita de chave por código. |
| Instalação | Nenhum instalador; o QGIS oficial só lido, com a guarda OK em toda rodada. |

## Achados

1. **O painel das abas fica branco puro** (`#FFFFFF`), não da cor do fundo: é a conta do Fusion a partir do novo
   `Button`. A faixa clara do achado 1 do `#065` continua, mais clara. Decisão do sponsor no smoke.
2. **A tinta de três setas caiu com a cor**, com o desenho da seta igual (A3). Decidido nesta sessão: achado.
3. **A aba não selecionada fica cinza neutra** (`#ECECEC`), sem o tom verde das outras regiões.

## Teto honesto

- A verdade é a VM limpa (BL-7): nada desta fatia rodou nela. Esta fatia não gera instalador.
- O desenho do Fusion para o degradê e a mistura de cores foi escrito sem o `qfusionstyle.cpp` na bancada; a prova de
  que está igual é a medição (zero pixel diferente fora das quinas, sete estados, escala 1,25). Em outra escala de tela,
  não medido.
- O raio estimado tem viés conhecido do estimador (2,133 para 2, 4,152 para 4, pela calibração); o veredito compara com
  a referência de raio conhecido, não com o número cru.
- Os estados hover, pressionado e com foco do A5 foram desenhados pelo estilo com o estado posto na opção do botão, não
  com o mouse e o teclado de verdade.

## Como reproduzir

```
pwsh -NoProfile -File iman/build/Invoke-ImanBuild.ps1 -Offline -SkipTools             # em cada commit medido
pwsh -NoProfile -File iman/build/Invoke-ButtonCaptures.ps1                             # ANTES (develop)
pwsh -NoProfile -File iman/build/Invoke-ButtonCaptures.ps1 -Reference <rodada da develop> -Expect Color
pwsh -NoProfile -File iman/build/Invoke-ButtonCaptures.ps1 -Reference <rodada da cor> -Expect Radius -TargetRadius 4
pwsh -NoProfile -File iman/build/Invoke-ButtonCaptures.ps1 -Reference <outra rodada do mesmo build> -Expect Same
pwsh -NoProfile -File iman/build/Invoke-ArrowCaptures.ps1
pwsh -NoProfile -File iman/build/Test-ThemeDefaults.ps1 [-ProfileState Seeded]
pwsh -NoProfile -File iman/build/Measure-PaletteContrast.ps1 -Before <theme.json> -After <theme.json> -TextRole ButtonText -BackgroundRole Button
pwsh -NoProfile -File iman/build/Measure-HighlightCases.ps1 -Case a|b|d [-Target Official]
pwsh -NoProfile -File iman/build/Invoke-HomeCaptures.ps1
pwsh -NoProfile -File iman/build/Invoke-Smoke.ps1
```

As comparações de `bateria/a3-setas-comparacao.txt`, `a3-setas-pixels.txt` e `a8-telas-059-comparacao.txt` saíram de
scripts de comparação da bancada, fora do repositório, como no laudo 065: eles leem os `arrows.json` e os PNG das duas
rodadas, que estão nesta pasta; a regra de cada número está escrita no topo de cada arquivo.

`SHA256SUMS.txt` lista cada arquivo desta pasta, com o caminho a partir da raiz do repositório.
