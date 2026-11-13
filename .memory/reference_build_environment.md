---
name: reference_build_environment
description: Bancada de build desta maquina: o que a fatia 043 instalou (versoes), onde fica cada coisa, tempos e disco medidos em 2026-10-23; achados de BL-3, build e captura da fatia 044 (2026-10-25); instalador, nome interno e armadilhas da fatia 047 (2026-10-27).
type: reference
---

Medido em 2026-10-22 (arquiteto) e atualizado pela fatia 043 em 2026-10-23. Laudo:
`iman/docs/verify/043-fundacao/README.md`.

- Windows 11 Pro, 24 processadores logicos, 32 GB de RAM. Localidade do Windows em espanhol (a UI do QGIS segue).
- **Instalado pela fatia 043, com o "sim" do sponsor na sessao:** VS 2022 Build Tools 17.14.42 (MSVC 14.44.35207,
  `cl` 19.44.35229, Windows SDK 10.0.26100, ATL) em `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools`
  (12,2 GB a menos no C:). Ferramentas portateis em `D:\iman-terra-build\tools`: CMake 3.29.0, ninja 1.10.2,
  winflexbison 2.5.25. Nada em `C:\OSGeo4W`; sem Cygwin.
- **Raiz de trabalho** `D:\iman-terra-build` (fora do repo): `cache\` (pacotes OSGeo4W do lock, 652 MB), `osgeo4w\`
  (raiz isolada, 2,2 GB), `build\` (14,9 GB), `install\apps\qgis-ltr` (saida, 0,4 GB), `logs\`, `smoke\`, `guard\`.
  Raizes extras da fatia 043: `D:\iman-terra-build-clean` (prova do clone limpo) e `D:\iman-terra-build-latest`
  (matriz "OSGeo4W andou"); podem ser apagadas.
- **Tempos:** do clone limpo ao binario com smoke 31 min; build limpo 22,5 min; incremental de um `.cpp` 26 s;
  configure ~2,5 min; install ~2 min; smoke ~1 min.
- Com o QGIS 3.44.13 oficial em `C:\Program Files\QGIS 3.44.13` (do sponsor: so leitura, nunca alterar; a guarda
  `iman/build/Test-OfficialQgisUntouched.ps1` prova) e o IMAN Terra 0.3.0 da distro em
  `%LOCALAPPDATA%\Programs\IMAN Terra` (congelado). Existe a chave vazia `HKCU\Software\QGIS\QGIS3`.
- `C:\Windows\System32` nao recebe DLL do OSGeo4W: os postinstall `openssl.bat` e `opencl.bat` nao rodam.
- Clone deste repo: parcial (`--filter=blob:none`), `core.longpaths=true`, `core.autocrlf=false`; remoto
  `upstream` = `qgis/QGIS` (nunca `git fetch --all`: baixa o QGIS inteiro).
- `gh` autenticado com escopo `repo`; o PR da fatia e contra `develop` deste fork.

Medido na fatia 044 (2026-10-25), laudo `iman/docs/verify/044-marca-no-fonte/README.md`:

- **Nome interno compartilhado com o QGIS oficial (BL-3):** sem `cache/directory` no perfil, o QGIS (build ou
  oficial) grava o cache de rede em `%LOCALAPPDATA%\QGIS\QGIS3\cache`; o crash handler grava em
  `%LOCALAPPDATA%\QGIS\QGIS3\crashes`; o WinToast valida a cada abertura `%APPDATA%\Microsoft\Windows\Start
  Menu\Programs\QGIS3.lnk` (hoje do spike 016 da distro, 2026-09-06). O smoke semeia `[cache] directory` no perfil
  descartavel (`New-DisposableProfile`) e a guarda vigia as tres coisas. Resolve de vez so com o nome interno
  (fatia do instalador). Decisao do sponsor: mitigar e seguir.
- **Ninja nao rastreia o `.ico` do `qgis_win32.rc`:** o `Build-Qgis.ps1` remove o `.res` mais velho que o `qgis.ico`.
- **Build incremental depois de mudar so a marca:** build ~60 s, `cmake --install` ~330 a 370 s (o install domina).
- **Python fixado com Pillow:** o `python3` da raiz OSGeo4W (3.12.13) tem Pillow 12.3.0 (do lock); e o que roda
  `iman/brand/derive_assets.py`. Fora do `o4w_env` ele nao sobe.
- **Captura de janela:** o pwsh 7 nasce com a consciencia de DPI fixada; `WindowCapture.ps1` usa DPI por thread.
  Testar captura so com janela criada pelo proprio teste, nunca com app do usuario (o Bloco de Notas do Windows 11
  restaura as abas da sessao do usuario).

Medido na fatia 047 (2026-10-27), laudo `iman/docs/verify/047-instalador/README.md`:

- **Nome interno proprio** (`InstitutoIMAN`/`IMANTerra`): o produto grava em `%APPDATA%\InstitutoIMAN\IMANTerra`,
  `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra` (cache, crashes) e `HKCU\Software\InstitutoIMAN\IMANTerra`; o `.ini`
  do perfil e `<perfil>\InstitutoIMAN\IMANTerra.ini` (o `New-DisposableProfile` semeia pelo alvo). O R2 do 044
  (gravar em `QGIS\QGIS3`) fechou.
- **Inno Setup 7.1.0** ja estava em `C:\Program Files\Inno Setup 7`; sem version info (0.0.0.0): a versao sai da
  linha `Compiler engine version` (sonda no `Build-Installer.ps1`). ISCC da arvore de 2,2 GB: 751 a 857 s, 489 MB.
- **Do Git Bash, `tar.exe` e o GNU tar do Git** (le `D:\` como host): os scripts usam `$TarExe` (System32). O gate
  roda do Git Bash.
- **WinToast:** cria `Start Menu\Programs\<QGIS_WIN_APP_NAME ou o nome interno>.lnk`. O `Import-QgisRuntime` passa uma
  pasta inexistente para o build de desenvolvimento nao criar atalho; o produto instalado valida o `IMAN Terra.lnk` do
  instalador.
- **`PYQGIS_STARTUP`** roda antes do pacote `qgis` estar no `sys.path` (so PyQt5 no topo do script).
- **Hook da Crew:** comando de shell que cita `.env` (mesmo `iman-terra.env` em comentario) e bloqueado; editar pelo
  Edit/Write.
- **A 0.3.0 da distro foi substituida e desinstalada** nesta maquina pelo A6 (com o sim do sponsor); o perfil dela em
  `%APPDATA%\InstitutoIMAN\IMAN Terra` ficou com o mesmo hash. O IMAN Terra 0.4.0 tambem foi desinstalado no fim.
- Sem Debugging Tools do Windows SDK: o `dbghelp.dll`/`symsrv.dll` do pacote `qgis-ltr` oficial nao tem fonte aqui.
  (Superado pelo patch de 2026-10-29, abaixo.)

Medido no patch da fatia 047 (2026-10-29), laudo `iman/docs/verify/047-instalador/README.md`, secao "Patch de
2026-10-29":

- **Debugging Tools for Windows instaladas** com o sim do sponsor (so o feature `OptionId.WindowsDesktopDebuggers` do
  SDK 10.0.26100.7705, pelo `winsdksetup` em cache; UAC; 20 s): `C:\Program Files (x86)\Windows Kits\10\Debuggers\x64`.
  O `dbghelp.dll`/`symsrv.dll` 10.0.26100.7705 de la vai para `apps\qgis-ltr` com o sha256 fixado no `Common.ps1`;
  atualizar o SDK muda o hash e o `New-RuntimeTree.ps1` recusa.
- **O 0.4.0 NAO tinha sido desinstalado** no fim da fatia 047 (o registro acima estava errado): estava em
  `%LOCALAPPDATA%\Programs\IMAN Terra`. O patch o desinstalou e terminou com o IMAN Terra desinstalado.
- **Sobras renomeadas, nao apagadas** (sufixo `.antes-047-patch`, decisao do sponsor): `%APPDATA%` e `%LOCALAPPDATA%`
  `\InstitutoIMAN\IMANTerra`, `HKCU\Software\InstitutoIMAN\IMANTerra` e a chave de notificacao do AUMI do produto (o
  A3 exige que ela nao exista antes). Os `.reg` exportados ficam em `D:\iman-terra-build\verify\patch-047-pre-ciclo`.
  Depois do ciclo, os nomes sem sufixo voltaram a existir (perfil da rodada).
- **Disco:** D: com 9,5 GB livres no comeco (seguiu por decisao do sponsor), 105 GB no fim; C: 259 GB.
- **Memoria:** um build em segundo plano foi interrompido pelo ambiente por pouca memoria (com ~9 GB livres); o
  Claude Code nao reinicia sozinho. O incremental retoma de onde parou.
- **Tempos:** arvore de runtime 58 a 111 s; ISCC 709 s; instalar 88 s; desinstalar 11 a 15 s.

Medido na fatia 049 (2026-10-30), laudo `iman/docs/verify/049-tema-e-padroes/README.md`:

- **O 0.4.0 estava instalado de novo** (2026-10-29 15:10, smoke do sponsor). Desinstalado pelo `unins000.exe` (18 s) e
  as sobras do produto renomeadas com o sufixo `.antes-049` (decisao do sponsor; `.reg` em
  `D:\iman-terra-build\verify\049-pre-ciclo`). Ficaram tambem as `.antes-047-patch`. A sessao terminou desinstalado.
- **Rodar o alvo Build cria `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra\cache`**, mesmo com perfil descartavel (o
  `Invoke-Smoke.ps1` tambem). O `A2:perfil-novo-antes` do `Test-Installed.ps1` exige a pasta ausente: rodar o
  `Test-Installed` antes das medicoes do build, ou com `-ResetProductData`.
- **O QGIS instalado devolve caminhos na forma 8.3** (`C:/Users/FRANCI~1/...`): comparar pastas pela forma curta.
- **Captura da barra de status logo depois de mudar a coordenada sai com o layout velho** (rotulo e icone sobre o
  campo, no oficial tambem): mudar antes da espera. O `QToolTip.showText` so aparece no ciclo de eventos seguinte.
- **O painel Navegador lista as unidades da maquina com nome e e-mail de conta:** fora de captura que vai para o laudo.
- **Disco:** D: com 33 GB livres no comeco (abaixo do teto de 50 GB do briefing; seguiu por decisao do sponsor), 31 GB
  no fim; C: 254 GB.
- **Tempos:** build incremental (so qgsversion.h) 51 s + install 173 s; arvore de runtime 85 s; ISCC 741 s; instalar
  89 s; desinstalar 11 s.


Medido no patch 049p (2026-11-04), laudo `iman/docs/verify/049-tema-e-padroes/README.md`, secao "Patch 049p":

- **Dados do produto da sessao 049 apagados** pelo `-ResetProductData` do `Test-Installed.ps1` (sim do sponsor); as
  `.antes-*` ficaram. Depois do ciclo, `%APPDATA%\InstitutoIMAN\IMANTerra` voltou a existir (perfil da rodada, fica na
  desinstalacao) e o cache do alvo Build tambem: o proximo `Test-Installed` precisa de novo do `-ResetProductData`.
- **O gate pelo pwsh desta ferramenta caiu no titulo do console** (0xE9, rodada 1 da fatia 049): o build aninhado nao
  tem console. A rodada do gate vai para o sponsor, num terminal com janela propria.
  **Vencida pela fatia 061** (briefing 063, correcao de 2026-11-13): a 061 rodou o gate por esta ferramenta
  (`pass_e0c555b4f2`, 2026-11-11 15:26, 268 s). A Crew roda o gate depois do PR aberto; se cair, a rodada conta e o
  `/deliver` cola a saida do erro.
- **Captura da tabela de atributos** saiu na escala 1,25 numa rodada (961x441 contra 769x353): comparar por regra, nao
  por tamanho.
- **`gh` sem `--repo` resolve para o upstream `qgis/QGIS`** (o remoto `upstream`): o `/deliver` da 049 leu "sem PR" assim, com o PR #5 aberto. Todo `gh` leva `--repo camelloncaseoficial/iman-qgis-build-agent`.
- **Disco:** D: 92 GB livres no comeco; C: 226 GB.
- **Tempos:** build incremental (so o qgsversion.h) 70 s + configure 185 s + install 153 s, 7 min no total; arvore de
  runtime 62 s; ISCC 799 s; instalar 84 s; desinstalar 11 s.

Medido na fatia 051 (2026-11-08), laudo `iman/docs/verify/051-plugin-reurb-embarcado/README.md`:

- **Clone do plugin** em `..\iman-qgis-plugin-agent` com `core.autocrlf=true`: o `git archive` converte o fim de linha,
  e por isso o `Export-ImanPlugin` passa `-c core.autocrlf=false`. O build so le o clone (tag e objetos); as tags dos
  testes de falha vivem num clone `--shared` descartavel.
- **Dados do produto apagados** de novo pelo `-ResetProductData` (sim do sponsor); as `.antes-*` ficaram. Depois, o
  alvo Build recriou o cache do produto: o proximo `Test-Installed` precisa do `-ResetProductData`. A sessao terminou
  desinstalada.
- **O `python3` da raiz OSGeo4W nao sobe fora do `o4w_env`** (sem `encodings`): para rodar o `build_brand.py` a mao,
  qualquer Python 3 serve (so biblioteca padrao).
- **Disco:** D: com 46 GB livres no comeco; C: 191 GB.
- **Tempos:** build incremental + install 4 a 7 min; arvore de runtime 107 a 115 s; ISCC 949 s; instalar 253 s;
  desinstalar 12 s; `Test-PluginBoot` 10 a 15 s por estado.

Medido na fatia 058 (2026-11-11), laudo `iman/docs/verify/058-higiene-e-tema-do-smoke/README.md`:

- **O 0.4.0 estava instalado** (smoke do sponsor, 2026-11-09) e **aberto** pelo sponsor no comeco: renomear os dados do
  produto com ele aberto falha no perfil (`%APPDATA%`, em uso). Conferir `Get-Process` pelo caminho de
  `Programs\IMAN Terra` antes e pedir ao sponsor para fechar; nunca fechar processo dele.
- **Sobras `.antes-058`** (sim do sponsor): `%APPDATA%` e `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra.antes-058`,
  `HKCU\Software\InstitutoIMAN\IMANTerra.antes-058` e a chave de notificacao do AUMI com `.antes-058`; `.reg` em
  `D:\iman-terra-build\verify\058-pre-ciclo`. A sessao terminou desinstalada; `%APPDATA%\InstitutoIMAN\IMANTerra` voltou
  a existir (perfil do `Test-Installed`).
- **A pasta `cache` do produto** vem do HSTS do Qt (`qgsnetworkaccessmanager.cpp:223`), no fechamento de todo
  `qgis_process` e de toda GUI; os testes do alvo Build a removem no fim (`Restore-ProductData`, `Common.ps1`). O
  `Test-Installed` depois das medicoes do build passa sem `-ResetProductData`. O `qgis_process` (o oficial tambem)
  grava em `%LOCALAPPDATA%\qgis_process\cache\http-ranges`.
- **`NoDefaultCurrentDirectoryInExePath=1`** no ambiente do terminal do agente: o `cmd` nao acha executavel na pasta
  atual (o `vswhere` do `VsDevCmd.bat`). O `Import-VsEnvironment` limpa a variavel so no `cmd` do `vcvarsall`.
- **`cdb.exe`** das Debugging Tools (`C:\Program Files (x86)\Windows Kits\10\Debuggers\x64`) com
  `bp KERNELBASE!CreateDirectoryW "du @rcx; k 40; gc"` acha quem cria uma pasta; os PDB do build ficam em
  `D:\iman-terra-build\build\apps\qgis-ltr\pdb`.
- **Notificacao do AUMI:** com a chave `Notifications\Settings\InstitutoIMAN.IMANTerra...` renomeada, o Windows nao a
  recriou e o toast caiu na barra de mensagens (`A3:notificacao` do `Test-Installed` reprovado nas rodadas 2 e 3).
- **Tema:** o `QToolBar` le o padding do QSS so pelo lado esquerdo e o aplica nos quatro; `0` sem unidade nao serve. O
  `grab()` de widget de fundo transparente sai sobre preto: medir pela janela.
- **Disco:** D: com 35 GB livres no comeco; C: 176 GB.
- **Tempos:** build incremental 98 s + install 285 s; arvore de runtime 91 a 94 s; ISCC 744 s; instalar 290 s;
  desinstalar 12 s; `Measure-ThemeRegions` 25 a 35 s.

Medido na fatia 061 (2026-11-11), laudo `iman/docs/verify/061-plugin-0-4-0/README.md`:

- **Plugin 0.4.0 embarcado** (tag `v0.4.0`, `4f7cff8998`). O sponsor instalou o IMAN Terra da 058 as 14:20; a 061 foi
  instalada por cima e **ficou instalada** para o smoke dele (sem desinstalar). Pasta e chave do produto nao foram
  renomeadas (briefing); o `Test-Installed.ps1` nao roda com o perfil do sponsor no lugar.
- **Projeto REURB v3 descartavel:** `D:\iman-terra-build\verify\plugin-migration-seed-build-20261111-145407\semente`
  (plugin 0.3.1, um lote, uma pessoa sem documento, um vinculo). `Test-PluginMigration.ps1 -Phase Migrate -SeedRun`
  reusa a semente.
- **A migracao so dispara ao reabrir pelo plugin** (`OpenReurbProjectService.read`, o botao "Reabrir projeto"); abrir o
  `.qgz` nao migra. A copia `<gpkg>.bak` nao e byte a byte o arquivo: o GDAL tira o modo WAL ao abrir (bytes 18, 19,
  27 e 95 do cabecalho).
- **Tempos:** build incremental + install 4 a 5 min; arvore 59 s; ISCC 770 s; instalar 159 s.

Medido na fatia 059 (2026-11-12), laudo `iman/docs/verify/059-prototipo-pagina-inicial-e-sobre/README.md`:

- **Pagina inicial e Sobre do produto** em `src/app/iman/` (C++ do `qgis_app`); a `QgsWelcomePage` segue criada, fora
  da tela. O estilo delas fica no C++ com as cores `IMAN_COLOR_*` do `iman_brand.h` (paleta do cabecalho do
  `style.qss`): o `Test-ThemeQss.ps1` exige 12 `border-radius` no tema, regra nova la o derruba.
- **`THIRD_PARTY_NOTICES.md` na raiz do install** (`D:\iman-terra-build\install`), copiado pelo `Build-Qgis.ps1`: o
  Sobre o le dois niveis acima do prefixo, como no instalado (`{app}`).
- **Captura com dado da maquina:** o painel Navegador e a pagina Navegador do gerenciador de fontes listam as unidades
  com o e-mail das contas; o dialogo de abrir projeto abre na pasta pessoal e mostra o nome da conta na barra
  lateral. O `capture_home.py` esconde o painel, troca a pagina e aponta o dialogo para a pasta da rodada.
- **Escala da tela 125%:** tamanhos de janela do Qt sao logicos (maximizada 1536x889, imagem 1920x1111).
- **Nada instalado** nesta fatia; o IMAN Terra da 061 segue instalado para o smoke do sponsor.
- **Tempos:** configure + build 289 s, install 372 s; incremental so com o commit 100 s + install 378 s; capturas da
  059 cerca de 70 s; smoke 30 s. D: com 33 GB livres.

Medido na fatia 063 (2026-11-13), laudo `iman/docs/verify/063-tema-padrao-do-qgis/README.md`:

- **Tema do produto fora do build:** sem `ui_theme` no `brand.json` e sem `[UI]` na global; o `Build-Qgis.ps1` remove a
  pasta `resources\themes\IMAN Terra` que um build anterior deixou (o `cmake --install` nao apaga o que nao instala).
- **`UI/UITheme` ausente e nao `default`:** o `main.cpp:1459` le a chave sem valor padrao; vazia, o QGIS usa `fusion`
  (`QgsAppStyle` sobre `QFusionStyle`), como o oficial; `default` daria o estilo do Windows. Todo perfil (o do oficial
  tambem) termina com `qgis/style=fusion`, gravado pelo `main.cpp:1487`.
- **Captura em pixels fisicos:** o `grab()` sai na escala da tela (1,25); retangulo de `subControlRect` e logico e
  precisa ser multiplicado pelo `devicePixelRatio` da imagem antes de medir.
- **Botao com menu do QGIS** monta a lista com `addAction`, sem `setMenu`: `menu()` volta `None`; achar por
  `popupMode() == MenuButtonPopup` e `actions()`.
- **Commit no meio do build:** o `qgsversion.h` sai do HEAD do comeco do build; um commit depois disso faz o
  `version` do smoke cair (revisao diferente do HEAD). Commitar antes do build, ou refazer o incremental (7 min).
- **Perfil da develop** para reabrir com outro build: `D:\iman-terra-build\verify\063-perfil-da-develop`.
- **Disco:** D: com 35 GB livres no comeco. **Tempos:** build com a volta da 059 393 s + install 355 s; incremental so
  com a marca 95 a 101 s + install 303 a 390 s; setas 40 s; perfis 12 a 20 s; `Test-ThemeDefaults` 40 s.
- Nada instalado; o IMAN Terra da 061 segue instalado (com o tema) para o smoke do sponsor.

Medido na fatia 064 (2026-11-13), laudo `iman/docs/verify/064-destaque-iman-pela-paleta/README.md`:

- **Paleta da marca no `brand.json`** (`palette`, 18 tokens); o `build_brand.py` valida e falha se faltar token que
  o C++ usa (varre as `IMAN_COLOR_*` de `src/app/iman`). O `style.qss` nao e mais lido pelo build.
- **Destaque pela paleta:** `ImanPalette::applyHighlight` (desde a 065, `ImanPalette::apply`) no `main.cpp`, depois do `setStyle`; precisa de `APP_EXPORT`
  porque o `main.cpp` vai no executavel e o `imanpalette.cpp` no `qgis_app`. O `QgisAppStyleSheet` monta a cor de
  selecao da `QTableView` com a paleta do momento: a tabela pega o verde sem QSS novo.
- **Fusion pinta a selecao das arvores em degrade** em torno da cor da paleta (`#1D784C` a `#1E7E4F` para
  `#1E7A4D`): medir pela media da faixa, nao pela cor mais comum.
