@echo off
rem IMAN Terra: ambiente de runtime, o mesmo do bin\qgis-ltr.bat do QGIS 3.44.13 oficial (pacote qgis-ltr do
rem OSGeo4W), sem abrir o programa. Usado pelo postinstall da instalacao, que grava dele o bin\iman-terra.env lido
rem pelo iman-terra.exe (src/app/mainwin.cpp), e pelo bin\qgis_process-iman-terra.bat.
rem @IMAN_PRODUCT_NAME@ e trocado pelo nome do produto (iman/brand/brand.json) ao montar a arvore.
call "%~dp0o4w_env.bat"
if not exist "%OSGEO4W_ROOT%\apps\qgis-ltr\bin\qgisgrass8.dll" goto nograss
if not exist "%OSGEO4W_ROOT%\apps\grass\grass85\etc\env.bat" goto nograss
set savedpath=%PATH%
call "%OSGEO4W_ROOT%\apps\grass\grass85\etc\env.bat"
path %OSGEO4W_ROOT%\apps\grass\grass85\lib;%OSGEO4W_ROOT%\apps\grass\grass85\bin;%savedpath%
:nograss
@echo off
path %OSGEO4W_ROOT%\apps\qgis-ltr\bin;%PATH%
set QGIS_PREFIX_PATH=%OSGEO4W_ROOT:\=/%/apps/qgis-ltr
set GDAL_FILENAME_IS_UTF8=YES
rem Set VSI cache to be used as buffer, see #6448
set VSI_CACHE=TRUE
set VSI_CACHE_SIZE=1000000
set QT_PLUGIN_PATH=%OSGEO4W_ROOT%\apps\qgis-ltr\qtplugins;%OSGEO4W_ROOT%\apps\qt5\plugins
rem o atalho do Menu Iniciar que o WinToast valida e o do instalador: Start Menu\Programs\<nome>.lnk
set QGIS_WIN_APP_NAME=@IMAN_PRODUCT_NAME@
