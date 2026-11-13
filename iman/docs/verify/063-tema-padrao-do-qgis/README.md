# Laudo 063: o IMAN Terra volta ao tema padrão do QGIS

Briefing `qgis-build #063` (D-IMAN-040, emenda de 2026-11-12; D-IMAN-026, que fica como referência; D-IMAN-034), com
a correção de 2026-11-13 (pergunta P0.10 da Crew sobre a `tema-na-arvore`). Branch `fix/063-tema-padrao-do-qgis`,
nascida de `develop` `27cc517ad0`. Máquina: Windows 11 Pro em espanhol, tela em escala 125%. Medições de 2026-11-13.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (lido no código, não
medido, com o motivo), **N/E** (não executado).

**Builds medidos:**
- ANTES: `27cc517ad0`, a `develop` intacta, compilada no começo da sessão (`QGIS code revision` do binário).
- DEPOIS: `cc3677ab9d` (setas, perfis, `Test-ThemeDefaults`) e `1f621a8d13` (smoke). Entre os dois só muda
  `.memory/`: o commit de memória entrou durante o build da `cc3677ab9d`, e o smoke exige que a revisão do binário seja
  o HEAD (BL-6). Por isso o build foi refeito no HEAD para o smoke.

Os commits depois desses mudam só este laudo.

**Como o sponsor abre:** `pwsh -NoProfile -File iman/build/Start-ImanTerra.ps1` (o build desta branch, perfil novo).
Nenhum instalador nesta fatia. Nos textos da evidência, o caminho do perfil do Windows virou `%USERPROFILE%`. As
capturas da janela escondem o painel Navegador (ele lista as unidades com nome e e-mail de conta).

## Veredito

**A1 a A6 medidos; o gate roda depois do PR aberto (resultado no `/deliver`).** Sem o tema, o produto abre com o tema
`default`, sem folha de estilo e com o mesmo estilo do Qt do QGIS oficial (`QgsAppStyle` sobre `QFusionStyle`). Todas as
setas do A2 aparecem no DEPOIS, com a mesma medida do oficial. Nenhum perfil existente ficou com o tema. Nada mais
mudou. O QGIS oficial ficou intocado (guarda OK em toda rodada).

Nenhum STOP disparou. Testes existentes alterados, todos da lista fechada do briefing: `Test-ThemeDefaults.ps1`
(`T1:tema-padrao`, `T9:temas-de-fabrica` e `tema-na-arvore`, esta pela correção de 2026-11-13), `Test-ThemeQss.ps1` (só a
forma de achar o arquivo) e `smoke/theme_facts.py` (só acréscimo).

## O que mudou

| Onde | O quê |
|---|---|
| `iman/brand/brand.json` | Sai a chave `ui_theme`. |
| `iman/brand/build_brand.py` | O `qgis_global_settings.ini` gerado não tem mais a seção `[UI]` com `UITheme`. |
| `iman/build/Build-Qgis.ps1` | Não copia mais o tema para `resources\themes`. Remove a pasta que um build anterior deixou lá: o `cmake --install` não apaga o que não instala. Os temas do QGIS ficam. |
| `iman/brand/theme/IMAN Terra/style.qss` | Só o comentário do cabeçalho que dizia como o arquivo chega ao produto: agora diz que ele está fora do build desde a 063. Regras e paleta sem mudança (`Test-ThemeQss.ps1` 14 de 14). |
| `iman/brand/README.md` | O `ui_theme` saiu da linha do `brand.json`, e a linha do `style.qss` diz que ele está fora do build. |
| `iman/build/Test-ThemeDefaults.ps1`, `Test-ThemeQss.ps1`, `smoke/theme_facts.py` | Lista fechada do briefing (seção A5). |
| `iman/build/Invoke-ArrowCaptures.ps1`, `smoke/arrow_controls.py` (novos) | Medida e capturas das setas do A2, por alvo, com perfil novo. |
| `iman/build/Measure-ProfileTheme.ps1`, `smoke/profile_theme.py` (novos) | Medida do A3: tema, folha, estilo do Qt e as chaves `UI/UITheme` e `qgis/style` do `.ini`, antes e depois de o alvo abrir o perfil. |
| `.memory/reference_build_environment.md` | A nota do 049p (gate fora desta ferramenta) foi marcada como vencida pela 061 (briefing). |

