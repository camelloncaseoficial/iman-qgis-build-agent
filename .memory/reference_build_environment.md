---
name: reference_build_environment
description: Bancada de build desta maquina: o que a fatia 043 instalou (versoes), onde fica cada coisa, tempos e disco medidos em 2026-10-23; achados de BL-3, build e captura da fatia 044 (2026-10-25).
type: reference
---

Medido em 2026-10-22 (arquiteto) e atualizado pela fatia 043 em 2026-10-23. Laudo:
`iman/docs/verify/043-fundacao/README.md`.

- Windows 11 Pro, 24 processadores logicos, 32 GB de RAM. Localidade do Windows em espanhol (a UI do QGIS segue).
- **Instalado pela fatia 043, com o "sim" do sponsor na sessao:** VS 2022 Build Tools 17.14.42 (MSVC 14.44.35207,
  `cl` 19.44.35229, Windows SDK 10.0.26100, ATL) em `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools`
  (12,2 GB a menos no C:). Ferramentas portateis em `D:\iman-terra-build\tools`: CMake 3.29.0, ninja 1.10.2,
  winflexbison 2.5.25. Nada em `C:\OSGeo4W`; sem Cygwin.
- **Raiz de trabalho** `D:\iman-terra-build` (fora do repo): `cache\` (pacotes OSGeo4W do lock, 652 MB), `osgeo4w\`
  (raiz isolada, 2,2 GB), `build\` (14,9 GB), `install\apps\qgis-ltr` (saida, 0,4 GB), `logs\`, `smoke\`, `guard\`.
  Raizes extras da fatia 043: `D:\iman-terra-build-clean` (prova do clone limpo) e `D:\iman-terra-build-latest`
  (matriz "OSGeo4W andou"); podem ser apagadas.
- **Tempos:** do clone limpo ao binario com smoke 31 min; build limpo 22,5 min; incremental de um `.cpp` 26 s;
  configure ~2,5 min; install ~2 min; smoke ~1 min.
- Com o QGIS 3.44.13 oficial em `C:\Program Files\QGIS 3.44.13` (do sponsor: so leitura, nunca alterar; a guarda
  `iman/build/Test-OfficialQgisUntouched.ps1` prova) e o IMAN Terra 0.3.0 da distro em
  `%LOCALAPPDATA%\Programs\IMAN Terra` (congelado). Existe a chave vazia `HKCU\Software\QGIS\QGIS3`.
- `C:\Windows\System32` nao recebe DLL do OSGeo4W: os postinstall `openssl.bat` e `opencl.bat` nao rodam.
- Clone deste repo: parcial (`--filter=blob:none`), `core.longpaths=true`, `core.autocrlf=false`; remoto
  `upstream` = `qgis/QGIS` (nunca `git fetch --all`: baixa o QGIS inteiro).
- `gh` autenticado com escopo `repo`; o PR da fatia e contra `develop` deste fork.

Medido na fatia 044 (2026-10-25), laudo `iman/docs/verify/044-marca-no-fonte/README.md`:

- **Nome interno compartilhado com o QGIS oficial (BL-3):** sem `cache/directory` no perfil, o QGIS (build ou
  oficial) grava o cache de rede em `%LOCALAPPDATA%\QGIS\QGIS3\cache`; o crash handler grava em
  `%LOCALAPPDATA%\QGIS\QGIS3\crashes`; o WinToast valida a cada abertura `%APPDATA%\Microsoft\Windows\Start
  Menu\Programs\QGIS3.lnk` (hoje do spike 016 da distro, 2026-09-06). O smoke semeia `[cache] directory` no perfil
  descartavel (`New-DisposableProfile`) e a guarda vigia as tres coisas. Resolve de vez so com o nome interno
  (fatia do instalador). Decisao do sponsor: mitigar e seguir.
- **Ninja nao rastreia o `.ico` do `qgis_win32.rc`:** o `Build-Qgis.ps1` remove o `.res` mais velho que o `qgis.ico`.
- **Build incremental depois de mudar so a marca:** build ~60 s, `cmake --install` ~330 a 370 s (o install domina).
- **Python fixado com Pillow:** o `python3` da raiz OSGeo4W (3.12.13) tem Pillow 12.3.0 (do lock); e o que roda
  `iman/brand/derive_assets.py`. Fora do `o4w_env` ele nao sobe.
- **Captura de janela:** o pwsh 7 nasce com a consciencia de DPI fixada; `WindowCapture.ps1` usa DPI por thread.
  Testar captura so com janela criada pelo proprio teste, nunca com app do usuario (o Bloco de Notas do Windows 11
  restaura as abas da sessao do usuario).
