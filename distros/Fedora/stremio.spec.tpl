Name:           stremio
Version:        PKG_VER
Release:        1%{?dist}
Summary:        Stremio is a one-stop hub for video content aggregation. Discover, organize and watch video from all kind of sources on any device that you own.
License:        MIT

URL:            https://www.stremio.com
Source0:        https://github.com/Stremio/stremio-shell/archive/master.zip

BuildRequires: cmake
BuildRequires: qt-devel
BuildRequires: librsvg2-tools
BuildRequires: qt5-qtwebengine-devel
BuildRequires: openssl-devel
BuildRequires: mpv-libs-devel
 
Requires:       nodejs
Requires:       qt5-qtwebchannel
Requires:       qt5-qtwebengine 
Requires:       qt5-qtquickcontrols
Requires:       qt5-qtquickcontrols2

%description

%global debug_package %{nil}

%prep
%autosetup -n stremio-shell-master

git init
git remote add origin https://github.com/Stremio/stremio-shell.git
git fetch --all
git reset --hard origin/master
if [ -n "$BRANCH" ]; then
        git checkout "$BRANCH"
fi
git submodule update --init
make -f release.makefile clean


%build
make -f release.makefile PREFIX="%{buildroot}"


%install
make -f release.makefile PREFIX="%{buildroot}" install


%files
/opt/stremio


%post


%preun
test $1 = 0 || exit 0


%changelog
* Wed Oct 24 2018 Vladimir Borisov
- 
