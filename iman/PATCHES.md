# Patchset do IMAN Terra sobre o QGIS

Todo arquivo do QGIS que este fork altera, a partir da tag `final-3_44_13`, fica listado aqui com o motivo e a
decisao (D-ID). O que e do IMAN e novo vive em `iman/` e nao entra nesta lista; `.claude/`, `.memory/` e
`CLAUDE.md` sao o harness da Crew e tambem nao entram.

Conferencia (tem de listar exatamente os arquivos da tabela):

```
git diff --stat final-3_44_13..HEAD -- . ':!iman' ':!.claude' ':!.memory' ':!CLAUDE.md'
```

A conferencia automatica e `iman/build/Test-Patchset.ps1`, que falha se um arquivo alterado nao estiver na tabela.

## Como a marca chega ao QGIS sem espalhar o nome

- **Textos** vao pela traducao sobreposta `iman_pt_BR.qm` (gerada no build de `iman/brand/i18n/curadoria_pt_BR.json`
  e `iman/brand/brand.json`), que o `QgsApplication` instala depois da do QGIS. O fonte do QGIS nao muda por causa
  de frase, salvo as superficies do Bloco D, que nao passam por tradutor ou tem texto fixo.
- **Nome, nome interno e enderecos no C++** vem do `iman_brand.h`, gerado no build da mesma fonte e gravado na raiz do build (que o
  QGIS ja poe no include path). Nenhum arquivo do QGIS tem o nome do produto escrito.
- **Configuracao** (idioma padrao, feed de noticias, checagem de versao, enderecos do menu Ajuda) vai pelo
  `qgis_global_settings.ini` gerado, que o build copia por cima do instalado. O `resources/qgis_global_settings.ini`
  do QGIS nao muda.
- **Cores** vem da paleta da marca (`palette` no `iman/brand/brand.json`, desde a 064), pelas `IMAN_COLOR_*` do
  `iman_brand.h`. Em controle nativo do QGIS, so pela paleta do Qt (`QPalette`), nunca por folha de estilo (emenda de
  2026-11-13 ao D-IMAN-040).
- **Forma** (desde a 066, so o raio das quinas do `QPushButton`): por um estilo do Qt em C++ (`ImanAppStyle`, que
  herda do `QgsAppStyle`), com o valor do `brand.json` (`button_radius_px`), nunca por folha de estilo.
- **Imagens** sao os derivados de `iman/brand/derived/`, copiados por `iman/brand/derive_assets.py` sobre os arquivos
  do QGIS de mesmo nome; o smoke confere byte a byte que o recurso compilado e o derivado.

## Arquivos alterados

