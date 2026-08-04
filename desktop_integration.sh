#!/usr/bin/env bash

# Integrate a Stremio source build with the current user's desktop.

set -Eeuo pipefail

readonly DESKTOP_FILENAME="stremio.desktop"
readonly SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly EXECUTABLE="${STREMIO_EXECUTABLE:-${SCRIPT_DIR}/build/stremio}"
readonly ICON_PATH="${STREMIO_ICON:-${SCRIPT_DIR}/images/stremio.svg}"

if [[ "${EXECUTABLE}" != /* ]]; then
  printf 'error: STREMIO_EXECUTABLE must be an absolute path\n' >&2
  exit 1
fi

if [[ "${ICON_PATH}" != /* ]]; then
  printf 'error: STREMIO_ICON must be an absolute path\n' >&2
  exit 1
fi

if [[ -n "${XDG_DATA_HOME:-}" ]]; then
  [[ "${XDG_DATA_HOME}" == /* ]] || {
    printf 'error: XDG_DATA_HOME must be an absolute path\n' >&2
    exit 1
  }
  readonly DATA_HOME="${XDG_DATA_HOME}"
elif [[ -n "${HOME:-}" ]]; then
  readonly DATA_HOME="${HOME}/.local/share"
else
  printf 'error: HOME is not set\n' >&2
  exit 1
fi

readonly APPLICATIONS_DIR="${DATA_HOME}/applications"
readonly DESKTOP_FILE="${APPLICATIONS_DIR}/${DESKTOP_FILENAME}"

TEMP_FILE=""

cleanup() {
  if [[ -n "${TEMP_FILE}" && -e "${TEMP_FILE}" ]]; then
    rm -f -- "${TEMP_FILE}"
  fi
}
trap cleanup EXIT

error() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Integrate a Stremio source build with the current user's desktop environment.

Usage:
  desktop_integration.sh --install    Install the Stremio desktop entry
  desktop_integration.sh --uninstall  Remove the Stremio desktop entry
  desktop_integration.sh --help       Show this help

By default, the entry starts build/stremio next to this script. Override it
with STREMIO_EXECUTABLE, for example /opt/stremio/stremio.

The entry is installed below XDG_DATA_HOME/applications, or
~/.local/share/applications when XDG_DATA_HOME is not set.
USAGE
}

refresh_desktop_database() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    if ! update-desktop-database --quiet "${APPLICATIONS_DIR}"; then
      printf 'warning: could not refresh the desktop-entry cache\n' >&2
    fi
  fi
}

# Escape characters that are reserved in a quoted Desktop Entry Exec value.
desktop_escape() {
  printf '%s' "$1" | sed 's/[\\$"`]/\\&/g'
}

write_desktop_entry() {
  local executable_escaped
  executable_escaped="$(desktop_escape "${EXECUTABLE}")"

  cat <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Stremio
GenericName=Video Organizer
Comment=Video organizer for movies, TV shows, and channels
Exec="${executable_escaped}" %U
Icon=${ICON_PATH}
Terminal=false
StartupNotify=true
StartupWMClass=stremio
Categories=AudioVideo;Video;Player;TV;
MimeType=application/x-bittorrent;x-scheme-handler/magnet;x-scheme-handler/stremio;video/avi;video/msvideo;video/x-msvideo;video/mp4;video/x-matroska;
EOF
}

install_desktop_entry() {
  [[ -x "${EXECUTABLE}" ]] || error "Stremio executable not found or not executable: ${EXECUTABLE}"
  [[ -f "${ICON_PATH}" ]] || error "Stremio icon not found: ${ICON_PATH}"

  mkdir -p -- "${APPLICATIONS_DIR}"
  TEMP_FILE="$(mktemp "${DESKTOP_FILE}.tmp.XXXXXX")" || error "could not create a temporary desktop entry"
  write_desktop_entry >"${TEMP_FILE}" || error "could not write the desktop entry"
  chmod 0644 "${TEMP_FILE}"
  mv -f -- "${TEMP_FILE}" "${DESKTOP_FILE}"
  TEMP_FILE=""

  refresh_desktop_database
  printf 'Installed Stremio desktop entry: %s\n' "${DESKTOP_FILE}"
}

uninstall_desktop_entry() {
  if [[ -e "${DESKTOP_FILE}" || -L "${DESKTOP_FILE}" ]]; then
    rm -f -- "${DESKTOP_FILE}"
    refresh_desktop_database
    printf 'Removed Stremio desktop entry: %s\n' "${DESKTOP_FILE}"
  else
    printf 'Stremio desktop entry is not installed: %s\n' "${DESKTOP_FILE}"
  fi
}

if [[ "$#" -ne 1 ]]; then
  usage
  [[ "$#" -eq 0 ]] && exit 0
  exit 1
fi

case "$1" in
  -i|--install)
    install_desktop_entry
    ;;
  -u|--uninstall)
    uninstall_desktop_entry
    ;;
  -h|--help)
    usage
    ;;
  *)
    printf 'error: unknown option: %s\n\n' "$1" >&2
    usage >&2
    exit 1
    ;;
esac
