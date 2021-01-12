;Stremio
;Installer Source for NSIS 3.0 or higher

Unicode True

#Tells the compiler whether or not to do datablock optimizations.
SetDatablockOptimize on

;Include Modern UI
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "fileassoc.nsh"
!include "nsProcess.nsh"

;Parse package.json

!define APP_NAME "Stremio"
!define PRODUCT_VERSION "$%package_version%"
!searchparse "${PRODUCT_VERSION}" `` VERSION_MAJOR `.` VERSION_MINOR `.` VERSION_REVISION
!define APP_URL "https://www.stremio.com"
!define DATA_FOLDER "stremio"

!define COMPANY_NAME "Smart Code Ltd"


; ------------------- ;
;      Settings       ;
; ------------------- ;
;General Settings
Name "${APP_NAME}"
Caption "${APP_NAME} ${PRODUCT_VERSION} - Installer"
BrandingText "${APP_NAME} ${PRODUCT_VERSION}"
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "FileDescription" "${APP_NAME} ${PRODUCT_VERSION} Installer"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "CompanyName" "${COMPANY_NAME}"
VIAddVersionKey "LegalCopyright" "${APP_URL}"
VIProductVersion "${PRODUCT_VERSION}.0"
OutFile "../../${APP_NAME} ${PRODUCT_VERSION}.exe"
ShowInstDetails "nevershow"
ShowUninstDetails "nevershow"
CRCCheck on
;SetCompressor /SOLID lzma
;SetCompressorDictSize 4
SetCompressor lzma
SetCompressorDictSize 1

;Default installation folder
InstallDir "$LOCALAPPDATA\Programs\LNV\${APP_NAME}-${VERSION_MAJOR}"
InstallDirRegKey HKLM Software\SmartCode\Stremio InstallLocation

;Request application privileges
;RequestExecutionLevel highest
RequestExecutionLevel user
;RequestExecutionLevel admin

!define APP_LAUNCHER "Stremio.exe"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

; ------------------- ;
;     UI Settings     ;
; ------------------- ;
;Define UI settings

;!define MUI_UI_HEADERIMAGE_RIGHT "../../images/icon.png"
!define MUI_ICON "../../images/stremio.ico"
!define MUI_UNICON "../../images/stremio.ico"

; WARNING; these bmps have to be generated in BMP3 - convert SMTH BMP3:SMTH.bmp
!define MUI_WELCOMEFINISHPAGE_BITMAP "windows-installer.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "windows-installer.bmp"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_LINK "www.stremio.com"
!define MUI_FINISHPAGE_LINK_LOCATION "${APP_URL}"
!define MUI_FINISHPAGE_RUN "$INSTDIR\stremio.exe"

; Hack...
!define MUI_FINISHPAGE_SHOWREADME ""
;!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "$(desktopShortcut)"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION finishpageaction
!define MUI_FINISHPAGE_TITLE "Completing the ${APP_NAME} Setup"

; Define header image
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "windows-installer-header.bmp"
!define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
!define MUI_HEADER_TRANSPARENT_TEXT
; also consider MUI_WELCOMEFINISHPAGE_BITMAP

; Beautiful progress bar
XPStyle off
!define MUI_INSTALLCOLORS "000000 643F9E"
!define MUI_INSTFILESPAGE_PROGRESSBAR colored


# Include Sections header so that we can manipulate section properties in .onInit
!include "Sections.nsh"

;ReserveFile /plugin InstallOptions.dll

; Pages
;!insertmacro MUI_PAGE_WELCOME
; !insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
;!insertmacro MUI_PAGE_DIRECTORY

# Perform installation (executes each enabled Section)
!insertmacro MUI_PAGE_INSTFILES
!define MUI_PAGE_CUSTOMFUNCTION_SHOW fin_pg_options
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE fin_pg_leave
!insertmacro MUI_PAGE_FINISH

; Uninstall pages
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Load Language Files
!insertmacro MUI_LANGUAGE "English"

; Progress bar - part 2
!define MUI_PAGE_CUSTOMFUNCTION_SHOW InstShow

; ------------------- ;
;    Localization     ;
; ------------------- ;
LangString removeDataFolder ${LANG_ENGLISH} "Remove all data and configuration?"
LangString noRoot ${LANG_ENGLISH} "You cannot install Stremio in a directory that requires administrator permissions"
LangString desktopShortcut ${LANG_ENGLISH} "Desktop Shortcut"
LangString appIsRunning ${LANG_ENGLISH} "${APP_NAME} is running. Do you want to close it?"
LangString appIsRunningInstallError ${LANG_ENGLISH} "${APP_NAME} cannot be installed while another instance is running."
LangString appIsRunningUninstallError ${LANG_ENGLISH} "${APP_NAME} cannot be uninstalled while another instance is running."

Var Parameters