`iman/PATCHES.md` sem mudança: nenhum arquivo do QGIS foi tocado.

**Por que tirar a chave, e não gravar `UITheme=default`** (escolha da Crew, item 1 do briefing; medido):
- O `src/app/main.cpp:1458-1466` lê `UI/UITheme` **sem valor padrão**. Com a chave ausente, o tema vem vazio, que é
  diferente de `default`, e o QGIS troca o estilo do Qt para `fusion`. É o que acontece no QGIS oficial, cujo
  `qgis_global_settings.ini` não tem a chave.
- Com `UITheme=default`, o QGIS cairia no estilo da plataforma (o do Windows), uma cara diferente da do oficial.
- Ausente, o produto fica igual ao oficial: `QgsAppStyle` sobre `QFusionStyle` nos dois (A1, A3).

## A1 Tema padrão no build (medido)

`tema-padrao/depois-perfil-novo/result.json` (`Test-ThemeDefaults.ps1 -Target Build -ProfileState New`, build
`cc3677ab9d`):

| Fato | Valor |
|---|---|
| `themeName` | `default` |
| Folha de estilo | 0 caracteres |
| Estilo do Qt | `QgsAppStyle` (o proxy do QGIS) sobre `QFusionStyle` |
| `UI/UITheme` | ausente (`null`) |
| `qgis/style` | `fusion`, gravado pelo próprio QGIS no perfil, `main.cpp:1487` |
| Lista de temas | `Blend of Gray`, `default`, `Night Mapping` |
| Opções > Geral | `default`, com os mesmos três itens |
| `resources\themes\IMAN Terra` | ausente |

**O estilo do Qt nesta máquina, sem tema e sem `qgis/style`, é o Fusion** (`QFusionStyle`, dentro do `QgsAppStyle`). O
perfil novo do QGIS oficial dá o mesmo: `perfis/perfil-oficial-novo/result.json` e
`tema-padrao/oficial-controle/result.json`. O estilo da plataforma não entra porque o tema vem vazio (acima).

## A2 As setas (medido)

`Invoke-ArrowCaptures.ps1`, perfil novo, janela maximizada (área útil 1536x889 lógicos; imagens em pixels físicos, escala
125%). Para cada controle, o roteiro pega o retângulo da seta que o próprio estilo informa (`subControlRect`, já com a
folha de estilo, se houver) e conta a "tinta": pixels que diferem da cor mais comum do retângulo. Seta visível = 3 ou
mais pixels de tinta. As capturas estão ao lado, ampliadas.

Pastas: ANTES `setas-antes-27cc517ad0/`, DEPOIS `setas-depois-cc3677ab9d/`, controle `setas-oficial/`.

| Controle | Captura | ANTES (com o tema) | DEPOIS | Oficial |
|---|---|---|---|---|
| Caixa de lista (tipo de simbologia, Propriedades da camada) | `05-caixa-de-lista.png` | visível (30) | visível (35) | visível (35) |
| Caixa de número com setas (rotação do símbolo, `spinAngle`) | `06-caixa-de-numero.png` | **ausente** (0 e 0: só traços no lugar das setas) | visível (39 e 35) | visível (39 e 35) |
| Botão de barra com menu (seleção de feições) | `02-botao-com-menu.png` | visível (90), **mas por cima do ícone** | visível (25), ao lado do ícone | visível (25) |
| Barra de rolagem (caixa de ferramentas do Processamento) | `04-barra-de-rolagem.png` | **ausente** (o tema não desenha os botões das pontas: retângulo vazio) | visível (32 e 32) | visível (32 e 32) |
| Setas de expandir, painel Camadas (grupo aberto e fechado) | `03b-setas-da-arvore.png` | visíveis (33, 30) | visíveis (34, 30) | visíveis (34, 30) |
| Setas de expandir, caixa de ferramentas | `04b-caixa-de-ferramentas.png` | visíveis | visíveis | visíveis |
| Abas do diálogo do Processamento (`native:buffer`) | `07-abas-do-processamento.png`, `07b-...-registro.png` | visíveis, texto inteiro (aba 81 para texto 50; 46 para 16) | visíveis, texto inteiro (75 para 50; 40 para 16) | iguais ao DEPOIS |

