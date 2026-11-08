# Laudo 049: o tema da distro como tema nativo do IMAN Terra e o SRC padrão SIRGAS 2000 / UTM 24S

Briefing `qgis-build #049` (emenda de 2026-10-29 ao D-IMAN-040, itens 1 e 2; D-IMAN-033, D-IMAN-026, D-IMAN-041).
Branch `feat/049-tema-e-padroes`, nascida de `develop` `f2d8c5894e` (o merge do PR #4, que contém `97bfc103d2`).
Máquina: Windows 11 Pro em espanhol, 24 processadores lógicos, 32 GB. Medições de 2026-10-30.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (dito por fonte externa
ou não observável por este teste, com o motivo), **N/E** (não executado).

**Alvo do smoke do sponsor (desde o patch 049p, 2026-11-04):**
`D:\iman-terra-build\dist\0.4.0-c086bde009\Instituto-IMAN-IMAN-Terra-Setup-0.4.0-c086bde009.exe` (512.782.201 bytes,
SHA-256 `35802d4dd13a00f19735419c5e87ac32b7dd554d1ac40cd41e74adfcc6205f43`, Inno Setup 7.1.0;
`patch-049p/instalador/BUILD_INFO.txt`). Ver a seção "Patch 049p", no fim.

Build medido nas seções antes do patch: `51968a5220` (todas as capturas e medições do build e da árvore instalada
dessas seções saem dele, V.4). Os commits seguintes da branch, até `41561ea755`, só mexem nos testes desta fatia e neste
laudo. Instalador de então, substituído pelo de cima como alvo do smoke:
`D:\iman-terra-build\dist\0.4.0-51968a5220\Instituto-IMAN-IMAN-Terra-Setup-0.4.0-51968a5220.exe` (512.779.274 bytes,
SHA-256 `5e70e0e0f87e3b39884cf461e52ec0d6f7cc98db98be67aae1d968e78784f230`; `instalador/BUILD_INFO.txt`).
Nenhum instalador **entra no git**. Nos arquivos de texto da evidência, o caminho do perfil do Windows virou `%USERPROFILE%`; nas
capturas, o painel Navegador fica escondido (ele lista as unidades da máquina, com nome e e-mail de conta).

| Pasta | O que é |
|---|---|
| `tema-qss/` | `Test-ThemeQss.ps1` no tema portado (`result.json`) e contra o original da distro e cinco mutantes (T3, T4) |
| `configuracao-global/ini-diff.txt` | o `.ini` gerado contra o do QGIS e a contagem de cada chave (A5, B6, B7, T5) |
| `build-perfil-novo/` | `Test-ThemeDefaults.ps1 -Captures` no build, perfil novo: fatos e as capturas por região (T1, T2, T3, T5, T9) |
| `build-perfil-semeado-0.4.0/` | o mesmo com o `IMANTerra.ini` de uma rodada do 0.4.0 instalado (T1) |
| `build-escolha-do-usuario-default/`, `build-escolha-do-usuario-blend-of-gray/` | perfil com `UI/UITheme` gravado pelo usuário (T1 visto falhando, T9) |
| `oficial-visto-falhando/` | o QGIS 3.44.13 oficial na mesma medição (T5 visto falhando, controle do D2) |
| `instalado-perfil-novo/`, `instalado-perfil-semeado-0.4.0/` | o mesmo na árvore instalada pelo instalador desta branch (T6) |
| `ciclo/` | a máquina sem o IMAN Terra antes (`pre-ciclo.txt`), instalar e desinstalar (T6) |
| `instalado/` | `Test-Installed.ps1` inteiro (T7) e a primeira rodada, que caiu no A2 (achado 2) |
| `smoke-build/`, `smoke-instalado/`, `sem-ecw/`, `conjunto/` | smoke do 044, `Test-NoEcw.ps1` e `Test-RuntimeSet.ps1` (T7) |
| `distro-referencia/` | a captura da distro usada no lado a lado da janela (origem abaixo) |
| `patch-049p/` | o patch de 2026-11-04 (a coordenada inteira): guarda, mutantes, build, instalado, ciclo, instalador |
| `SHA256SUMS.txt` | hash de cada arquivo desta pasta |

## Veredito

**Os blocos A e B fecharam e T1, T4, T5, T6, T7 e T9 passaram; T3 passou no D1 e no D4 e reprovou no D2, um STOP do
briefing que foi relatado ao sponsor na sessão; T2 tem as onze regiões classificadas; T8 (o gate) roda depois do PR
aberto.** O tema `IMAN Terra` é um tema nativo do QGIS, copiado da distro sem mudar cor, raio nem regra, e é o padrão em
perfil novo e em perfil semeado da 0.4.0; a escolha do usuário vence a global; projeto novo nasce em EPSG:31984 no build
e na árvore instalada; nenhum arquivo do QGIS mudou; o QGIS oficial ficou intocado em toda etapa.

**STOP D2 (decisão do sponsor na sessão: "Não mexer; relatar e seguir"):** com o tema, o campo de coordenadas da barra de
status corta o primeiro dígito do Leste (achado 1). O tema ficou como o aprovado; a decisão é do arquiteto.

**Atualização do patch 049p (2026-11-04): o D2 fechou.** A regra nova `QStatusBar QLineEdit { padding-left: 0;
padding-right: 0; }` (emenda de 2026-11-04 ao D-IMAN-040) devolve 161 px úteis ao campo, e a coordenada sai inteira no
build e na árvore instalada da ponta `c086bde009`. Detalhe na seção "Patch 049p".

## Bloco A: o tema

### A1 a A3 A fonte em `iman/`: medido

- `iman/brand/theme/IMAN Terra/style.qss`: cópia de `app/profile-template/iman-distro/themes/IMAN Terra/style.qss` da
  distro em `origin/develop` `df761da5e892378fbf8066794c2dd0132e1926a1` (sha256 do original
  `0c87465696d358055857537e92539c86173980b10021f8770baadb104e14494b`). O cabeçalho cita a origem e diz como o tema chega
  agora; deixou de citar o `iman_startup.py`, o perfil e o plugin.
- **Regras iguais, comprovado por diff sem comentários:** tirados os comentários dos dois arquivos, a única diferença
  são as seis linhas da camada de marca (`#qa`, `#qatile`, `#rec`, `#ImanHomeVersao`, `#ImanSobreCreditos`,
  `#ImanTerraMenuBtn`), que saíram (A2). Os comentários D1, D2 e D4 ficaram, com uma frase a mais no D2 dizendo que o
  ajuste de largura do plugin não existe no fork.
- Os dois ícones da branch cancelada da distro não entraram (A3).
- Sem travessão, meia-risca, tabulação nem CRLF no arquivo portado.

### A4 O tema chega em `<pkgDataPath>/resources/themes/IMAN Terra/`: medido

- `iman/build/Build-Qgis.ps1`, depois do `cmake --install`: copia `iman/brand/theme/<ui_theme>` (nome do `brand.json`)
  para `apps\qgis-ltr\resources\themes\<ui_theme>`, refeita do zero; falha se não houver `style.qss`. O
  `New-RuntimeTree.ps1` copia a instalação inteira, então o tema chega ao instalador sem passo novo.
- **Nenhum arquivo do QGIS mudou:** `Test-Patchset.ps1` dá `PATCHSET OK` com os mesmos 13 arquivos de antes e nenhuma
  linha nova no `PATCHES.md`.
- `tema-na-arvore` (em `build-perfil-novo/result.json` e `instalado-perfil-novo/result.json`): o `style.qss` da árvore
  tem o mesmo sha256 do repo, e `QgsApplication.uiThemes()["IMAN Terra"]` aponta para essa pasta (no instalado, pela
  forma 8.3 do caminho, que é como o QGIS o devolve). Os temas de fábrica seguem ao lado:
  `resources\themes` = `Blend of Gray`, `IMAN Terra`, `Night Mapping`.

### A5 O padrão: medido

- `brand.json` ganha `ui_theme: "IMAN Terra"`; o `build_brand.py` escreve `[UI] UITheme=IMAN Terra` no fim do `.ini`
  gerado e falha se o `.ini` do QGIS já tiver a chave (o QGIS lê `UI/UITheme` sem seção, em `src/app/main.cpp:1459` e
  `src/app/qgisapp.cpp:2874`; o `.ini` do QGIS não tem `[UI]`).

## Bloco B: padrões de projeto

### B6 Projeto novo em EPSG:31984: medido

- `projections\defaultProjectCrs=EPSG:31984` e `projections\newProjectCrsBehavior=UsePresetCrs`, **trocadas no lugar** na
  seção `[app]` (linhas 109 e 114 do `.ini` do QGIS), valores de `brand.json` (`default_project_crs`,
  `new_project_crs_behavior`). O `build_brand.py` exige achar as duas, como as de versão.

### B7 SRC de camada sem SRC: medido

- **A chave que o QGIS lê é `Projections/layerDefaultCrs`, fora da seção `app`:** `src/core/project/qgsproject.cpp:4975`
  (`QgsProject::defaultCrsForNewLayers`) e `src/app/qgisapp.cpp:644`. Vai como `[Projections] layerDefaultCrs=EPSG:31984`
  no fim do `.ini` (`brand.json` `layer_default_crs`).
- **A chave da distro (`[app] projections\layerDefaultCrs`) não era lida**, medido na GUI (`distroLayerKey` em cada
  `theme.json`): gravando `EPSG:5880` em `app/projections/layerDefaultCrs`, `defaultCrsForNewLayers()` seguiu
  `EPSG:31984` no build e `EPSG:4326` no oficial; gravando o mesmo valor em `Projections/layerDefaultCrs`, deu
  `EPSG:5880` nos dois. A hipótese do briefing se confirma.
- Ressalva: com o `projections\unknownCrsBehavior=NoAction` do QGIS (que não mudou), camada sem SRC continua sem SRC ao
  ser carregada; a chave vale para quem escolher "Usar o SRC da camada padrão" e para `defaultCrsForNewLayers()`.

### B8 Dicas ao abrir: medido (sem objeto)

- `git grep -n -i showTips final-3_44_13` acha só `.docker/qgis_resources/test_runner/qgis_setup.sh:38`. O
  `src/ui/qgstipguibase.ui` existe, mas `git grep "QgsTipGui\|qgstipgui" final-3_44_13 -- src` (fora o próprio `.ui`) não
  acha código que o use. Nada a fazer.

## Critérios de aceite

### T1 O tema é o padrão, em três estados de perfil: medido

| Estado | Build | Instalado |
|---|---|---|
| perfil novo | `themeName` = `IMAN Terra`, folha de 10.560 caracteres | igual |
| perfil semeado com o `IMANTerra.ini` da 0.4.0 (sem `UI/UITheme`) | igual | igual |
| **visto falhando:** `UI/UITheme=default` gravado pelo usuário | `default`, folha vazia | N/E (o mecanismo é o do binário, o mesmo) |
| `UI/UITheme=Blend of Gray` gravado pelo usuário | `Blend of Gray` | N/E |

- O perfil semeado é `iman/build/smoke/fixtures/profile-0.4.0/IMANTerra.ini`, cópia byte a byte (sha256
  `8891dd1352eb53ac34d6d933d0ded5a60fe6391c0954c312965bd35abfc37b02`) do perfil gravado pelo IMAN Terra 0.4.0 instalado
  na rodada `installed-20261029-133938` do patch do 047 (revisão `25da3275c5`); só a pasta do cache é trocada pela da
  rodada. Ele tem `[UI]` (estado e geometria da janela) e não tem `UITheme`; o teste confere isso antes de abrir.
- Com folha de estilo, `QApplication.style()` é sempre o `QStyleSheetStyle`; o nome do estilo base fica como fato, não
  como critério.

### T2 Lado a lado por região: medido

Build: `build-perfil-novo/*.png`. Distro: `distro-referencia/022-DEPOIS-titulo-raio-densidade.png` (cópia de
`docs/verify/022-titulo-raio-densidade/evidencia/shots/DEPOIS-titulo-raio-densidade.png` da distro em `df761da`, a janela
com o tema na forma atual, 2026-09-09) e as capturas de `docs/verify/041-tema-no-arranque/evidencia/develop/shots/` da
distro (lidas lá, não copiadas: trazem o caminho do perfil do Windows).

| Região | Build | Distro | Veredito |
|---|---|---|---|
| barra de menus | `03-barra-de-menus.png` | 022 | **igual**: branca, texto escuro, itens com 3px 4px |
| menu aberto | `02-menu-aberto.png` | 022 (menu Camada) | **igual**: branco, borda clara, separadores, raio 2px |
| barra de ferramentas | `04-barra-de-ferramentas.png`, `01-janela.png` | 022 | **igual**: panel-2 com separadores sutis |
| título de dock | `05-dock-titulo.png`, `05b-dock-inteiro.png` | 022 | **igual**: faixa clara; o texto sai escuro nos dois, embora a regra peça `#155F3D` (o QSS não alcança o texto do título nativo, também na distro) |
| abas | `06-abas.png` | sem captura de abas no conjunto da distro | **igual à regra**: aba ativa branca, texto e sublinhado verdes; comparada à regra `QTabBar::tab`, que é a mesma |
| botões | `07-opcoes-src.png`, `08-opcoes-geral.png` | 041 `041-opcoes-pagina-00.png`, 022 (diálogo) | **igual**: OK verde cheio, os demais com contorno verde, raio 2px |
| campos | `07`, `08` | 041 `041-opcoes-pagina-00.png`, `041-propriedades-da-camada.png` | **igual**: brancos, borda clara, raio 2px |
| barra de status | `09-barra-de-status.png` | 022, 018 `A00-status-bar.png` | **cores iguais; o campo de coordenadas corta o primeiro dígito** (STOP D2, achado 1). Na distro, o plugin de marca alargava o campo: essa parte é **fora** |
| cabeçalho de tabela | `10-tabela-de-atributos.png` | sem captura de cabeçalho no conjunto da distro | **igual à regra**: panel-2 com divisórias claras |
| barra de rolagem | `11-barra-de-rolagem.png` | 041 `041-opcoes-pagina-00.png` | **igual**: fina (10 px, contra 14 px do oficial), alça clara |
| dica | `12-dica.png` | sem captura de dica no conjunto da distro | **igual à regra**: branca, borda verde, raio 2px |
| lista lateral de Opções e Propriedades | `07`, `08` | 041 (cinza escuro) | **diferente, pelo mecanismo, não pela regra**: o QGIS só pinta a lista escura quando `UI/UITheme` é `default` (`src/app/qgisappstylesheet.cpp:68-69`); a distro aplicava o QSS pelo startup com o tema `default`, o fork aplica como tema nativo, e a lista fica com a regra `QListView` do QSS (branca) |
| página inicial, botão e "Sobre o IMAN Terra" | não há | 022 (botão verde e cartões da home) | **fora**: dependiam do plugin de marca (fatias próprias, D-IMAN-040) |

Os mesmos arquivos da árvore instalada estão em `instalado-perfil-novo/` e são iguais aos do build região a região.

### T3 As três lições do D-IMAN-033: D1 e D4 medidos e OK; D2 medido e REPROVADO (STOP)

- **D1, o botão de fechar das docks aparece:** `qt_dockwidget_closebutton` visível, 13x15 px, ícone não nulo, 117 pixels
  de tinta (o flutuar ao lado tem 101; a distro medira tinta 0 com a regra antiga); e funciona: o clique fecha a dock e a
  ação do menu a reabre (`dockCloseReopen`). Captura: `05-dock-titulo.png` e `01-janela.png` (canto direito da faixa).
- **D4, o título das docks não é cortado:** faixa de 19 px para fonte de 12 px (`dock` em `theme.json`); captura
  `05-dock-titulo.png`.
- **D2, a coordenada inteira no campo da barra de status: reprovado.** Ver achado 1. Captura `09-barra-de-status.png` e
  `09b-campo-de-coordenadas.png` (build e instalado), controles em `build-escolha-do-usuario-default/` e
  `oficial-visto-falhando/`.
- **A guarda estática pega a regressão de cada lição** (`tema-qss/mutantes-e-distro.txt`): o mutante com
  `titlebar-close-icon: none` cai na asserção 6; `padding: 2px 8px` no `QStatusBar` cai na 3; `padding: 6px 10px` no
  `QDockWidget::title` cai na 4; um raio de 8px cai na 1; um hex fora da paleta cai na 7.

### T4 Zero token órfão: medido

- `pwsh -NoProfile -File iman/build/Test-ThemeQss.ps1` (asserção 7): os 12 hex distintos das regras estão todos na
  paleta do cabeçalho (18 tokens); `tema-qss/result.json`.
- **Visto falhando no original da distro:** o `#95A093` do `QPushButton:disabled` não estava na paleta do cabeçalho dela
  (`linha 121: #95A093 fora da paleta`). É o token `text-faint` da tabela D-IMAN-026 (`docs/design-system.md:49` da
  distro); o cabeçalho portado o lista. Nenhuma cor mudou.
- O único literal de cor fora de hex é `rgba(16,40,30,0.06)` no hover do botão da barra de status, igual ao da distro.

### T5 SRC: medido

- **Projeto novo pela GUI do build:** `QgsProject.instance().crs().authid()` = `EPSG:31984` no arranque e depois de
  `iface.newProject()` ("SIRGAS 2000 / UTM zone 24S"); `build-perfil-novo/result.json`, `T5:src-projeto-novo`.
- **Opções > SRC:** `leProjectGlobalCrs` = `EPSG:31984`, "Usar um SRC padrão" marcado, "Use SRC para adicionar primeira
  camada" desmarcado, `leLayerGlobalCrs` = `EPSG:31984`; captura `07-opcoes-src.png`.
- **Sem duplicata:** `configuracao-global/ini-diff.txt`, cada uma das seis chaves que a marca escreve aparece uma vez no
  `.ini` da instalação.
- **Visto falhando:** o QGIS oficial, na mesma medição, dá `EPSG:4326` no arranque e depois do projeto novo, com
  `UseCrsOfFirstLayerAdded` (`oficial-visto-falhando/result.json`).
- Na árvore instalada, os mesmos valores (`instalado-perfil-novo/result.json`).
- **Relatado, não medido:** o botão de SRC no canto da barra de status. O teste não o achou (`statusBarCrs` nulo em todos
  os alvos, o oficial inclusive) e ele não aparece nas capturas, que são tiradas com o projeto do fixture carregado.
  O SRC do projeto novo está medido pela API e pelas Opções; o canto da barra de status fica para o smoke do sponsor.

### T6 Instalado: medido

- **Máquina sem o IMAN Terra antes** (`ciclo/pre-ciclo.txt`): o 0.4.0 instalado em 2026-10-29 15:10 (o do smoke do
  sponsor) foi desinstalado pelo próprio `unins000.exe`, aberto pelo PID (exit 0, 18 s), sem processo da árvore rodando.
  As sobras do produto foram **renomeadas, não apagadas**, com o sufixo `.antes-049`: `%APPDATA%\InstitutoIMAN\IMANTerra`
  (9 arquivos), `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra` (4 arquivos), `HKCU\Software\InstitutoIMAN\IMANTerra` e a chave
  de notificação do produto (as duas exportadas antes em `.reg`, fora do git). Decisão do sponsor na sessão:
  "Desinstalar e renomear .antes-049". A guarda passou antes e depois.
- **Instalar** (`ciclo/result-install.json`): 89 s, sem elevação, uma entrada `IMAN Terra` `0.4.0`, perfil da distro com o
  mesmo hash.
- **T1 (perfil novo e semeado) e T5 na árvore instalada:** `instalado-perfil-novo/` e `instalado-perfil-semeado-0.4.0/`,
  o produto aberto pelo `bin\iman-terra.exe` com o ambiente de antes do runtime; tudo OK, menos o D2 (achado 1).
- **O tema em** `%LOCALAPPDATA%\Programs\IMAN Terra\apps\qgis-ltr\resources\themes\IMAN Terra\style.qss`, com o sha256 do
  repo (`tema-na-arvore`).
- **Desinstalar** (`ciclo/result-uninstall.json`): 11 s; a pasta, os atalhos, as associações e a entrada saíram; o perfil
  do produto ficou (como no 047). **A sessão terminou com o IMAN Terra desinstalado.**

### T7 Nada regride: medido

- `Test-Installed.ps1` inteiro (`instalado/result.json`): A2 a A9 OK, guarda OK. A primeira rodada caiu no
  `A2:perfil-novo-antes` (achado 2); a segunda rodou com a opção `-ResetProductData` do próprio teste.
- `Test-Patchset.ps1`: `PATCHSET OK` (13 de 13).
- `Test-NoEcw.ps1` (`sem-ecw/result.json`): OK, com o visto falhando no oficial.
- Smoke do 044: no build (`smoke-build/summary.json`, revisão `51968a5220` = HEAD de então) e na árvore instalada
  (`smoke-instalado/summary.json`), todas as checagens OK, as 8 de marca inclusive. **Nenhum `smoke/expected/*.txt` mudou.**
- `Test-RuntimeSet.ps1` (`conjunto/`): reprova só pelo `gdal-ecw` (R1 do gate do `047p`, dívida, não regressão); 152
  pacotes com a mesma lista de arquivos do oficial; o "só no nosso build" ganhou uma linha esperada,
  `apps/qgis-ltr/resources/themes/IMAN Terra/style.qss`.
- **A guarda passou em toda etapa:** em cada rodada de medição, no pré-ciclo, na instalação, nos testes da árvore
  instalada e na desinstalação.

### T8 Gate: N/E nesta pasta

Roda depois do PR aberto (`bash ../iman-product-architect/.claude/crew-hooks/crew_gate.sh qgis-build`); o resultado vai
no `/deliver`. Os testes novos desta fatia não fazem parte do gate (que é do arquiteto).

### T9 Os temas de fábrica: medido

- Opções > Geral lista `Blend of Gray`, `Night Mapping`, `IMAN Terra` e `default`, com `IMAN Terra` selecionado
  (`08-opcoes-geral.png`).
- Escolher funciona: `QgsApplication.setUITheme` troca para `Blend of Gray` (folha de 35.624 caracteres) e `Night Mapping`
  (37.487) e volta ao `IMAN Terra` (10.560); capturas `13-tema-blend-of-gray.png` e `13-tema-night-mapping.png`. E pela
  escolha gravada no perfil, que é o caminho do diálogo depois do reinício: `UI/UITheme=Blend of Gray` abre em
  `Blend of Gray` (`build-escolha-do-usuario-blend-of-gray/`).

## Achados

1. **STOP D2: o tema espreme o campo de coordenadas.** Medido em `coordinateField` de cada `theme.json`, com o mesmo
   ponto (555519,9 9585490,5) e o mesmo campo de 167 px (min = max, fixado pelo QGIS):

   | Alvo | Área útil do texto | Texto precisa | Cabe |
   |---|---|---|---|
   | build, tema `IMAN Terra` (perfil novo e semeado; e instalado) | 147 px | 152 px | **não**: aparece `ı55519,90000  9585490,50000` |
   | build, `UI/UITheme=default` | 161 px | 152 px | sim |
   | QGIS oficial | 161 px | 152 px | sim |

   Causa: a regra geral `QLineEdit, QComboBox, ... { padding: 3px 7px; }` do tema também casa com o campo da barra de
   status, e a regra `QStatusBar QLineEdit` não zera o padding; o QGIS dá ao campo a largura do texto mais 16 px
   (`ensureCoordinatesVisible`, `src/app/qgsstatusbarcoordinateswidget.cpp:397`), e os 14 px de padding mais a borda
   comem quase tudo. Na distro, o plugin de marca alargava o campo (`_ajusta_campo_de_coordenadas`), e esse ajuste não
   volta (D-IMAN-040, emenda de 2026-10-29, item 5). Só uma mudança de regra resolve (por exemplo,
   `padding-left: 0; padding-right: 0` na regra `QStatusBar QLineEdit`, que daria 161 px). Relatado ao sponsor na sessão;
   decisão: **não mexer no tema, relatar e seguir**. O smoke do sponsor vai ver a coordenada cortada.
2. **O build deixa uma pasta de cache do produto em `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra\cache`, com perfil
   descartável.** Medido: apagada a pasta, uma rodada do `Invoke-Smoke.ps1` no build a recria (17:45:53), e uma do
   `Test-ThemeDefaults.ps1` também (17:45:36). É o comportamento já existente do alvo Build (o mesmo nome interno do
   produto), não desta fatia; vira problema só porque o `A2:perfil-novo-antes` do `Test-Installed.ps1` exige a pasta
   ausente, e aqui as medições do build rodaram antes dele (no patch do 047, o `Test-Installed` rodou antes). A segunda
   rodada usou o `-ResetProductData` do próprio teste, que apaga só as pastas do produto (todas desta sessão: as do
   sponsor estão em `.antes-049`). O QGIS oficial não foi tocado (guarda OK). Fica para o arquiteto decidir se o alvo
   Build deve isolar também essa pasta.
3. **O cabeçalho do tema da distro tinha um hex fora da própria paleta** (`#95A093`, T4). Corrigido no cabeçalho, sem
   mudar cor.
4. **A lista lateral escura das Opções** muda pelo mecanismo do QGIS, não pela regra (T2).
5. **O título nativo das docks não sai na cor `#155F3D` da regra** nem no build nem na distro (T2): o QSS do
   `QDockWidget::title` pinta a faixa, e o texto segue escuro.

## Patch 049p: a coordenada volta a caber na barra de status

Briefing `qgis-build #049` PATCH (emenda de 2026-11-04 ao D-IMAN-040), no mesmo PR #5. Ponta medida: `c086bde009`
(V.4: toda captura e medição desta seção sai do build dela e do instalador dela). Medições de 2026-11-04. Evidência em
`patch-049p/`, com o caminho do perfil do Windows trocado por `%USERPROFILE%` nos arquivos de texto.

### O que mudou

- `iman/brand/theme/IMAN Terra/style.qss`: a regra `QStatusBar QLineEdit { padding-left: 0; padding-right: 0; }`, logo
  abaixo da regra `QStatusBar QLineEdit, QStatusBar QComboBox`, e uma frase a mais no comentário D2. O `QComboBox` da
  barra de status, o padding vertical, as cores e os raios não mudaram.
- `iman/build/Test-ThemeQss.ps1`: a asserção 9 nova (a regra `QStatusBar QLineEdit` zera `padding-left` e
  `padding-right`) e a asserção 3 estreitada pela correção de 2026-11-04 do briefing (aceita só `padding-left` e
  `padding-right` com valor `0` ou `0px` num bloco `QStatusBar`; segue reprovando o atalho `padding`, `padding-top`,
  `padding-bottom` e lado com valor diferente de zero). A asserção 3 original reprovava a regra nova (STOP da Crew,
  conferido pelo arquiteto).

### P1 D2 no build: medido, OK

- `T3:D2-coordenada` do `Test-ThemeDefaults.ps1` (que não mudou), o mesmo ponto (555519,9 9585490,5) e o mesmo campo de
  167 px fixado pelo QGIS: **161 px úteis, 152 px de texto, cabe**, no perfil novo e no semeado
  (`patch-049p/build-perfil-novo/result.json`, `patch-049p/build-perfil-semeado-0.4.0/result.json`).
- Captura `patch-049p/build-perfil-novo/09b-campo-de-coordenadas.png`: `555519,90000  9585490,50000`, com o primeiro
  dígito do Leste.
- **Visto falhando:** a medição da `51968a5220`, acima (achado 1): 147 px úteis, o Leste cortado.

### P2 Barra de status inteira: medido, mudou e segue legível

Captura nova `patch-049p/build-perfil-novo/09-barra-de-status.png` contra a `build-perfil-novo/09-barra-de-status.png`
da `51968a5220`, pixel a pixel por faixa da barra (1920x40, as duas):

| Faixa | Pixels diferentes | O que mudou |
|---|---|---|
| localizador | 1228 | o texto de ajuda ("Escreva para localizar") começa 9 px mais à esquerda (primeira coluna de tinta: x 51 para 42), ainda depois da lupa, sem encostar; `09-comparacao-localizador-antes-depois.png` (4x) |
| mensagem ("Carregando camada points") | 1307 | a mensagem começa 8 px mais à esquerda (x 325 para 317) |
| coordenada | 1566 | a coordenada inteira (P1) |
| escala | 0 | nada |
| lupa | 0 | nada |
| rotação | 235 | o `0,0 °` começa 9 px mais à esquerda (x 1598 para 1589); `09-comparacao-rotacao-antes-depois.png` (4x). O topo do glifo já saía rente à borda antes do patch, igual nas duas |
| o resto (Renderizar, mensagens) | 0 | nada |

Nada ficou ilegível: não é STOP. As outras capturas da ponta nova, contra as da `51968a5220`: iguais pixel a pixel no
menu aberto, barra de menus, barra de ferramentas, título de dock, abas, Opções > SRC, barra de rolagem e dica; nas
demais, só a barra de status (janela inteira), a cor sorteada do símbolo da camada de pontos, a data do exemplo e a pasta
da rodada (Opções > Geral), e a tabela de atributos saiu na escala 1,25 (961x441 contra 769x353, o mesmo conteúdo).

### P3 Nada mais mudou: medido, OK

- `Test-ThemeQss.ps1` na árvore: **9 de 9** (`patch-049p/tema-qss/result.json`); 12 raios de 2px, os 2 cantos da aba, zero
  hex órfão (T4), sem `titlebar-close-icon`, sem as regras da camada de marca.
- **Visto falhando e mutantes** (`patch-049p/tema-qss/mutantes-e-41561ea755.txt`): o `style.qss` da `41561ea755` reprova
  na asserção 9; o mutante que tira a regra nova reprova na 9; **o mutante D2 que já existia, o com `padding-left: 1px` e
  o com `padding: 0` na regra nova têm 1 reprovação cada na asserção 3** (os dois últimos também na 9); D1, D4, órfão e
  raio seguem caindo nas asserções 6, 4, 7 e 1.
- Diff sem comentários do `style.qss` contra a `41561ea755`: só a linha da regra nova
  (`diff <(git show '41561ea755:iman/brand/theme/IMAN Terra/style.qss' | strip) <(strip < style.qss)`, com `strip` =
  `perl -0777 -pe 's{/\*.*?\*/}{}gs' | grep -v '^\s*$'`: `> QStatusBar QLineEdit { padding-left: 0; padding-right: 0; }`).
- `Test-ThemeDefaults.ps1` no build: T1 perfil novo e semeado (`IMAN Terra`, folha de 10.929 caracteres: os 10.560 de antes
  mais o comentário e a regra), T1 visto falhando (`UI/UITheme=default` gravado: `default`, folha vazia) e
  `Blend of Gray` gravado (`Blend of Gray`); T5 (`EPSG:31984` no arranque e no projeto novo, Opções > SRC); T9 (os temas de
  fábrica na lista e escolhíveis); D1 e D4 iguais aos de antes. Guarda OK em cada rodada.

### P4 Instalado: medido, OK

- **Máquina sem o IMAN Terra antes** (`patch-049p/ciclo/pre-ciclo.txt`): sem a pasta do produto, sem entrada de
  desinstalação, sem processo da árvore. Os dados do produto da sessão do 049 (2026-10-30) existiam e foram apagados pelo
  `-ResetProductData` do próprio `Test-Installed.ps1`, com o sim do sponsor na sessão (só as pastas e a chave do produto;
  as `.antes-*` e o QGIS oficial não foram tocados).
- Instalador desta ponta: `D:\iman-terra-build\dist\0.4.0-c086bde009\Instituto-IMAN-IMAN-Terra-Setup-0.4.0-c086bde009.exe`,
  512.782.201 bytes, SHA-256 `35802d4dd13a00f19735419c5e87ac32b7dd554d1ac40cd41e74adfcc6205f43`, ISCC 799 s.
- Instalar (`patch-049p/ciclo/result-install.json`): 84 s, sem elevação, perfil da distro intacto, guarda OK.
- `Test-Installed.ps1` inteiro (`patch-049p/instalado/result.json`): A2, A3, A5, A7 e A9 OK, guarda OK.
- `Test-ThemeDefaults.ps1 -Target Installed`, perfil novo (`patch-049p/instalado-perfil-novo/`): T1 (`IMAN Terra`), o
  tema na árvore instalada com o sha256 do repo, T5, T9, D1, D4 e **P1: 161 px úteis, cabe**; capturas `09` e `09b`.
- Desinstalar (`patch-049p/ciclo/result-uninstall.json`): 11 s, a árvore, os atalhos, as associações e a entrada saíram,
  guarda OK. **A sessão terminou com o IMAN Terra desinstalado.**

### P5 Regressões: medido

- `Test-Patchset.ps1`: `PATCHSET OK`, 13 de 13, sem linha nova no `PATCHES.md` (`patch-049p/patchset.txt`).
- `Test-NoEcw.ps1` na árvore instalada: OK, com o visto falhando no oficial (`patch-049p/sem-ecw/result.json`).
- `Test-RuntimeSet.ps1`: reprova só pelo `gdal-ecw` (R1 do gate do `047p`); 152 pacotes com a mesma lista de arquivos; o
  "só no nosso build" é a mesma lista do 049 (`patch-049p/conjunto/`).
- A guarda passou em toda etapa: no build (antes de cada medição), na instalação, nos testes da árvore instalada e na
  desinstalação.

### P6 Gate: N/E nesta pasta

A 2a e última rodada é do sponsor, num terminal com janela própria, depois do push; o resultado vai no `/deliver`.

## Testes pré-existentes

Nenhum teste pré-existente mudou na fatia. Testes novos: `iman/build/Test-ThemeQss.ps1`, `iman/build/Test-ThemeDefaults.ps1`,
`iman/build/smoke/theme_facts.py` e o fixture `iman/build/smoke/fixtures/profile-0.4.0/IMANTerra.ini`.

No patch 049p, por ordem do briefing do patch (lista fechada): `Test-ThemeQss.ps1` ganhou a asserção 9 e teve a asserção
3 estreitada (correção de 2026-11-04). Nenhuma outra asserção, nenhum outro teste e nenhum `smoke/expected/*.txt` mudou.