| Arquivo | Motivo | D-ID | Fatia |
|---|---|---|---|
| `src/core/qgsapplication.cpp` | `installTranslators()` instala a traducao sobreposta `iman_<idioma>.qm` por ultimo (precedencia sobre a `qgis_<idioma>`) e a remove ao reinstalar. Unico ponto que faz os textos de marca chegarem a toda a interface. Desde a 047: as constantes `QGIS_ORGANIZATION_NAME`, `QGIS_ORGANIZATION_DOMAIN` e `QGIS_APPLICATION_NAME` vem do `iman_brand.h` (nome interno `InstitutoIMAN`/`institutoiman.org.br`/`IMANTerra`), entao perfil, cache, crashes, registro e AUMI deixam de ser os do QGIS oficial (`QGIS`/`QGIS3`). | D-IMAN-041 (regra 2), D-IMAN-043 | 044, 047 |
| `src/app/qgisapp.cpp` | O item "Verificar a versao do QGIS" some do menu quando a configuracao global desliga a checagem (`qgis/allowVersionCheck=false`); sem isso o item continua no menu Ajuda mesmo com a checagem desligada. Desde a 058: a cor do texto de carregamento do splash vem do `iman_brand.h` (`IMAN_SPLASH_TEXT_COLOR`, de `splash_text_color` no `brand.json`, hoje `#FFFFFF`) no lugar do `Qt::black`; o rodape do splash do produto e verde muito escuro, e o preto nao se lia (smoke do sponsor de 2026-11-11). Desde a 059 (prototipo): o indice 1 do `mCentralContainer` passa a ser a `ImanHomePage` (a `QgsWelcomePage` segue criada, fora da tela, dona do modelo de recentes); `about()` abre o `ImanAboutDialog`, e o `QgsAbout`, sem mudanca, abre pelo botao "Sobre o QGIS" dele; a "Pagina do IMAN Terra" (`mActionQgisHomePage`) sai do menu Ajuda por `removeAction` (a acao segue existindo, fora da interface). | D-IMAN-039 (regra 4), D-IMAN-040 (emendas de 2026-11-11) | 044, 058, 059 |
| `src/core/layout/qgslayoutexporter.cpp` | `getCreator()` (Creator e Producer de PDF e imagens de layout) passa a `<produto> (motor QGIS <versao>)`, com o nome do `iman_brand.h`. O texto e fixo no C++ (`QStringLiteral`), a sobreposicao nao alcanca. | D-IMAN-041 (regra 3) | 044 |
| `src/crashhandler/main.cpp` | O crash handler instala a traducao do QGIS e a sobreposta da marca no idioma padrao do produto (`IMAN_DEFAULT_LOCALE`); sem isso ele so fala ingles e diz QGIS. Com elas, o texto, o "Reabrir" e o link de relato vem da curadoria. Desde a 047: organizacao e aplicacao do crash handler vem do nome interno do `iman_brand.h`, e a pasta dos crashes passa a ser a do produto. | D-IMAN-041 (regra 3), D-IMAN-043 | 044, 047 |
| `src/crashhandler/qgscrashreport.cpp` | O "Crash ID" do relatorio fica como texto, sem o link para a busca de issues no GitHub do QGIS. O resto do relatorio tecnico e gerado igual. | D-IMAN-041 (regra 3) | 044 |
| `src/app/mainwin.cpp` | Caixa de erro de carga do `qgis.exe` (antes do Qt, sem tradutor): titulo e mensagens em pt_BR com o nome do `iman_brand.h`. Frases sem acento porque `MessageBoxA` mostra os bytes no codepage ANSI. | D-IMAN-041 (regra 3) | 044 |
| `src/app/qgis.ico` | Icone do executavel (`IDI_ICON1` em `qgis_win32.rc`, tambem o do crash handler e o `icons/qgis.ico` instalado): copia de `iman/brand/derived/qgis.ico`, que e o `icon-iman-terra.ico` aprovado. | D-IMAN-039 (regra 2), D-IMAN-041 (regra 6) | 044 |
| `images/icons/qgis_icon.svg` | Simbolo do produto no lugar do logo do QGIS (Navegador para `.qgs`/`.qgz`, crash handler, perfis, primeira execucao, painel de documentacao, notificacoes): copia de `iman/brand/derived/qgis_icon.svg`. | D-IMAN-039 (regra 2), D-IMAN-041 (regra 6) | 044 |
| `images/icons/qgis-icon-16x16.png` | Idem, 16x16 (Propriedades da camada, `.qlr` no Navegador): copia de `iman/brand/derived/qgis-icon-16x16.png`. | D-IMAN-039 (regra 2), D-IMAN-041 (regra 6) | 044 |
| `images/icons/qgis-icon-60x60.png` | Idem, 60x60 (icone da janela e dos dialogos, lido do disco por `appIconPath()`, e dos widgets do Designer): copia de `iman/brand/derived/qgis-icon-60x60.png`. | D-IMAN-039 (regra 2), D-IMAN-041 (regra 6) | 044 |
| `images/splash/splash.png` | Splash aprovado no lugar do splash do QGIS: copia de `iman/brand/derived/splash.png` (`splash-iman-terra.png`). | D-IMAN-041 (regra 6) | 044 |
| `images/themes/default/providerQgis.svg` | Simbolo do produto nos provedores e grupos da caixa de Processamento e em Opcoes > Processamento > Provedores: copia de `iman/brand/derived/providerQgis.svg`. | D-IMAN-039 (regra 2), D-IMAN-041 (regra 6) | 044 |
| `src/process/main.cpp` | O `qgis_process` usa o nome interno do produto (as constantes do `QgsApplication`, que vem do `iman_brand.h`) no lugar dos literais `QGIS`/`qgis.org`/`QGIS3`: le os perfis da pasta do produto, nunca a do QGIS oficial. | D-IMAN-043 | 047 |
| `src/app/CMakeLists.txt` | Compila os arquivos do IMAN em `src/app/iman/` no `qgis_app`: a pagina inicial e o Sobre (059), desde a 064 o destaque pela paleta (`imanpalette.cpp`) e, desde a 066, o estilo com o raio dos botoes (`imanappstyle.cpp`). | D-IMAN-040 (emenda de 2026-11-11, itens 3 a 5; emendas de 2026-11-13) | 059, 064, 066 |
| `src/app/iman/imanhomepage.h` | Arquivo novo do IMAN: pagina inicial do produto (cabecalho, selos de versao e de SRC, quatro cartoes com as acoes do QGIS, projetos recentes do modelo da `QgsWelcomePage` com o menu de contexto dela, modelos de projeto, creditos do QGIS). Desenho da distro congelada (`dashboard.py`, `59ac0ce`); cores da paleta do tema pelo `iman_brand.h`; textos pela traducao sobreposta. | D-IMAN-040 (emenda de 2026-10-29, item 3; emenda de 2026-11-11), D-IMAN-025, D-IMAN-026 | 059 |
| `src/app/iman/imanhomepage.cpp` | Idem. | D-IMAN-040 (emenda de 2026-10-29, item 3; emenda de 2026-11-11), D-IMAN-025, D-IMAN-026 | 059 |
| `src/app/iman/imanaboutdialog.h` | Arquivo novo do IMAN: "Sobre o IMAN Terra" (simbolo, nome, versao e commit, motor QGIS, Instituto, creditos do QGIS, `THIRD_PARTY_NOTICES.md` da instalacao) com o botao "Sobre o QGIS" para o `QgsAbout`. Desenho da distro congelada (`sobre.py`, `59ac0ce`), sem o botao do site. | D-IMAN-040 (emenda de 2026-11-11, itens 4 e 5), D-IMAN-039, D-IMAN-025 | 059 |
| `src/app/iman/imanaboutdialog.cpp` | Idem. | D-IMAN-040 (emenda de 2026-11-11, itens 4 e 5), D-IMAN-039, D-IMAN-025 | 059 |
| `src/app/main.cpp` | Uma chamada ao `ImanPalette::apply( theme )` (ate a 064, `applyHighlight`) logo depois do `QApplication::setStyle` do arranque (que repoe a paleta do estilo), com o include. Sem tema escolhido (o `default` do QGIS), o destaque (`Highlight` e `HighlightedText`, grupos `Active` e `Inactive`) vai para as cores `brand-2` e `panel` da paleta da marca (064), o fundo das janelas (`Window`, grupos `Active`, `Inactive` e `Disabled`) para o `bg` (065) e os botoes e abas (`Button`, nos mesmos tres grupos) para o `panel-2` (066), pela paleta do Qt; com tema de fabrica escolhido pelo usuario, nada muda. Nenhuma folha de estilo. Desde a 066, os dois `new QgsAppStyle( ... )` do arranque viram `new ImanAppStyle( ..., theme )` (com o include): o mesmo proxy do QGIS, com o raio da marca so no `QPushButton` e so com o tema `default` e o estilo fusion. | D-IMAN-040 (emendas de 2026-11-13), D-IMAN-026 | 064, 065, 066 |
| `src/app/iman/imanpalette.h` | Arquivo novo do IMAN: `ImanPalette` (`isDefaultTheme`, com a mesma regra do `QgsApplication::setUITheme`, e `apply`, que muda os papeis da marca num unico `setPalette`: `Highlight` e `HighlightedText` desde a 064, `Window` desde a 065, `Button` desde a 066; ate a 064 se chamava `applyHighlight`), exportada do `qgis_app` (`APP_EXPORT`) para o `main.cpp`. Cores so das `IMAN_COLOR_*` do `iman_brand.h`, sem hex no C++. | D-IMAN-040 (emendas de 2026-11-13), D-IMAN-026, D-IMAN-025 | 064, 065, 066 |
| `src/app/iman/imanpalette.cpp` | Idem. | D-IMAN-040 (emendas de 2026-11-13), D-IMAN-026, D-IMAN-025 | 064, 065, 066 |
| `src/app/iman/imanappstyle.h` | Arquivo novo do IMAN: `ImanAppStyle`, que herda do `QgsAppStyle` (sem mudar o `qgsproxystyle.*` do QGIS) e so redesenha o painel do botao (`PE_PanelButtonCommand`) quando o widget e um `QPushButton`: o desenho do Fusion com o raio `IMAN_BUTTON_RADIUS_PX` do `iman_brand.h` (o dobro do raio 2 do Fusion, laudo 066) no lugar do 2. Botao de ferramenta, botao de cor e todo outro widget seguem com o Fusion. So com o tema `default` e a base fusion; `clone()` proprio; o `objectName` segue `QgsAppStyle` (o `QgsProxyStyle` o procura). Nenhuma folha de estilo. | D-IMAN-040 (emendas de 2026-11-13, adendo da terceira mudanca), D-IMAN-025 | 066 |
| `src/app/iman/imanappstyle.cpp` | Idem. | D-IMAN-040 (emendas de 2026-11-13, adendo da terceira mudanca), D-IMAN-025 | 066 |
