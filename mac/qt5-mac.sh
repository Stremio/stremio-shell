# credits to https://github.com/LRFLEW/OpenRCT2Launcher/blob/af9be273df102c6e4971c6600a8a260a9708d767/qt5-mac.sh

QT5_VERS=95
QT5_MAJOR=9
QT5_MINOR=5
QT5_PATCH=0

QT5_OSX_VERSION=10

if (( $# < 2 )); then
  echo "Usage: <destination> <component> [component...]"
  (( "$#" == 0 ))
  exit $?;
fi

# TODO: cache all those packages somewhere

QT_CACHE=${QT_CACHE:-/tmp}

for x in ${@:2}; do
  if [[ $x = http* ]]; then 
    DOWNLOAD_URL="$x"
  elif [[ $x = extra-* ]]; then
    DOWNLOAD_URL="https://download.qt.io/online/qtsdkrepository/mac_x64/desktop/qt5_5${QT5_VERS}/qt.5${QT5_VERS}.qt${x/#extra-/}.clang_64/5.${QT5_MAJOR}.${QT5_MINOR}-${QT5_PATCH}qt${x/#extra-/}-OSX-OSX_10_${QT5_OSX_VERSION}-Clang-OSX-OSX_10_${QT5_OSX_VERSION}-X86_64.7z"
  else
    DOWNLOAD_URL="https://download.qt.io/online/qtsdkrepository/mac_x64/desktop/qt5_5${QT5_VERS}/qt.5${QT5_VERS}.clang_64/5.${QT5_MAJOR}.${QT5_MINOR}-${QT5_PATCH}qt${x}-OSX-OSX_10_${QT5_OSX_VERSION}-Clang-OSX-OSX_10_${QT5_OSX_VERSION}-X86_64.7z"
  fi

  FILENAME=$(basename $DOWNLOAD_URL)

  if [[ -e $QT_CACHE/$FILENAME ]]; then
    echo "$FILENAME already downloaded, skipping" 1>&2
    7z x '-x!*debug' -aoa "-o$1" $QT_CACHE/$FILENAME 1>&2
    continue;
  fi
  
  DOWNLOAD_CHECK=$(curl -f ${DOWNLOAD_URL}.sha1 2>/dev/null)
  if [[ -z $DOWNLOAD_CHECK ]]; then
    echo "ERROR: Unknown package $x"
    exit 1
  fi
  
  wget -q "$DOWNLOAD_URL" -O $QT_CACHE/$FILENAME
  DOWNLOAD_HASH=$(shasum -a 1 $QT_CACHE/$FILENAME)
  if [[ $DOWNLOAD_HASH != $DOWNLOAD_HASH ]]; then
    echo "ERROR: Hash missmatch for $x" 1>&2
    exit 1
  fi
  
  7z x '-x!*debug' -aoa "-o$1" $QT_CACHE/$FILENAME 1>/dev/null
done

QT_PATH=$1/5.${QT5_MAJOR}.${QT5_MINOR}/clang_64

# Minimal Qt Configuration File
echo "[Paths]" > $QT_PATH/bin/qt.conf
echo "Prefix=.." >> $QT_PATH/bin/qt.conf

# Why does Qt default to Enterprise Licence?
sed -i "" -E 's/^[[:space:]]*QT_EDITION[[:space:]]*=.*$/QT_EDITION = OpenSource/' $QT_PATH/mkspecs/qconfig.pri

echo $QT_PATH/bin