# Finish page custom options
Var AssociateTorrentCheckbox
Var checkbox_value
Function fin_pg_options
  ${NSD_CreateCheckbox} 180 -100 100% 8u "Associate ${APP_NAME} with .torrent files"
  Pop $AssociateTorrentCheckbox
  SetCtlColors $AssociateTorrentCheckbox '0xFF0000' '0xFFFFFF'
  ${NSD_Check} $AssociateTorrentCheckbox
Functionend

Function fin_pg_leave
  ${NSD_GetState} $AssociateTorrentCheckbox $checkbox_value
  IfSilent 0 assoc
  StrCpy $checkbox_value ${BST_UNCHECKED}
  ${GetOptions} $Parameters /notorrentassoc $R1
  IfErrors 0 assoc
  StrCpy $checkbox_value ${BST_CHECKED}
  assoc:
  ;MessageBox MB_OK $checkbox_value
  ${If} $checkbox_value == ${BST_CHECKED}
    !insertmacro APP_ASSOCIATE "torrent" "stremio" "BitTorrent file" "$INSTDIR\stremio.exe,0" "Play with Stremio" "$INSTDIR\stremio.exe $\"%1$\""
	${EndIf}
Functionend

!macro checkIfAppIsRunning AppIsRunningErrorMsg
    ; Check if stremio.exe is running
    ${nsProcess::FindProcess} ${APP_LAUNCHER} $R0

    ${If} $R0 == 0
        IfSilent killapp
        MessageBox MB_YESNO|MB_ICONQUESTION "$(appIsRunning)" IDYES killapp
        ; Check if stremio.exe is still running.
        ; No need to abort if the user manually closes Stremio and answer NO on the prompt
        ${nsProcess::FindProcess} ${APP_LAUNCHER} $R0
        ${If} $R0 == 0
            ; Hide the progress bar
            FindWindow $0 "#32770" "" $HWNDPARENT
            GetDlgItem $1 $0 0x3ec
            ShowWindow $1 ${SW_HIDE}
            ; Abort install
            Abort "${AppIsRunningErrorMsg}"
        ${EndIf}
        killapp:
        ${nsProcess::CloseProcess} "${APP_LAUNCHER}" $R0
        Sleep 2000
    ${EndIf}

    ${nsProcess::Unload}
!macroend

; ------------------- ;
;    Install code     ;
; ------------------- ;
Function .onInit ; check for previous version
    ReadRegStr $0 HKCU "${UNINSTALL_KEY}" "InstallString"
    StrCmp $0 "" done
    StrCpy $INSTDIR $0

    ${GetParameters} $Parameters
    ClearErrors
    ${GetOptions} $Parameters "/addon" $R1

    FileOpen $0 "$INSTDIR\addons.txt" w
    FileWrite $0 "$R1"
    FileClose $0
done:
FunctionEnd

Section ; App Files
    !insertmacro checkIfAppIsRunning "$(appIsRunningInstallError)"

    ; Hide details
    SetDetailsPrint None

    ;Set output path to InstallDir
    SetOutPath "$INSTDIR"

    ;Add the files
    File /r "..\..\dist-win\*"

    ;Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

; ------------------- ;
;      Shortcuts      ;
; ------------------- ;
Section ; Shortcuts
    ; Hide details
    SetDetailsPrint none

    ;Working Directory
    SetOutPath "$INSTDIR"

    ;Start Menu Shortcut
    RMDir /r "$SMPROGRAMS\${APP_NAME}"
    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\stremio.exe" "" "$INSTDIR\stremio.exe" "" "" "" "${APP_NAME} ${PRODUCT_VERSION}"
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME} web.lnk" "$INSTDIR\stremio web.bat" "" "$INSTDIR\stremio web.bat" "" "" "" "${APP_NAME} ${PRODUCT_VERSION}"
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\stremio.exe" "" "" "" "Uninstall ${APP_NAME}"

    ;Desktop Shortcut
    Delete "$DESKTOP\${APP_NAME}.lnk"

    ;Add/remove programs uninstall entry
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "EstimatedSize" "$0"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\stremio.exe"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "${COMPANY_NAME}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallString" "$INSTDIR"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "URLInfoAbout" "${APP_URL}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "NoModify" 1
    WriteRegStr HKCU "${UNINSTALL_KEY}" "NoRepair" 1

    ;File association
    ; WARNING: doesn't work
    ; !insertmacro APP_ASSOCIATE "torrent" "stremio" "BitTorrent file" "$INSTDIR\stremio.exe,0" "Play with Stremio" "$INSTDIR\stremio.exe $\"%1$\""
    ; !insertmacro UPDATEFILEASSOC

    ; Register stremio:// protocol handler
    WriteRegStr HKCU "Software\Classes\stremio" "" "URL:Stremio Protocol"
    WriteRegStr HKCU "Software\Classes\stremio" "URL Protocol" ""
    WriteRegStr HKCU "Software\Classes\stremio\DefaultIcon" "" "$INSTDIR\stremio.exe,1"
    WriteRegStr HKCU "Software\Classes\stremio\shell" "" "open"
    WriteRegStr HKCU "Software\Classes\stremio\shell\open\command" "" '"$INSTDIR\stremio.exe" "%1"'

    ; Register magnet:// protocol handler
    WriteRegStr HKCU "Software\Classes\magnet" "" "URL:BitTorrent magnet"
    WriteRegStr HKCU "Software\Classes\magnet" "URL Protocol" ""
    WriteRegStr HKCU "Software\Classes\magnet\DefaultIcon" "" "$INSTDIR\stremio.exe,1"
    WriteRegStr HKCU "Software\Classes\magnet\shell" "" "open"
    WriteRegStr HKCU "Software\Classes\magnet\shell\open\command" "" '"$INSTDIR\stremio.exe" "%1"'
    IfSilent 0 end
    Call fin_pg_leave
    ${GetOptions} $Parameters /nodesktopicon $R1
    IfErrors 0 end
    Call finishpageaction
    end:
