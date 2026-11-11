# Laudo 058: a bancada sem as dívidas e o tema que o smoke reprovou

Briefing `qgis-build #058` (D-IMAN-040, emendas de 2026-10-29, 2026-11-04 e 2026-11-11; D-IMAN-026, D-IMAN-039,
D-IMAN-034). Branch `fix/058-higiene-e-tema-do-smoke`, nascida de `develop` `ed077db443` (merge do PR #6, a 051).
Máquina: Windows 11 Pro em espanhol, 24 processadores lógicos, 32 GB. Medições de 2026-11-11.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (não observável por
este teste, com o motivo), **N/E** (não executado).

**Build medido:** `961da7e559` (`QGIS code revision` do binário e `Commit` do `instalador/BUILD_INFO.txt`). Os commits
depois dele mudam só scripts de medição (`Measure-ThemeRegions.ps1`), um comentário do `style.qss` e este laudo.
O "antes" é o binário da `85296b938d`, de árvore idêntica à da `ed077db443` (`git diff` vazio), medido antes de
recompilar.

**Alvo do smoke do sponsor:**
`D:\iman-terra-build\dist\0.4.0-961da7e559\Instituto-IMAN-IMAN-Terra-Setup-0.4.0-961da7e559.exe` (513.010.025 bytes,
SHA-256 `9faf370f382d0aa558a775ac311bff661c127c526a70301f1b07d45aca8c224d`, Inno Setup 7.1.0). Nenhum instalador entra
no git. Nos textos da evidência, o caminho do perfil do Windows (longo, 8.3 e com qualquer barra) virou
`%USERPROFILE%`. As capturas das regiões escondem o painel Navegador (unidades com nome e e-mail de conta); das
rodadas de smoke só vão os JSON.

## Veredito

**T1 a T7 medidos; o gate roda depois do PR aberto (resultado no `/deliver`).** As cinco regiões passam no build e na
árvore instalada, contra o QGIS oficial na mesma janela e no mesmo algoritmo. O texto do splash sai branco e legível
no rodapé inteiro. As quatro dívidas da bancada têm dono e prova. Nada regrediu no T6. O QGIS oficial ficou intocado
em toda etapa (guarda OK em cada rodada).

Desvios do briefing, todos decididos pelo sponsor na sessão e declarados aqui:
- **B1:** a causa medida é vertical, não horizontal. A correção tira o padding da regra geral dos campos (decisão do
  sponsor: "campos e barras" com os recuos do QGIS original), e não o `padding-left: 0; padding-right: 0` previsto. A
  asserção 3 não precisou mudar.
- **B2:** o conserto tira o negrito da aba selecionada.
- **B3:** só os botões "..." (QToolButton). As setas dos campos numéricos, que também somem, ficam como achado 2.
- **B5:** o briefing manda tirar `spacing` e `padding` e exige altura e passo iguais aos do oficial; as duas coisas não
  fecham (sem nenhum, 33 e 30). Valeu o oficial: `padding: 4px` na barra e `1px` no botão de barra. A asserção 14
  confere esses valores, e não a ausência.
- **A3:** a pasta vem do QGIS (HSTS do Qt), e só o caminho do perfil não resolve. Os testes do alvo Build passaram a
  remover o que a rodada criou (só pastas vazias), além do caminho do perfil.

## T1 Causas medidas (formato do D2 da 049)

`regioes-*/result.json` (`Measure-ThemeRegions.ps1` e `smoke/theme_regions.py`). Rotação em 359,9, janela 1536 x 960,
diálogo do `native:buffer` em 900 x 720, perfil novo. Unidades em pixels lógicos.

| Região | Oficial | Build antes (`ed077db443`) | Build depois (`961da7e559`) | Instalado |
|---|---|---|---|---|
| B1 rotação: altura útil / texto | 16 / 13 | **8 / 13, corta ao meio** | 16 / 13 | 16 / 13 |
| B1 rotação: largura útil / texto | 57 / 36 | 55 / 36 | 55 / 36 | 55 / 36 |
| B1 escala e lupa: altura útil / texto | 18 e 16 / 13 | 16 e 16 / 13 | 16 e 18 / 13 | 16 e 18 / 13 |
| B2 "Parâmetros" selecionada: largura útil / texto desenhado | 51 / 50 | **51 / 58 (negrito), corta dos dois lados** | 51 / 50 | 51 / 50 |
| B3 "..." ("Selecionar entrada" e saída): borda em repouso | `#ABABAB`, 82/86 do anel | **sem borda, 0/100** | `#D0D5C9`, 96/100 | `#D0D5C9`, 96/100 |
| B4 borda dos campos (contraste com o fundo do diálogo) | `#ABABAB` (207) | `#E2E5DE` (43) | `#D0D5C9` (98) | `#D0D5C9` (98) |
| B5 barra "Arquivo de projeto": altura / passo | 39 / 33 | **47 / 38** | 39 / 32 | 39 / 32 |

- **B1:** o QGIS fixa a altura do campo de rotação pela barra de status, e o `padding: 3px 7px` da regra geral dos
  campos casava com o spin box e com o campo de texto dentro dele. Os 3 px de cima e de baixo, duas vezes, comiam a
  altura. A largura sempre coube. Escala e lupa cabiam.
- **B2:** o Qt dá à aba a largura do texto normal mais a caixa (padding 14 + 14 e borda 1 + 1, total 30) e desenhava a
  selecionada com `font-weight: 600` (no Qt 5, `QFont::Bold`). As abas não selecionadas sempre couberam.
- **B3:** a regra global `QToolButton { background: transparent; border: 1px solid transparent }` apagava a borda de
  todo botão de ferramenta, também fora das barras. Os botões que o oficial já desenha planos (iterar, opções
  avançadas, valor definido por dado, recolher grupo, todos `autoRaise` ou com estilo próprio) seguem planos.
- **B5:** com `spacing: 3px; padding: 4px 6px` na barra e `padding: 3px` no botão, 47 e 38. Sem nenhum, 33 e 30: o tema
  troca o estilo do Qt para fusion, de margens menores que as do estilo do Windows (`b5-iteracoes/`). O Qt lê o padding
  do `QToolBar` só pelo lado esquerdo e o aplica nos quatro: com `padding: 2px 0px` a barra ficou com margem zero e
  altura 31; com `padding: 4px` e `1px` no botão, 39 e 32, primeiro botão em (13, 4) com 31 x 31 (oficial 32 x 31).

## T2 Lado a lado (V.4)

Capturas de perfil novo, do build desta branch, do QGIS oficial, do "antes" e do instalado, nas pastas
`regioes-oficial/`, `regioes-build-antes-ed077db443/`, `regioes-build-depois/` e `regioes-instalado/`:
`b1-barra-de-status.png` e `b1-escala-lupa-rotacao.png` (rodapé com 359,9), `b2-dialogo-parametros.png`,
`b2-dialogo-registro.png`, `b2-abas-*.png` (as duas abas), `b4-campo-em-repouso.png` e `b4-combo-em-repouso.png`,
`b5-barra-arquivo-de-projeto.png` e `b5-barra-navegacao.png`. A aba que o QGIS chama de "Log" sai "Log" nos dois
(o briefing a chamou de "Registro").

## T3 Guarda do tema vista falhando

`tema-qss/`: `Test-ThemeQss.ps1` na ponta (14 de 14) e contra o `style.qss` da `ed077db443` (asserções 1 a 9 passam,
10 a 14 caem, cada uma com a linha). Asserções novas, por acréscimo: 10 campos sem padding (B1, inclui rotação e
escala), 11 aba selecionada sem negrito (B2), 12 QToolButton fora da barra com borda e de barra transparente (B3), 13
borda dos campos `1px solid #D0D5C9` (B4), 14 `QToolBar` sem `spacing`, com `padding: 4px`, e `QToolBar QToolButton`
com `padding: 1px` (B5). As 9 existentes não mudaram. Raio: 12 declarações, todas 2px; nenhum hex fora da paleta.

## T4 Splash

- **Cor:** `splash_text_color: "#FFFFFF"` no `brand.json`, `IMAN_SPLASH_TEXT_COLOR "#FFFFFF"` no `iman_brand.h` gerado
  pelo `build_brand.py` (que recusa outro formato que não `#RRGGBB`), usada no `qgisapp.cpp` no lugar do `Qt::black`.
- **Captura (medido):** `regioes-build-depois/c1-splash-*.png` e `regioes-instalado/c1-splash-*.png`, splash real
  durante o carregamento. Os pixels da faixa do rodapé que diferem do `splash.png` derivado (o texto da mensagem) têm
  luminância mediana 198,5 no build e 199,2 no instalado; no "antes", 1 (preto,
  `regioes-build-antes-ed077db443/c1-splash-*.png`). O rodapé é escuro de ponta a ponta: o branco se lê em toda a faixa,
  e o STOP da cor não disparou.
- **Checagem:** `marca:splash-texto` no `Invoke-Smoke.ps1`. No commit do binário, o `qgisapp.cpp` usa a constante (e
  não `Qt::black`) e o `brand.json` tem a chave; no Build, o `iman_brand.h` a define com esse valor. Vista falhando no
  binário da `85296b938d` (`smoke-build-visto-falhando/summary.json`); OK na ponta (`smoke-build/`) e no instalado.

## T5 Higiene item a item (H.1), na ponta

- **A1 (medido):** `a1-conjunto-arvore/`: `Test-RuntimeSet.ps1` OK na árvore do instalador desta branch (152 pacotes do
  conjunto do produto, nenhum fora dele, 152 com a mesma lista de arquivos). `a1-conjunto-visto-falhando/`: numa cópia
  descartável de `iman/` com o `gdal-ecw` fora do `$RuntimeExcluded`, cai ("fora dele 1"); a cópia foi apagada.
  `conjunto-instalado/`: OK na árvore instalada. O `packages.differences` (relato contra o oficial menos os `qgis-ltr*`)
  segue igual, e o `Test-NoEcw.ps1`, que o lê, passou sem mudança (`sem-ecw-*`).
- **A2 (medido):** a mensagem vinha do `VsDevCmd.bat` (`Common7\Tools`, linha 181): `pushd` na pasta do Installer e
  `vswhere.exe` pelo nome. O ambiente do terminal define `NoDefaultCurrentDirectoryInExePath=1`, e o `cmd` deixa de
  procurar na pasta atual. A variável sai só no `cmd` do `vcvarsall`. `a2-vswhere/`: os logs dos builds incrementais da
  `c23b7a3db2` e da `961da7e559` começam pela linha do MSVC, sem a do `vswhere` (o log da 051 começava por ela).
- **A3 (medido):** causa, com o `cdb` das Debugging Tools (`a3-pasta-do-produto/cdb-CreateDirectoryW-trecho.txt`): na
  saída do processo, o destrutor do `QgsNetworkAccessManager` da thread principal sincroniza o armazenamento HSTS do
  Qt, que o QGIS liga sem diretório (`src/core/network/qgsnetworkaccessmanager.cpp:223`,
  `enableStrictTransportSecurityStore( true )`). O Qt usa então o `CacheLocation` padrão,
  `%LOCALAPPDATA%\InstitutoIMAN\IMANTerra\cache`, e ignora o `[cache] directory` do perfil. Acontece em todo
  `qgis_process` (menos `--version`, mesmo com `--skip-python`) e em toda GUI, no fechamento
  (`observador-*-antes.txt`). Perfil e ambiente não redirecionam o `CacheLocation`, e mudar o QGIS mudaria o produto.
  Decisão do sponsor: o alvo Build anota o que existia e remove no fim só o que a rodada criou, se forem pastas vazias;
  arquivo deixado lá reprova (`dados-do-produto` no smoke, no `Test-ThemeDefaults.ps1`, no `Test-PluginBoot.ps1`, no
  `Invoke-BrandCaptures.ps1` e no `Measure-ThemeRegions.ps1`). Prova: com as pastas e a chave do produto renomeadas
  para `.antes-058` (sim do sponsor), depois do smoke, do `Test-ThemeDefaults.ps1` (novo e semeado), do
  `Test-PluginBoot.ps1` (quatro estados e assistente) e das medições, as três seguem ausentes
  (`ausente-depois-do-build.txt`). Instalado o produto, o `Test-Installed.ps1` sem `-ResetProductData` passou no
  `A2:perfil-novo-antes` (`test-installed-sem-reset.json`).
- **A4 (medido no gate):** o `Invoke-Gate.ps1` roda cada etapa num `pwsh` com console próprio e oculto
  (`CreateNoWindow`), entrada fechada e saída repassada linha a linha; etapas, ordem e critério iguais. A queda da 049
  (0xE9 ao definir o título do console) não se reproduziu nesta sessão: o `pwsh` aninhado define o título em primeiro e
  em segundo plano, dos dois terminais do agente. A prova é o `crew_gate.sh qgis-build` rodado pela Crew, no
  `/deliver`.

## T6 Nada regride (medido, na `961da7e559`)

`bateria/t6-build-961da7e559.txt`: `Test-Patchset.ps1` (13 arquivos, a linha do `qgisapp.cpp` com a 058),
`Test-ThemeQss.ps1` (14 de 14), `Invoke-Smoke.ps1` (as 8 de marca, a do plugin, a nova do splash e
`dados-do-produto`; `smoke-build/`), `Test-ThemeDefaults.ps1` novo e semeado (`tema-build-*`), `Test-PluginBoot.ps1`
nos quatro estados e com o assistente (`plugin-build-*`), `Test-PluginEmbed.ps1` (`embarcado-build/`) e
`Test-NoEcw.ps1` na árvore (`sem-ecw-arvore/`). Guarda do QGIS oficial OK em todos.

## T7 Instalado (medido, com o sim do sponsor)

`ciclo/`: instalou por cima do 0.4.0 do smoke do sponsor (290 s, sem elevação, uma entrada só, perfil da distro
intacto), mediu e desinstalou (12 s, sem sobra; o perfil do produto fica). Na árvore instalada: `regioes-instalado/`
(B1 a B5 e o splash, com capturas), `smoke-instalado/`, `tema-instalado/`, `conjunto-instalado/` e
`sem-ecw-instalado/`, todos OK. A máquina terminou sem IMAN Terra instalado.

`instalado/`: o `Test-Installed.ps1` passou em tudo menos o `A3:notificacao` (achado 3).

## Achados

1. **`qgis_process` grava em `%LOCALAPPDATA%\qgis_process\cache\http-ranges`** (desde 2026-10-23 nesta máquina): os
   membros da aplicação nascem no construtor, antes do nome da organização, e o `QgsTileDownloadManager` cria a pasta
   pelo nome do executável. Fora da pasta do produto e fora do A3. O `qgis_process` do QGIS oficial grava no mesmo
   lugar. Fica para o arquiteto.
2. **As setas dos campos numéricos e a caixa da seta dos combos somem com o tema** (rodapé e diálogos; captura
   `regioes-build-depois/b2-dialogo-parametros.png` contra a do oficial). Os temas de fábrica do QGIS desenham com
   imagens próprias (`@theme_path/icons/arrow-up.svg`). Pela decisão do sponsor, fora desta fatia.
3. **`A3:notificacao` do `Test-Installed.ps1`:** na primeira rodada, a chave de notificação do AUMI do produto
   (`HKCU\...\Notifications\Settings\InstitutoIMAN.IMANTerra.IMANTerra.3.44.13-Solothurn`) já existia, do uso do
   0.4.0 pelo sponsor, e a checagem exige que não exista; o toast nativo saiu. Com a chave renomeada para `.antes-058`
   (sim do sponsor), nas rodadas 2 e 3 o Windows não recriou a chave e o QGIS caiu no aviso da barra de mensagens. A
   058 não toca esse caminho; na 047, na 049 e na 051 passou. Hipótese: estado da plataforma de notificações do
   Windows para esse AUMI. Relatado.
4. **O "..." do diálogo mede 26 x 24** (o tamanho de antes da 058, com o `padding: 3px` mantido); no oficial, 23 x 20 e
   23 x 22. Na sessão eu disse ao sponsor "26 x 24, como no oficial", o que estava errado; o comentário do tema foi
   corrigido. Com `padding: 2px` ficaria mais perto do oficial; fica para o smoke do sponsor.

## Bancada

- Sobras renomeadas, não apagadas (sim do sponsor): `%APPDATA%` e `%LOCALAPPDATA%` `\InstitutoIMAN\IMANTerra.antes-058`,
  `HKCU\Software\InstitutoIMAN\IMANTerra.antes-058` e a chave de notificação do AUMI com `.antes-058`. Os `.reg` em
  `D:\iman-terra-build\verify\058-pre-ciclo`. Depois do ciclo, `%APPDATA%\InstitutoIMAN\IMANTerra` voltou a existir
  (perfil das rodadas do `Test-Installed.ps1`, que fica na desinstalação).
- Disco: D: com 35 GB livres no começo; C: 176 GB.
- Tempos: build incremental 98 s + install 285 s; árvore de runtime 91 a 94 s; ISCC 744 s; instalar 290 s;
  desinstalar 12 s; medição das regiões com splash 25 a 35 s.
