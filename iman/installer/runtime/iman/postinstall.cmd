@echo off
rem IMAN Terra: postinstall da arvore instalada, rodado pelo instalador como o proprio usuario, sem elevacao.
rem Faz o que o osgeo4w-setup e o MSI do QGIS oficial fazem na instalacao, dentro da arvore e so nela:
rem   1. roda cada etc\postinstall\*.bat dos pacotes (troca de caminho nos scripts e lancadores do Python, GRASS)
rem      com OSGEO4W_ROOT na raiz instalada e os atalhos do OSGeo4W desligados, e renomeia para .done;
rem      openssl.bat e opencl.bat nao rodam: copiariam DLL para C:\Windows\System32 (ficam .skipped);
rem   2. no lugar do postinstall dos pacotes qgis-ltr*: crssync, remocao dos .pyc e o bin\iman-terra.env
rem      (iman-terra.exe --postinstall grava o ambiente listado em bin\iman-terra.vars).
rem      A associacao de arquivos do qgis-ltr (qgis.reg, regedit) nao existe aqui: o "Abrir com" e do instalador.
rem Log em var\log\iman-postinstall.log. Sai com 1 se o bin\iman-terra.env nao for gravado.
setlocal
for %%i in ("%~dp0..") do set "OSGEO4W_ROOT=%%~fsi"
set "OSGEO4W_ROOT_MSYS=%OSGEO4W_ROOT:\=/%"
set OSGEO4W_MENU_LINKS=0
set OSGEO4W_DESKTOP_LINKS=0
set OSGEO4W_SKIP_ARP_REGISTRATION=1
set "OSGEO4W_STARTMENU=%OSGEO4W_ROOT%\var\nao-usado\startmenu"
set "OSGEO4W_DESKTOP=%OSGEO4W_ROOT%\var\nao-usado\desktop"
if not exist "%OSGEO4W_ROOT%\var\log" mkdir "%OSGEO4W_ROOT%\var\log"
set "LOG=%OSGEO4W_ROOT%\var\log\iman-postinstall.log"
echo postinstall %DATE% %TIME% em %OSGEO4W_ROOT%> "%LOG%"
set "PATH=%OSGEO4W_ROOT%\bin;%PATH%"

rem lista feita antes de rodar (dir /on: ordem alfabetica, a do osgeo4w-setup); cada script renomeia o seu
for /f "delims=" %%f in ('dir /b /on "%OSGEO4W_ROOT%\etc\postinstall\*.bat"') do call :package "%OSGEO4W_ROOT%\etc\postinstall\%%f" "%%f"

call "%OSGEO4W_ROOT%\bin\iman-terra-env.bat"
echo == crssync>> "%LOG%"
pushd "%OSGEO4W_ROOT%"
"%OSGEO4W_ROOT%\apps\qgis-ltr\crssync.exe" >> "%LOG%" 2>&1
echo crssync exit %ERRORLEVEL%>> "%LOG%"
popd
del /s /q "%OSGEO4W_ROOT%\apps\qgis-ltr\python\*.pyc" >nul 2>&1
if exist "%OSGEO4W_ROOT%\bin\iman-terra.env" del "%OSGEO4W_ROOT%\bin\iman-terra.env"
"%OSGEO4W_ROOT%\bin\iman-terra.exe" --postinstall
echo iman-terra.exe --postinstall exit %ERRORLEVEL%>> "%LOG%"
if not exist "%OSGEO4W_ROOT%\bin\iman-terra.env" (
  echo FALHOU: bin\iman-terra.env nao foi gravado>> "%LOG%"
  exit /b 1
)
echo OK>> "%LOG%"
exit /b 0

:package
if /i "%~2"=="openssl.bat" goto skip
if /i "%~2"=="opencl.bat" goto skip
echo == %~2>> "%LOG%"
pushd "%OSGEO4W_ROOT%"
cmd /d /c call "%~1" >> "%LOG%" 2>&1
echo %~2 exit %ERRORLEVEL%>> "%LOG%"
popd
if exist "%~1" move /y "%~1" "%~1.done" >nul
goto :eof
:skip
echo == %~2 PULADO (escreve em C:\Windows\System32)>> "%LOG%"
move /y "%~1" "%~1.skipped" >nul
goto :eof