**Critério do briefing: todas visíveis no DEPOIS. Cumprido.** No DEPOIS, cada número é idêntico ao do oficial.

- **Botão com menu, no ANTES:** a tinta conta o canto do ícone junto com a seta. A imagem mostra o que o número sozinho
  não distingue: com o tema, o botão é estreito e a seta ▾ fica desenhada sobre o ícone; sem o tema, ela fica ao lado,
  como no oficial. Isso também aparece nas `01-janela.png` (barra de seleção).
- **Abas:** abas não têm seta. A linha mede o que o briefing pede delas, visíveis e com o texto inteiro.

## A3 Perfis existentes (medido)

`Measure-ProfileTheme.ps1`. As chaves foram lidas do `.ini` do perfil antes e depois da rodada; o que mudar foi o QGIS
que gravou. O perfil (c) nasceu do build da `develop` (`-ProfileState Existing`, pasta da bancada
`D:\iman-terra-build\verify\063-perfil-da-develop`) e foi reaberto pelo build desta branch.

| Perfil | Build | Tema | Folha | Estilo do Qt | `.ini` antes: `UITheme` / `style` | `.ini` depois |
|---|---|---|---|---|---|---|
| (a) novo | `develop` (ANTES) | `IMAN Terra` | 14518 | `QStyleSheetStyle` | ausente / ausente | ausente / `fusion` |
| (a) novo | esta branch | `default` | 0 | `QgsAppStyle` (`QFusionStyle`) | ausente / ausente | ausente / `fusion` |
| (b) cópia do `profile-0.4.0` | `develop` (ANTES) | `IMAN Terra` | 14518 | `QStyleSheetStyle` | ausente / `fusion` | ausente / `fusion` |
| (b) cópia do `profile-0.4.0` | esta branch | `default` | 0 | `QgsAppStyle` (`QFusionStyle`) | ausente / `fusion` | ausente / `fusion` |
| (c) criado pela `develop` | `develop` (cria) | `IMAN Terra` | 14518 | `QStyleSheetStyle` | ausente / ausente | ausente / `fusion` |
| (c) criado pela `develop` | esta branch (reabre) | `default` | 0 | `QgsAppStyle` (`QFusionStyle`) | ausente / `fusion` | ausente / `fusion` |
| controle: novo | QGIS oficial | `default` | 0 | `QgsAppStyle` (`QFusionStyle`) | ausente / ausente | ausente / `fusion` |

Evidência: `perfis/perfil-{antes,depois}-{novo,fixture,develop}/` e `perfis/perfil-oficial-novo/`.

**Relato pedido pelo briefing (nenhuma migração escrita):**
- Nenhum perfil continuou com o tema. Nenhum dos três tinha `UI/UITheme` gravado: o tema vinha só da global, que saiu.
- Os três continuam com `qgis/style=fusion`, e isso é o comportamento do QGIS, não um resto do tema. O perfil novo do
  oficial também termina com `fusion`, gravado pelo próprio `main.cpp:1487`. O estilo usado é o mesmo com ou sem a
  chave.
- **Relatado, não medido:** um usuário que escolheu `IMAN Terra` em Opções > Geral tem `UI/UITheme=IMAN Terra` no
  perfil. Pela leitura do código, `QgsApplication::setUITheme` (`src/core/qgsapplication.cpp:1095`) cai no `default`
  quando o tema não existe mais. Na caixa de Opções, o item gravado não acha correspondência. O que fazer com esses
  perfis é decisão do sponsor.

