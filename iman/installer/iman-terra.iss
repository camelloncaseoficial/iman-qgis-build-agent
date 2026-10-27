; IMAN Terra: instalador (Inno Setup 7), fatia 047 do fork (D-IMAN-043, D-IMAN-030).
;
; Compilado so por iman/installer/Build-Installer.ps1, que monta a arvore (New-RuntimeTree.ps1) e passa ao ISCC os
; #define abaixo a partir da fonte unica (iman/brand/brand.json) e do build. O que ele instala:
;   - a arvore de runtime em {app} (layout da instalacao oficial do QGIS: bin, apps, etc, share...), por usuario e
;     sem elevacao, em {localappdata}\Programs\<produto>;
;   - o atalho do Menu Iniciar (e, opcional, o da Area de Trabalho) para bin\iman-terra.exe, com o AUMI do processo,
;     para o WinToast validar o atalho do instalador em vez de criar outro (QGIS_WIN_APP_NAME no .env);
;   - o "Abrir com" (OpenWithProgids) de .qgs, .qgz e .qlr em HKCU\Software\Classes, sem tocar no padrao;
;   - a GPL na tela de licenca e os notices (LICENSE, THIRD_PARTY_NOTICES.md, SOURCE_CODE.md, licencas\).
; Depois de copiar, roda iman\postinstall.cmd (o postinstall dos pacotes e o bin\iman-terra.env).
; Atualizacao da 0.3.0 da distro: mesmo AppId; a arvore antiga sai ([InstallDelete]); o perfil da distro
; (%APPDATA%\InstitutoIMAN\IMAN Terra) nao e tocado. Desinstalacao: a arvore, os atalhos e as associacoes saem; o
; perfil do produto fica.

#ifndef TreeDir
  #error Rode iman\installer\Build-Installer.ps1: ele monta a arvore e passa os parametros ao ISCC.
#endif
#if !FileExists(AddBackslash(TreeDir) + "bin\iman-terra.exe")
  #error A arvore nao tem bin\iman-terra.exe: rode iman\installer\Build-Installer.ps1.
#endif
#if !FileExists(AddBackslash(TreeDir) + "iman\BUILD_INFO.txt")
  #error A arvore nao tem iman\BUILD_INFO.txt: rode iman\installer\Build-Installer.ps1.
#endif
#define NoticesDir StageDir + "\notices"

