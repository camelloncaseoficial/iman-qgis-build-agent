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
- **Imagens** sao os derivados de `iman/brand/derived/`, copiados por `iman/brand/derive_assets.py` sobre os arquivos
  do QGIS de mesmo nome; o smoke confere byte a byte que o recurso compilado e o derivado.

## Arquivos alterados

| Arquivo | Motivo | D-ID | Fatia |
|---|---|---|---|
| `src/core/qgsapplication.cpp` | `installTranslators()` instala a traducao sobreposta `iman_<idioma>.qm` por ultimo (precedencia sobre a `qgis_<idioma>`) e a remove ao reinstalar. Unico ponto que faz os textos de marca chegarem a toda a interface. Desde a 047: as constantes `QGIS_ORGANIZATION_NAME`, `QGIS_ORGANIZATION_DOMAIN` e `QGIS_APPLICATION_NAME` vem do `iman_brand.h` (nome interno `InstitutoIMAN`/`institutoiman.org.br`/`IMANTerra`), entao perfil, cache, crashes, registro e AUMI deixam de ser os do QGIS oficial (`QGIS`/`QGIS3`). | D-IMAN-041 (regra 2), D-IMAN-043 | 044, 047 |
| `src/app/qgisapp.cpp` | O item "Verificar a versao do QGIS" some do menu quando a configuracao global desliga a checagem (`qgis/allowVersionCheck=false`); sem isso o item continua no menu Ajuda mesmo com a checagem desligada. | D-IMAN-039 (regra 4) | 044 |
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
