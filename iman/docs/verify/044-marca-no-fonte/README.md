# Laudo 044: a marca entra no fonte

Briefing `qgis-build #044` (D-IMAN-041, regras 2 a 4 do D-IMAN-039, sob o D-IMAN-040). Branch
`feat/044-marca-no-fonte`, nascida de `origin/develop` `8b10d9117c`. Maquina: Windows 11 Pro em espanhol, 24
processadores logicos, 32 GB. Medicoes de 2026-10-25.

Legenda: **medido** (rodado e observado nesta maquina, com a evidencia indicada), **relatado** (dito por fonte
externa, nao medido aqui), **N/E** (nao executado).

Evidencia nesta pasta. Os binarios das rodadas finais sairam do commit `95abe8cd9f` (o `qgis_process --version` diz
`QGIS code revision 95abe8cd9f`); o commit `aa0acb80c1` mudou so o script de captura de janela e foi o usado nas
capturas. Nos arquivos de texto da evidencia, o caminho do perfil do Windows foi trocado por `%USERPROFILE%`
(`iman/build/Export-Evidence.ps1`); as imagens estao como sairam.

| Pasta | O que e |
|---|---|
| `build-smoke/`, `oficial-smoke/` | `Invoke-Smoke.ps1` no build e no QGIS 3.44.13 oficial (controle), perfil novo, sem `--lang` |
| `build-capturas/`, `oficial-capturas/` | `Invoke-BrandCaptures.ps1`, perfil novo, `--lang pt_BR` nos dois (lado a lado do A13) |
| `a2-nome-de-teste/` | a prova do A2, com o nome trocado so no `brand.json` |
| `guarda/result.json` | `Test-GuardRounds.ps1` (A12) |
| `curadoria.md`, `curadoria-medida.txt` | a tabela das 275 mensagens e a medicao (A3) |
| `idi-icon1.json` | o `IDI_ICON1` lido de dentro dos executaveis (A6) |
| `SHA256SUMS.txt` | hash de cada arquivo desta pasta (A14) |

## Veredito

**Os blocos A, B, C e D fecharam dentro do briefing, com 12 arquivos do QGIS alterados (83 linhas incluidas, 17
removidas), e todo criterio de A1 a A13 esta medido no binario compilado.** O smoke do build passa nas 8 checagens
de marca e nas de comportamento; o mesmo smoke contra o QGIS oficial reprova as 8 checagens de marca e passa nas de
comportamento e no controle do "Sobre", que e a prova de que cada checagem enxerga a marca.

Um STOP disparou e foi decidido pelo sponsor na sessao (achado 1 abaixo). Duas correcoes sairam das proprias
checagens: o icone do executavel que o build incremental nao trocava (achado 2) e tres rotulos do "Sobre" que a
primeira curadoria tinha mudado (achado 3). A VM limpa (BL-7) segue lacuna declarada.

## Como a marca chega ao binario

```
iman/brand/brand.json ----------------+--> build_brand.py --> iman_brand.h (raiz do build) --> C++ do Bloco D
iman/brand/i18n/curadoria_pt_BR.json -+                   --> iman_pt_BR.ts --> lrelease fixado --> i18n/iman_pt_BR.qm
resources/qgis_global_settings.ini ---+                   --> qgis_global_settings.ini --> resources/ da instalacao
iman/brand/assets/ --> derive_assets.py --> iman/brand/derived/ --> copia sobre os arquivos do QGIS (patchset)
```

- A traducao sobreposta e instalada por `QgsApplication::installTranslators()` depois da `qgis_pt_BR`, e por isso
  tem precedencia (Qt procura no tradutor instalado por ultimo primeiro).
- O `iman_brand.h` vai para a raiz do build porque o QGIS ja faz `include_directories(${CMAKE_BINARY_DIR})`: nenhum
  `CMakeLists.txt` do QGIS mudou.
- O `.qm` e o `.ini` sao copiados pelo `Build-Qgis.ps1` depois do `cmake --install`, a cada build.

## A1 Patchset: medido

