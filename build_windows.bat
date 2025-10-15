@echo off
cd /d %~dp0

SETLOCAL
for /f delims^=^"^ tokens^=2 %%i IN ('type .\CMakeLists.txt ^| find "stremio VERSION"') DO (
   set package_version=%%i
)

SET BUILD_DIR=build

:: Set up VS environment
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x86

IF NOT EXIST "%BUILD_DIR%" mkdir "%BUILD_DIR%"
PUSHD "%BUILD_DIR%"

cmake -G"NMake Makefiles" -DCMAKE_BUILD_TYPE=Release ..
::exit /b
cmake --build .

POPD

rd /s/q dist-win
md dist-win

::copy "C:\Program Files (x86)\nodejs\node.exe" dist-win\stremio-runtime.exe
@REM CALL windows\generate_stremio-runtime.cmd dist-win
powershell -Command Start-BitsTransfer -Source "$(cat .\server-url.txt)" -Destination .\dist-win\server.js; ((Get-Content -path .\dist-win\server.js -Raw) -replace 'os.tmpDir','os.tmpdir') ^| Set-Content -Path .\dist-win\server.js
copy build\*.exe dist-win
copy windows\*.dll dist-win
copy windows\*.exe dist-win
copy windows\DS\* dist-win
copy c:\OpenSSL-Win32\bin\libcrypto-3.dll dist-win
windeployqt --release --no-compiler-runtime --qmldir=. ./dist-win/stremio.exe
"C:\Program Files (x86)\NSIS\makensis.exe" windows\installer\windows-installer.nsi
ENDLOCAL
