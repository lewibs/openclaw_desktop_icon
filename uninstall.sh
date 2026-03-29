#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${OPENCLAW_BIN_DIR:-$HOME/.local/bin}"
APP_DIR="${OPENCLAW_DATA_HOME:-$HOME/.local/share}/applications"

LAUNCHER_DST="${BIN_DIR}/openclaw-chat-launcher.sh"
DESKTOP_DST="${APP_DIR}/openclaw-chat.desktop"
DESKTOP_COPY="${HOME}/Desktop/openclaw-chat.desktop"

rm -f "${LAUNCHER_DST}" "${DESKTOP_DST}"

if [[ -f "${DESKTOP_COPY}" ]]; then
  rm -f "${DESKTOP_COPY}"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${APP_DIR}" >/dev/null 2>&1 || true
fi

echo "Removed OpenClaw Chat launcher files."