`Test-Patchset.ps1`: `patchset: 12 arquivo(s) do QGIS alterado(s) desde final-3_44_13; 12 listado(s) em
iman/PATCHES.md`, `PATCHSET OK`. `git diff --stat final-3_44_13..HEAD -- . ':!iman' ':!.claude' ':!.memory'
':!CLAUDE.md'`:

```
 images/icons/qgis-icon-16x16.png       | Bin 846 -> 853 bytes
 images/icons/qgis-icon-60x60.png       | Bin 4401 -> 5805 bytes
 images/icons/qgis_icon.svg             |  14 +++++++++++++-
 images/splash/splash.png               | Bin 2425959 -> 320192 bytes
 images/themes/default/providerQgis.svg |  14 +++++++++++++-
 src/app/mainwin.cpp                    |  32 +++++++++++++++++++-------------
 src/app/qgis.ico                       | Bin 131462 -> 68384 bytes
 src/app/qgisapp.cpp                    |   2 ++
 src/core/layout/qgslayoutexporter.cpp  |   4 +++-
 src/core/qgsapplication.cpp            |  19 +++++++++++++++++++
 src/crashhandler/main.cpp              |  12 ++++++++++++
 src/crashhandler/qgscrashreport.cpp    |   3 ++-
 12 files changed, 83 insertions(+), 17 deletions(-)
```

Por que cada um nao podia ser evitado (o motivo de cada linha esta em `iman/PATCHES.md`):

- `qgsapplication.cpp`: o unico jeito de a sobreposicao ser carregada, antes do splash, por toda a interface.
- `qgisapp.cpp`: o item "Verificar a versao do QGIS" e criado no `.ui` e nao some sozinho quando a configuracao
  global desliga a checagem; 2 linhas o escondem com a mesma chave (`qgis/allowVersionCheck`).
- `qgslayoutexporter.cpp`, `mainwin.cpp`, `qgscrashreport.cpp`: texto fixo no C++ (`QStringLiteral`, literais de
  `MessageBoxA`), fora do alcance de tradutor: as superficies do Bloco D.
- `crashhandler/main.cpp`: o crash handler nao instalava tradutor nenhum; sem ele, nem a traducao do QGIS nem a
  sobreposta chegam la.
- Os 6 arquivos de imagem: recursos compilados (`:/images/...`), lidos do disco (`appIconPath()`) ou embutidos no
  executavel (`IDI_ICON1`); trocar o arquivo e o que alcanca os tres caminhos de uma vez.

Mudanca de comportamento alem da identidade: nenhuma. O unico efeito que nao e texto nem imagem e o item de menu
escondido, pedido pelo item 10 do briefing.

## A2 Fonte unica: medido

Com `product_name` trocado para `Marca Teste A2` **so** no `iman/brand/brand.json`
(`a2-nome-de-teste/git-status-durante-o-teste.txt`: ` M iman/brand/brand.json`) e um build incremental, o smoke do
build passou inteiro, lendo as expectativas do proprio `brand.json` (`a2-nome-de-teste/smoke-summary.json`):

| Superficie | Valor medido com o nome de teste | Evidencia |
|---|---|---|
| Titulo | `Projeto sem título — Marca Teste A2 [iman-smoke]`, legenda `Marca Teste A2 - motor QGIS %1 ('%2')` | `smoke-gui.json`, `01-janela.png` |
| Splash | `Marca Teste A2 pronto!` | `02-splash-mensagem-final.png` |
| Crash handler | `Marca Teste A2 terminou inesperadamente`, `Reabrir o Marca Teste A2` | `09-crash-handler.png`, `capturas-summary.json` |
| PDF | Creator e Producer `Marca Teste A2 (motor QGIS 3.44.13-Solothurn)` | `layout.pdf`, `smoke-gui.json` |
| Caixa de erro | `Erro ao carregar o Marca Teste A2` | `10-erro-de-carga.png` |

Depois o `brand.json` voltou (`git checkout`), e as rodadas finais sao do nome real.

