# Laudo 047: o instalador, o nome interno, o runtime do oficial e os notices

Briefing `qgis-build #047` (D-IMAN-043, regra 5 do D-IMAN-041, sob o D-IMAN-040, o D-IMAN-025 e o D-IMAN-030). Branch
`feat/047-instalador`, nascida de `origin/develop` `f640169532`. Máquina: Windows 11 Pro em espanhol, 24 processadores
lógicos, 32 GB. Medições de 2026-10-27.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (dito por fonte externa
ou não observável por este teste, com o motivo), **N/E** (não executado).

O instalador final é o do commit `14f1fd4efd`: `D:\iman-terra-build\dist\0.4.0-14f1fd4efd\Instituto-IMAN-IMAN-Terra-Setup-0.4.0-14f1fd4efd.exe`
(512.806.527 bytes, SHA-256 `905492bb1b3ae956218a1685b16404997732393c6f71917d8d7821b344073ae1`, Inno Setup 7.1.0;
`instalador/BUILD_INFO.txt`). Ele **não entra no git** e
não foi distribuído. Nos arquivos de texto da evidência, o caminho do perfil do Windows virou `%USERPROFILE%`.

| Pasta | O que é |
|---|---|
| `guarda/` | `Test-GuardAreas.ps1` (cada área nova reprova com o retrato adulterado) e `Test-GuardRounds.ps1` (A1) |
| `upgrade-0.3.0/` | a atualização sobre a 0.3.0 da distro (instalador `d64b622a4f`), o perfil da distro antes e depois (A6) |
| `instalador/BUILD_INFO.txt` | a identidade do instalador final: commit, versão 0.4.0, Inno Setup 7.1.0, SHA-256 (A10, DC-3) |
| `instalado/` | `Test-Installed.ps1` no instalador final: A2, A3, A5, A7, A9 e os fatos de dentro do processo |
| `conjunto/` | `Test-RuntimeSet.ps1` na árvore instalada (A4) |
| `smoke-instalado/` | o smoke de comportamento do 044 contra a árvore instalada (A4, A5) |
| `capturas-instaladas/` | o "Sobre", a janela, o crash handler e a caixa de erro da árvore instalada (A9) |
| `ciclo-limpo/` | instalar e desinstalar o instalador final com a pasta inexistente (A6) |
| `ciclo-pasta-preexistente/` | o mesmo com a pasta `IMAN Terra` já existente (achado 6) |
| `licencas-osgeo4w/termos-medidos.txt` | os termos de ECW, MrSID, Oracle, ODBC e SZIP, com o md5 do `setup.ini` (A8, STOP) |
| `SHA256SUMS.txt` | hash de cada arquivo desta pasta (A11) |

## Veredito

**Os cinco blocos (A a E) fecharam e todo critério de A1 a A11 tem evidência, com duas ressalvas declaradas: a
captura da notificação (relatado, o toast é janela do Windows) e a tela de licença do instalador (relatado, vista no
smoke do sponsor).** O produto agora tem nome interno próprio (`InstitutoIMAN`/`IMANTerra`), roda de uma árvore igual à
do QGIS oficial (153 pacotes, mesma versão e mesma lista de arquivos de cada um, mais o nosso build), abre pelo atalho
sem PowerShell nosso, instala e desinstala por usuário sem elevação, e o QGIS oficial ficou intocado em toda etapa.

Um STOP disparou e foi decidido pelo sponsor na sessão: o termo do `gdal-ecw` (achado 1). Três decisões do sponsor na
sessão estão no achado 1 e no A6. A VM limpa (BL-7) segue lacuna declarada.

## A1 Evidência e guarda: medido

- **`.gitattributes`:** `iman/docs/verify/.gitattributes` com `* -text`. Num clone com `-c core.autocrlf=true`
  (`git clone --no-checkout -c core.autocrlf=true`, sparse em `iman/docs/verify/`), `sha256sum -c`:
  - **visto falhando** (antes, em `f640169532`): o 044 cai em 54 de 54, porque o próprio `SHA256SUMS.txt` vira CRLF e
    cada nome ganha um `\r`; com a lista normalizada (`tr -d '\r'`), caem os 4 que o arquiteto mediu: o `SHA256SUMS.txt`
    e 3 de conteúdo (`README.md`, `curadoria-medida.txt`, `curadoria.md`);
  - **depois** (em `218ef5763c`): 043 9 de 9 OK, 044 54 de 54 OK. O 043 não tinha `SHA256SUMS.txt`: esta fatia o gerou
    dos blobs commitados (`git cat-file blob HEAD:<caminho>`), sem mexer em nenhum arquivo do laudo.