SectionEnd

; ------------------- ;
;     Uninstaller     ;
; ------------------- ;
Section "uninstall"
    !insertmacro checkIfAppIsRunning "$(appIsRunningUninstallError)"

    SetDetailsPrint none

    RMDir /r "$INSTDIR"
    RMDir /r "$SMPROGRAMS\${APP_NAME}"
    Delete "$DESKTOP\${APP_NAME}.lnk"

    DeleteRegKey HKCU "${UNINSTALL_KEY}"
    DeleteRegKey HKCU Software\Classes\stremio
    DeleteRegKey HKCU Software\Classes\magnet

    !insertmacro APP_UNASSOCIATE "torrent" "stremio"

    IfSilent +3
    MessageBox MB_YESNO|MB_ICONQUESTION "$(removeDataFolder)" IDNO KeepUserData
    goto notsilent
    ${GetParameters} $Parameters
    ClearErrors
    ${GetOptions} $Parameters "/keepdata" $R1
    IfErrors 0 KeepUserData
    notsilent:
      RMDir /r "$LOCALAPPDATA\${COMPANY_NAME}"
      RMDir /r "$APPDATA\${DATA_FOLDER}"
    KeepUserData:

    IfSilent +2
    ExecShell "open" "http://www.strem.io/goodbye"
SectionEnd

; ------------------- ;
;  Check if writable  ;
; ------------------- ;
Function IsWritable

  !define IsWritable `!insertmacro IsWritableCall`
 
  !macro IsWritableCall _PATH _RESULT
    Push `${_PATH}`
    Call IsWritable
    Pop ${_RESULT}
  !macroend
 
  Exch $R0
  Push $R1
 
start:
  StrLen $R1 $R0
  StrCmp $R1 0 exit
  ${GetFileAttributes} $R0 "DIRECTORY" $R1
  StrCmp $R1 1 direxists
  ${GetParent} $R0 $R0
  Goto start
 
direxists:
  ${GetFileAttributes} $R0 "DIRECTORY" $R1
  StrCmp $R1 0 ok

  StrCmp $R0 $PROGRAMFILES64 notok
  StrCmp $R0 $WINDIR notok

  ${GetFileAttributes} $R0 "READONLY" $R1

  Goto exit

notok:
  StrCpy $R1 1
  Goto exit

ok:
  StrCpy $R1 0
 
exit:
  Exch
  Pop $R0
  Exch $R1
 
FunctionEnd

; ------------------- ;
;  Check install dir  ;
; ------------------- ;
Function CloseBrowseForFolderDialog
	!ifmacrodef "_P<>" ; NSIS 3+
		System::Call 'USER32::GetActiveWindow()p.r0'
		${If} $0 P<> $HwndParent
	!else
		System::Call 'USER32::GetActiveWindow()i.r0'
		${If} $0 <> $HwndParent
	!endif
		SendMessage $0 ${WM_CLOSE} 0 0
		${EndIf}
FunctionEnd

Function .onVerifyInstDir

  Push $R1
  ${IsWritable} $INSTDIR $R1
  IntCmp $R1 0 pathgood
  Pop $R1
  Call CloseBrowseForFolderDialog
  MessageBox MB_OK|MB_USERICON "$(noRoot)" /SD IDOK
  Abort

pathgood:
  Pop $R1

FunctionEnd

; ------------------ ;
;  Desktop Shortcut  ;
; ------------------ ;
Function finishpageaction
    CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\stremio.exe" "" "$INSTDIR\stremio.exe" "" "" "" "${APP_NAME} ${PRODUCT_VERSION}"
FunctionEnd
