# Código-fonte do IMAN Terra

Quem recebeu o IMAN Terra do Instituto IMAN tem direito ao código-fonte correspondente dos componentes sob licença
copyleft (GPL, LGPL e AGPL), a começar pelo próprio QGIS. Este arquivo diz onde ele está.

## 1. Este pacote

| | |
|---|---|
| Produto | IMAN Terra @IMAN_PRODUCT_VERSION@ |
| Commit do fork | `@IMAN_COMMIT@` |
| QGIS | 3.44.13, recompilado e modificado pelo Instituto IMAN |

O commit também está em `iman\BUILD_INFO.txt`, na pasta de instalação, e no nome do instalador. Ao pedir o
fonte, informe a versão e o commit.

## 2. O QGIS e os componentes do Instituto IMAN

O QGIS do IMAN Terra **não é** o binário da QGIS.ORG: ele foi **recompilado e modificado** pelo Instituto IMAN. O
código-fonte correspondente é o do fork público:

- **Repositório:** https://github.com/camelloncaseoficial/iman-qgis-build-agent
- **Base:** a tag **`final-3_44_13`** do QGIS (https://github.com/qgis/QGIS/tree/final-3_44_13)
- **Commit deste pacote:** `@IMAN_COMMIT@`
  (https://github.com/camelloncaseoficial/iman-qgis-build-agent/tree/@IMAN_COMMIT@)

No fork:

- `iman/PATCHES.md` lista todo arquivo do QGIS modificado, com o motivo; `git diff final-3_44_13..@IMAN_COMMIT@`
  mostra as modificações inteiras;
- `iman/build/` são os scripts que compilam o QGIS (`Invoke-ImanBuild.ps1`), com as versões das dependências
  fixadas em `iman/build/osgeo4w.lock.tsv`;
- `iman/installer/` é o instalador e o lançador; `iman/brand/` é a fonte de marca.

## 3. Os pacotes OSGeo4W

Os demais componentes são os pacotes OSGeo4W do QGIS 3.44.13 oficial, na mesma versão (`THIRD_PARTY_NOTICES.md`,
seção 3). Cada um foi baixado de https://download.osgeo.org/osgeo4w/v2 e conferido pelo SHA-256 registrado em
`iman/build/osgeo4w.lock.tsv` do fork.

O pacote `<nome>-<versão>-src.tar.bz2` que o OSGeo4W publica ao lado de cada pacote é a **receita** de build, não o
código-fonte: o fonte correspondente é o tarball do upstream que essa receita baixa e compila. A URL do upstream de
cada pacote está em `THIRD_PARTY_NOTICES.md` e em `iman/notices/licencas-upstream.tsv` do fork.

## 4. Como pedir

Escreva ao Instituto IMAN (https://institutoiman.org.br) informando a versão e o commit acima e de quais componentes
deseja o fonte. O Instituto IMAN fornece o código-fonte correspondente por download ou em mídia física, sem custo
além do custo de distribuição, pelo prazo que a licença de cada componente exige.
