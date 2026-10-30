# Avisos de terceiros do IMAN Terra (powered by QGIS)

> **O IMAN Terra é uma experiência geoespacial desktop independente, powered by QGIS.**
> **O QGIS é um sistema de informação geográfica livre e de código aberto, desenvolvido por QGIS.ORG e
> contribuidores (https://qgis.org).**
> **Este projeto NÃO é um produto oficial do QGIS e NÃO é endossado pela QGIS.ORG.**

## 1. O que o IMAN Terra distribui

O instalador do IMAN Terra carrega uma árvore completa de programas: o QGIS 3.44.13 **compilado pelo Instituto IMAN
a partir de um fork público do código-fonte do QGIS, com modificações** (seção 2), e o conjunto de pacotes OSGeo4W
que o QGIS 3.44.13 oficial instala no Windows, na mesma versão de cada pacote (seção 3), mais dois arquivos das
Debugging Tools for Windows da Microsoft (seção 5). O Instituto IMAN é **redistribuidor** desses componentes: eles
não são obra do Instituto IMAN, pertencem aos seus autores e permanecem sob as suas próprias licenças.

**O driver ECW/JP2 não é distribuído.** O QGIS 3.44.13 oficial instala também o pacote `gdal-ecw` (o driver ECW/JP2
do GDAL, com o SDK ECW/JP2 da Hexagon). O IMAN Terra não o distribui, por causa do termo da Hexagon ("ERDAS ECW/JP2
Server Read-Only End-user SDK License Agreement", v5.5), cuja seção 2.2 não permite distribuir aplicação desktop com o
SDK. Sem ele, o IMAN Terra não abre arquivos ECW; o JPEG 2000 segue pelo driver JP2OpenJPEG do GDAL.

<!-- gerado: resumo (iman/notices/Update-Notices.ps1) -->
| | |
|---|---|
| Entradas do inventário (seção 3) | **153**: 152 pacotes OSGeo4W e o QGIS compilado pelo Instituto IMAN |
| Pacotes com arquivo de licença dentro do próprio pacote | 68 |
| Pacotes cuja licença vem do upstream (URL na tabela) | 85 |
<!-- gerado: fim -->

## 2. QGIS, recompilado e modificado

- **Projeto:** QGIS, A Free and Open Source Geographic Information System, de QGIS.ORG e contribuidores
  (https://qgis.org, código em https://github.com/qgis/QGIS).
- **Licença:** GNU General Public License, versão 2 ou posterior (**GPL-2.0-or-later**). O texto está em
  `apps\qgis-ltr\doc\LICENSE`, e os créditos do QGIS (`AUTHORS`, `CONTRIBUTORS`, `SPONSORS`, `DONORS`,
  `TRANSLATORS`) ficam na mesma pasta e no "Sobre o QGIS" do programa, intactos.
- **O que o Instituto IMAN fez:** o QGIS do IMAN Terra **não é** o binário publicado pela QGIS.ORG. Ele foi
  **recompilado** pelo Instituto IMAN a partir do fork público
  https://github.com/camelloncaseoficial/iman-qgis-build-agent, ramo `develop`, que nasce da tag
  **`final-3_44_13`** do QGIS, e foi **modificado**: o nome e a marca do produto, ícones, a pasta de configuração
  do usuário e alguns textos. O comportamento do QGIS (provedores, algoritmos, formato de projeto) é o do
  original.
- **Commit exato:** cada instalador registra o commit do fork de que saiu, em `iman\BUILD_INFO.txt` e em
  `SOURCE_CODE.md`, instalados junto, e no nome do próprio instalador.
- **Arquivos do QGIS modificados** (o motivo de cada um está em `iman/PATCHES.md` no fork):

<!-- gerado: patchset (iman/notices/Update-Notices.ps1) -->
- `src/core/qgsapplication.cpp` (D-IMAN-041 (regra 2), D-IMAN-043; fatia 044, 047)
- `src/app/qgisapp.cpp` (D-IMAN-039 (regra 4); fatia 044)
- `src/core/layout/qgslayoutexporter.cpp` (D-IMAN-041 (regra 3); fatia 044)
- `src/crashhandler/main.cpp` (D-IMAN-041 (regra 3), D-IMAN-043; fatia 044, 047)
- `src/crashhandler/qgscrashreport.cpp` (D-IMAN-041 (regra 3); fatia 044)
- `src/app/mainwin.cpp` (D-IMAN-041 (regra 3); fatia 044)
- `src/app/qgis.ico` (D-IMAN-039 (regra 2), D-IMAN-041 (regra 6); fatia 044)
- `images/icons/qgis_icon.svg` (D-IMAN-039 (regra 2), D-IMAN-041 (regra 6); fatia 044)
- `images/icons/qgis-icon-16x16.png` (D-IMAN-039 (regra 2), D-IMAN-041 (regra 6); fatia 044)
- `images/icons/qgis-icon-60x60.png` (D-IMAN-039 (regra 2), D-IMAN-041 (regra 6); fatia 044)
- `images/splash/splash.png` (D-IMAN-041 (regra 6); fatia 044)
- `images/themes/default/providerQgis.svg` (D-IMAN-039 (regra 2), D-IMAN-041 (regra 6); fatia 044)
- `src/process/main.cpp` (D-IMAN-043; fatia 047)
<!-- gerado: fim -->

O que é novo e do Instituto IMAN (scripts de build, instalador, lançador, marca) vive na pasta `iman/` do fork
(seção 6).

## 3. Inventário: uma entrada por pacote da árvore instalada

Uma linha por pacote do manifesto da instalação (`etc\setup\installed.db`). A coluna "Fonte da licença" diz de
onde a licença foi lida: o arquivo de licença que vem **dentro do próprio pacote** (caminho relativo à pasta de
instalação) ou, quando o pacote não traz arquivo de licença, a **URL do upstream** de onde ela foi obtida. A licença
nunca foi deduzida pelo nome do componente. Os textos completos dos termos proprietários estão na pasta
`licencas\` da instalação (seção 5).

<!-- gerado: inventario (iman/notices/Update-Notices.ps1) -->
| # | Pacote | Versão | Licença | Fonte da licença |
|---:|---|---|---|---|
| 1 | `iman-terra` | 0.4.0 (QGIS 3.44.13 recompilado e modificado, seção 2) | GPL-2.0-or-later | arquivo no pacote: `apps/qgis-ltr/doc/LICENSE` |
| 2 | `arrow-cpp` | 25.0.0-1 | Apache-2.0 | upstream: https://github.com/apache/arrow |
| 3 | `avce00` | 2.0.0-5 | MIT | upstream: http://avce00.maptools.org/dl/avce00-2.0.0.tar.gz |
| 4 | `base` | 1.0.0-23 | MIT (utilitarios C de src/base: textreplace, bgspawn, getspecialfolder e outros); o xxmklink.exe e binario de terceiro sem licenca declarada no repositorio | upstream: https://github.com/jef-n/OSGeo4W/tree/master/src/base |
| 5 | `brotli` | 1.2.0-1 | MIT | upstream: https://github.com/google/brotli |
| 6 | `c-blosc` | 1.21.6-4 | BSD License (texto proprio do Blosc) | upstream: https://github.com/Blosc/c-blosc/blob/main/LICENSE.txt |
| 7 | `cairo` | 1.18.4-1 | Dupla: LGPL-2.1 OU MPL-1.1 (a escolha do destinatario) | upstream: https://www.cairographics.org/ |
| 8 | `curl` | 8.21.0-1 | curl License (tipo MIT/X) | upstream: https://github.com/curl/curl/blob/master/COPYING |
| 9 | `curl-ca-bundle` | 8.21.0-1 | MPL-2.0 (conjunto de CAs da Mozilla, extraido pelo curl) | upstream: https://curl.se/docs/caextract.html |
| 10 | `exiv2` | 0.28.8-1 | GPL-2.0-or-later (texto proprio no arquivo COPYING) | upstream: https://github.com/exiv2/exiv2/blob/main/COPYING |
| 11 | `expat` | 2.8.2-1 | MIT | upstream: https://github.com/libexpat/libexpat |
| 12 | `freetype` | 2.13.3-4 | MULTIPLA: FreeType License (BSD-style com credito) OU GPL-2.0 | upstream: https://gitlab.freedesktop.org/freetype/freetype/-/blob/master/LICENSE.TXT |
| 13 | `freexl` | 2.0.0-4 | Tri-licenca MPL-1.1 OU GPL-2.0-or-later OU LGPL-2.1-or-later (a escolha do destinatario) | upstream: https://www.gaia-gis.it/fossil/freexl/index |
| 14 | `gdal` | 3.13.2-1 | MIT (nucleo) + BSD-2/BSD-3 e outras em partes | arquivo no pacote: `apps/gdal/share/gdal/LICENSE.TXT` |
| 15 | `gdal-hdf5` | 3.13.2-1 | MIT (plugin GDAL) - liga em HDF5 (BSD-3 com termos proprios) | upstream: https://gdal.org/en/stable/license.html |
| 16 | `gdal-mrsid` | 3.13.2-1 | PROPRIETARIA: Software License Agreement for MrSID Decode SDKs (Extensis); o plugin GDAL e MIT. Redistribuicao permitida com condicoes (secao 1.3). Ver drivers de licenca condicionada | upstream: https://download.osgeo.org/osgeo4w/v2/x86_64/release/gdal/gdal-dev/gdal-dev-mrsid/gdal-dev-mrsid-3.14.0-1183-940f719842-1.txt |
| 17 | `gdal-mss` | 3.13.2-1 | MIT (plugin GDAL) - INUTIL sem o msodbcsql proprietario | upstream: https://gdal.org/en/stable/drivers/vector/mssqlspatial.html |
| 18 | `gdal-oracle` | 3.13.2-1 | PROPRIETARIA na dependencia - plugins GDAL sob MIT ligam em OCI.dll (Oracle Instant Client) | upstream: https://www.oracle.com/database/technologies/instant-client.html |
| 19 | `gdal-sosi` | 3.13.2-1 | MIT (plugin GDAL) | upstream: https://gdal.org/en/stable/license.html |
| 20 | `gdal313-runtime` | 3.13.2-1 | MIT (nucleo) + BSD-2/BSD-3 e outras em partes | upstream: https://gdal.org/en/stable/license.html |
| 21 | `geos` | 3.14.1-1 | LGPL-2.1 | upstream: https://github.com/libgeos/geos/blob/main/COPYING |
| 22 | `gpsbabel` | 1.9.0-4 | GPL-2.0 | upstream: https://github.com/gpsbabel/gpsbabel |
| 23 | `grass` | 8.5.0-1 | GPL-2.0-or-later | arquivo no pacote: `apps/grass/grass85/COPYING`, `apps/grass/grass85/bin/COPYING` e mais 2 |
| 24 | `grass8` | 99-1 | GPL-2.0-or-later | upstream: https://grass.osgeo.org/about/license/ |
| 25 | `gs` | 10.07.1-1 | AGPL (GPL Ghostscript - fontes/CMap sob AGPL com excecao) | upstream: https://github.com/ArtifexSoftware/ghostpdl/blob/master/LICENSE |
| 26 | `gsl` | 2.7.101-1 | GPL-3.0 | upstream: https://www.gnu.org/software/gsl/ |
| 27 | `hdf4` | 4.3.1-1 | Termos proprios do HDF Group (BSD-style) | upstream: https://github.com/HDFGroup/hdf4/blob/master/COPYING |
| 28 | `hdf5` | 1.14.6-1 | BSD-3-Clause com termos proprios do HDF Group | upstream: https://github.com/HDFGroup/hdf5/blob/develop/COPYING |
| 29 | `icu` | 67.1-6 | Unicode License v3 | upstream: https://github.com/unicode-org/icu/blob/main/LICENSE |
| 30 | `laszip` | 3.4.3-4 | Apache-2.0 | upstream: https://github.com/LASzip/LASzip |
| 31 | `lerc` | 4.0.0-1 | Apache-2.0 | upstream: https://github.com/Esri/lerc |
| 32 | `libaec` | 1.1.6-1 | BSD-2-Clause | upstream: https://github.com/MathisRosenhauer/libaec |
| 33 | `libarchive` | 3.8.7-2 | BSD-2-Clause (a distribuicao como um todo - arquivos com notas proprias) | upstream: https://github.com/libarchive/libarchive/blob/master/COPYING |
| 34 | `libgeotiff` | 1.7.4-1 | MIT/X-style (texto proprio, Niles Ritter / SoftwareBistro) | upstream: https://github.com/OSGeo/libgeotiff/blob/master/libgeotiff/LICENSE |
| 35 | `libharu` | 2.4.4-1 | Zlib License | upstream: https://github.com/libharu/libharu |
| 36 | `libiconv` | 1.17-1 | LGPL (biblioteca) / GPL (utilitarios) - projeto GNU | upstream: https://www.gnu.org/software/libiconv/ |
| 37 | `libjpeg-turbo` | 3.0.4-1 | MULTIPLA: IJG License + BSD-3-Clause (zlib para partes) | upstream: https://github.com/libjpeg-turbo/libjpeg-turbo/blob/main/LICENSE.md |
| 38 | `libjxl` | 0.11.2-1 | BSD-3-Clause | upstream: https://github.com/libjxl/libjxl |
| 39 | `liblas` | 1.8.1-24 | BSD-3-Clause | arquivo no pacote: `doc/COPYING`, `doc/LICENSE.txt` |
| 40 | `libmysql` | 8.2.0-2 | GPL-2.0 com FOSS License Exception, OU licenca comercial (Oracle/MySQL) | upstream: https://dev.mysql.com/doc/refman/8.0/en/license-info.html |
| 41 | `libpng` | 1.6.57-2 | PNG Reference Library License (libpng license) | upstream: http://www.libpng.org/pub/png/src/libpng-LICENSE.txt |
| 42 | `libpq` | 18.4-1 | PostgreSQL License (tipo BSD/MIT) | upstream: https://www.postgresql.org/about/licence/ |
| 43 | `librttopo` | 1.1.0-18 | GPL-2.0 | upstream: https://git.osgeo.org/gitea/rttopo/librttopo |
| 44 | `libspatialindex` | 1.9.3-3 | MIT (desde a 1.8.0 - era LGPL antes) | upstream: https://github.com/libspatialindex/libspatialindex/blob/master/LICENSE.txt |
| 45 | `libspatialite` | 5.1.0-9 | Tri-licenca MPL-1.1 OU GPL-2.0-or-later OU LGPL-2.1-or-later (a escolha do destinatario) | upstream: https://www.gaia-gis.it/fossil/libspatialite/index |
| 46 | `libtiff` | 4.7.2rc4-1 | libtiff License (tipo MIT/BSD, Sam Leffler / SGI) | upstream: https://gitlab.com/libtiff/libtiff/-/blob/master/LICENSE.md |
| 47 | `libwebp` | 1.6.0-1 | BSD-3-Clause | upstream: https://github.com/webmproject/libwebp |
| 48 | `libxml2` | 2.12.10-1 | MIT | upstream: https://gitlab.gnome.org/GNOME/libxml2/-/blob/master/Copyright |
| 49 | `libxslt` | 1.1.39-1 | MIT (libxslt) - libexslt com nota propria | upstream: https://gitlab.gnome.org/GNOME/libxslt/-/blob/master/Copyright |
| 50 | `libzip` | 1.10.2really1.7.3-1 | BSD-3-Clause | upstream: https://github.com/nih-at/libzip/blob/main/LICENSE |
| 51 | `lz4` | 1.10.0-1 | BSD-2-Clause (lib/) + GPL-2.0-or-later (demais arquivos) | upstream: https://github.com/lz4/lz4/blob/dev/LICENSE |
| 52 | `msodbcsql` | 18.0-2 | PROPRIETARIA: Microsoft Software License Terms, Microsoft ODBC Driver 18 for SQL Server. So o codigo da lista REDIST e distribuivel (secao 2). Ver drivers de licenca condicionada | upstream: https://download.osgeo.org/osgeo4w/v2/x86_64/release/msodbcsql/msodbcsql-devel/msodbcsql-devel-18.0-2.txt |
| 53 | `msvcrt2019` | 14.2-2 | PROPRIETARIA - Microsoft Visual C++ Redistributable (termos de redistribuicao da Microsoft) | upstream: https://learn.microsoft.com/cpp/windows/redistributing-visual-cpp-files |
| 54 | `netcdf` | 4.10.1-1 | BSD-3-Clause | upstream: https://github.com/Unidata/netcdf-c |
| 55 | `oci` | 21.13-1 | PROPRIETARIA: Oracle Free Use Terms and Conditions (Oracle Instant Client 21.13). Redistribuicao permitida sem modificacao, sem cobranca e com copia da licenca. Ver drivers de licenca condicionada | upstream: https://download.osgeo.org/osgeo4w/v2/x86_64/release/oci/oci-devel/oci-devel-21.13-1.txt |
| 56 | `ogdi` | 4.1.1-2 | MULTIPLA (duas licencas tipo MIT/BSD conforme o arquivo LICENSE) | upstream: https://github.com/libogdi/ogdi/blob/master/LICENSE |
| 57 | `opencl` | 2023.12.14-1 | Apache-2.0 | upstream: https://github.com/KhronosGroup/OpenCL-SDK |
| 58 | `openjpeg` | 2.5.4-4 | BSD-2-Clause | upstream: https://github.com/uclouvain/openjpeg/blob/master/LICENSE |
| 59 | `openssl` | 3.0.21-1 | Apache-2.0 | upstream: https://github.com/openssl/openssl |
| 60 | `pdal` | 2.10.0-4 | BSD-3-Clause (texto proprio, Hobu Inc.) | upstream: https://github.com/PDAL/PDAL/blob/master/LICENSE.txt |
| 61 | `pdal-libs` | 2.10.0-4 | BSD-3-Clause (texto proprio, Hobu Inc.) | upstream: https://github.com/PDAL/PDAL/blob/master/LICENSE.txt |
| 62 | `poppler` | 26.06.0-1 | GPL-2.0 | upstream: https://gitlab.freedesktop.org/poppler/poppler/-/blob/master/COPYING |
| 63 | `proj` | 9.8.1-1 | MIT | upstream: https://proj.org/en/stable/about.html |
| 64 | `proj-runtime-data` | 9.8.1-1 | MIT (o pacote traz o proj.db e os arquivos de inicializacao do PROJ, sem grades de datum) | upstream: https://github.com/OSGeo/PROJ/blob/master/COPYING |
| 65 | `proj9-runtime` | 9.8.1-1 | MIT | upstream: https://proj.org/en/stable/about.html |
| 66 | `python3-annotated-types` | 0.7.0-1 | OSI Approved :: MIT License | arquivo no pacote: `apps/Python312/Lib/site-packages/annotated_types-0.7.0.dist-info/licenses/LICENSE` |
| 67 | `python3-certifi` | 2026.6.17-1 | MPL-2.0 | arquivo no pacote: `apps/Python312/Lib/site-packages/certifi-2026.6.17.dist-info/licenses/LICENSE` |
| 68 | `python3-charset-normalizer` | 3.4.9-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/charset_normalizer-3.4.9.dist-info/licenses/LICENSE` |
| 69 | `python3-contourpy` | 1.3.3-1 | BSD 3-Clause License | arquivo no pacote: `apps/Python312/Lib/site-packages/contourpy-1.3.3.dist-info/LICENSE` |
| 70 | `python3-core` | 3.12.13-5 | PSF License | arquivo no pacote: `apps/Python312/LICENSE.txt` |
| 71 | `python3-cycler` | 0.12.1-1 | Copyright (c) 2015, matplotlib project | arquivo no pacote: `apps/Python312/Lib/site-packages/cycler-0.12.1.dist-info/LICENSE` |
| 72 | `python3-duckdb` | 1.5.4-1 | OSI Approved :: MIT License | arquivo no pacote: `apps/Python312/Lib/site-packages/duckdb-1.5.4.dist-info/licenses/LICENSE`, `apps/Python312/Lib/site-packages/duckdb/experimental/spark/LICENSE` |
| 73 | `python3-et-xmlfile` | 2.0.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/et_xmlfile-2.0.0.dist-info/LICENCE.python`, `apps/Python312/Lib/site-packages/et_xmlfile-2.0.0.dist-info/LICENCE.rst` |
| 74 | `python3-exifread` | 3.5.1-1 | BSD-3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/exifread-3.5.1.dist-info/licenses/LICENSE` |
| 75 | `python3-fonttools` | 4.63.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/fonttools-4.63.0.dist-info/licenses/LICENSE`, `apps/Python312/Lib/site-packages/fonttools-4.63.0.dist-info/licenses/LICENSE.external` |
| 76 | `python3-future` | 1.0.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/future-1.0.0.dist-info/LICENSE.txt` |
| 77 | `python3-gdal` | 3.13.2-1 | MIT (nucleo) + BSD-2/BSD-3 e outras em partes | upstream: https://gdal.org/en/stable/license.html |
| 78 | `python3-geographiclib` | 2.1-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/geographiclib-2.1.dist-info/licenses/LICENSE` |
| 79 | `python3-geopandas` | 1.1.4-1 | BSD-3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/geopandas-1.1.4.dist-info/licenses/LICENSE.txt` |
| 80 | `python3-httplib2` | 0.32.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/httplib2-0.32.0.dist-info/licenses/LICENSE` |
| 81 | `python3-idna` | 3.18-1 | BSD-3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/idna-3.18.dist-info/licenses/LICENSE.md` |
| 82 | `python3-jinja2` | 3.1.6-1 | OSI Approved :: BSD License | arquivo no pacote: `apps/Python312/Lib/site-packages/jinja2-3.1.6.dist-info/licenses/LICENSE.txt` |
| 83 | `python3-kiwisolver` | 1.5.0-1 | ========================= | arquivo no pacote: `apps/Python312/Lib/site-packages/kiwisolver-1.5.0.dist-info/licenses/LICENSE` |
| 84 | `python3-lxml` | 6.1.1-1 | BSD-3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/lxml-6.1.1.dist-info/licenses/LICENSE.txt`, `apps/Python312/Lib/site-packages/lxml-6.1.1.dist-info/licenses/LICENSES.txt` |
| 85 | `python3-markupsafe` | 3.0.3-1 | BSD-3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/markupsafe-3.0.3.dist-info/licenses/LICENSE.txt` |
| 86 | `python3-matplotlib` | 3.11.0-1 | License agreement for matplotlib versions 1.3.0 and later | arquivo no pacote: `apps/Python312/Lib/site-packages/matplotlib-3.11.0.dist-info/LICENSE`, `apps/Python312/Lib/site-packages/matplotlib/mpl-data/fonts/ttf/LICENSE_DEJAVU` e mais 1 |
| 87 | `python3-mock` | 5.2.0-1 | OSI Approved :: BSD License | arquivo no pacote: `apps/Python312/Lib/site-packages/mock-5.2.0.dist-info/LICENSE.txt` |
| 88 | `python3-narwhals` | 2.23.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/narwhals-2.23.0.dist-info/licenses/LICENSE.md` |
| 89 | `python3-networkx` | 3.6.1-1 | BSD-3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/networkx-3.6.1.dist-info/licenses/LICENSE.txt` |
| 90 | `python3-nose2` | 0.16.0-1 | BSD-2-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/nose2-0.16.0.dist-info/licenses/LICENSE` |
| 91 | `python3-numpy` | 2.4.6-1 | BSD-3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/numpy-2.4.6.dist-info/licenses/LICENSE.txt`, `apps/Python312/Lib/site-packages/numpy/ma/LICENSE` e mais 17 |
| 92 | `python3-openpyxl` | 3.1.5-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/openpyxl-3.1.5.dist-info/LICENCE.rst` |
| 93 | `python3-owslib` | 0.36.0-1 | BSD-3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/owslib-0.36.0.dist-info/LICENSE` |
| 94 | `python3-packaging` | 26.2-1 | Apache-2.0 | arquivo no pacote: `apps/Python312/Lib/site-packages/packaging-26.2.dist-info/licenses/LICENSE`, `apps/Python312/Lib/site-packages/packaging-26.2.dist-info/licenses/LICENSE.APACHE` e mais 1 |
| 95 | `python3-pandas` | 3.0.3-1 | BSD 3-Clause License | arquivo no pacote: `apps/Python312/Lib/site-packages/pandas-3.0.3.dist-info/LICENSE` |
| 96 | `python3-pillow` | 12.3.0-1 | MIT-CMU (licenca historica da PIL, texto proprio) | arquivo no pacote: `apps/Python312/Lib/site-packages/pillow-12.3.0.dist-info/licenses/LICENSE` |
| 97 | `python3-pip` | 26.1.2-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/pip-26.1.2.dist-info/licenses/LICENSE.txt`, `apps/Python312/Lib/site-packages/pip/_vendor/cachecontrol/LICENSE.txt` e mais 39 |
| 98 | `python3-plotly` | 6.9.0-1 | OSI Approved :: MIT License | arquivo no pacote: `apps/Python312/Lib/site-packages/plotly-6.9.0.dist-info/licenses/LICENSE.txt` |
| 99 | `python3-ply` | 3.11-2 | BSD | upstream: http://www.dabeaz.com/ply/ |
| 100 | `python3-psycopg` | 3.3.4-1 | LGPL | arquivo no pacote: `apps/Python312/Lib/site-packages/psycopg-3.3.4.dist-info/licenses/LICENSE.txt` |
| 101 | `python3-psycopg2` | 2.9.12-1 | LGPL with exceptions | arquivo no pacote: `apps/Python312/Lib/site-packages/psycopg2-2.9.12.dist-info/licenses/LICENSE` |
| 102 | `python3-pyarrow` | 25.0.0-1 | Apache-2.0 | arquivo no pacote: `apps/Python312/Lib/site-packages/pyarrow-25.0.0.dist-info/licenses/LICENSE.txt`, `apps/Python312/Lib/site-packages/pyarrow-25.0.0.dist-info/licenses/NOTICE.txt` |
| 103 | `python3-pydantic` | 2.13.4-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/pydantic-2.13.4.dist-info/licenses/LICENSE` |
| 104 | `python3-pydantic-core` | 2.46.4-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/pydantic_core-2.46.4.dist-info/licenses/LICENSE` |
| 105 | `python3-pygments` | 2.20.0-1 | BSD-2-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/pygments-2.20.0.dist-info/licenses/LICENSE` |
| 106 | `python3-pyodbc` | 5.3.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/pyodbc-5.3.0.dist-info/licenses/LICENSE.txt` |
| 107 | `python3-pyogrio` | 0.13.0-1 | MIT License | arquivo no pacote: `apps/Python312/Lib/site-packages/pyogrio-0.13.0.dist-info/licenses/LICENSE` |
| 108 | `python3-pyopengl` | 3.1.10-1 | OSI Approved :: BSD License | upstream: https://mcfletch.github.io/pyopengl/ |
| 109 | `python3-pyparsing` | 3.3.2-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/pyparsing-3.3.2.dist-info/licenses/LICENSE` |
| 110 | `python3-pypdf` | 6.14.2-1 | BSD-2-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/pypdf-6.14.2.dist-info/licenses/LICENSE` |
| 111 | `python3-pyproj` | 3.7.2-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/pyproj-3.7.2.dist-info/licenses/LICENSE`, `apps/Python312/Lib/site-packages/pyproj-3.7.2.dist-info/licenses/LICENSE_proj` |
| 112 | `python3-pyqt5` | 5.15.11-3 | GPL v3 | upstream: https://www.riverbankcomputing.com/software/pyqt/ |
| 113 | `python3-pyqt5-sip` | 12.18.0-1 | BSD-2-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/pyqt5_sip-12.18.0.dist-info/licenses/LICENSE` |
| 114 | `python3-pyserial` | 3.5-2 | BSD | arquivo no pacote: `apps/Python312/Lib/site-packages/pyserial-3.5.dist-info/LICENSE.txt` |
| 115 | `python3-python-dateutil` | 2.9.0.post0-1 | Dual License | arquivo no pacote: `apps/Python312/Lib/site-packages/python_dateutil-2.9.0.post0.dist-info/LICENSE` |
| 116 | `python3-pytz` | 2026.2-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/pytz-2026.2.dist-info/LICENSE.txt` |
| 117 | `python3-pywin32` | 311-1 | PSF | arquivo no pacote: `apps/Python312/Lib/site-packages/adodbapi/license.txt`, `apps/Python312/Lib/site-packages/pythonwin/license.txt` e mais 2 |
| 118 | `python3-pyyaml` | 6.0.3-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/pyyaml-6.0.3.dist-info/licenses/LICENSE` |
| 119 | `python3-qscintilla` | 2.14.1-2 | GPL-3.0 OU licenca comercial (Riverbank) | upstream: https://www.riverbankcomputing.com/software/qscintilla/ |
| 120 | `python3-remotior-sensus` | 0.7.5-1 | OSI Approved :: GNU General Public License v3 or later (GPLv3+) | arquivo no pacote: `apps/Python312/Lib/site-packages/remotior_sensus/COPYING`, `apps/Python312/Lib/site-packages/remotior_sensus-0.7.5.dist-info/licenses/COPYING` e mais 1 |
| 121 | `python3-reportlab` | 5.0.0-1 | OSI Approved :: BSD License | arquivo no pacote: `apps/Python312/Lib/site-packages/reportlab-5.0.0.dist-info/licenses/LICENSE` |
| 122 | `python3-requests` | 2.34.2-1 | Apache-2.0 | arquivo no pacote: `apps/Python312/Lib/site-packages/requests-2.34.2.dist-info/licenses/LICENSE`, `apps/Python312/Lib/site-packages/requests-2.34.2.dist-info/licenses/NOTICE` |
| 123 | `python3-scipy` | 1.18.0-1 | OSI Approved :: BSD License | arquivo no pacote: `apps/Python312/Lib/site-packages/scipy-1.18.0.dist-info/LICENSE.txt`, `apps/Python312/Lib/site-packages/scipy/integrate/LICENSE_DOP` e mais 3 |
| 124 | `python3-setuptools` | 83.0.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/setuptools-83.0.0.dist-info/licenses/LICENSE`, `apps/Python312/Lib/site-packages/setuptools/config/NOTICE` e mais 15 |
| 125 | `python3-shapely` | 2.1.2-2 | BSD 3-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/shapely-2.1.2.dist-info/licenses/LICENSE.txt` |
| 126 | `python3-simplejson` | 4.1.1-1 | MIT OR AFL-2.1 | arquivo no pacote: `apps/Python312/Lib/site-packages/simplejson-4.1.1.dist-info/licenses/LICENSE.txt` |
| 127 | `python3-sip` | 6.15.3-1 | BSD-2-Clause | arquivo no pacote: `apps/Python312/Lib/site-packages/sip-6.15.3.dist-info/licenses/LICENSE`, `apps/Python312/Lib/site-packages/sipbuild/module/source/12/10/LICENSE` e mais 42 |
| 128 | `python3-six` | 1.17.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/six-1.17.0.dist-info/LICENSE` |
| 129 | `python3-typing-extensions` | 4.16.0-1 | PSF License | arquivo no pacote: `apps/Python312/Lib/site-packages/typing_extensions-4.16.0.dist-info/licenses/LICENSE` |
| 130 | `python3-typing-inspection` | 0.4.2-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/typing_inspection-0.4.2.dist-info/licenses/LICENSE` |
| 131 | `python3-tzdata` | 2026.2-1 | Apache-2.0 | arquivo no pacote: `apps/Python312/Lib/site-packages/tzdata-2026.2.dist-info/licenses/LICENSE`, `apps/Python312/Lib/site-packages/tzdata-2026.2.dist-info/licenses/licenses/LICENSE_APACHE` |
| 132 | `python3-urllib3` | 2.7.0-1 | MIT | arquivo no pacote: `apps/Python312/Lib/site-packages/urllib3-2.7.0.dist-info/licenses/LICENSE.txt` |
| 133 | `python3-wxpython` | 4.2.5-1 | OSI Approved | arquivo no pacote: `apps/Python312/Lib/site-packages/wxpython-4.2.5.dist-info/licenses/LICENSE.txt`, `apps/Python312/Lib/site-packages/wx/lib/pubsub/LICENSE_BSD_Simple.txt` |
| 134 | `python3-xlrd` | 2.0.2-1 | BSD | arquivo no pacote: `apps/Python312/Lib/site-packages/xlrd-2.0.2.dist-info/LICENSE` |
| 135 | `python3-xlwt` | 1.3.0-2 | BSD | upstream: http://www.python-excel.org/ |
| 136 | `qca` | 2.3.8-2 | LGPL-2.1 | upstream: https://github.com/KDE/qca |
| 137 | `qscintilla` | 2.14.1-2 | GPL-3.0 OU licenca comercial (Riverbank) | upstream: https://www.riverbankcomputing.com/software/qscintilla/ |
| 138 | `qt5-libs` | 5.15.13-2 | LGPL-3.0 (edicao open source - partes so sob GPL-3.0) | upstream: https://www.qt.io/licensing/open-source-lgpl-obligations |
| 139 | `qt5-qml` | 5.15.13-2 | LGPL-3.0 (edicao open source - partes so sob GPL-3.0) | upstream: https://www.qt.io/licensing/open-source-lgpl-obligations |
| 140 | `qt5-tools` | 5.15.13-2 | LGPL-3.0 / GPL-3.0 conforme a ferramenta (edicao open source) | upstream: https://www.qt.io/licensing/open-source-lgpl-obligations |
| 141 | `qtkeychain-libs` | 0.14.2-1 | BSD-2-Clause (texto proprio no COPYING) | upstream: https://github.com/frankosterfeld/qtkeychain/blob/master/COPYING |
| 142 | `qtwebkit-libs` | 5.212.0-alpha4-9 | LGPL-2.1-or-later e LGPL-2.0-or-later (WebCore, JavaScriptCore), com partes BSD-2-Clause (LICENSE-APPLE) | upstream: https://github.com/qtwebkit/qtwebkit/tree/qtwebkit-5.212.0-alpha4/Source/WebCore |
| 143 | `qwt-libs` | 6.3.0-2 | Qwt License 1.0 (LGPL-2.1 com tres excecoes) | upstream: https://qwt.sourceforge.io/qwtlicense.html |
| 144 | `saga` | 9.12.4-1 | GPL-2.0-or-later (interface e ferramentas); a API (saga_api) sob LGPL-2.1-or-later | upstream: https://sourceforge.net/p/saga-gis/code/ci/master/tree/saga-gis/src/saga_core/ |
| 145 | `setup` | 1.1.2-17 | GPL-2.0-or-later (osgeo4w-setup, derivado do setup do Cygwin) | upstream: https://github.com/jef-n/OSGeo4W/blob/master/src/setup/COPYING |
| 146 | `sqlite3` | 3.53.4-1 | Dominio publico (nao ha licenca - dedicacao ao dominio publico) | upstream: https://www.sqlite.org/copyright.html |
| 147 | `szip` | 99-1 | Licenca propria do SZIP (ICs, LLC): descompressao livre; compressao so para uso cientifico nao comercial | upstream: https://download.osgeo.org/osgeo4w/v2/x86_64/release/szip/szip-devel/szip-devel-2.1.1-4.txt |
| 148 | `thrift` | 0.24.0-1 | Apache-2.0 | upstream: https://github.com/apache/thrift |
| 149 | `wxwidgets` | 3.2.9-1 | wxWindows Library Licence 3.1 (LGPL-2 com excecao para binarios) | upstream: https://www.wxwidgets.org/about/licence/ |
| 150 | `xerces-c` | 3.2.5-1 | Apache-2.0 | upstream: https://github.com/apache/xerces-c |
| 151 | `xz` | 5.4.7-1 | MULTIPLA (0BSD para a liblzma - outras partes com licencas distintas) | upstream: https://github.com/tukaani-project/xz/blob/master/COPYING |
| 152 | `zlib` | 1.3.2-3 | Zlib License | upstream: https://github.com/madler/zlib/blob/develop/LICENSE |
| 153 | `zstd` | 1.5.7-1 | BSD-3-Clause + GPL-2.0 (duplo, ver arquivo) | upstream: https://github.com/facebook/zstd/blob/dev/LICENSE |
<!-- gerado: fim -->

## 4. Qt e a LGPL

O Qt 5.15.13 (`qt5-libs`, `qt5-qml`, `qt5-tools`) é distribuído na edição de código aberto, sob a **GNU Lesser
General Public License versão 3 (LGPL-3.0)**, com fonte em https://download.qt.io/archive/qt/5.15/. As
ferramentas de desenvolvimento do `qt5-tools` (Designer, Linguist) seguem os termos de cada uma.

**Partes do Qt que são só GPL.** Na edição de código aberto, alguns módulos do Qt 5.15 **não** são LGPL: são
oferecidos só sob a **GNU General Public License versão 3 (GPL-3.0)** ou licença comercial (lista "Add-ons
available under Commercial Licenses, or GNU General Public License v3" de https://doc.qt.io/qt-5/qtmodules.html).
Os que estão nesta árvore:

| Módulo (GPL-3.0) | Arquivos |
|---|---|
| Qt Charts | `apps\qt5\bin\Qt5Charts.dll`, `apps\qt5\qml\QtCharts` |
| Qt Data Visualization | `apps\qt5\bin\Qt5DataVisualization.dll`, `apps\qt5\qml\QtDataVisualization` |
| Qt Lottie Animation | `apps\qt5\bin\Qt5Bodymovin.dll` |
| Qt Network Authorization | `apps\qt5\bin\Qt5NetworkAuth.dll` |
| Qt Virtual Keyboard | `apps\qt5\bin\Qt5VirtualKeyboard.dll`, `apps\qt5\plugins\virtualkeyboard` |
| Qt Quick 3D | `apps\qt5\bin\Qt5Quick3D*.dll`, `apps\qt5\qml\QtQuick3D` |
| Qt Quick WebGL | `apps\qt5\plugins\platforms\qwebgl.dll` |

A GPL-3.0 desses módulos é compatível com a GPL-2.0-or-later do QGIS, porque a do QGIS admite "versão posterior".

**O direito de substituir o Qt (LGPL).** O Qt está em DLLs separadas em `apps\qt5\bin` e plugins em
`apps\qt5\plugins`; não há Qt estático. O QGIS liga ao Qt por vínculo dinâmico. Para usar outro build do Qt 5.15
(Windows x64, MSVC, mesma ABI): feche o IMAN Terra, troque os `Qt5*.dll` de `apps\qt5\bin` e os plugins de
`apps\qt5\plugins` pelos do seu build e abra o IMAN Terra de novo. O mesmo vale para os demais componentes LGPL da
árvore (GEOS, cairo, QCA, Qwt, wxWidgets, libiconv, libspatialite, FreeXL, QtWebKit), que também são DLLs
separadas.

## 5. Drivers e componentes de licença condicionada

Estes componentes **não** são software livre. São os mesmos que o QGIS 3.44.13 oficial instala, e o OSGeo4W
publica para cada um o termo que o seu instalador mostra (campo `license` do `setup.ini` do OSGeo4W). As cópias
desses termos, como publicadas, estão na pasta `licencas\` da instalação.

### MrSID (`gdal-mrsid`): redistribuição condicionada

- **Arquivos:** `bin\lti_dsdk_9.5.dll`, `bin\lti_dsdk_cdll_9.5.dll`, `bin\lti_lidar_dsdk_1.1.dll`, `bin\tbb.dll`
  (MrSID Decode SDK da Extensis) e `apps\gdal\lib\gdalplugins\gdal_MrSID.dll` (plugin do GDAL, MIT).
- **Termo:** "Software License Agreement for MrSID Decode SDKs" (`licencas\gdal-mrsid.txt`). A seção 1.3 permite
  distribuir o SDK em código objeto junto do produto, com condições: o aviso de propriedade da Extensis, a
  sublicença com as mesmas proteções e, na alínea (b), que a distribuição "shall not cause, or could be
  interpreted or asserted to cause, DSDK to become subject to the terms of any open source agreement, including,
  without limitation, the GNU General Public License". O SDK é carregado pelo GDAL como plugin separado e
  continua sob o termo da Extensis, não sob a GPL.
- **Aviso de propriedade:** o MrSID Decode SDK é propriedade da Celartem, Inc., que atua como Extensis, e dos
  seus licenciadores, protegido por direito autoral e segredo industrial, e licenciado, não vendido.

### Oracle (`oci` e `gdal-oracle`): redistribuição condicionada

- **Arquivos:** `bin\oci.dll`, `bin\oraociicus.dll` (Oracle Instant Client 21.13) e, ligados a eles,
  `apps\gdal\lib\gdalplugins\gdal_GEOR.dll`, `apps\gdal\lib\gdalplugins\ogr_OCI.dll` (GDAL, MIT), o provedor
  Oracle do QGIS e o driver `qsqlocispatial.dll`.
- **Termo:** "Oracle Free Use Terms and Conditions" (`licencas\oci.txt`, cópia incluída como o termo exige). Ele
  permite redistribuir os programas sem modificação, desde que o usuário final não pague nada a mais por eles.
  O IMAN Terra é gratuito.

### Microsoft ODBC Driver 18 for SQL Server (`msodbcsql`): redistribuição condicionada

- **Arquivos:** `bin\msodbcsql18.dll`, `bin\msodbcdiag18.dll`, `bin\adal.dll`, `bin\1033\msodbcsqlr18.rll`.
- **Termo:** "Microsoft Software License Terms, Microsoft ODBC Driver 18 for SQL Server"
  (`licencas\msodbcsql.txt`). Só o código da lista REDIST da Microsoft é distribuível (seção 2). A lista não foi
  conferida arquivo a arquivo; fica como pendência antes de qualquer distribuição.

### Microsoft Visual C++ (`msvcrt2019` e o runtime do compilador)

- **Arquivos:** `bin\msvcp140*.dll`, `bin\vcruntime140*.dll`, `bin\concrt140.dll` (pacote `msvcrt2019`) e as
  mesmas DLLs em `apps\qgis-ltr\bin`, do compilador que gerou o QGIS do IMAN Terra (MSVC 14.44).
- **Termo:** código distribuível do Visual Studio, conforme
  https://learn.microsoft.com/cpp/windows/redistributing-visual-cpp-files.

### Microsoft Debugging Tools for Windows (`dbghelp.dll` e `symsrv.dll`)

- **Arquivos:** `apps\qgis-ltr\dbghelp.dll` e `apps\qgis-ltr\symsrv.dll`, versão 10.0.26100.7705, das Debugging
  Tools for Windows do Windows SDK 10.0.26100, no mesmo lugar em que o pacote `qgis-ltr` oficial os leva. O crash
  handler do QGIS os usa para montar a pilha de uma falha.
- **Termo:** "Microsoft Software License Terms, Microsoft Windows Software Development Kit (SDK) for Windows"
  (`licencas\windows-sdk.txt`), seção "Distributable Code": é distribuível o código da lista REDIST.TXT da Microsoft
  (https://learn.microsoft.com/legal/windows-sdk/redist), que na seção "Debugging Tools for Windows" diz "You may
  distribute these files as part of your program." e nomeia `Dbghelp.dll` e `Symsrv.dll`. Os dois vão sem
  modificação, como parte do IMAN Terra, e seguem sob o termo da Microsoft.

### SZIP (`szip`)

- **Termo:** licença própria (`licencas\szip.txt`): a descompressão é livre; a compressão SZIP é licenciada só para
  uso científico não comercial.

## 6. Componentes próprios do Instituto IMAN

- Scripts de build, instalador, lançador (`bin\iman-terra-env.bat`, `bin\qgis_process-iman-terra.bat`,
  `iman\postinstall.cmd`) e a fonte de marca, na pasta `iman/` do fork: código do **Instituto IMAN**, sob
  **GPL-3.0-or-later**, compatível com o QGIS. Ver `LICENSE`.
- As modificações nos arquivos do QGIS (seção 2) seguem a licença do arquivo do QGIS, GPL-2.0-or-later.
- Os assets de marca (nome, logo, ícones, splash) são marca do **Instituto IMAN** e **não** são licenciados para
  reuso. Ver `LICENSE`.

## 7. Marcas

"QGIS" e o logotipo do QGIS são marcas da QGIS.ORG. O uso aqui é **nominativo** ("powered by QGIS") e não implica
endosso. "IMAN" e "IMAN Terra" são marcas do Instituto IMAN. As demais marcas citadas pertencem aos seus titulares.

## 8. Validade

Este aviso descreve a árvore montada a partir do lock `iman/build/osgeo4w.lock.tsv` do fork (os pacotes
`Runtime=official`, menos o `gdal-ecw`, seção 1). Trocar a versão do QGIS ou de qualquer pacote obriga a regenerar
o inventário (`iman/notices/Update-Notices.ps1`). Erros ou omissões: escreva ao Instituto IMAN pelo canal de
`SOURCE_CODE.md`. Créditos e licenças de terceiros são corrigidos com prioridade.
