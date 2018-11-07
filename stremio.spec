Name:           stremio
Version:        4.4.10
Release:        1%{?dist}
Summary:        Stremio is a one-stop hub for video content aggregation. Discover, organize and watch video from all kind of sources on any device that you own.
License:        MIT

URL:            https://www.stremio.com
Source0:        https://github.com/Stremio/stremio-shell/archive/debian.zip

BuildRequires: qt5-devel
BuildRequires: ImageMagick
BuildRequires: qt5-qtwebengine-devel
BuildRequires: openssl-devel
BuildRequires: mpv-libs-devel
 
Requires:       nodejs
Requires:       qt5-qtwebchannel
Requires:       qt5-qtwebengine 
Requires:       qt5-qtquickcontrols
Requires:       qt5-qtquickcontrols2

%description
The next generation media center

%global debug_package %{nil}

%prep
%autosetup -n stremio-shell-debian

git init
git remote add origin https://github.com/Stremio/stremio-shell.git
git fetch --all
git reset --hard origin/debian
git checkout debian
git submodule update --init
make -f release.makefile clean


%build
sed -i 's/qmake /qmake-qt5 /g' release.makefile
make -f release.makefile PREFIX="%{buildroot}"


%install
make -f release.makefile PREFIX="%{buildroot}" install


%files
/opt/stremio


%post
ln -s /opt/stremio/stremio /usr/bin/stremio

xdg-desktop-menu install --mode system /opt/stremio/smartcode-stremio.desktop

cd /opt/stremio/icons || exit 1
regex="([^_]+)_([0-9]+).png$"
for file in *.png
do
	if [[ $file  =~ $regex ]]
	then
		icon="${BASH_REMATCH[1]##*/}"
		size="${BASH_REMATCH[2]}"
		xdg-icon-resource install --context apps --size "$size" "$file" "$icon"
	fi
done


$preun
test $1 = 0 || exit 0

rm -f /usr/bin/stremio

xdg-desktop-menu uninstall --mode system /opt/stremio/smartcode-stremio.desktop

cd /opt/stremio/icons || exit 1
regex="([^_]+)_([0-9]+).png$"
for file in *.png
do
	if [[ $file  =~ $regex ]]
	then
		icon="${BASH_REMATCH[1]##*/}"
		size="${BASH_REMATCH[2]}"
		xdg-icon-resource uninstall --context apps --size "$size" "$icon"
	fi
done


%changelog
* Wed Oct 24 2018 Vladimir Borisov
- 