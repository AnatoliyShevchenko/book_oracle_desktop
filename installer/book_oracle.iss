; Inno Setup script for Book Oracle.
;
; Build it with tool\build_installer.ps1 — that script compiles the app,
; locates the Visual C++ runtime and passes the paths in as /D defines.
;
; Required defines:
;   AppVersion   e.g. 1.0.0
;   BuildDir     the Flutter Release folder
;   CrtDir       the Microsoft.VC*.CRT redist folder
;   ProjectDir   the repository root

#define AppName        "Book Oracle"
#define AppExeName     "book_oracle.exe"
#define AppPublisher   "Book Oracle"

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
; Never change AppId — it is how Windows recognises an upgrade of this app.
AppId={{223ABA41-F344-48D8-8919-51F196AA2C4B}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
VersionInfoVersion={#AppVersion}

; Installs per user by default, so no UAC prompt; the user may still pick a
; machine-wide install from the first page.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes

; The app is Windows 10 and newer, 64-bit only.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

OutputDir={#ProjectDir}\dist
OutputBaseFilename=BookOracleSetup-{#AppVersion}
SetupIconFile={#ProjectDir}\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}

Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ShowLanguageDialog=auto

; Offer to close a running copy instead of failing on locked files.
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
russian.CreateDesktopIcon=Создать значок на рабочем столе
russian.LaunchApp=Запустить {#AppName}
russian.RemoveDataTitle=Удалить настройки?
russian.RemoveDataPrompt=Удалить настройки Book Oracle и сохранённую копию списка книг?%n%nСама Google Таблица не пострадает — удалятся только локальные файлы приложения.
english.CreateDesktopIcon=Create a desktop shortcut
english.LaunchApp=Launch {#AppName}
english.RemoveDataTitle=Remove settings?
english.RemoveDataPrompt=Remove Book Oracle's settings and its saved copy of the book list?%n%nYour Google Sheet is untouched — this only deletes the app's local files.

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; The whole Flutter release payload: exe, engine, plugins and data\.
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Visual C++ runtime, deployed app-local so the installer needs no admin
; rights and no separate redistributable. Microsoft permits this; the trade-off
; is that these copies are not serviced by Windows Update.
Source: "{#CrtDir}\msvcp140.dll";              DestDir: "{app}"; Flags: ignoreversion
Source: "{#CrtDir}\msvcp140_1.dll";            DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#CrtDir}\msvcp140_2.dll";            DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#CrtDir}\msvcp140_atomic_wait.dll";  DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#CrtDir}\msvcp140_codecvt_ids.dll";  DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#CrtDir}\vcruntime140.dll";          DestDir: "{app}"; Flags: ignoreversion
Source: "{#CrtDir}\vcruntime140_1.dll";        DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchApp}"; Flags: nowait postinstall skipifsilent

[Code]
// The app keeps its settings and cached list in %APPDATA%\com.bookoracle.
// Leave them alone unless the user says otherwise.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  DataDir: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    DataDir := ExpandConstant('{userappdata}\com.bookoracle');
    if DirExists(DataDir) then
      if SuppressibleMsgBox(ExpandConstant('{cm:RemoveDataPrompt}'),
                            mbConfirmation, MB_YESNO, IDNO) = IDYES then
        DelTree(DataDir, True, True, True);
  end;
end;