- **Tabela de atributos:** a linha selecionada segue a selecao de feicoes (`QgsFeatureSelectionModel`); `selectRow`
  nao seleciona; usar `selectByIds` na camada.
- **Opcoes do QGIS 3.44:** o `QgsOptions` so salva pelo OK da caixa de botoes (o `accept()` nao salva); o widget se
  chama `buttonBox` (o `mOptButtonBox` e so a referencia). Tema e estilo so valem ao reabrir (`uiThemeChanged` nao
  esta ligado). Depois de um OK, `UI/UITheme=default` fica gravado e o `qgis/style` escolhido passa a valer.
- **Estilo `windowsvista`** desenha a selecao com a cor do Windows (`#CCE8FF`) e ignora o `Highlight` da paleta.
- **Tempos:** build desta branch 147 s + install 319 s; destaque 30 s; casos 10 a 30 s; capturas da 059 50 s.
- Nada instalado; o IMAN Terra da 061 segue instalado (com o tema antigo) para o smoke do sponsor.

Medido na fatia 065 (2026-11-13), laudo `iman/docs/verify/065-fundo-das-janelas-pela-paleta/README.md`:

- **Fundo pela paleta:** `ImanPalette::apply` aplica o destaque e o `Window` = `bg` (Active, Inactive e Disabled) num
  unico `setPalette`; a proxima cor de paleta entra no mesmo lugar, sem segunda linha no `main.cpp`.
