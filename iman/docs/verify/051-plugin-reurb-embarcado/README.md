# Laudo 051: o IMAN Terra sai com o plugin IMAN REURB instalado e ligado

Briefing `qgis-build #051` (emenda de 2026-10-29 ao D-IMAN-040, item 4; emenda de 2026-10-30, DB-27 e (b)).
Branch `feat/051-plugin-reurb-embarcado`, nascida de `develop` `6f849b3c9f` (o merge do PR #5, com o #049 e o 049p).
Máquina: Windows 11 Pro em espanhol, 24 processadores lógicos, 32 GB. Medições de 2026-11-08.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (dito por fonte externa
ou não observável por este teste, com o motivo), **N/E** (não executado).

**Build medido:** `471fbc2cf4` (`QGSVERSION` do build e `QGIS code revision` do binário). Todas as pastas abaixo saem
dele, salvo `embarcado-build-visto-falhando/` (o `Build-Qgis.ps1` que para antes de tudo, rodado na árvore de trabalho
de antes dos commits, com o mesmo `Export-ImanPlugin`).

**Alvo do smoke do sponsor:**
`D:\iman-terra-build\dist\0.4.0-471fbc2cf4\Instituto-IMAN-IMAN-Terra-Setup-0.4.0-471fbc2cf4.exe` (513.031.906 bytes,
SHA-256 `da9b224c3f00c5f7c3f6d536b4977a391eddedcd3db168bab9004951aacc8907`, Inno Setup 7.1.0;
`instalador/BUILD_INFO.txt`). Nenhum instalador entra no git. Nos arquivos de texto da evidência, o caminho do perfil
do Windows (nas formas longa e 8.3) virou `%USERPROFILE%`; das rodadas de smoke só vão os JSON (o `gui.png` mostra o
painel Navegador, que lista as unidades da máquina com nome e e-mail de conta).

| Pasta | O que é |
|---|---|
| `configuracao-global/ini-plugin.txt` | a seção `[PythonPlugins]` do `.ini` gerado e a contagem dela no `.ini` do QGIS (item 3) |
| `build-perfil-novo/`, `build-perfil-semeado-0.4.0/`, `build-usuario-desligou/`, `build-copia-no-perfil/` | `Test-PluginBoot.ps1` no build, nos quatro estados de perfil (T1) |
| `build-perfil-novo-assistente/` | o mesmo, perfil novo, com o assistente de projeto REURB e as capturas (T1, T3) |
| `oficial-visto-falhando/` | o QGIS 3.44.13 oficial na mesma medição: sem o plugin (controle) |
| `embarcado-build/` | `Test-PluginEmbed.ps1 -SeenFailing` na instalação do build: SHA-256 por arquivo e os cinco casos de falha (T2) |
| `embarcado-build-visto-falhando/` | `Test-PluginEmbed.ps1 -SeenFailingBuild`: o `Build-Qgis.ps1` para com a tag em outro commit (T2) |
| `smoke-build/`, `smoke-oficial/` | `Invoke-Smoke.ps1` no build e no oficial, com a checagem nova `marca:plugin-reurb` (item 6) |
| `ciclo/` | instalar e desinstalar o instalador desta branch (T5) |
| `embarcado-instalado/` | `Test-PluginEmbed.ps1` na árvore instalada, antes de abrir a GUI (T5, T2) |
| `instalado/` | `Test-Installed.ps1 -ResetProductData` inteiro (T6) |
| `instalado-perfil-novo-assistente/` | `Test-PluginBoot.ps1 -Target Installed -Wizard` (T5, T1 e T3) |
| `smoke-instalado/`, `tema-instalado/` | `Invoke-Smoke.ps1` e `Test-ThemeDefaults.ps1` na árvore instalada (T6) |
| `conjunto/` | `Test-RuntimeSet.ps1`: antes (049p, instalado), a árvore do instalador e a instalada (T6) |
| `sem-ecw/` | `Test-NoEcw.ps1` na árvore instalada (T6) |
| `instalador/BUILD_INFO.txt` | a identidade do instalador medido |
| `SHA256SUMS.txt` | hash de cada arquivo desta pasta |

## Veredito

**T1 a T6 passaram; T7 (o gate) roda depois do PR aberto.** O plugin IMAN REURB 0.3.1 sai da tag `v0.3.1` (commit
`a307801e3f4649c08a5d1be16abcef345fd53fbb`) para `apps\qgis-ltr\python\plugins\iman_plugin`, no build e na árvore do
instalador, byte a byte igual ao commit, e carrega no arranque pela configuração global, sem a chave no perfil. A escolha
do usuário vence a global. Nenhum arquivo do QGIS mudou. O QGIS oficial ficou intocado em toda etapa. Nenhum STOP do
briefing disparou.

Ressalva herdada, não regressão: o `Test-RuntimeSet.ps1` reprova só pelo `gdal-ecw` (R1 do gate do `047p`), como
no laudo 049; o que esta fatia muda nele é só a lista "só no nosso build" (T6).

## Pré-condições: medido

1. `origin/develop` `6f849b3c9f` tem `iman/brand/theme/IMAN Terra/style.qss` (blob `15babc080a`).
2. O clone do plugin (`..\iman-qgis-plugin-agent`, `develop` limpo em `a307801`) tem a tag anotada `v0.3.1`, que aponta
   para `a307801e3f4649c08a5d1be16abcef345fd53fbb` (o merge do PR #40 do plugin, depois do #050).
3. Na tag: `src/iman_plugin/LICENSE` é a GPL versão 2; o `metadata.txt` traz `version=0.3.1`, `author=Instituto IMAN`,
   `email=contato@example.org` e o bloco "MARCA RESERVADA".

## O que mudou

| Item | Onde |
|---|---|
| 1. Trava | `iman/plugin/plugin.lock.json` (id, nome, versão, licença, tag, commit de 40 caracteres, `path_in_repo`) e `iman/plugin/README.md`. O clone é parâmetro da bancada: `-PluginRepo` ou `IMAN_PLUGIN_REPO`, padrão `..\iman-qgis-plugin-agent` relativo à raiz do fork (`Common.ps1`) |
| 2. Exportação | `Export-ImanPlugin` (`iman/build/Common.ps1`): `git archive` do commit da trava com `core.autocrlf=false`, extraído numa pasta temporária e movido para `python\plugins\<id>`. Chamado pelo `Build-Qgis.ps1` depois do install e pelo `New-RuntimeTree.ps1` (que não copia a pasta do build e exporta de novo). Falha alto: clone ausente, tag ausente, tag em outro commit, `LICENSE` ausente e, além do briefing, `version` do `metadata.txt` diferente da trava |
| 3. Ligado por padrão | `iman/brand/build_brand.py`: `[PythonPlugins] <id>=true` no `qgis_global_settings.ini`, com o id lido da trava |
| 4. Notices | `iman/notices/Update-Notices.ps1` gera o bloco `plugin` do `THIRD_PARTY_NOTICES.md` da trava e exige o `LICENSE` do plugin no `iman-terra.lst.gz` da árvore (o `-Check` cobre a linha); `SOURCE_CODE.md` ganha a seção 3 com marcadores que o `Build-Installer.ps1` preenche da trava, sem URL do repo do plugin; o `BUILD_INFO.txt` ganha a linha `Plugin` |
| 5. Marca fora da GPL | `iman/brand/README.md` (seção nova) e `THIRD_PARTY_NOTICES.md`, seção 7 (instalado em `{app}`). `LICENSE` sem mudança; nenhuma linha de copyright |
| 6. Smoke | `smoke_gui.py` coleta `qgis.utils.active_plugins`, o arquivo do módulo e a versão; `Invoke-Smoke.ps1` ganha `marca:plugin-reurb` |

O plugin entra no pacote `iman-terra` do manifesto (`iman-terra.lst.gz`), não como pacote próprio: um pacote novo no
`installed.db` reprovaria o item 1 do `Test-RuntimeSet.ps1`, que compara a lista de pacotes com a do oficial.

## Item 3 e STOP da chave global: medido, não disparou

`QgsSettings::value` (`src/core/settings/qgssettings.cpp:170-182`) devolve o valor do perfil quando ele existe e,
senão, o da configuração global; `qgspluginregistry.cpp:655` lê `PythonPlugins/<id>` com ele. No perfil novo
(`build-perfil-novo/plugin.json`): `active: true`, `setting_effective: "true"`, `setting_in_user_ini: false`, sem
`watchDogTimestamp` sobrando, sem mensagem na barra e sem log crítico no arranque. A chave global liga o plugin sem
mexer na lista fixa do `qgspluginregistry.cpp`.

## T1 Carrega, em quatro estados de perfil: medido

| Estado | Resultado | Evidência |
|---|---|---|
| Perfil novo | ativo, de `apps\qgis-ltr\python\plugins\iman_plugin` do build, 0.3.1, autor Instituto IMAN; barra `IMAN REURB` visível, 14 ações | `build-perfil-novo/`, `toolbar.png` |
| Semeado com o `IMANTerra.ini` de uma rodada da 0.4.0 (sem `PythonPlugins/iman_plugin`) | ativo, igual ao novo | `build-perfil-semeado-0.4.0/` |
| Visto falhando: `PythonPlugins/iman_plugin=false` gravado pelo usuário | **não** carrega, sem barra; a chave do perfil vence a global | `build-usuario-desligou/` |
| Cópia própria em `python/plugins/iman_plugin` do perfil (a cópia de trabalho do clone do plugin, `a307801`, limpa) | **relatado:** carrega a cópia do perfil, versão 0.3.1. O `qgis.utils.plugin_paths` põe a pasta do perfil antes da do sistema | `build-copia-no-perfil/` (`loadedFrom`, `pluginPaths`) |
| Controle: QGIS oficial, perfil novo | sem o plugin (`active: false`, `available: false`) | `oficial-visto-falhando/` |

Na árvore instalada (T5), perfil novo: ativo, da pasta instalada, 0.3.1, barra visível (`instalado-perfil-novo-assistente/`).

## T2 A pasta embarcada é a da tag: medido

- `git archive` de `src/iman_plugin` em `a307801e3f` com `core.autocrlf=false`: 121 arquivos, cada um com o id de blob
  (`git hash-object --no-filters`) do `ls-tree` do commit. O clone do plugin tem `core.autocrlf=true`: sem o
  `-c core.autocrlf=false`, o archive sairia com CRLF e não seria o commit.
- Instalação do build: 121 de 121 com o mesmo SHA-256, nenhum a mais ou a menos, `LICENSE` presente; 101 arquivos em
  `__pycache__` (gravados pelo Python ao abrir a GUI) relatados, não reprovam (`embarcado-build/`,
  `sha256-embarcado.txt`).
- Árvore instalada, antes de abrir a GUI: 121 de 121, zero `__pycache__` (`embarcado-instalado/`).
- Visto falhando, na função de exportação (`embarcado-build/result.json`), cada caso para com a mensagem e não deixa
  nada na pasta de destino: clone ausente; tag ausente; trava em outro commit (`e9e2b57`, o pai da tag); `LICENSE`
  ausente (tag num clone `--shared` descartável em `e758256`, o commit de antes do `LICENSE`); `version` diferente.
- Visto falhando, no build inteiro (`embarcado-build-visto-falhando/`): com `-PluginRepo` num clone descartável em que a
  `v0.3.1` aponta para `e9e2b57`, o `Build-Qgis.ps1` sai com 1 e a mensagem `PLUGIN: a tag v0.3.1 aponta para
  e9e2b57b3e4d4b1bfcbf3b538fd16883ba56fce8, e a trava fixa a307801e3f4649c08a5d1be16abcef345fd53fbb`. Nada foi escrito
  no clone do plugin.

## T3 O plugin abre de verdade: medido

No perfil novo, pela ação `imanReurbToggle` (painel) e o botão "Criar projeto REURB" do painel: o diálogo "Criar
projeto REURB" abre com o SRC proposto **EPSG:31984** (`wizard.png`), aceita os campos e cria `smoke_051.gpkg` na pasta
descartável `<rodada>\work\reurb`, com 9 camadas (`areas_publicas`, `confrontacoes`, `edificacoes`, `lote_pessoa`,
`lotes`, `pessoas`, `quadras`, `vertices`, `vias`); o projeto fica em EPSG:31984 (`dock.png`). No build e na árvore
instalada (`build-perfil-novo-assistente/`, `instalado-perfil-novo-assistente/`). Nenhum projeto real foi aberto.

Relatado para a Crew do plugin, sem correção aqui: ao criar o projeto, o plugin emite um `DeprecationWarning` do
Python (`infrastructure/processors/field_mapping.py:47`, "QgsField constructor is deprecated"). É aviso, no uso, não no
arranque; o arranque não tem aviso nem erro (`bootWarnings` e `bootErrors` vazios).

## T4 Notices: medido

- `THIRD_PARTY_NOTICES.md`, seção 6, bloco gerado: `IMAN REURB (iman_plugin) | 0.3.1 | GPL-2.0-or-later | v0.3.1,
  a307801e3f4649c08a5d1be16abcef345fd53fbb | arquivo no pacote: apps/qgis-ltr/python/plugins/iman_plugin/LICENSE`.
- `SOURCE_CODE.md` instalado, seção 3: a tag e o commit, e que o fonte completo é a própria pasta instalada; zero
  ocorrência da URL do repo do plugin no `SOURCE_CODE.md` e no `THIRD_PARTY_NOTICES.md` instalados.
- `LICENSE` na pasta instalada do plugin (T2).
- O aviso de marca no `iman/brand/README.md` e na seção 7 do `THIRD_PARTY_NOTICES.md` instalado; o bloco "MARCA
  RESERVADA" no `metadata.txt` do plugin instalado (vem da tag).
- `Update-Notices.ps1 -Check`: em dia na árvore do instalador e na instalada (153 entradas, plugin 0.3.1).

## T5 Instalado: medido

Com o "sim" do sponsor na sessão (instalar, apagar os dados do produto e desinstalar):
`ciclo/result-install.json`: instalou em 253 s, sem elevação (`Administrative install mode: No`), uma entrada 0.4.0
em "Aplicativos instalados", o perfil da distro 0.3.0 com o mesmo SHA-256, a guarda OK. Na árvore instalada: T2
(acima), T1 no perfil novo e T3. `ciclo/result-uninstall.json`: desinstalou em 12 s; a árvore inteira saiu, e com ela
`apps\qgis-ltr\python\plugins\iman_plugin`; atalhos, associações e a entrada saíram; o perfil do produto ficou (como no
047); a guarda OK. A sessão terminou com o IMAN Terra desinstalado.

## T6 Nada regride: medido

- `Test-Installed.ps1 -ResetProductData` inteiro: OK (`instalado/`). O `-ResetProductData` apagou
  `%APPDATA%\InstitutoIMAN\IMANTerra`, `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra` e `HKCU\Software\InstitutoIMAN\IMANTerra`
  (os da rodada da 049p), com o sim do sponsor; as `.antes-*` ficaram.
- `Invoke-Smoke.ps1`: OK no build e no instalado, com `marca:plugin-reurb`; no oficial, o controle passa e
  `marca:plugin-reurb` cai junto com as outras marcas (`smoke-oficial/summary.json`). A comparação de plugins do
  `qgis_process` não mudou: o `qgis_process --json plugins` só lista plugin com provedor do Processamento
  (`src/process/qgsprocess.cpp:677`), e o plugin tem `hasProcessingProvider=no`; a lista segue `grassprovider`,
  `processing` (o item condicional da lista fechada não se aplicou).
- `Test-ThemeDefaults.ps1 -Target Installed`: OK (`tema-instalado/`).
- `Test-Patchset.ps1`: 13 arquivos do QGIS, 13 no `PATCHES.md`, sem linha nova.
- `Test-NoEcw.ps1` na árvore instalada: OK (`sem-ecw/`).
- `Test-RuntimeSet.ps1`: reprova só pelo `gdal-ecw` (herdado). A lista "só no nosso build" era 10 no 049p
  (`conjunto/antes-049p-instalado/`) e é 131 na árvore do instalador e na instalada; os 121 a mais são todos de
  `apps/qgis-ltr/python/plugins/iman_plugin/`, e nenhum dos 10 saiu. Pacotes e listas de arquivo dos 152 pacotes
  OSGeo4W: iguais. Comando que conta: a diferença dos conjuntos `ourBuildVsQgisLtr.onlyOurs` dos dois `result.json`.
- A guarda (`Test-OfficialQgisUntouched.ps1`): OK em toda rodada.

## T7 Gate: N/E nesta sessão

O gate registrado (`crew_gate.sh qgis-build`) roda depois do PR aberto (PR #6); o resultado vai no `/deliver`.

## Achados

1. **Cópia própria do plugin no perfil ganha da embarcada** (T1, relatado): o `qgis.utils` procura primeiro em
   `<perfil>\python\plugins`. Quem tem uma cópia de desenvolvimento no perfil do IMAN Terra roda a cópia dele, não a
   embarcada; o Gerenciador de complementos mostra a versão da cópia.
2. **Rodar o alvo Build cria `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra\cache` de novo** (já descrito na bancada desde a
   049): depois desta sessão, o próximo `Test-Installed` precisa outra vez do `-ResetProductData`.