## A4 Nada mais muda (medido)

| Verificação | Resultado | Evidência |
|---|---|---|
| `Invoke-Smoke.ps1` no build `1f621a8d13` | 19 de 19 OK: `version` (revisão `1f621a8d13` = HEAD), provedores, plugins, `native:buffer`, GUI e `.qgz`, projeto salvo, as dez `marca:*` (título, tradução, idioma, splash, texto do splash, ícones, endereços do Ajuda, notícias e versão, PDF, plugin REURB 0.4.0), `controle:sobre`, `dados-do-produto` e a guarda. Mesmo conjunto e mesmo resultado das fatias anteriores | `smoke-build/summary.json` |
| `Test-Patchset.ps1` | 13 arquivos do QGIS alterados, 13 listados, OK; `iman/PATCHES.md` sem mudança | `bateria/patchset.txt` |
| `Test-ThemeQss.ps1` sobre o arquivo do repositório | 14 de 14 | `bateria/tema-qss.txt` |
| Guarda do QGIS oficial | OK em toda rodada: setas, perfis, `Test-ThemeDefaults`, smoke | `guard` em cada `result.json` |
| `Test-ThemeDefaults.ps1`, fora do tema | `T5` (SRC do projeto novo e Opções), `B7` (SRC de camada sem SRC), `T3:D1` (botão de fechar da dock), `T3:D2` (coordenada inteira no campo) e `T3:D4` (título da dock), todos OK no DEPOIS, nos perfis novo e semeado, e sem mudança no teste | `tema-padrao/depois-perfil-*` |

**O que o smoke não confere** e como ficou coberto:
- SRC padrão de projeto e de camada: o `Test-ThemeDefaults` (T5 e B7, acima).
- Plugin REURB nos quatro estados de perfil e a pasta embarcada contra a trava: `Test-PluginBoot.ps1` e
  `Test-PluginEmbed.ps1`, **N/E** nesta fatia. Nenhum arquivo do plugin, da trava ou do `Export-ImanPlugin` mudou. O
  smoke confere o plugin ativo (`marca:plugin-reurb`).
- A árvore instalada e o instalador: fora de escopo. O instalado nesta máquina (o da 061) continua com o tema até o
  próximo instalador.
- O ícone do executável (`.ico`) e o atalho do Menu Iniciar: só no instalado.

## A5 `Test-ThemeDefaults.ps1` ajustado (medido)

O que mudou no teste, todo da lista fechada do briefing:
- **`T1:tema-padrao`:** afirma o `default`, sem folha, sem `UI/UITheme` escolhido pela global.
- **`T9:temas-de-fabrica`:** Opções > Geral em `default`, sem `IMAN Terra` na caixa, e a volta ao `default` sem folha.
- **`tema-na-arvore`:** invertida (correção de 2026-11-13). Afirma a pasta `IMAN Terra` fora de `resources\themes` do
  alvo e fora da lista de temas.
- **Nome do tema do produto:** vem da pasta de `iman/brand/theme`, porque o `brand.json` não tem mais `ui_theme`. Por
  isso o `controle:tema-default` do oficial lê o nome de lá; a asserção dele não mudou.
- `T3:D1`, `T3:D2` e `T3:D4` não mudaram.

**Visto falhando** contra o build da `develop` `27cc517ad0`, que tem o tema
(`tema-padrao/visto-falhando-develop-27cc517ad0/result.json`):

