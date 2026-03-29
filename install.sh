#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use canonical per-user install locations by default.
# Some environments (e.g. snapped IDE terminals) override XDG vars to app-scoped
# paths that desktop shells do not use for launcher discovery.
BIN_DIR="${OPENCLAW_BIN_DIR:-$HOME/.local/bin}"
DATA_HOME="${OPENCLAW_DATA_HOME:-$HOME/.local/share}"
APP_DIR="${DATA_HOME}/applications"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/openclaw-chat"

LAUNCHER_SRC="${ROOT_DIR}/scripts/openclaw-chat-launcher.sh"
DESKTOP_TEMPLATE="${ROOT_DIR}/openclaw-chat.desktop"

LAUNCHER_DST="${BIN_DIR}/openclaw-chat-launcher.sh"
DESKTOP_DST="${APP_DIR}/openclaw-chat.desktop"

copy_to_desktop=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--copy-to-desktop]

Installs:
  - launcher script to ~/.local/bin/openclaw-chat-launcher.sh
  - desktop entry to ~/.local/share/applications/openclaw-chat.desktop

Options:
  --copy-to-desktop  Also copy .desktop file to ~/Desktop (if directory exists)
USAGE
}

for arg in "$@"; do
  case "${arg}" in
    --copy-to-desktop)
      copy_to_desktop=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "${arg}" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v sed >/dev/null 2>&1; then
  echo "sed is required but not found in PATH." >&2
  exit 1
fi

mkdir -p "${BIN_DIR}" "${APP_DIR}" "${STATE_DIR}"

install -m 0755 "${LAUNCHER_SRC}" "${LAUNCHER_DST}"

sed "s|__OPENCLAW_LAUNCHER_PATH__|${LAUNCHER_DST}|g" \
  "${DESKTOP_TEMPLATE}" > "${DESKTOP_DST}"
chmod 0644 "${DESKTOP_DST}"

if [[ "${copy_to_desktop}" -eq 1 ]]; then
  if [[ -d "${HOME}/Desktop" ]]; then
    cp "${DESKTOP_DST}" "${HOME}/Desktop/openclaw-chat.desktop"
    chmod +x "${HOME}/Desktop/openclaw-chat.desktop"
  else
    echo "Skipping desktop copy: ${HOME}/Desktop does not exist." >&2
  fi
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${APP_DIR}" >/dev/null 2>&1 || true
fi

cat <<EOF
Installed OpenClaw Chat launcher.

Launcher script:
  ${LAUNCHER_DST}

Desktop entry:
  ${DESKTOP_DST}

Run it from your application menu by searching for:
  OpenClaw Chat
EOF
