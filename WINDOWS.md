Building on Windows
===

Requirements
---

* Windows 7 or newer
* 7zip or another utility that supports extracting 7zip archives
* Git
* Microsoft Visual Studio
* CMake
* QT
* OpenSSL
* Node.js
* FFmpeg
* MPV

Setup
---

Download and install Git for Windows from here https://git-scm.com/download/win

Download and install Microsoft Visual Studio Community 2017 from here https://visualstudio.microsoft.com/vs/older-downloads/


Download and install QT 5.12.7 from here http://download.qt.io/official_releases/qt/5.12/5.12.7/qt-opensource-windows-x86-5.12.7.exe (I had to disconnect from the Internet in order to skip the account log in/registration). In the setup select QT version for **MSVC 2017 32 bit**. Also the **Qt WebEngine** component must be selected for installation.

Download and install **Win32 OpenSSL v1.1.1** from https://slproweb.com/products/Win32OpenSSL.html
The full version is required. The light version doesn't include all necessary files.

Download Node.js from here https://nodejs.org/dist/v8.17.0/win-x86/node.exe

Download FFmpeg from https://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-3.3.4-win32-static.zip
Other version may also work.

The MPV library is obtained from here https://sourceforge.net/projects/mpv-player-windows/files/libmpv/ We use `mpv-dev-i686` version. For convenience it is already in the windows directory of the project

Open command prompt and run the following commands:

Clone the repository

		git clone --recursive git@github.com:Stremio/stremio-shell.git
		cd stremio-shell

Add QT and OpenSSL to the system Path

		set PATH=C:\Qt\Qt5.15.2\5.15.2\msvc2019\bin;C:\OpenSSL-Win32\bin;%PATH%

Setup the environment

    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars32.bat"
		FOR /F "usebackq delims== tokens=2" %i IN (`type stremio.pro ^| find "VERSION=4"`) DO set package_version=%i

Download server.js

		powershell -Command Start-BitsTransfer -Source "https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v%package_version%/server.js" -Destination server.js


Build the shell

    cmake -G"NMake Makefiles" -DCMAKE_BUILD_TYPE=Release ..
    cmake --build .

Now create new folder where we will put the final product and copy there the required files:

		mkdir dist-win
		copy release\stremio.exe dist-win\
		copy windows\msvcr120.dll dist-win\
		copy windows\mpv-1.dll dist-win\
		copy windows\DS\* dist-win\
		copy server.js dist-win\
		copy C:\OpenSSL-Win32\bin\libcrypto-1_1.dll dist-win\

You need to also put the following previously downloaded files in the dist-win folder:

 * node.exe
 * ffmpeg.exe from the ffmpeg-3.3.4-win32-static.zip

 The last step is do deploy the QT dependencies:

		windeployqt --qmldir . dist-win\stremio.exe

Now inside the dist-win folder should be located all necessary files for the shell to work.

Installer (optional)
---

Download NSIS from here https://nsis.sourceforge.io/Download and install it. The default installation path is `C:\Program Files (x86)\NSIS`

WARNING: Before packing the application make sure it behaves as expected.

If you build the installer in another command prompt or at latter time you need to set again the `package_version` environment variable as it is required by the installer script. To generate it you can run the following commands from the root directory of the stremio-shell repository:

		FOR /F "usebackq delims== tokens=2" %i IN (`type stremio.pro ^| find "VERSION=4"`) DO set package_version=%i
		"C:\Program Files (x86)\NSIS\makensis.exe" windows\installer\windows-installer.nsi

This will generate `Stremio %package_version%.exe` - the Stremio installer where `%package_version%` is the current Stremio version.

The Stremio installer silent mode
--

By default the installer has GUI but you can run it in silent mode with the `/S` argument (case sensitive). When in silent mode it supports some additional configuration via command line arguments as follows:

		/notorrentassoc - does not associate Stremio with .torrent files
		/nodesktopicon - does not create Desktop shortcut for Stremio

The default behavior is the opposite of what the arguments do.


Once installed Stremio is located in `%LOCALAPPDATA%\Programs\LNV\Stremio-4\` directory. The uninstaller also have a silent mode when `/S` argument is present. By default everything is removed. If silent uninstall is required but the user's data have to be kept the uninstaller can be called like this:

	"%LOCALAPPDATA%\Programs\LNV\Stremio-4\Uninstall.exe" /S /keepdata