Literal `IMAN Terra` escrito a mao: `git grep -l 'IMAN Terra'` acha, alem de `iman/brand/brand.json` (a fonte),
so documentacao e harness da Crew: `CLAUDE.md`, `.claude/commands/start-session.md`, `.memory/*.md`,
`iman/PATCHES.md`, `iman/brand/README.md` e este laudo com a `curadoria.md` gerada. Nenhum arquivo do QGIS, nenhum
script de build e nenhum asset tem o nome escrito; os assets tem o nome desenhado na arte do splash (aprovada, nao
gerada por nos). Gerados no build, fora do repo: `iman_brand.h`, `iman_pt_BR.ts`/`.qm`, `qgis_global_settings.ini`.

## A3 Sobreposicao: medido

- `QCoreApplication.translate("QgisApp", "QGIS")`, perfil novo: **`IMAN Terra`** no build, **`QGIS`** no oficial
  (`build-smoke/gui.json`, `oficial-smoke/gui.json`; o oficial abre em `es_ES`, ver A4, e com `--lang pt_BR`
  tambem devolve `QGIS`, `oficial-capturas/`).
- Contagem: `lconvert` (o fixado) converte o `qgis_pt_BR.qm` oficial em `.ts`, e
  `python3 iman/brand/build_brand.py --measure` conta **275 mensagens com "QGIS" na traducao, em 85 contextos**
  (`curadoria-medida.txt`). O `.qm` do build e o do oficial sao o mesmo arquivo (sha256 `5ea0f566...`). A forense
  falava em 60 contextos; o numero de mensagens bate.
- Classes: **aplicativo 74, versao 8, projeto QGIS 185, duvida 8**. Entram na sobreposicao as 82 de aplicativo e
  versao e 1 superficie do Bloco D fora das 275 (a mensagem do crash handler que manda relatar no QGIS, sem traducao
  pt_BR no QGIS). Tabela completa, com o texto final de cada mensagem que muda: `curadoria.md`.
- Nenhuma mensagem da classe aplicativo deixou de mudar com a sobreposicao entre as que o smoke e as capturas
  exercitam (titulo, splash, menu Ajuda, crash handler); o STOP "a sobreposicao nao alcanca" nao disparou.
  As 82 nao foram exercitadas uma a uma na interface (ver "O que esta fatia NAO testou").
- Classe versao: o texto diz "motor QGIS" (`IMAN Terra - motor QGIS 3.44.13-Solothurn ('Solothurn')`, `Versão do
  motor QGIS: %1` no log do Processamento, `Bem vindo ao IMAN Terra (motor QGIS %1)` na primeira execucao).

### Duvidas para o arquiteto (ficaram como estao)

| # | Mensagem | Por que |
|---|---|---|
| 5 | "The installer used to install this version of QGIS does not include the PDAL library ... from https://qgis.org" | manda obter outro instalador em qgis.org; com QGIS ou com o nome do produto a frase fica falsa (nao aparece neste build, que tem PDAL) |
| 35 | "QGIS native provider" | nome de provedor de dados do QGIS |
| 258, 274, 275 | "QGIS (PDAL)", "QGIS (3D)", "QGIS (native c++)" | nome dos provedores de algoritmos do QGIS: o icone passa a ser o do produto (item 7), mas o nome identifica o conjunto de algoritmos do QGIS |
| 32, 125, 268 | "QGIS Generated Color Map Export File", "QGIS Generated Transparent Pixel Value Export File", "Digitized in QGIS" | texto gravado em arquivo ou dado do usuario, nao na interface |

## A4 pt_BR por padrao: medido

