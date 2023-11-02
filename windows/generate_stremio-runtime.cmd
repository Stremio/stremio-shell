@echo off

:: Prepare paths and environment
set "rt_path=%~dpf1"
set rt_exe="%rt_path%\stremio-runtime.exe"

set rh="C:\RH\ResourceHacker.exe"

set node="C:\Program Files (x86)\nodejs\node.exe"

pushd %~dp0
set rcedit="%cd%\..\rcedit-x86.exe"
pushd ..\images
set rt_icon="%cd%\stremio_gray.ico"
popd
popd

:: Check if all paths are correct
if not exist %rcedit% goto :norcedit
if not exist %node% goto :nonode
if not exist %rt_icon% goto :noico
if not exist "%rt_path%\" goto :nodir

:: Copy node.exe to the dist dir and remove signature
copy %node% "%rt_exe%"
signtool remove /s %rt_exe%

:: Patch the exe
%rcedit% %rt_exe% ^
--set-icon %rt_icon% ^
--set-version-string "ProductName" "StremioRuntime" ^
--set-version-string "FileDescription" "Stremio Server JavaScript Runtime" ^
--set-version-string "OriginalFilename" "stremio-runtime.exe" ^
--set-version-string "InternalName" "stremio-runtime"
exit /b %errorlevel%

:: Error states

:norcedit
echo rcedit-x86.exe not found at %rcedit%
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
