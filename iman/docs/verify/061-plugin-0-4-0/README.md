# Laudo 061: o IMAN Terra embarca o plugin IMAN REURB 0.4.0

Briefing `qgis-build #061` (D-IMAN-040, emenda de 2026-10-29, item 4, e emenda de 2026-11-11, item 6; DB-27).
Branch `feat/061-plugin-0-4-0`, nascida de `develop` `d87fcc95db` (merge do PR #7, a 058). Máquina: Windows 11 Pro em
espanhol, 24 processadores lógicos, 32 GB. Medições de 2026-11-11.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (não observável por
este teste, com o motivo), **N/E** (não executado).

**Build medido:** `ee83c9c7b7` (`QGIS code revision` do binário e `Commit` do `instalador/BUILD_INFO.txt`). O commit
`7222f3f334`, depois dele, muda só o critério da cópia de segurança no teste de migração (abaixo), e as rodadas
`migracao-build-perfil-*` e `migracao-instalado` já saem com ele.

**Alvo do smoke do sponsor:** `D:\iman-terra-build\dist\0.4.0-ee83c9c7b7\Instituto-IMAN-IMAN-Terra-Setup-0.4.0-ee83c9c7b7.exe`,
instalado nesta máquina no fim da sessão (decisão do sponsor: fica instalado para o smoke). Nenhum instalador entra no
git. Nos textos da evidência, o caminho do perfil do Windows virou `%USERPROFILE%`.

## Pré-condições (medidas antes da branch)

- A tag `v0.4.0` do plugin aponta para `4f7cff89988b2af2f03dc6da6f116d7e53c5b224`, na `develop` dele. Dentro dela:
  `metadata.txt` com `version=0.4.0`, `LICENSE` presente e `SCHEMA_VERSION = 4` em `shared/config.py:47`.
- `origin/develop` do fork com o merge da 058 (`d87fcc95db`); nenhuma outra branch da Crew aberta, nenhum PR aberto.
- Nenhum script de teste fixa `0.3.1`, `v0.3.1` ou o commit antigo: fora do laudo, só a trava e a linha dos notices.

## O que mudou

- `iman/plugin/plugin.lock.json`: `version 0.4.0`, `tag v0.4.0`, `commit 4f7cff89988b2af2f03dc6da6f116d7e53c5b224`.
- `iman/notices/THIRD_PARTY_NOTICES.md`: a linha do plugin, regerada pelo `Update-Notices.ps1` (`-Check` OK).
- Nenhum arquivo do QGIS (`Test-Patchset.ps1`: os mesmos 13). Nenhum teste existente mudou.
- Teste novo: `iman/build/Test-PluginMigration.ps1` com `iman/build/smoke/migration_facts.py` (T2 da aba, T3, T4).

## Veredito

**T1 a T6 medidos; T7 (o gate) roda depois do PR aberto (resultado no `/deliver`).** O plugin 0.4.0 sai da tag,
byte a byte, no build, na árvore do instalador e na instalada, e carrega no arranque nos quatro estados de perfil. Um
projeto REURB v3 criado pelo plugin 0.3.1 do produto migra para v4 ao ser reaberto no IMAN Terra desta branch, com a
cópia de segurança ao lado e sem perder lote, pessoa ou vínculo; a aba Pessoas lista a pessoa migrada; a segunda
abertura não migra de novo. Nenhum STOP disparou. O QGIS oficial ficou intocado em toda etapa (guarda OK em cada rodada).

## T1 Embarque (medido)

`embarcado-build/`, `embarcado-arvore/`, `embarcado-instalado/`: `Test-PluginEmbed.ps1` OK nos três; a pasta embarcada
é a do `git archive` do commit da tag. No build, com `-SeenFailing`, os cinco casos de falha da 051 se reproduzem
contra a trava nova (clone ausente, tag ausente, trava em outro commit, licença ausente, versão diferente).

## T2 Arranque (medido)

`arranque-build-*`: `Test-PluginBoot.ps1` nos quatro estados da 051, todos OK com a trava 0.4.0: perfil novo e semeado
(plugin ativo, da árvore, versão 0.4.0), usuário que desligou (não carrega) e cópia no perfil (relato: carregou a
cópia de trabalho do clone, também 0.4.0); com o assistente de projeto, OK. No instalado (`arranque-instalado-*`):
perfil novo e assistente, OK. A aba Pessoas no dock é medida pelo `Test-PluginMigration.ps1` (T3), nos perfis novo e
semeado do build e no novo do instalado: o `Test-PluginBoot.ps1` não a olha, e a lista fechada do briefing não deixa
mudá-lo.

## T3 Migração no produto (medido)

- **Semente** (`migracao-semente-0.3.1/`): no build da 058 (`3a380f84e4`, plugin 0.3.1 da tag `v0.3.1`), antes de
  recompilar, o `Test-PluginMigration.ps1 -Phase Seed` criou pelo serviço do próprio plugin um projeto descartável
  (`projeto_de_teste_061.gpkg`, schema 3) com um lote, uma pessoa sem documento ("Pessoa de Teste 061", nenhum CPF ou
  CNPJ) e o vínculo dela ao lote, como proprietária principal. O briefing pedia o produto da `ed077db443`: o plugin é o
  mesmo (0.3.1, mesma tag), e a 058 só mudou tema e splash.
- **Visto falhando** (`migracao-visto-falhando-0.3.1/`): a fase Migrate no mesmo build 0.3.1 cai em `M1:migrou`
  (schema 3 antes e depois), `M1:copia-de-seguranca` (nenhuma), `M1:aba-pessoas` (abas "Projeto", "Confrontações",
  "Memorial") e `T4:gerenciador` (0.3.1 contra a trava 0.4.0).
- **Build desta branch** (`migracao-build-perfil-novo/`, `migracao-build-perfil-semeado/`) e **instalado**
  (`migracao-instalado/`), cada um com uma cópia nova da semente, abrindo duas vezes pelo caminho do botão "Reabrir
  projeto" do painel (o `OpenReurbProjectService` lê, migra e ativa):
  - M1: schema 3 para 4; `projeto_de_teste_061.gpkg.bak` ao lado; lotes, pessoas e vínculos 1, 1 e 1 antes e depois,
    a pessoa pelo nome; as oito colunas novas em `pessoas` (`issuing_agency`, `mother_name`, `father_name`,
    `municipality_name`, `municipality_state`, `spouse_id`, `property_regime`, `married_before_law_6515`);
  - M1: a aba Pessoas habilitada, "1 pessoa", a tabela com "Pessoa de Teste 061" (`dock-pessoas-abertura-1.png`; o
    painel nasce estreito e a coluna Nome sai cortada na captura, o nome está no JSON);
  - M2: na segunda abertura o schema já é 4 antes, nenhuma cópia nova (só o `.bak`), o `.bak` com o mesmo SHA-256 e as
    mesmas contagens.
- **A cópia de segurança não é byte a byte a semente** (`migracao-build-criterio-de-bytes/`): a primeira versão do
  teste exigia o SHA-256 da semente e caiu. Medido: as tabelas são todas iguais, inclusive o `sqlite_master`; muda só
  a página 0, nos bytes 18 e 19 (2 para 1: o arquivo sai do modo WAL para o modo de journal clássico) e 27 e 95 (o
  contador de alterações, mais 1) (`semente-x-bak.txt`). O GDAL faz isso ao abrir o arquivo, antes de o plugin copiar;
  na abertura pelo plugin 0.3.1, sem migração, o arquivo fica com o mesmo SHA-256 que o `.bak` tem aqui. O teste passou
  a conferir o conteúdo de todas as tabelas, e os SHA-256 seguem no relato. Não é perda de dado: o STOP da migração não
  disparou. Fica como achado para a Crew do plugin (a cópia é do arquivo já tocado pelo GDAL, não do arquivo intocado).

## T4 Gerenciador (medido)

Em `migracao-*/migration-abertura-1.json`, `plugin.manager`: o que a lista de complementos instalados mostra
(`pyplugin_installer`): "IMAN REURB", `version_installed` 0.4.0, autor "Instituto IMAN", instalado; o `pluginMetadata`
do QGIS diz o mesmo. Captura da janela do gerenciador: N/E (o dado é o da lista).

## T5 Instalado (medido, com o sim do sponsor)

`ciclo/result-install.json`: instalou por cima do IMAN Terra da 058 que o sponsor tinha instalado às 14:20 (159 s, sem
elevação, uma entrada só, perfil da distro intacto, guarda OK). Na árvore instalada: embarque (T1), arranque com perfil
novo e assistente (T2) e migração (T3), todos OK. Por decisão do sponsor, o produto **ficou instalado** para o smoke
dele: a fase de desinstalação não rodou. Nenhuma pasta ou chave do produto foi renomeada (briefing); o
`Test-Installed.ps1` não rodou: ele abre o produto pelo atalho com o perfil padrão, que é o do sponsor, e não está no T5
nem no T6 desta fatia (N/E).

## T6 Nada regride (medido)

`bateria/`: `Test-Patchset.ps1` (13, sem linha nova), `Invoke-Smoke.ps1` no build e no instalado (as 8 de marca,
`marca:splash-texto` e `marca:plugin-reurb` com 0.4.0; `smoke-*`), `Update-Notices.ps1 -Check` OK, `Test-NoEcw.ps1` na
árvore e no instalado (`sem-ecw-*`), `Test-RuntimeSet.ps1` OK na árvore e no instalado (`conjunto-*`). A lista "só no
nosso build" passou de 131 (árvore da 058) a 142 arquivos, e os 11 a mais estão todos em
`apps/qgis-ltr/python/plugins/iman_plugin/` (`conjunto-arvore/so-no-nosso-build-058-x-061.txt`: o registro de
pessoas, o painel, os formulários e o documento da 0.4.0); nenhum some.

## Achados

1. **A cópia de segurança da migração não é o arquivo intocado:** o GDAL tira o GeoPackage do modo WAL ao abri-lo, antes
   de o `GeoPackageSchemaMigrator` copiar. O dado é o mesmo; os bytes do cabeçalho não. Para a Crew do plugin, se a
   cópia tiver de ser o arquivo como o usuário o deixou.
2. **O painel do plugin nasce estreito** e a coluna Nome da aba Pessoas fica cortada até o usuário alargar o painel
   (captura). Para a Crew do plugin.
3. **Cópia no perfil:** o `Test-PluginBoot.ps1 -ProfileState OwnCopy` carregou a cópia de trabalho do clone do plugin
   (0.4.0 hoje); continua relato, sem árbitro, como na 051.

## Bancada

- Disco: D: com 35 GB livres no começo.
- Tempos: build incremental + install 4 a 5 min; árvore de runtime 59 s; ISCC 770 s; instalar 159 s; semente 10 s;
  migração (duas aberturas) 18 a 20 s.
