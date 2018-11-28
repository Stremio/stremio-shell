SETLOCAL
SET VERSION=4.4.10
SET BUILD_DIR=build

:: Set up VS environment
CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86

IF NOT EXIST "%BUILD_DIR%" mkdir "%BUILD_DIR%"
PUSHD "%BUILD_DIR%"

qmake ..
nmake

IF NOT EXIST "server.js" powershell -Command "(New-Object Net.WebClient).DownloadFile('https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v%VERSION%/server.js', 'server.js')"

POPD
ENDLOCAL