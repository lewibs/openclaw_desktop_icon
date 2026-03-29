#!/usr/bin/env bash
set -euo pipefail

# Minimal launcher behavior:
# 1) Reuse running OpenClaw gateway when healthy.
# 2) Start gateway if needed.
# 3) Open OpenClaw chat UI in the browser.

OPENCLAW_BIN="${OPENCLAW_BIN:-openclaw}"
WAIT_SECONDS="${OPENCLAW_WAIT_SECONDS:-20}"
SLEEP_SECONDS=1
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/openclaw-chat"
LOG_FILE="${STATE_DIR}/launcher.log"

notify() {
  local msg="$1"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "OpenClaw Chat" "${msg}" || true
  fi
}

log() {
  printf '[openclaw-chat] %s\n' "$*" >&2
}

resolve_openclaw_bin() {
  local path_lookup
  local candidate

  if [[ -x "${OPENCLAW_BIN}" ]]; then
    return 0
  fi

  path_lookup="$(command -v "${OPENCLAW_BIN}" 2>/dev/null || true)"
  if [[ -n "${path_lookup}" && -x "${path_lookup}" ]]; then
    OPENCLAW_BIN="${path_lookup}"
    return 0
  fi

  for candidate in \
    "$HOME/.local/bin/openclaw" \
    "/usr/local/bin/openclaw" \
    "/usr/bin/openclaw"; do
    if [[ -x "${candidate}" ]]; then
      OPENCLAW_BIN="${candidate}"
      return 0
    fi
  done

  # Handle NVM installs when desktop PATH does not include ~/.nvm/.../bin.
  shopt -s nullglob
  for candidate in "$HOME"/.nvm/versions/node/*/bin/openclaw; do
    if [[ -x "${candidate}" ]]; then
      OPENCLAW_BIN="${candidate}"
      shopt -u nullglob
      return 0
    fi
  done
  shopt -u nullglob

  return 1
}

gateway_healthy() {
  "${OPENCLAW_BIN}" gateway status --require-rpc >/dev/null 2>&1
}

start_gateway() {
  log "Gateway not healthy; attempting managed gateway start."
  if "${OPENCLAW_BIN}" gateway start >/dev/null 2>&1; then
    return 0
  fi

  log "Managed gateway start did not succeed; attempting foreground gateway fallback."
  nohup "${OPENCLAW_BIN}" gateway run --allow-unconfigured \
    >>"${XDG_STATE_HOME:-$HOME/.local/state}/openclaw-chat/launcher.log" 2>&1 &
}

wait_for_gateway() {
  local i
  for ((i = 0; i < WAIT_SECONDS; i += SLEEP_SECONDS)); do
    if gateway_healthy; then
      return 0
    fi
    sleep "${SLEEP_SECONDS}"
  done
  return 1
}

open_dashboard() {
  # `openclaw dashboard` opens the Control UI in the default browser.
  "${OPENCLAW_BIN}" dashboard >/dev/null 2>&1
}

main() {
  mkdir -p "${STATE_DIR}"
  exec >>"${LOG_FILE}" 2>&1

  log "Launcher invoked."
  log "Current PATH: ${PATH}"

  if ! resolve_openclaw_bin; then
    log "openclaw CLI is not installed or not discoverable from desktop environment."
    notify "OpenClaw CLI not found. See ${LOG_FILE}"
    exit 1
  fi

  log "Using openclaw binary: ${OPENCLAW_BIN}"

  if ! gateway_healthy; then
    start_gateway
    if ! wait_for_gateway; then
      log "Gateway failed to become healthy within ${WAIT_SECONDS}s."
      notify "Gateway failed to start. See ${LOG_FILE}"
      exit 1
    fi
  fi

  if ! open_dashboard; then
    log "Failed to open OpenClaw dashboard."
    notify "Failed to open OpenClaw dashboard. See ${LOG_FILE}"
    exit 1
  fi

  log "Dashboard launch request completed."
}

main "$@"