[Setup]
; mesmo AppId da distro (decisao 6 do D-IMAN-043): a 0.4.0 atualiza a 0.3.0 e "Aplicativos instalados" fica com
; uma entrada so
AppId={{7B3A9E42-1C6D-4E9F-9A21-6F2E5A1D8B34}
AppName={#ProductName}
AppVersion={#ProductVersion}
AppVerName={#ProductName} {#ProductVersion}
AppPublisher={#Publisher}
AppPublisherURL={#ProductUrl}
AppComments={#ProductName}, powered by QGIS {#QgisVersion} (commit {#Commit})
VersionInfoVersion={#ProductVersion}
VersionInfoProductName={#ProductName}
VersionInfoDescription={#ProductName} {#ProductVersion}, powered by QGIS {#QgisVersion} (commit {#Commit})
DefaultDirName={localappdata}\Programs\{#ProductName}
; pasta fixa: o [InstallDelete] limpa as pastas da arvore dentro de {app}, e isso so e seguro numa pasta nossa
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBase}
SetupIconFile={#RepoDir}\iman\brand\assets\icon-iman-terra.ico
UninstallDisplayIcon={app}\bin\iman-terra.exe
UninstallDisplayName={#ProductName}
LicenseFile={#NoticesDir}\LICENSE
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
ChangesAssociations=yes
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=yes
LZMANumBlockThreads=8

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar um atalho na Área de Trabalho"; GroupDescription: "Atalhos adicionais:"; Flags: unchecked

[InstallDelete]
; a 0.3.0 da distro: a arvore do QGIS em {app}\qgis e a camada de marca (o perfil dela fica em %APPDATA%)
Type: filesandordirs; Name: "{app}\qgis"
Type: filesandordirs; Name: "{app}\launcher"
Type: filesandordirs; Name: "{app}\assets"
Type: filesandordirs; Name: "{app}\demo"
Type: filesandordirs; Name: "{app}\notices"
Type: filesandordirs; Name: "{app}\profile-template"
Type: filesandordirs; Name: "{app}\startup"
Type: filesandordirs; Name: "{app}\i18n"
Type: files; Name: "{app}\BUILD_ID.txt"
Type: files; Name: "{app}\qgis-manifest.txt"
Type: files; Name: "{app}\README.md"
Type: files; Name: "{autoprograms}\Desinstalar {#ProductName}.lnk"
; a arvore desta versao, para reinstalar sobre ela pousar em terreno limpo
#include TreeDirsInclude

[Files]
Source: "{#TreeDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#NoticesDir}\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#NoticesDir}\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#NoticesDir}\SOURCE_CODE.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#NoticesDir}\licencas\*.txt"; DestDir: "{app}\licencas"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#ProductName}"; Filename: "{app}\bin\iman-terra.exe"; WorkingDir: "{userdocs}"; Comment: "{#ProductName}, powered by QGIS"; AppUserModelID: "{#Aumi}"
Name: "{autodesktop}\{#ProductName}"; Filename: "{app}\bin\iman-terra.exe"; WorkingDir: "{userdocs}"; Comment: "{#ProductName}, powered by QGIS"; AppUserModelID: "{#Aumi}"; Tasks: desktopicon

[Registry]
; "Abrir com" por usuario (decisao 2): so OpenWithProgids e o ProgID do produto; o padrao do tipo nao e tocado.
; As chaves vazias saem na desinstalacao (uninsdeletekeyifempty), o valor e o ProgID saem sempre.
Root: HKCU; Subkey: "Software\Classes\.qgs"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\.qgs\OpenWithProgids"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\.qgs\OpenWithProgids"; ValueType: string; ValueName: "IMANTerra.qgs"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qgs"; ValueType: string; ValueName: ""; ValueData: "Projeto do {#ProductName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qgs\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\iman\icons\iman-terra-qgs.ico"
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qgs\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\iman-terra.exe"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\.qgz"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\.qgz\OpenWithProgids"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\.qgz\OpenWithProgids"; ValueType: string; ValueName: "IMANTerra.qgz"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qgz"; ValueType: string; ValueName: ""; ValueData: "Projeto do {#ProductName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qgz\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\iman\icons\iman-terra-qgz.ico"
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qgz\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\iman-terra.exe"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\.qlr"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\.qlr\OpenWithProgids"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\.qlr\OpenWithProgids"; ValueType: string; ValueName: "IMANTerra.qlr"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qlr"; ValueType: string; ValueName: ""; ValueData: "Definição de camada do {#ProductName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qlr\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\iman\icons\iman-terra-qlr.ico"
Root: HKCU; Subkey: "Software\Classes\IMANTerra.qlr\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\iman-terra.exe"" ""%1"""
; o nome que o "Abrir com" mostra para o executavel (sem isto, o nome do arquivo)
Root: HKCU; Subkey: "Software\Classes\Applications\iman-terra.exe"; ValueType: string; ValueName: "FriendlyAppName"; ValueData: "{#ProductName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Applications\iman-terra.exe\SupportedTypes"; ValueType: string; ValueName: ".qgs"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\Applications\iman-terra.exe\SupportedTypes"; ValueType: string; ValueName: ".qgz"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\Applications\iman-terra.exe\SupportedTypes"; ValueType: string; ValueName: ".qlr"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\Applications\iman-terra.exe\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\iman-terra.exe"" ""%1"""

[Run]
Filename: "{app}\bin\iman-terra.exe"; WorkingDir: "{userdocs}"; Description: "Abrir o {#ProductName} agora"; Flags: postinstall nowait skipifsilent unchecked

[UninstallDelete]
; a arvore inteira, inclusive o que nasceu depois da copia (o .env e os .done do postinstall, os .pyc do Python)
#include TreeDirsUninstallInclude

[Code]
// postinstall da arvore (iman\postinstall.cmd): troca de caminho nos scripts dos pacotes e o bin\iman-terra.env
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    WizardForm.StatusLabel.Caption := 'Configurando o ambiente do {#ProductName}...';
    if not Exec(ExpandConstant('{app}\iman\postinstall.cmd'), '', ExpandConstant('{app}'), SW_HIDE,
      ewWaitUntilTerminated, ResultCode) or (ResultCode <> 0) or
      not FileExists(ExpandConstant('{app}\bin\iman-terra.env')) then
      SuppressibleMsgBox('A configuração do ambiente do {#ProductName} falhou (código ' + IntToStr(ResultCode) +
        '). O registro está em ' + ExpandConstant('{app}\var\log\iman-postinstall.log') + '.', mbError, MB_OK, IDOK);
  end;
end;