- **O que segue o `Window` no Fusion:** barra de menus, barra de status, titulo dos paineis, fundo de dialogos, a
  barra de ferramentas (em degrade que clareia), a caixa de lista aberta (nao fica branca) e o contorno de campos,
  quadros e abas (mais escuro, levemente esverdeado). O menu aberto segue branco.
- **O que nao segue:** o painel das abas (`QTabWidget`) fica `#FCFCFC`, derivado do `Button`; as listas laterais das
  Propriedades, das Opcoes e do QgsAbout tem folha propria do QGIS (`qgisappstylesheet.cpp`, cinza semitransparente;
  o item selecionado usa `palette(window)`).
- **Medida por regiao:** mascarar os filhos de `Base` (listas, arvores, tabelas, campos) antes da cor mais comum; a
  arvore lateral das Opcoes e `mOptionsTreeView`, a lista das Propriedades e `mOptionsListWidget`; grupo recolhido
  nao serve de quadro.
- **Pagina inicial:** comparar so a area dela (pixels `bg` do ANTES); os recentes levam o carimbo de hora da pasta da
  rodada no caminho e o selo leva o commit.
- **Tempos:** build incremental 210 s a 255 s; regioes 30 s; casos 10 a 25 s.
- Nada instalado; o IMAN Terra da 061 segue instalado para o smoke do sponsor.
