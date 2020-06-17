Building on Windows
===

Requirements
---

* Windows 7 or newer
* 7zip or another utility that supports extracting 7zip archives
* Git
* Microsoft Visual Studio
* QT
* OpenSSL
* NodeJs
* FFmpeg
* MPV

Setup
---

Download and install Git for Windows from here https://git-scm.com/download/win

Download and install Microsoft Visual Studio Community 2017 from here https://visualstudio.microsoft.com/vs/older-downloads/


Download and install QT 5.12.7 from here http://download.qt.io/official_releases/qt/5.12/5.12.7/qt-opensource-windows-x86-5.12.7.exe (I had to disconnect from the Internet in order to skip the account log in/registration). In the setup select QT version for **MSVC 2017 32 bit**. Also the **Qt WebEngine** component must be selected for installation.

Download and install **Win32 OpenSSL v1.1.0** from https://slproweb.com/products/Win32OpenSSL.html
The full version is required. The light version doesn't include all necessary files.

Download NodeJs from here https://nodejs.org/dist/v8.17.0/win-x86/node.exe

Download FFmpeg from https://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-3.3.4-win32-static.zip
Other version may also work.

Download MPV from here https://sourceforge.net/projects/mpv-player-windows/files/libmpv/ We need `mpv-dev-i686` version. Stremio is tested to work with mpv-dev-i686-20200610-git-c7fe4ae.7z

Download stremio-server from here https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/v4.4.116/server.js where v4.4.116 is the shell version.

Open command prompt and run the following commands:

Clone the repository

		git clone --recursive git@github.com:Stremio/stremio-shell.git
		cd stremio-shell

Add QT and OpenSSL to the system Path

		set PATH=C:\Qt\Qt5.12.7\5.12.7\msvc2017\bin;C:\OpenSSL-Win32\bin;%PATH%

Setup the environment

		"C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x86

Build the shell

		qmake .
		nmake

Now create new folder where we will put the final product:

		mkdir stremio-windows
		copy release\stremio.exe stremio-windows\
		copy C:\Windows\System32\msvcr120.dll stremio-windows\
		copy C:\OpenSSL-Win32\bin\libcrypto-1_1.dll stremio-windows\

You need to also put the following previously downloaded files in the stremio-windows folder:

 * node.exe
 * ffmpeg.exe from the ffmpeg-3.3.4-win32-static.zip
 * mpv-1.dll from the mpv-dev-i686 archive
 * server.js

 The last step is do deploy the QT dependencies:

		windeployqt --qmldir . stremio-windows\stremio.exe

Now inside the stremio-windows folder should be located all necessary files for the shell to work.