Perfil novo, Windows em espanhol, sem `--lang`: o build abre em **`pt_BR`** (`translation`, `locale/userLocale`
`pt_BR`, `locale/overrideFlag` `true`, "About QGIS" = "Sobre o QGIS"); o oficial abre em **`es_ES`** ("Acerca de
QGIS"). As chaves que fazem isso, num perfil novo, sao `[locale] overrideFlag=true` e `userLocale=pt_BR` na
configuracao global gerada: o `main.cpp` (linhas 1127 a 1187) so usa o `locale/userLocale` se o `overrideFlag` estiver
ligado; sem ele, usa o idioma do Windows. O operador muda nas Opcoes como sempre (a chave do perfil vence a global).

## A5 Janela e splash: medido

- Titulo: `Projeto sem título — IMAN Terra [iman-smoke]` ao abrir, `smoke — IMAN Terra [iman-smoke]` com o projeto;
  a legenda inicial com a versao e `IMAN Terra - motor QGIS %1 ('%2')`. No oficial: `... — QGIS`.
  (O "—" e o "[iman-smoke]" sao do QGIS: separador e nome do perfil.)
- Splash: o recurso compilado `:/images/splash/splash.png` tem o sha256 do `splash-iman-terra.png` aprovado; a
  mensagem final e `IMAN Terra pronto!` (oficial: `QGIS pronto!`). Capturas: `build-capturas/02-splash-real.png`
  (o splash real, na tela, durante a carga, com "Configurando a GUI") e `02-splash-mensagem-final.png` (o splash
  montado como o `main.cpp` monta, 600x300, com a mensagem final que o `QgisApp` escreve; a mensagem final dura
  milissegundos na tela e nao foi capturada ao vivo).

## A6 Icones: medido

Sha256 do recurso lido de dentro do binario (`QFile(':/...')` pelo PyQGIS do build) igual ao do derivado em
`iman/brand/derived/`, para `qgis_icon.svg`, `qgis-icon-16x16.png`, `qgis-icon-60x60.png`, `providerQgis.svg` e
`splash.png`; o `qgis-icon-60x60.png` lido do disco por `appIconPath()` tambem (`build-smoke/summary.json`,
`marca:icones`). O `IDI_ICON1` do `qgis.exe` e do `qgiscrashhandler.exe` tem as 7 imagens do `icon-iman-terra.ico`
aprovado; o do `qgis-ltr-bin.exe` oficial, nao (`idi-icon1.json`, lido com `LoadLibraryEx` como dado). O leitor foi
validado contra o controle: o `IDI_ICON1` do oficial bate com o `qgis.ico` original do QGIS.

**Controle negativo do BL-1:** o `:/images/icons/qgis-full.png` do build e byte a byte o do QGIS (sha256
`3e5ebce1...`, igual nos dois alvos, `controle:sobre`), e o "Sobre" abre com os creditos do QGIS
(`build-capturas/05-sobre.png`, igual ao `oficial-capturas/05-sobre.png`).

Varredura de outros icones com o logo: `qgis-icon-512x512.png` e `qgis-icon-macos.png` (instalados, mas nenhum codigo
do Windows os le), `qbrowser-icon.png` (o app QBrowser nao e compilado) e `mIconNetworkLogger.svg` (painel de
depuracao de rede; o desenho e o logo com uma rede, nao representa o aplicativo e trocar pediria desenho novo).
Ficaram como estao.

## A7 Enderecos, feed e versao: medido

URL que cada acao do menu Ajuda abriria, medida interceptando o `QDesktopServices` (sem abrir o navegador):

| Acao | Build | Oficial |
|---|---|---|
| Pagina do IMAN Terra / Pagina do QGIS | `https://institutoiman.org.br` | `https://qgis.org` |
| Reportar um problema | `https://institutoiman.org.br` | `https://qgis.org/resources/support/bug-reporting/` |
| Precisa de Suporte Comercial? | `https://institutoiman.org.br` | `https://qgis.org/resources/support/commercial-support/` |
| Doe para o QGIS | `https://qgis.org/funding/donate/` | `https://qgis.org/funding/donate/` |
| Envolva-se | `https://qgis.org/community/involve/` | `https://qgis.org/community/involve/` |
| Membros de Suporte do QGIS | `https://qgis.org/funding/membership/members/` | `https://qgis.org/funding/membership/members/` |

(Build sem `--lang`, oficial em `es_ES`: as tres do QGIS sao iguais nos dois; em pt_BR o menu e o mesmo,
`*-capturas/captures.json`.) Perfil novo: `core/httpsfeedqgisorg/disabled=true`, `qgis/checkVersion=false`,
`qgis/allowVersionCheck=false`, e o item "Verificar a versao do QGIS" nao esta visivel (oficial: `false`, `true`,
`true`, visivel). Prova independente do feed: o cache de rede do perfil descartavel do oficial tem a resposta de
`https://feed.qgis.org/?lang=es`; o do build esta vazio. A ajuda F1 segue no manual do QGIS (`help/helpSearchPath`
nao mudou).

## A8 Crash handler: medido

`qgiscrashhandler.exe` com um relatorio sintetico (o processo "travado" e um `ping` descartavel, encerrado depois):
titulo e textos em pt_BR, icone do produto na janela e no dialogo, `IMAN Terra terminou inesperadamente`,
`Reabrir o IMAN Terra`, e o unico link leva a `https://institutoiman.org.br` (`build-capturas/09-crash-handler.png`,
textos lidos por UI Automation em `build-capturas/summary.json`). O relatorio tecnico e gerado igual; o `Crash ID`
fica como texto: `**Crash ID**: ID not generated due to missing information.` (`build-capturas/crash-report.txt`;
no oficial, `**Crash ID**: [...](https://github.com/qgis/QGIS/search?q=...)`). Os textos do proprio relatorio
(`QGIS Info`, "Your version of QGIS install...") ficam em ingles: sao o relatorio tecnico, que o briefing manda gerar
igual.

O crash handler grava o relatorio em `%LOCALAPPDATA%\QGIS\QGIS3\crashes\<uuid>` (nome interno, fatia do
instalador). Por decisao do sponsor nesta sessao, a rodada copia o `report.txt` para a evidencia e remove a pasta que
ela mesma criou; a guarda da rodada passou depois disso.

## A9 Caixa de erro de carga: medido

Numa copia da pasta `bin` da instalacao, sem o `qgis_app.dll`, com o PATH so do Windows: titulo `Erro ao carregar o
IMAN Terra`, texto `Ops, houve um erro ao carregar o IMAN Terra ... Falha ao carregar o qgis_app.dll ... Erro do
Windows: ...` (`build-capturas/10-erro-de-carga.png`). O oficial, numa copia so do `qgis-ltr-bin.exe`:
`Error loading QGIS`. As frases nao tem acento de proposito: a `MessageBoxA` mostra os bytes no codepage ANSI.

## A10 PDF: medido

Layout com um mapa do projeto do smoke, exportado pelo PyQGIS do build (`QgsLayoutExporter.exportToPdf`): Creator e
Producer **`IMAN Terra (motor QGIS 3.44.13-Solothurn)`**, no dicionario Info que vale (o ultimo; o PDF tem uma
atualizacao incremental do GDAL depois da do Qt) e no XMP (`xmp:CreatorTool`, `pdf:Producer`). Oficial:
`QGIS 3.44.13-Solothurn` (`build-smoke/layout.pdf`, `oficial-smoke/layout.pdf`).

## A11 Comportamento igual: medido

Nos dois alvos: os mesmos 7 provedores (`3d gdal model native pdal qgis script`), os mesmos **426 ids de algoritmo**
e os mesmos plugins (`grassprovider processing`), comparados com a referencia medida no oficial no #043
(`iman/build/smoke/expected/`); `native:buffer` no fixture com 3 feicoes; o `.qgz` do smoke abre com a camada valida e
3 feicoes; uma copia salva pelo build grava `qgis version="3.44.13-Solothurn"`, igual ao oficial.

## A12 Gate: medido

Ressalva R1 do #043 corrigida: `Invoke-Gate.ps1` (e `Invoke-ImanBuild.ps1`) tira o retrato da guarda no comeco de
cada rodada. Prova com `Test-GuardRounds.ps1`, contra uma instalacao e um perfil **de teste** (`guarda/result.json`):

| Cenario | Saida da guarda | Esperado |
|---|---|---|
| rodada 1 sem mudanca | 0 | 0 |
| arquivo do perfil de teste muda entre rodadas; rodada 2 tira retrato novo | 0 | 0 |
| arquivo muda durante a rodada 3 | 1 | 1 |
| controle do defeito antigo: rodada 2 comparada com o retrato da rodada 1 | 1 | 1 |

A guarda passou a vigiar tambem `%LOCALAPPDATA%\QGIS` e o atalho `QGIS3.lnk` do Menu Iniciar (achado 1). Cada
checagem de marca do smoke cai contra o oficial: `oficial-smoke/summary.json`, `brandControl.passedOnOfficial: []`
(8 checagens, nenhuma passou no oficial), e o smoke do oficial so da OK quando isso acontece.

O gate registrado roda depois do PR aberto; o resultado vai no `/deliver`.

## A13 Lado a lado: medido

Perfil novo, `--lang pt_BR` nos dois. Build em `build-capturas/`, oficial em `oficial-capturas/`, mesmo nome de
arquivo:

| Regiao | Arquivo | O que muda |
|---|---|---|
| Janela principal (barras; o titulo esta em `captures.json`) | `01-janela.png` | titulo com IMAN Terra no lugar de QGIS |
| Splash | `02-splash-real.png`, `02-splash-mensagem-final.png` | arte aprovada; `IMAN Terra pronto!` |
| Caixa de Processamento | `03-processamento.png` | simbolo do produto nos grupos |
| Menu Ajuda | `04-menu-ajuda.png` | `Página do IMAN Terra`; sem `Verificar a versão do QGIS`; Doe, Envolva-se e Membros iguais |
| Sobre | `05-sobre.png` | nada: creditos, logo e textos do QGIS |
| Navegador com o `.qgz` | `06-navegador-qgz.png` | simbolo do produto no item do projeto |
| Propriedades da camada | `07-propriedades-camada.png` | icone da janela |
| Opcoes > Processamento > Provedores | `08-opcoes-processamento-provedores.png` | simbolo do produto nos provedores do QGIS |
| Crash handler | `09-crash-handler.png` | pt_BR, simbolo, link do IMAN |
| Caixa de erro | `10-erro-de-carga.png` | `Erro ao carregar o IMAN Terra` |

## A14 SHA256SUMS: ver `SHA256SUMS.txt`

Gerado da raiz do repo sobre os arquivos desta pasta. A conferencia num clone novo da ponta do PR
(`sha256sum -c` e `git cat-file blob HEAD:<caminho>` para cada um) vai no `/deliver`.

## Achados

1. **STOP do QGIS do sponsor, decidido na sessao.** O nome interno `QGIS/QGIS3` (fatia do instalador) faz o build
   gravar no `%LOCALAPPDATA%\QGIS\QGIS3\cache` do QGIS oficial: o cache de rede padrao
   (`qgsnetworkaccessmanager.cpp:833`) cai la quando o perfil nao define `cache/directory`. Medido: a pasta mudou as
   15:08:54 de 2026-10-23, durante o smoke `build-20261023-150841` do #043, e o arquivo gravado
   (`data8\e\1ec6zt5n.d`) tem o mesmo nome da resposta do `feed.qgis.org` no cache do oficial hoje. A guarda do #043
   nao via (so `%APPDATA%\QGIS`). O crash handler grava em `%LOCALAPPDATA%\QGIS\QGIS3\crashes`, e o WinToast valida a
   cada abertura o atalho `%APPDATA%\...\Start Menu\Programs\QGIS3.lnk` (hoje do spike 016 da distro, de 2026-09-06,
   que o build so le porque o AUMI e igual). Decisao do sponsor: **mitigar e seguir**. O smoke poe o cache dentro
   do perfil descartavel, a guarda vigia as duas coisas, e o A8 remove a pasta de crash que criar. **O produto
   instalado continua gravando nessas pastas**: isso so se resolve com o nome interno, na fatia do instalador.
   Tambem do nome interno: o `main.cpp` le um `qgis_global_settings.ini` de `%APPDATA%\QGIS\QGIS3` antes do da
   instalacao, se existir (so leitura, `main.cpp:995`).
2. **O build incremental nao trocava o icone do executavel.** O ninja nao rastreia o `.ico` que o `qgis_win32.rc`
   embute: o primeiro smoke mostrou `IDI_ICON1` ainda do QGIS. O `Build-Qgis.ps1` agora remove o `.res` mais velho que
   o `qgis.ico` antes do build. Um build limpo nao teria o problema.
3. **Tres rotulos do "Sobre" corrigidos.** A primeira curadoria pos na classe versao `QGIS version`, `QGIS code
   revision` e `QGIS code branch` (contexto `QgisApp`), e a captura do "Sobre" mostrou "Versao do motor QGIS".
   `QgisApp::getVersionString` so alimenta o "Sobre", e o "Sobre" fica (BL-1): os tres voltaram para a classe projeto
   QGIS antes das rodadas finais (`05-sobre.png` agora igual ao oficial).
4. O link da revisao no "Sobre" aponta para `github.com/qgis/QGIS/commit/<commit deste fork>`. E o "Sobre" do QGIS e
   nao mudou; fica registrado para quem decidir o link da fonte (BL-6).

## Testes alterados (todos nossos, em `iman/build/`)

Nenhum teste do QGIS foi tocado (a suite nao roda no build, `ENABLE_TESTS=FALSE`).

| Arquivo | Mudanca | Motivo |
|---|---|---|
| `Invoke-Smoke.ps1` | a GUI roda tambem no oficial; o passo `providers` compara ids com `smoke/expected/` (antes: "tem provedor e tem `native:buffer`"); `plugins` compara com a referencia; novos `projeto-salvo`, `marca:*`, `controle:sobre`; veredito de controle no oficial; cache de rede no perfil | itens 16, A11, A12 e achado 1 |
| `smoke/smoke_gui.py` | coleta os fatos de marca, exporta o PDF, salva a copia do projeto | A3 a A11 |
| `Test-OfficialQgisUntouched.ps1` | vigia `%LOCALAPPDATA%\QGIS` e o `QGIS3.lnk`; raizes parametrizaveis | achado 1, A12 |
| `Invoke-Gate.ps1`, `Invoke-ImanBuild.ps1` | retrato da guarda no comeco de cada rodada | R1, item 15 |
| novos | `Test-GuardRounds.ps1`, `Invoke-BrandCaptures.ps1`, `WindowCapture.ps1`, `smoke/capture_gui.py`, `smoke/pe_icon.py`, `smoke/expected/*.txt`, `Export-Evidence.ps1`, `Start-ImanTerra.ps1` | A6, A8, A9, A12, A13 |

## O que esta fatia NAO testou

- **A VM limpa (BL-7)**: tudo aqui rodou na bancada; a lacuna segue declarada.
- As 82 mensagens da sobreposicao uma a uma na interface: o smoke confere as do titulo, splash, menu e crash handler;
  as demais estao no `.qm` (o lrelease compilou as 83) mas nao foram abertas tela a tela.
- Um travamento real do QGIS: o crash handler rodou com relatorio sintetico.
- A notificacao do Windows (WinToast) com o icone do produto; o SVG que ela pede do disco (`images/icons/qgis_icon.svg`)
  nao e instalado pelo QGIS, como no oficial.
- O idioma ingles: sem sobreposicao em ingles (fora de escopo); quem trocar o idioma para ingles ve "QGIS".
- O crash handler fala pt_BR fixo (o idioma padrao do produto), mesmo que o operador mude o idioma do QGIS.
- Build limpo do zero com o patchset: as rodadas foram incrementais sobre o build do #043.

## Smoke do sponsor

```
pwsh -NoProfile -File iman/build/Start-ImanTerra.ps1
```

Abre o build de `D:\iman-terra-build\install` com um perfil descartavel novo (em
`D:\iman-terra-build\smoke\sponsor-<data>`), no idioma padrao do produto. Para comparar com o oficial nas mesmas
condicoes: `pwsh -NoProfile -File iman/build/Invoke-BrandCaptures.ps1 -Target Official`.
