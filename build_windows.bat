@echo off
cd /d %~dp0

SETLOCAL
FOR /F "skip=2 delims== tokens=2" %%i IN (stremio.pro) DO (
   set package_version=%%i
   goto :version_set
)
:version_set
SET BUILD_DIR=build

:: Set up VS environment
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x86

IF NOT EXIST "%BUILD_DIR%" mkdir "%BUILD_DIR%"
PUSHD "%BUILD_DIR%"

cmake -G"NMake Makefiles" -DCMAKE_BUILD_TYPE=Release ..
cmake --build .

POPD

rd /s/q dist-win
md dist-win

::copy "C:\Program Files (x86)\nodejs\node.exe" dist-win\stremio-runtime.exe
CALL windows\generate_stremio-runtime.cmd dist-win
powershell -Command Start-BitsTransfer -Source "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v%package_version%/server.js" -Destination .\dist-win\server.js; ((Get-Content -path .\dist-win\server.js -Raw) -replace 'os.tmpDir','os.tmpdir') ^| Set-Content -Path .\dist-win\server.js
copy build\*.exe dist-win
copy build\*.dll dist-win
copy windows\mpv-1.dll dist-win
copy windows\msvcr120.dll dist-win
copy windows\DS\* dist-win
copy C:\tools\ffmpeg.exe dist-win
copy C:\OpenSSL-Win32\bin\libcrypto-1_1.dll dist-win
::windeployqt --release --no-compiler-runtime --qmldir=. ./dist-win/stremio.exe

ENDLOCAL