- **A guarda cresceu** (`iman/build/Test-OfficialQgisUntouched.ps1`): a pasta do oficial no Menu Iniciar de todos os
  usuários e a chave de desinstalação do MSI oficial `{740D7A65-CBA3-1014-A0B5-B03A9B7608F5}` entram inteiras; HKCR e
  `HKCU\Software\Classes` para `.qgs`, `.qgz`, `.qlr` e os ProgIDs do oficial (`QGIS Project`, `QGIS Layer
  Definition`), o `UserChoice` dos três tipos, toda chave de `HKCU\Software\Classes` (e `Applications\`) cujo nome fala
  de QGIS e as configurações de notificação cujo nome começa por `QGIS` entram **valor a valor**. Valor ou chave com o
  nome do próprio produto (`IMANTerra.*`) fica fora: o "Abrir com" do produto não é mudança do oficial.
- **Cada área nova reprova pelo retrato adulterado, nunca pelo sistema** (`guarda/areas-result.json`,
  `Test-GuardAreas.ps1`): controle sem adulteração exit 0; `hkcr-associacoes-e-progids`, `hkcu-software-classes`,
  `userchoice`, `notificacoes`, `menu-iniciar-do-oficial` e `desinstalacao-do-msi-oficial` exit 1 cada. O teste de
  rodadas do 044 (`guarda/rodadas-result.json`) segue passando com a guarda nova.
- **R3 vira regra escrita:** `CLAUDE.md`, "Processo alheio não se toca". Todo processo aberto pelos testes desta fatia
  foi aberto e fechado pelo PID que o próprio teste recebeu (o produto pelo `ShellExecute` do atalho, o crash handler,
  o processo "travado" descartável, o instalador e o desinstalador).

## A2 Nome interno: medido (o "visto falhando" relatado)

Fonte única: `iman/brand/brand.json` ganhou `internal_organization_name` `InstitutoIMAN`,
`internal_organization_domain` `institutoiman.org.br` e `internal_application_name` `IMANTerra`, separados do
`organization_name` de exibição; o `iman_brand.h` gerado as leva para o C++. Três arquivos do QGIS mudaram por isso
(`iman/PATCHES.md`): as três constantes em `src/core/qgsapplication.cpp`, os literais do `qgis_process`
(`src/process/main.cpp`) e os do crash handler (`src/crashhandler/main.cpp`). O patchset passou de 12 para 13 arquivos
(`Test-Patchset.ps1`: `PATCHSET OK`; `git diff --shortstat final-3_44_13..HEAD` fora de `iman/`: 13 arquivos, 96
inclusões, 25 remoções; desta fatia, 3 arquivos, 13 inclusões, 8 remoções).

No produto instalado, num perfil novo (`instalado/result.json`; antes, as três coisas ausentes):

| O que | Onde ficou | Fonte |
|---|---|---|
| Perfil | `%APPDATA%\InstitutoIMAN\IMANTerra\profiles\default` | `QgsApplication.qgisSettingsDirPath()` de dentro do processo |
| Configurações do perfil | `...\profiles\default\InstitutoIMAN\IMANTerra.ini` | `QSettings().fileName()` |
| Cache | `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra\cache` | `QStandardPaths.CacheLocation` |
| Crashes | `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra\crashes\<uuid>` | crash handler instalado, relatório sintético |
| Registro | `HKCU\Software\InstitutoIMAN\IMANTerra` (criada) | `Test-Path` antes e depois |
| Organização, domínio, aplicação | `InstitutoIMAN`, `institutoiman.org.br`, `IMANTerra` | `QgsApplication` de dentro do processo |

- **`qgis_process`** (`bin\qgis_process-iman-terra.bat --json plugins`, sem perfil customizado): lista o plugin
  marcador `iman_marcador_047` posto só em `%APPDATA%\InstitutoIMAN\IMANTerra\profiles\default\python\plugins`
  (`instalado/qgis_process-plugins.json`): ele lê os perfis da pasta nova. O marcador foi apagado em seguida.
- **O oficial:** a guarda passa em toda etapa; nada novo em `QGIS\QGIS3`.
- **Visto falhando, relatado:** rodar um build com a constante de volta a `QGIS3` grava em `%LOCALAPPDATA%\QGIS\QGIS3` e
  `HKCU\Software\QGIS\QGIS3`, que são áreas do QGIS oficial. O sponsor decidiu na sessão não rodar ("Não, fica
  relatado"). O que sustenta o critério sem tocar o oficial: o 044 mediu essa escrita com o nome `QGIS3` (R2 do gate do
  044), e a guarda reprova mudança nessas áreas (rodadas e áreas acima).

## A3 Um atalho só: medido (a captura da notificação relatada)

- Depois de instalar e abrir o produto pelo atalho, o Menu Iniciar tem **um** atalho do produto,
  `%APPDATA%\Microsoft\Windows\Start Menu\Programs\IMAN Terra.lnk`. O AUMI dele (`System.AppUserModel.ID`, gravado pelo
  `AppUserModelID:` do `[Icons]`) e o do processo (`GetCurrentProcessExplicitAppUserModelID` de dentro do processo) são
  iguais: `InstitutoIMAN.IMANTerra.IMANTerra.3.44.13-Solothurn`. O mtime do atalho não mudou com a abertura: o WinToast
  validou o atalho do instalador (o `.env` traz `QGIS_WIN_APP_NAME=IMAN Terra`) e não criou outro.
- O `QGIS3.lnk` do oficial não foi regravado: a guarda o vigia e passou.
- **Notificação:** uma tarefa visível de 6 s (o QGIS notifica tarefa com 5 s ou mais) terminou `completed`; não caiu na
  barra de mensagens (o caminho de quando a notificação nativa falha); e o Windows criou
  `HKCU\...\Notifications\Settings\InstitutoIMAN.IMANTerra.IMANTerra.3.44.13-Solothurn`, que não existia antes. A
  **captura do toast fica relatada**: o toast é janela do Windows, não do processo que o teste abriu (regra R3).

## A4 Conjunto igual ao oficial: medido

- **O lock** (`iman/build/osgeo4w.lock.tsv`): o `Resolve-Osgeo4wLock.ps1` passou a usar o `installed.db` oficial como
  raiz. 191 linhas: as 156 antigas idênticas (colunas 1 a 7) e 35 novas, todas na versão do `installed.db` oficial e
  todas no mirror, com hash gravado no primeiro download (86,98 MB). Coluna nova `Runtime`: `official` em 153
  (entram na árvore) e `build-only` em 38 (os `-devel` e os `dated` só de compilação: `fcgi`, `hdf5-tools`,
  `python3-oauthlib`, `python3-pyqt-builder`, `qt5-oci` e os `-devel`). O briefing contava 26 `python3-*` novos; o
  medido é **27** (41 = 6 `qgis-ltr*` + 8 + 27).
- **Pacotes** (`conjunto/result.json`, na árvore instalada): `installed.db` com 154 pacotes; sem o nosso build, 153;
  o oficial tem 159, sem os 6 `qgis-ltr*`, 153. **Diferença de nome e versão: vazia. `-devel`: nenhum.**
- **Arquivos de cada pacote:** a lista de cada um dos 153 `<pacote>.lst.gz` contra a do oficial: **0 com diferença**
  (o oficial grava a saída verbosa do `tar`; compara-se o caminho, com o hardlink `qt.conf` do `qt5-libs` normalizado).
- **O nosso build no lugar dos `qgis-ltr*`** (`conjunto/qgis-ltr-so-*.txt`): só no nosso, os 8 DLLs do VC++ 14.44 em
  `apps\qgis-ltr\bin` e o `iman_pt_BR.qm`; só no oficial, `qgis.reg.tmpl` (a associação do oficial, que não usamos) e
  `dbghelp.dll`/`symsrv.dll` (achado 3). O que o `cmake --install` produz e os `qgis-ltr*` não têm (o `-devel`, o
  servidor, os `.pyc`) não entra na árvore; os plugins Qt e o widget-plugin que ele grava na raiz de build entram nos
  lugares do pacote oficial (`New-RuntimeTree.ps1`).
- **Comportamento** (`smoke-instalado/summary.json`): 7 provedores, 426 ids de algoritmo e os plugins `grassprovider` e
  `processing`, iguais ao oficial. A contagem não mudou: **nenhum `smoke/expected/*.txt` foi refeito**.
- **Python:** os 27 `python3-*` novos estão no conjunto e com a lista de arquivos igual à do oficial. **O import de cada
  um não foi rodado: N/E** (o smoke usa o Python do QGIS, mas não importa os 27 um a um).
- **Tamanho:** árvore montada 2.382.609.337 bytes, 37.333 arquivos; instalada 2.418.237.216 bytes, 38.244 arquivos (o
  postinstall e o Python criam os 911 a mais: `.done`, `.pyc`, o `.env`, o `srs.db` do `crssync`, os notices); oficial
  2.392.384.679 bytes, 37.421 arquivos. **Instalador: 512.806.527 bytes (489 MB).**

## A5 Lançador e runtime: medido

- **Como o produto abre sem o nosso PowerShell:** a árvore tem o layout da instalação oficial (`bin`, `apps`, `etc`,
  `share`...). `bin\iman-terra.exe` é o `qgis.exe` do nosso build (o `mainwin.cpp`). Na instalação, `iman\postinstall.cmd`
  roda como o usuário, sem elevação: cada `etc\postinstall\*.bat` dos pacotes com `OSGEO4W_ROOT` na pasta instalada
  (caminho curto, como o `o4w_env.bat`) e os atalhos do OSGeo4W desligados (o `openssl.bat` e o `opencl.bat` não rodam:
  copiariam DLL para `C:\Windows\System32`); no lugar do postinstall dos `qgis-ltr*`, o `crssync`, a remoção dos `.pyc`
  e `iman-terra.exe --postinstall`, que grava `bin\iman-terra.env` com as variáveis de `bin\iman-terra.vars` (a mesma
  lista do `qgis-ltr-bin.vars` oficial). A associação de arquivos do oficial (`qgis.reg`, `regedit`) não existe aqui.
- **Pelo atalho:** o teste abre `IMAN Terra.lnk` por `ShellExecute`, sem o ambiente do runtime; o processo é
  `%LOCALAPPDATA%\Programs\IMAN Terra\bin\iman-terra.exe` (`GetModuleFileNameW` de dentro do processo, PID igual ao
  devolvido pelo `ShellExecute`), abre a janela, roda e sai limpo em 18 s.
- **VC++ carregado** (`EnumProcessModules` e `VerQueryValue` de dentro do processo, `instalado/launch-facts.json`):
  `MSVCP140.dll`, `MSVCP140_1.dll`, `MSVCP140_2.dll`, `MSVCP140_ATOMIC_WAIT.dll`, `VCRUNTIME140.dll` e
  `VCRUNTIME140_1.dll`, **todos 14.38.33135.0, de `bin\`** (o pacote `msvcrt2019` do conjunto oficial, ao lado do
  `iman-terra.exe`, decisão 9). O build compila com `/D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR` justamente para esse
  runtime. Os 14.44 do `cmake --install` ficam em `apps\qgis-ltr\bin`, ao lado do `qgis_process.exe`; **qual o
  `qgis_process` carrega não foi medido: N/E**.
- **O smoke do 044 contra a árvore instalada** (`Invoke-Smoke.ps1 -Target Installed`, `smoke-instalado/`): todas as
  checagens passam (versão e revisão igual ao commit do `iman\BUILD_INFO.txt`, provedores, plugins, `native:buffer`,
  janela e `.qgz`, as 8 de marca, `controle:sobre`, guarda). A GUI abre pelo `iman-terra.exe` com o ambiente do processo
  sem o runtime montado pelo script.

## A6 Instalação, atualização e desinstalação: medido

Com o "sim" do sponsor na sessão ("Sim, pode instalar"), na ordem do briefing. O que mudou na máquina, antes de pedir,
estava descrito na pergunta.

- **Atualização sobre a 0.3.0** (`upgrade-0.3.0/`, instalador `d64b622a4f`, silencioso): exit 0 em 138 s. A árvore antiga
  saiu (`qgis`, `launcher`, `assets`, `demo`, `notices`, `profile-template`, `startup`, `BUILD_ID.txt`,
  `qgis-manifest.txt`, `README.md`, o atalho "Desinstalar IMAN Terra"); "Aplicativos instalados" tem **uma entrada**,
  `IMAN Terra` `0.4.0`, na mesma chave `{7B3A9E42-...}_is1` (`reconferencia-entradas.txt`: a chave do HKCU aparece nas
  duas vistas, é a mesma); o perfil da distro (28 arquivos) tem **o mesmo SHA-256 por arquivo** antes e depois
  (`perfil-distro-*.sha256`). O teste reportou `uma-entrada-0.4.0` como falha nessa rodada por defeito dele (o `.Count`
  de um dicionário só conta os campos); corrigido e reconferido sem reinstalar.
- **Sem elevação:** `Administrative install mode: No`, `Install mode root key: HKEY_CURRENT_USER` no log do Inno
  (`setup-log-modo.txt`); nenhum prompt de UAC (o teste roda silencioso e não pede elevação).
- **Instalador final, ciclo limpo** (`ciclo-limpo/`, `14f1fd4efd`, pasta inexistente antes): instalou em 76 s;
  desinstalou em 10 s; a pasta `IMAN Terra`, os atalhos, os ProgIDs, os valores do "Abrir com" e
  `Applications\iman-terra.exe` saíram; a entrada saiu; o perfil novo (`%APPDATA%\InstitutoIMAN\IMANTerra`) ficou; o da
  distro com o mesmo hash. **A guarda passou nas três etapas** (o retrato da desinstalação é o do começo da instalação).
- Reinstalar sobre a 0.4.0 também foi feito (dois instaladores intermediários) e pousou limpo.

## A7 "Abrir com": medido

`HKCU\Software\Classes\.qgs`, `.qgz` e `.qlr\OpenWithProgids` com o valor `IMANTerra.<tipo>`; ProgID
`HKCU\Software\Classes\IMANTerra.<tipo>` com `shell\open\command` `"<app>\bin\iman-terra.exe" "%1"` e o ícone do tipo
(`iman\icons\iman-terra-<tipo>.ico`, cópia do ícone aprovado, `iman/brand/derive_assets.py`); `Applications\iman-terra.exe`
com `FriendlyAppName` `IMAN Terra`. O padrão do `.qgz` é o mesmo antes e depois: `HKCR\.qgz` = `QGIS Project`,
`UserChoice` ausente nos dois. Depois de desinstalar, as entradas somem (`ciclo-limpo/result-uninstall.json`). Que o
"Abrir com" do Explorer **mostra** o IMAN Terra num `.qgz` é o smoke do sponsor (não cliquei no menu do Explorer:
seria interagir com processo do usuário).

## A8 Notices: medido (a tela de licença relatada)

- **Cobertura:** `THIRD_PARTY_NOTICES.md` tem **154 entradas** e o `installed.db` da árvore final tem **154 pacotes**
  (153 OSGeo4W e o `iman-terra`). Comandos: `(Select-String THIRD_PARTY_NOTICES.md '^\| \d+ \| `').Count` e
  `(Get-Content etc\setup\installed.db | Select-Object -Skip 1).Count`; o `iman/notices/Update-Notices.ps1 -Check` faz
  os dois e o `Build-Installer.ps1` recusa compilar se não baterem.
- **Fonte de cada licença:** 68 pacotes com arquivo de licença dentro do próprio pacote (caminho na tabela) e 86 pela URL
  do upstream. Os 4 que a distro deixou `DESCONHECIDA` foram resolvidos no upstream: `base` MIT (cabeçalhos de
  `jef-n/OSGeo4W/src/base`; o repositório não tem LICENSE e o `license.map` tem 0 bytes), `setup` GPL-2.0-or-later
  (`src/setup/COPYING`), `qtwebkit-libs` LGPL-2.1/2.0 com partes BSD-2 (tag `qtwebkit-5.212.0-alpha4`), `saga`
  GPL-2.0-or-later com a API em LGPL-2.1 (cabeçalhos no master do SourceForge; a tag 9.12.4 não foi conferida). O
  `proj-runtime-data` não traz grade de datum (19 entradas): MIT do PROJ.
- **Texto:** nenhuma frase diz que o QGIS não foi recompilado; `LICENSE`, `THIRD_PARTY_NOTICES.md` e `SOURCE_CODE.md`
  dizem que ele foi **recompilado e modificado**.
- **Fonte do código:** `SOURCE_CODE.md` aponta o fork, a tag `final-3_44_13` e o commit, carimbado pelo
  `Build-Installer.ps1` no arquivo que vai para o pacote.
- **L.2:** Qt sob LGPL-3.0; os módulos só GPL-3.0 presentes nomeados com os arquivos (Charts, Data Visualization,
  Lottie, Network Authorization, Virtual Keyboard, Quick 3D, Quick WebGL), pela lista de https://doc.qt.io/qt-5/qtmodules.html.
- **Instalação:** os três arquivos e a pasta `licencas\` (os termos de ECW, MrSID, Oracle, ODBC e SZIP) estão na pasta
  instalada (`ciclo-limpo/result-install.json`, `arvore-nova`). A tela de licença do Inno mostra o `LICENSE` (com o
  aviso da GPL; a GPL inteira fica em `apps\qgis-ltr\doc\LICENSE`): **relatado**, a instalação medida é silenciosa e a
  tela fica para o smoke do sponsor.

## A9 Créditos (BL-1, BL-2): medido

- `AUTHORS`, `CONTRIBUTORS`, `SPONSORS`, `DONORS` e `TRANSLATORS` de `apps\qgis-ltr\doc` são byte a byte os do oficial.
  O `LICENSE` do oficial é composto pelo pacote OSGeo4W (a GPL do QGIS seguida dos termos de Oracle, SZIP, ECW e MrSID,
  74.524 bytes); o nosso é a GPL do QGIS (18.801 bytes), contida inteira nele.
- **Controle negativo como no 044:** `controle:sobre` do smoke (o `qgis-full.png` do recurso é o do fonte do QGIS) passa
  na árvore instalada, e o "Sobre" capturado nela (`capturas-instaladas/05-sobre.png`, binário `2570fb84b3`, que difere
  do final só no `.iss`) tem o logo, as abas de desenvolvedores, colaboradores, tradutores e licença do QGIS, como o do
  oficial no 044.

## A10 Gate: medido no PR

`Invoke-Gate.ps1` sem mudança: o instalador **não entrou no gate**. Compilar o instalador leva **13 a 14 min de ISCC**
(751 a 857 s nas quatro compilações, lzma2/max sólido) mais 1 min da árvore; a saída do gate está no `/deliver`.

## A11 SHA256SUMS: medido

`SHA256SUMS.txt` gerado da raiz com `git cat-file blob HEAD:<caminho>` sobre os arquivos desta pasta.

## Achados

1. **STOP do ECW, decidido pelo sponsor.** O `setup.ini` do OSGeo4W associa ao `gdal-ecw` o "ERDAS ECW/JP2 Server
   Read-Only End-user SDK License Agreement" v5.5, cuja seção 2.2 diz que ele "does not permit You to ... (b)
   distribute Desktop Applications that include the SDK". O `LICENSE` composto do QGIS oficial embarca **o mesmo
   texto** na seção 4. Decisão do sponsor na sessão: "Manter e seguir": o `gdal-ecw` fica na árvore e o
   `THIRD_PARTY_NOTICES.md` traz o trecho e declara a **distribuição bloqueada até revisão jurídica ou outro termo da
   Hexagon**. MrSID (condições da seção 1.3), Oracle (sem cobrança, com cópia da licença) e ODBC (só a lista REDIST, não
   conferida) são condicionados, não proibidos.
2. **Gate e Git Bash:** do Git Bash, o `tar.exe` do PATH é o GNU tar do Git, que lê `D:\...` como host remoto. A raiz
   OSGeo4W foi apagada antes da falha e remontada. Corrigido: `$TarExe` (o `tar.exe` do `System32`) no
   `Get-Osgeo4wPackages.ps1`. O gate roda do Git Bash; sem isto, o primeiro gate depois de mudar o lock falharia.
3. **`dbghelp.dll` e `symsrv.dll`:** o pacote `qgis-ltr` oficial os traz em `apps\qgis-ltr` (para o crash handler montar
   a pilha). Não há Debugging Tools do Windows SDK nesta máquina, e instalá-los pede o "sim" do sponsor. Sem eles, o
   crash handler usa o `dbghelp` do sistema.
4. **Atalho do build de desenvolvimento:** o WinToast do build rodado pelo smoke criou `IMANTerra.lnk` no Menu Iniciar
   (alvo `D:\iman-terra-build\install\...\qgis.exe`), como o 044 regravava o `QGIS3.lnk`. Removido (era do produto,
   criado pelo teste) e evitado: `Import-QgisRuntime` passa `QGIS_WIN_APP_NAME` numa pasta inexistente, e o WinToast não
   consegue criar atalho.
5. **`ValueType: none` do Inno cria só a chave.** O primeiro instalador gravou `OpenWithProgids` sem o valor; o teste A7
   pegou. Corrigido para valor de texto vazio.
6. **`var\` do postinstall:** nasce na instalação, fora da árvore montada, e sobrava na desinstalação. Corrigido no
   `.iss`. Com a pasta do produto já existente antes da instalação (o que sobrou da rodada defeituosa), o Inno mantém a
   pasta vazia ao desinstalar, porque só remove pasta que ele criou (`ciclo-pasta-preexistente/`); com a pasta
   inexistente, ela sai (`ciclo-limpo/`).
7. **`PYQGIS_STARTUP` roda antes de o pacote `qgis` estar no `sys.path`.** O script de fatos do teste importa só o PyQt5
   no topo.

## O que esta fatia NÃO testou

- **A VM limpa (BL-7):** tudo aqui rodou nesta máquina, que tem o QGIS oficial, os Build Tools e o OSGeo4W de build. É a
  próxima fatia.
- A tela de licença e o "Abrir com" clicados no Explorer: smoke do sponsor.
- O import um a um dos 27 `python3-*` novos; o runtime VC++ que o `qgis_process` carrega.
- A instalação interativa (todas as medidas usaram `/VERYSILENT`) e o atalho opcional da Área de Trabalho.
- A 0.3.0 da distro **não está mais instalada** nesta máquina (o ciclo a substituiu e desinstalou). Para o smoke do
  sponsor "instala sobre a 0.3.0", ela precisa ser reinstalada antes, do instalador da distro.

## Patch de 2026-10-29

Briefing `qgis-build #047` PATCH (emenda de 2026-10-29 ao D-IMAN-043, decisão 3). Branch `fix/047-patch-sem-ecw`,
nascida de `origin/develop` `173221974b` (o merge do PR #3); PR #4. Mesma máquina, medições de 2026-10-29. O que está
acima desta seção é o que a fatia mediu em 2026-10-27 e não foi reescrito: onde o patch muda um resultado, o novo está
aqui. Evidência em `patch-2026-10-29/`, com o caminho do perfil do Windows trocado por `%USERPROFILE%`.

**O instalador novo é o do commit `25da3275c5`:**
`D:\iman-terra-build\dist\0.4.0-25da3275c5\Instituto-IMAN-IMAN-Terra-Setup-0.4.0-25da3275c5.exe` (512.754.179 bytes,
SHA-256 `207c5052789384efef1d0e016fec151c12a7e5537b4e4896b9976eb8ff7a172a`, Inno Setup 7.1.0, ISCC 709 s;
`patch-2026-10-29/instalador/BUILD_INFO.txt`). A versão segue 0.4.0 (o briefing não pede outra). Ele não entra no git e
não foi distribuído. O `SOURCE_CODE.md` carimbado que vai no pacote cita o commit inteiro,
`25da3275c54a92ee18fb68fccf8e89c09f630ed9` (`patch-2026-10-29/instalador/SOURCE_CODE.md`).

| Pasta | O que é |
|---|---|
| `patch-2026-10-29/instalador/` | `BUILD_INFO.txt` e o `SOURCE_CODE.md` carimbado do instalador novo (P8) |
| `patch-2026-10-29/sem-ecw/` | `Test-NoEcw.ps1` na árvore instalada, com o `Test-RuntimeSet.ps1` em `conjunto/`; em `visto-falhando-0.4.0/`, a mesma checagem no 0.4.0 anterior (P1) |
| `patch-2026-10-29/termos/` | o termo de redistribuição do `dbghelp.dll` e do `symsrv.dll`, com a origem e o hash dos arquivos (P3) |
| `patch-2026-10-29/pilha/` | `Test-CrashStack.ps1`: a pilha montada pelo crash handler instalado; em `visto-falhando-0.4.0/`, o 0.4.0 anterior (P3) |
| `patch-2026-10-29/qgis-process/` | `Test-QgisProcessRuntime.ps1`: o VC++ que o `qgis_process` instalado carrega (P4) |
| `patch-2026-10-29/instalado/` | `Test-Installed.ps1` no instalador novo, perfil novo (P5) |
| `patch-2026-10-29/ciclo/` | a máquina sem o IMAN Terra antes (`pre-ciclo.txt`), instalar e desinstalar (P5) |
| `patch-2026-10-29/smoke-instalado/` | o smoke do 044 contra a árvore instalada (P5) |

### Veredito do patch

**P1 a P5 e P8 medidos e passando; P6 e P7 no PR e no `/deliver`.** O produto sai sem o ECW, com o `dbghelp.dll` e o
`symsrv.dll` das Debugging Tools for Windows em `apps\qgis-ltr`, e o `qgis_process` instalado carrega um VC++ só. Nada
do resto do 047 regrediu, e a guarda passou em toda etapa. Nenhum STOP disparou.

### P1 Sem ECW: medido

`iman/installer/Test-NoEcw.ps1` (novo), na árvore instalada (`patch-2026-10-29/sem-ecw/result.json`):

- **Arquivos:** busca na árvore inteira por `NCSEcw.dll` e `gdal_ECW_JP2ECW.dll`: nenhum. No oficial, os dois estão
  (`bin\NCSEcw.dll` e `apps\gdal\lib\gdalplugins\gdal_ECW_JP2ECW.dll`).
- **Conjunto:** o `Test-RuntimeSet.ps1` do 047, sem mudança, compara a árvore com o `installed.db` do oficial menos os
  `qgis-ltr*`. A única diferença é `so-no-oficial gdal-ecw gdal-ecw-3.13.2-1.tar.bz2`, exatamente a esperada. Nenhum
  `-devel`, e 0 dos 152 pacotes com diferença de arquivos. Contra o alvo do briefing (o oficial menos os `qgis-ltr*` e
  o `gdal-ecw`, mais o nosso build), o diff é vazio. O teste pré-existente reporta `FALHOU` por essa diferença
  (`sem-ecw/conjunto/result.json`). Isso é o que ele deve dizer agora; o teste não foi editado, e o veredito do P1 vem do
  `Test-NoEcw.ps1`, que exige essa e só essa diferença (decisão do sponsor na sessão: "Teste novo para P1").
- **GDAL:** `gdalinfo --formats` da árvore instalada, com o `o4w_env.bat` dela, lista 148 drivers: sem `ECW`, sem
  `JP2ECW`, com `JP2OpenJPEG` (`sem-ecw/gdal-formats-produto.txt`).
- **Visto falhando:**
  - contra o oficial, a mesma checagem lista 150 drivers, com `ECW` e `JP2ECW` (`sem-ecw/gdal-formats-oficial.txt`);
  - contra o 0.4.0 anterior, ainda instalado antes do ciclo, o teste reprovou nas três checagens: os dois arquivos
    presentes, o conjunto sem a diferença esperada e o GDAL com `ECW` e `JP2ECW`
    (`sem-ecw/visto-falhando-0.4.0/result.json`).
- **Onde:** `$RuntimeExcluded` no `New-RuntimeTree.ps1`, com o motivo, é o lugar único da exclusão. O lock segue com
  `Runtime=official` para o `gdal-ecw` (diz o que o oficial instala) e não mudou. A árvore montada tem 152 pacotes mais
  o `iman-terra`, 37.332 arquivos e 2.377.372.907 bytes.
- **Nenhum outro pacote saiu nem mudou:** os 152 restantes têm a mesma lista de arquivos do oficial. O smoke abaixo dá
  os mesmos provedores, algoritmos e plugins.

### P2 Notices: medido

- **Contagem:** `THIRD_PARTY_NOTICES.md` tem 153 entradas, e o `installed.db` da árvore instalada tem 153 pacotes
  (152 OSGeo4W e o `iman-terra`). `Update-Notices.ps1 -Check -Tree "%LOCALAPPDATA%\Programs\IMAN Terra"`: "notices em
  dia: 153 entradas para 153 pacotes", exit 0. O `Build-Installer.ps1` faz a mesma conta antes de compilar.
- **Texto:**
  - saíram a seção "ECW/JP2 (`gdal-ecw`): redistribuição bloqueada", a linha do `gdal-ecw` no
    `licencas-upstream.tsv`, o `licencas/gdal-ecw.txt` e o ECW da lista de não livres do `LICENSE`;
  - a seção 1 do `THIRD_PARTY_NOTICES.md` diz que o driver ECW/JP2 **não é distribuído**, com o termo da Hexagon (seção
    2.2) e o `JP2OpenJPEG` como o que segue para JPEG 2000;
  - nenhuma frase diz que o ECW é parte do produto ou que a distribuição está bloqueada por ele.
- **Evidência do STOP:** o `licencas-osgeo4w/termos-medidos.txt` desta pasta fica como registro do STOP de 2026-10-27.

### P3 `dbghelp.dll` e `symsrv.dll`: medido

- **Origem:** Debugging Tools for Windows do Windows SDK 10.0.26100.7705. O feature `OptionId.WindowsDesktopDebuggers`
  foi instalado nesta máquina com o "sim" do sponsor na sessão, pelo `winsdksetup` em cache do SDK já instalado. O exit
  foi 0, em 20 s, e a guarda passou antes e depois. O `Install-BuildTools.ps1` passou a fazer esse passo (parâmetro
  `-SkipDebuggers` para pular), e o `New-RuntimeTree.ps1` copia os dois de `C:\Program Files (x86)\Windows
  Kits\10\Debuggers\x64` conferindo o SHA-256 fixado em `$DebuggerRedist` (`Common.ps1`).
- **Arquivos** (sem modificação; assinatura Microsoft válida):

  | Arquivo | Versão | Bytes | SHA-256 |
  |---|---|---|---|
  | `dbghelp.dll` | 10.0.26100.7705 | 2.259.288 | `23d33e01020b6d1de7dd29cd737287042476a6e0a8deafdab68f01e61a801fcf` |
  | `symsrv.dll` | 10.0.26100.7705 | 424.280 | `89efaac07673f87a2862d6b163bc6626b51770ad1bd48c4f277e356df0a08c1d` |

  O `qgis-ltr` oficial leva os dois na versão 10.0.19041.685. A versão difere; o lugar e o papel são os mesmos.
- **Termo** (`patch-2026-10-29/termos/debugging-tools-redist.txt`):
  - a licença do Windows SDK, seção 2.a.i, permite distribuir o que está na lista REDIST
    (https://learn.microsoft.com/en-us/legal/windows-sdk/redist, "UPDATED 10/21/2024", lida em 2026-10-29);
  - a seção "Debugging Tools for Windows" da lista diz "You may distribute these files as part of your program." e
    nomeia `Dbghelp.dll` e `Symsrv.dll`;
  - as condições de distribuição (2.a.ii e 2.a.iii: termos ao usuário final, indenização, sem licença excluída) são as
    mesmas do runtime do VC++ que o 047 já leva;
  - o texto da licença entrou no pacote como `licencas\windows-sdk.txt`, e os notices ganharam a entrada (seção 5 do
    `THIRD_PARTY_NOTICES.md`, seção 3 do `LICENSE`).
- **A pilha** (`Test-CrashStack.ps1`, novo; `patch-2026-10-29/pilha/`):
  - **Falha provocada:** num processo descartável aberto pelo teste (o Python da árvore instalada com
    `crash_target.py`), um `CreateThread` que começa em `msvcrt.strlen` com argumento nulo causa um access violation. O
    filtro de exceção grava o arquivo de informação no formato do QGIS.
  - **Crash handler:** o `qgiscrashhandler.exe` instalado, aberto pelo teste com o ambiente do `iman-terra.env`, abriu
    a janela em 5 s (`crash-handler.png`).
  - **DLLs carregadas** (`Process.Modules` do handler): o `dbghelp.dll` e o `symsrv.dll` de `apps\qgis-ltr`, os dois
    10.0.26100.7705.
  - **Símbolos:** o servidor de símbolos baixou os PDBs de `ntdll`, `kernel32` e `msvcrt` para a pasta da rodada.
  - **Pilha** (`stack.txt`): `strlen`, `BaseThreadInitThunk`, `RtlUserThreadStart`.
  - **Encerramento:** handler e processo fechados pelos PIDs que o teste recebeu.
- **Visto falhando** (o 0.4.0 anterior, `pilha/visto-falhando-0.4.0/`): os dois arquivos ausentes da árvore. O handler
  carregou `C:\WINDOWS\SYSTEM32\dbghelp.dll` 10.0.26100.9549, não carregou `symsrv` e não baixou símbolo. A pilha desta
  falha sintética saiu igual, porque os módulos são do sistema e o `dbghelp` do sistema os resolve pela tabela de
  exportação. A diferença medida é qual `dbghelp` monta a pilha e se o servidor de símbolos é usado. Que a pilha de um
  crash dentro do QGIS ganha nomes de função com os PDBs do build é **relatado**: o build não publica PDB para o servidor
  de símbolos, e provocar um crash dentro do `iman-terra.exe` está fora do que este teste abre.

### P4 O VC++ do `qgis_process`: medido

`Test-QgisProcessRuntime.ps1` (novo; `patch-2026-10-29/qgis-process/`), com perfil descartável novo
(`QGIS_CUSTOM_CONFIG_PATH`). O script `PYQGIS_STARTUP` `qgis_process_facts.py` lê, de dentro do processo, a cada 50 ms,
os módulos carregados (`EnumProcessModules`) e a versão de cada um (`VerQueryValue`). O intervalo entre a última leitura
e a saída do processo vai no resultado.

- **Chamadas:**
  - `bin\qgis_process-iman-terra.bat --json plugins`: exit 0, `grassprovider` e `processing`;
  - `bin\qgis_process-iman-terra.bat --json run native:buffer -- INPUT=<points.geojson> DISTANCE=0.01 SEGMENTS=8
    OUTPUT=<buffer.gpkg>`, sobre uma camada descartável de 3 pontos: exit 0. O `ogrinfo` da árvore lê 3 feições
    poligonais no `buffer.gpkg`.
- **VC++ carregado, nas duas chamadas:** `MSVCP140.dll`, `MSVCP140_1.dll`, `MSVCP140_2.dll`,
  `MSVCP140_ATOMIC_WAIT.dll`, `VCRUNTIME140.dll` e `VCRUNTIME140_1.dll`. Todos 14.44.35211.0, todos de
  `apps\qgis-ltr\bin`, ao lado do `qgis_process.exe` (o do `cmake --install`). **Uma versão só, um diretório só**:
  nenhum STOP de runtime, e nenhuma DLL foi trocada nem movida.
- A GUI segue com o 14.38.33135.0 de `bin\` (`instalado/result.json`, `A5:vc-runtime-carregado`). São dois processos
  distintos, cada um com um VC++ só. Isso fecha o `N/E` do A5.

### P5 O resto do 047: medido

- **Máquina sem o IMAN Terra antes do ciclo** (`ciclo/pre-ciclo.txt`):
  - o 0.4.0 de 2026-10-27 estava instalado. Foi desinstalado pelo próprio `unins000.exe` (aberto pelo PID): exit 0,
    15 s; a pasta e a entrada saíram;
  - para o A2 partir de um perfil novo, as sobras do produto dos testes anteriores foram **renomeadas, não apagadas**,
    com o sufixo `.antes-047-patch`: `%APPDATA%\InstitutoIMAN\IMANTerra` (9 arquivos),
    `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra` (5 arquivos), `HKCU\Software\InstitutoIMAN\IMANTerra` e
    `HKCU\...\Notifications\Settings\InstitutoIMAN.IMANTerra.IMANTerra.3.44.13-Solothurn` (as duas chaves exportadas em
    `.reg` antes, fora do git). Decisão do sponsor na sessão: "Renomear e restaurar";
  - a guarda passou antes e depois.
- **Instalar** (`ciclo/result-install.json`): 88 s, sem elevação (`Administrative install mode: No`), uma entrada
  `IMAN Terra` `0.4.0`, a árvore nova com os notices, e o perfil da distro com o mesmo hash.
- **`Test-Installed.ps1` inteiro, A2 a A9** (`instalado/result.json`): todas as checagens OK. Perfil novo antes; abre
  pelo atalho em 56 s e sai limpo; nome interno, perfil, cache, registro e crashes do produto; `qgis_process` lê o
  perfil novo; um atalho com o AUMI; a notificação; o "Abrir com"; o padrão do `.qgz` igual; os créditos iguais aos do
  oficial.
- **Smoke do 044 contra a árvore instalada** (`smoke-instalado/summary.json`): todas as checagens OK (versão e revisão
  `25da3275c5`, 7 provedores, 426 algoritmos, plugins, `native:buffer`, janela e `.qgz`, as 8 de marca,
  `controle:sobre`, guarda). **Nenhum `smoke/expected/*.txt` mudou.**
- **Desinstalar** (`ciclo/result-uninstall.json`): 11 s; a pasta, os atalhos, as associações e a entrada saíram; o
  perfil do produto ficou, como no A6; o da distro com o mesmo hash.
- **A guarda passou em toda etapa:** antes e depois do pré-ciclo, das Debugging Tools, da instalação, de cada teste e da
  desinstalação.
- **A sessão terminou com o IMAN Terra desinstalado.** Ficou da rodada, sem apagar:
  - o perfil `%APPDATA%\InstitutoIMAN\IMANTerra`, o cache e os crashes em `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra`;
  - `HKCU\Software\InstitutoIMAN\IMANTerra` e a chave de notificação do produto;
  - as quatro cópias `.antes-047-patch`, para o sponsor decidir.

  A pasta `IMAN Terra.SOBRAS-GATE` e o `QGIS3.lnk` não foram tocados.

### Desvios declarados

- **Disco:** no começo da sessão, D: tinha 9,5 GB livres, abaixo dos 50 GB do STOP. Parei e reportei. O sponsor mandou
  seguir na sessão ("pode prosseguir"). Depois, D: passou a ter mais de 94 GB livres, liberados fora desta sessão. No
  fim, C: tem 258,9 GB e D: 105,1 GB livres.
- **Branch e PR:** o briefing pedia a branch `feat/047-instalador` e o PR #3, mas o PR #3 já estava mergeado. O
  sponsor decidiu na sessão: "Nova branch, novo PR" (`fix/047-patch-sem-ecw`, PR #4).
- **O 0.4.0 estava instalado** no começo da sessão, ao contrário do registro da bancada. Foi desinstalado no
  pré-ciclo, acima.
- **A compilação incremental foi interrompida uma vez** pelo ambiente, por pouca memória. Reiniciei com o "sim" do
  sponsor, e ela retomou do ponto em que parou.

### O que o patch NÃO testou

- A VM limpa (BL-7): segue a próxima fatia.
- A pilha de um crash dentro do próprio `iman-terra.exe`, com os PDBs do build (relatado, acima).
- O smoke do sponsor (instalação interativa, Menu Iniciar, "Abrir com" no Explorer, notices lidos na tela).