```
T1:tema-padrao             FALHOU  {"themeName":"IMAN Terra","styleSheetLength":14518,"qtStyle":"QStyleSheetStyle","qtStyleBase":null,"settingUITheme":"IMAN Terra","settingQgisStyle":"fusion","userIniHasUITheme":false}
tema-na-arvore             FALHOU  {"product":"IMAN Terra","themeDir":"D:\\iman-terra-build\\install\\apps\\qgis-ltr\\resources\\themes\\IMAN Terra","inTree":true,"loadedFrom":"D:/iman-terra-build/install/apps/qgis-ltr/resources/themes/IMAN Terra"}
T9:temas-de-fabrica        FALHOU  {"optionsItems":["IMAN Terra","default","Night Mapping","Blend of Gray"],"optionsCurrent":"IMAN Terra",...}
T5:src-projeto-novo, B7:src-camada-sem-src, T5:opcoes-src, T3:D1, T3:D2, T3:D4, dados-do-produto, guard: OK
tema e padroes Build/new FALHOU
```

**Verde** contra o build desta branch, perfil novo (`tema-padrao/depois-perfil-novo/result.json`) e perfil semeado
(`tema-padrao/depois-perfil-semeado/result.json`):

```
T1:tema-padrao             OK  {"themeName":"default","styleSheetLength":0,"qtStyle":"QgsAppStyle","qtStyleBase":"QFusionStyle","settingUITheme":null,"settingQgisStyle":"fusion","userIniHasUITheme":false}
tema-na-arvore             OK  {"product":"IMAN Terra","themeDir":"D:\\iman-terra-build\\install\\apps\\qgis-ltr\\resources\\themes\\IMAN Terra","inTree":false,"loadedFrom":null}
T9:temas-de-fabrica        OK  {"optionsItems":["Blend of Gray","default","Night Mapping"],"optionsCurrent":"default",...}
T5, B7, T3:D1, T3:D2, T3:D4, dados-do-produto, guard: OK
tema e padroes Build/new OK
tema e padroes Build/seeded OK
```

Controle oficial (`tema-padrao/oficial-controle/result.json`): `controle:tema-default` e `controle:src-4326` OK.

## A6 Sem travessão (medido)

U+2014 e U+2013 contados nas linhas acrescentadas de `git diff 27cc517ad0..HEAD`, por arquivo, com este laudo
incluído: zero em todos os arquivos, salvo um: `smoke-build/summary.json`, com 3 U+2014 e zero U+2013. Os três são
títulos de janela medidos do programa: `"smoke [U+2014] IMAN Terra [iman-smoke]"` (duas vezes) e
`"Projeto sem título [U+2014] IMAN Terra [iman-smoke]"`. O QGIS monta esses títulos em `src/app/qgisapp.cpp:604`, e o
caractere é decisão do sponsor em aberto (fora de escopo). Como evidência, fica como foi medida. O código, os scripts,
o `style.qss`, o `README.md` da marca, a memória e este laudo: zero e zero.

## Achados

1. **O `qgis/style=fusion` dos perfis é o comportamento do QGIS.** O oficial grava a mesma chave num perfil novo
   (A3). Não há o que limpar.
2. **O instalado nesta máquina segue com o tema** (o IMAN Terra da 061, deixado para o smoke do sponsor) até o
   próximo instalador. Fora de escopo, como diz o briefing.
3. **O `THIRD_PARTY_NOTICES.md` na raiz de `D:\iman-terra-build\install`** é sobra do build da 059 (em HOLD). Ele não
   entra na árvore do instalador, que só leva `apps\qgis-ltr`, e não muda nada aqui.
4. **A tinta do botão com menu** conta o ícone quando a seta se sobrepõe a ele (A2). A captura é quem decide nesse
   caso, e o laudo diz isso.

## Bancada

- Disco: D: com 35 GB livres no começo.
- Tempos: build da `develop` 393 s + install 355 s; build desta branch 101 s + install 390 s; setas cerca de 40 s por
  rodada; perfis 12 a 20 s; `Test-ThemeDefaults` cerca de 40 s; smoke cerca de 30 s.
- Nada instalado, nada desinstalado. O QGIS oficial e o IMAN Terra instalado não foram abertos por esta fatia, fora o
  oficial nas rodadas de controle, só lido e com perfil descartável.
