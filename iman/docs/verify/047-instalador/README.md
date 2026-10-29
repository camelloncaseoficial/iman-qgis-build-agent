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
