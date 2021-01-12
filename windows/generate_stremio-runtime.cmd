@echo off

:: Prepare paths and environment
set "rt_path=%~dpf1"
set rt_exe="%rt_path%\stremio-runtime.exe"

set rh="C:\RH\ResourceHacker.exe"

set node="C:\Program Files (x86)\nodejs\node.exe"

pushd %~dp0
pushd ..\images
set rt_icon="%cd%\stremio_gray.ico"
popd
popd

:: Check if all paths are correct
if not exist %rh% goto :norh
if not exist %node% goto :nonode
if not exist %rt_icon% goto :noico
if not exist "%rt_path%\" goto :nodir

:: Create temp dir
set "res_dir=%TEMP%\srres"
md "%res_dir%"

:: Copy node.exe to the temp dir and remove signature
copy %node% "%res_dir%\node.exe"
set node="%res_dir%\node.exe"
signtool remove /s %node%

:: Extract Node.js resources
%rh% -open %node% -save "%res_dir%\resources.rc" -action extract -mask ",,"

:: Replace desired resources
copy /D /Y %rt_icon% "%res_dir%\ICON1_1.ico"

set textFile="%res_dir%\resources.rc"
for /f "delims=" %%i in ('type "%textFile%" ^& break ^> "%textFile%" ') do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    set line=!line:Node.js=Stremio Runtime!
    >>"%textFile%" echo !line:node.exe=stremio-runtime.exe!
    endlocal
)

:: Compile new resource file
pushd "%res_dir%"
%rh% -open .\resources.rc -save .\stremio-rt.res -action compile
popd

:: Build the stremio-runtime executable
%rh% -open %node% -saveas %rt_exe% -action addoverwrite -res "%res_dir%\stremio-rt.res"

:: Cleanup
rd /S /Q "%res_dir%"
exit /b 0

:: Error states

:norh
echo ResourceHacker.exe not found at %rh%
exit /b 1

:nonode
echo Node.exe not found at %node%
exit /b 2

:noico
echo Icon file not found at %rt_icon%
exit /b 3

:nodir
echo Destination directory does not exists at %rt_path%
exit /b 4
