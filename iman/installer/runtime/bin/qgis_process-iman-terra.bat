@echo off
rem IMAN Terra: qgis_process com o ambiente do produto, como o bin\qgis_process-qgis-ltr.bat do QGIS oficial.
call "%~dp0iman-terra-env.bat"
set PYTHONPATH=%OSGEO4W_ROOT%\apps\qgis-ltr\python;%PYTHONPATH%
"%OSGEO4W_ROOT%\apps\qgis-ltr\bin\qgis_process.exe" %*
