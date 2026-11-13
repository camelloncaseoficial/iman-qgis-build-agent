# Laudo 059: protótipo da página inicial IMAN e do "Sobre o IMAN Terra" no menu Ajuda

Briefing `qgis-build #059` (D-IMAN-040, emenda de 2026-10-29, item 3, e emenda de 2026-11-11, itens 3 a 5;
D-IMAN-039; D-IMAN-025; D-IMAN-026; D-IMAN-034). Protótipo de tela nova: as duas telas no lugar real, para o smoke do
sponsor. Sem guarda nova, sem teste de regressão, sem instalador. Branch `proto/059-pagina-inicial-e-sobre`, nascida
de `develop` `27cc517ad0` (merge do PR #8, a 061, que vem depois do merge da 058). Máquina: Windows 11 Pro em
espanhol, 24 processadores lógicos, 32 GB. Medições de 2026-11-12.

Legenda: **medido** (rodado e observado nesta máquina, com a evidência indicada), **relatado** (não observável por
este teste, com o motivo), **N/E** (não executado).

**Build medido:** `27f37b147a` (`QGIS code revision` do binário, no smoke e no selo de versão da página). Os commits
depois dele mudam só o roteiro de capturas (o que entra na foto) e este laudo.

**Como o sponsor abre:** `pwsh -NoProfile -File iman/build/Start-ImanTerra.ps1` (o build desta branch, perfil novo).

## Pré-condições (medidas antes da branch)

- `origin/develop` com o merge da 058 (`d87fcc95db` é ancestral) e da 061 (`27cc517ad0`); árvore limpa; nenhum PR
  aberto no fork antes do #9.

## O que mudou

| Onde | O quê |
|---|---|
| `src/app/iman/imanhomepage.{h,cpp}` (novos) | `ImanHomePage`: cabeçalho (sobretítulo, "Bem-vindo ao IMAN Terra", subtítulo), selo de versão com o commit, selo do SRC padrão (lido de `projections/defaultProjectCrs` a cada exibição), quatro cartões, "Projetos recentes", estado vazio, "Modelos de projeto", rodapé de créditos do QGIS. |
| `src/app/iman/imanaboutdialog.{h,cpp}` (novos) | `ImanAboutDialog`: símbolo, nome, subtítulo, versão e commit, "motor QGIS 3.44.13", Instituto IMAN e o nome completo, créditos do QGIS, "Licenças de terceiros" com o `THIRD_PARTY_NOTICES.md` da instalação, botões "Sobre o QGIS" e "Fechar". |
| `src/app/qgisapp.cpp` | Índice 1 do `mCentralContainer` passa a ser a `ImanHomePage`; `about()` abre o `ImanAboutDialog`, e o código do `QgsAbout`, sem mudança, roda pelo botão "Sobre o QGIS"; `mHelpMenu->removeAction( mActionQgisHomePage )`. |
| `src/app/CMakeLists.txt` | Os dois `.cpp` novos no `qgis_app`. |
| `iman/brand/brand.json`, `build_brand.py` | `organization_full_name`; o `iman_brand.h` ganha `IMAN_PRODUCT_VERSION`, `IMAN_ORGANIZATION_FULL_NAME` e `IMAN_COLOR_*`, a paleta lida do cabeçalho do `style.qss` do tema (as mesmas 18 cores que o `Test-ThemeQss.ps1` usa como fonte). |
| `iman/brand/i18n/curadoria_pt_BR.json` | 23 entradas `extra` (contextos `ImanHomePage` e `ImanAboutDialog`): o C++ tem a frase em inglês, o pt_BR vem da tradução sobreposta, o nome do produto entra por `%1` do `iman_brand.h`. |
| `iman/build/Build-Qgis.ps1` | Copia `iman/notices/THIRD_PARTY_NOTICES.md` para a raiz do install, dois níveis acima de `apps/qgis-ltr`, onde o instalador o põe (`{app}`): o "Sobre" o acha no build e no instalado pelo mesmo caminho. O `New-RuntimeTree.ps1` só leva `apps\qgis-ltr`, o instalador não muda. |
| `iman/PATCHES.md` | `qgisapp.cpp` (linha atualizada), `src/app/CMakeLists.txt` e os quatro arquivos de `src/app/iman/`: 18 arquivos, `Test-Patchset.ps1` OK. |
| `iman/build/Invoke-HomeCaptures.ps1`, `smoke/capture_home.py` (novos) | Roteiro das capturas e dos cliques deste laudo (fora do gate). |

Por que assim:

- **A `QgsWelcomePage` não foi removida nem alterada.** Ela segue criada, fora da tela, e continua dona do modelo de
  recentes e dos slots de fixar, desafixar, remover e limpar, ligados ao `QgisApp` como antes (e ao filtro do menu
  Projeto > Recentes). A página do produto mostra o mesmo modelo e repete o menu de contexto dela, com os textos e as
  traduções da própria `QgsWelcomePage`. Patch mínimo: nenhuma linha da página nativa nem do `qgisapp.h` muda.
- **O estilo das telas não foi para o `style.qss`.** A asserção 1 do `Test-ThemeQss.ps1` exige exatamente 12
  `border-radius` no tema; uma regra nova com raio a derrubaria (P0.10). As duas telas levam a folha de estilo
  delas no C++, com as cores do `iman_brand.h` (a paleta do cabeçalho do tema) e raio 2px. Nenhum hex escrito no C++.
- **Plugin e Python no arranque:** nenhum. As telas são C++ do `qgis_app` (STOP do briefing não disparou).

## Veredito

**T1 a T5 medidos no build `27f37b147a`; o T2 com o que ficou igual e o que mudou; o gate roda depois do PR aberto
(resultado no `/deliver`).** Nenhum STOP disparou. Nenhum teste existente mudou. O QGIS oficial ficou intocado (guarda
OK em cada rodada). O protótipo não foi instalado nem rodou na VM limpa (fora de escopo; BL-7 segue lacuna declarada).

## T1 Capturas (medido)

`capturas/`, todas do build com perfil novo, janela maximizada (área útil de 1536x889 pixels lógicos; a tela desta máquina está em escala 125%, e a imagem sai com 1920x1111) salvo a de 1366x768. O painel
Navegador foi escondido antes das capturas da janela: ele lista as unidades da máquina com o nome e o e-mail das
contas, que não vão para um repositório público. Pelo mesmo motivo, o diálogo de abrir projeto abre na pasta dos
projetos descartáveis e com só ela na barra lateral, e o gerenciador de fontes de dados é fotografado na página
Vetor (ele abre na página Navegador).

| Captura | O que mostra |
|---|---|
| `01-inicio-sem-recentes.png` | Página inicial, perfil novo: estado vazio "Nenhum projeto recente ainda. Comece por “Novo projeto” ou abra um projeto existente: os que você usar aparecem aqui."; "Modelos de projeto" com o "Novo Projeto Vazio" do QGIS. |
| `02-inicio-com-recentes.png` | Com três recentes, projetos descartáveis "Projeto de teste 059 A/B/C" (o fixture do smoke com outro título), abertos e fechados pelo próprio QGIS, do mais recente ao mais antigo. |
| `02b-recente-menu-de-contexto.png` | Menu de contexto de um recente: "Fixar à lista", "Abrir Diretório...", "Remover da Lista", "Clear List" (este último o QGIS 3.44.13 não traduz, nem na página nativa). |
| `03-inicio-1366x768.png` | Janela com moldura de 1366x768 pixels lógicos (área útil 1364x737; a imagem, na escala 125%, sai com 1705x921): os quatro cartões cabem numa linha; a página rola na vertical. |
| `04-menu-ajuda.png` | Menu Ajuda aberto (composição da janela com o menu na posição real): sem "Página do IMAN Terra"; "Sobre" no fim. |
| `05-sobre-iman-terra.png` | "Sobre o IMAN Terra", com a lista de terceiros rolada até o meio (5993 de 11986). |
| `06-sobre-o-qgis.png` | O `QgsAbout` aberto pelo botão "Sobre o QGIS": título "Sobre o QGIS", logo do QGIS, Sobre, O que há de Novo, Provedores, Desenvolvedores, Colaboradores, Tradutores, Contribuidores, Licença, "O QGIS é licenciado sob a General Public License (GNU)". |

Fatos lidos na tela (`capturas/home-captures.json`): selo "versão 0.4.0 · 27f37b147a"; SRC "EPSG:31984 · SIRGAS 2000 /
UTM zone 24S"; "Sobre o IMAN Terra" com "Versão 0.4.0 · 27f37b147a · motor QGIS 3.44.13", o
`THIRD_PARTY_NOTICES.md` lido de `D:\iman-terra-build\install\` (33353 caracteres de texto) e os botões "Sobre o QGIS" e
"Fechar". O item de menu continua "Sobre" (texto do QGIS, sem mudança).

## T2 Lado a lado com a distro (medido)

`capturas/lado-a-lado-*.png`: à esquerda `vitrine-home.png` e `vitrine-sobre.png` da distro congelada
(`../z_freeze/iman-qgis-distro-agent`, `59ac0ce`, `docs/verify/025-db23-db24/evidencia/shots/`), à direita o build.

**Página inicial, igual:** a ordem e a hierarquia (sobretítulo em verde, título de 26px, subtítulo, selos no canto
direito, quatro cartões numa linha com ladrilho, título e linha de apoio, "Projetos recentes" com título e caminho,
divisória, créditos do QGIS em texto pequeno no rodapé); as cores (fundo `bg`, cartões `panel` com borda `border`,
ladrilho `active-bg`, sobretítulo `brand-2`, textos `text`, `text-muted`, `text-faint`); os quatro cartões e os
textos de apoio; os recentes reais do QGIS e o estado vazio explícito.

**Página inicial, mudou e por quê:**
- Travessão fora (D-IMAN-034): o sobretítulo "... CADASTRO & REURB [travessão] CEARÁ" virou "INTELIGÊNCIA
  TERRITORIAL · CADASTRO E REURB · CEARÁ"; o subtítulo "... cartografia [travessão] em uma só ..." virou "...
  cartografia em uma só ..."; o rodapé "powered by QGIS [travessão] IMAN Terra é ..." virou "powered by QGIS: IMAN
  Terra é ...".
- Ícones dos cartões: do tema de ícones do QGIS (`mActionFileNew`, `mActionFileOpen`, `mActionDataSourceManager`,
  `mActionNewLayout`) no lugar dos caracteres e do emoji da distro (briefing).
- Selo de versão sem o "●" (sem ícone em texto); a versão é a do produto com o commit do binário.
- Selo do SRC: o nome vem do próprio SRC padrão ("SIRGAS 2000 / UTM zone 24S", do banco do PROJ), não um texto fixo.
- Raio 2px em tudo (D-IMAN-026, sponsor 2026-09-09); a distro tinha cantos maiores nos cartões e no selo.
- "Modelos de projeto": seção nova, abaixo dos recentes, com o modelo da página nativa; o sponsor decide no smoke se
  fica (briefing).
- Recentes: o item mostra o alfinete quando fixado e fica esmaecido quando o arquivo sumiu (o modelo do QGIS já marca);
  a distro escondia o que não existia mais.
- A janela ao redor é a do QGIS com as barras e o painel Camadas (V.3: a página substitui só o widget do índice 1); a
  captura da distro é só o miolo.

**Sobre, igual:** símbolo, nome em `brand`, subtítulo, versão com o commit, Instituto IMAN e o nome completo, o bloco
de créditos do QGIS em `panel-2` com borda, "Licenças de terceiros" com o `THIRD_PARTY_NOTICES.md` renderizado,
"Fechar".

**Sobre, mudou e por quê:**
- Botão "Sobre o QGIS" (com o ícone do Sobre do QGIS), padrão do diálogo, no lugar do "Site do Instituto IMAN": o
  endereço `institutoiman.org.br` não existe (briefing), e o botão é o gatilho que o sponsor pediu.
- "sobre QGIS 3.44.13-Solothurn" virou "motor QGIS 3.44.13" (o `engine_label` da marca, como no PDF e no título).
- Os avisos de terceiros são os do fork (`iman/notices/THIRD_PARTY_NOTICES.md`), não os da distro: outro texto, sem o
  travessão do título da distro.

## T3 Cartões e recentes clicados (medido)

`capturas/home-captures.json`, passos `cartao_*`, `recentes_semeados` e `recente_aberto`; cliques de mouse
sintetizados sobre os widgets da página.

| Clique | Resultado | Evidência |
|---|---|---|
| Novo projeto | a pilha central vai para o mapa (`QgsMapCanvas`); fechar o projeto volta à página | `07a-cartao-novo-projeto.png` |
| Abrir projeto | abre o diálogo "Abrir projeto" do QGIS (filtro `*.qgs *.qgz`); cancelado | `07b-cartao-abrir-projeto.png` (diálogo do Qt nesta rodada: o nativo do Windows não é fotografável por script) |
| Carregar dados | abre o "Gerenciador de Fonte de Dados" (não modal) | `07c-cartao-carregar-dados.png` |
| Novo layout | pede o nome ("Criar Imprimir layout") e, aceito, abre o designer "Layout 1"; o projeto passa a ter 1 layout | `07d-...-nome.png`, `07e-...-designer.png` |
| Recente "Projeto de teste 059 B" | carrega o projeto (título e arquivo batem, 1 camada) e mostra o mapa | `08a-recente-aberto-mapa.png` |
| Fechar o projeto | volta à página inicial (índice 1, `ImanHomePage`) | `08b-recente-fechado-volta-a-pagina.png` |

O menu de contexto foi aberto e fotografado (`02b`); fixar, remover e limpar não foram clicados por script: eles
chamam os slots públicos da `QgsWelcomePage`, que são os do QGIS. Fica para o smoke do sponsor (N/E aqui).

## T4 Sem travessão (medido)

U+2014 e U+2013 contados nos arquivos novos do fonte e dos scripts (`src/app/iman/*`, `Invoke-HomeCaptures.ps1`,
`capture_home.py`), nas linhas acrescentadas do fonte (`qgisapp.cpp`, `CMakeLists.txt`, `Build-Qgis.ps1`,
`PATCHES.md`, `build_brand.py`, `brand.json`), na curadoria e neste README: zero e zero. O `build_brand.py` já recusa
travessão e meia-risca na tradução sobreposta, e passou.

Os únicos U+2014 da pasta deste laudo estão nos `.json` de evidência (`capturas/home-captures.json`,
`capturas/summary.json`, `smoke-build/summary.json`): títulos de janela que o QGIS monta com U+2014
(`src/app/qgisapp.cpp:604`) e texto de terceiros, medidos do programa e mantidos como foram medidos. Nas capturas, o
único travessão é de terceiros: "GDAL version 3.13.2 [travessão] Iowa City", no `QgsAbout` (texto do QGIS).

(Corrigido em 2026-11-13, na fatia 064, pelo patch do arquiteto de 2026-11-12: a versão anterior desta seção dizia
zero nas linhas acrescentadas, e o README tinha 4 U+2014 nas citações.)

## T5 Nada regride (medido)

- `Invoke-Smoke.ps1` no build `27f37b147a` (`smoke-build/summary.json`): 19 checagens OK, inclusive as de marca,
  `marca:splash-texto`, `marca:plugin-reurb` (0.4.0), `controle:sobre` (o recurso do Sobre do QGIS igual ao do
  fonte), `dados-do-produto` e a guarda.
- `Test-Patchset.ps1` (`bateria/patchset.txt`): 18 arquivos, 18 listados, OK.
- `Test-ThemeQss.ps1` (`bateria/tema-qss.txt`): 14 de 14 (o `style.qss` não mudou).
- Guarda do QGIS oficial: OK no smoke e em cada rodada de capturas.

## Achados

1. **`marca:enderecos` do smoke segue OK com a "Página do IMAN Terra" fora do menu.** O smoke acha a ação pelo nome
   (`findChild`) e a dispara; a ação continua existindo (o `removeAction` a tira do menu, não a destrói), com o
   endereço da marca. O teste não contradiz o briefing e não foi tocado, mas passa a medir uma ação que o usuário não
   alcança. Para o briefing de implementação decidir.
2. **`Invoke-BrandCaptures.ps1` (capturas da 044, fora do gate) perde a captura do Sobre.** O passo `step_about` do
   `capture_gui.py` dispara `mActionAbout` e procura um `QgsAbout`; agora abre o `ImanAboutDialog`, e o passo segue
   sem a imagem `05-sobre.png`, sem falhar (o script não foi rodado nesta fatia; leitura do código). Não foi alterado
   (P0.10). Para o briefing de implementação.
3. **"Clear List" sem tradução:** o QGIS 3.44.13 não traduz a frase da `QgsWelcomePage`; a página do produto usa a
   mesma tradução e mostra o mesmo texto em inglês. Correção possível pela curadoria, se o sponsor quiser.
4. **"Reportar um problema" e "Precisa de Suporte Comercial?"** seguem para `institutoiman.org.br`, que não existe
   (fora de escopo, briefing).
5. **Menu de contexto dos modelos de projeto** (apagar modelo, da página nativa) não foi trazido para a página do
   produto no protótipo. Fica para a decisão do sponsor sobre os modelos.

## Bancada

- Disco: D: com 33 GB livres no começo.
- Tempos: build incremental com o configure 289 s + install 372 s; incremental só com o commit 100 s + install 378 s;
  capturas 60 a 75 s por rodada; smoke 30 s.
