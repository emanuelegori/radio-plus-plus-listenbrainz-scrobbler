#!/usr/bin/env bash
set -euo pipefail

BIN_FILE="$HOME/.local/bin/radio-scrobbler"
LEGACY_BIN="$HOME/.local/bin/radio-listenbrainz-scrobbler.py"
SVC_FILE="$HOME/.config/systemd/user/radio-scrobbler.service"
CFG_DIR="$HOME/.config/radio-scrobbler"
CACHE_DIR="$HOME/.cache/radio-scrobbler"

RED=$'\e[31m'; YLW=$'\e[33m'; GRN=$'\e[32m'; CYA=$'\e[36m'; RST=$'\e[0m'
info() { echo "${CYA}[info]${RST} $*"; }
ok()   { echo "${GRN}[ ok ]${RST} $*"; }
warn() { echo "${YLW}[warn]${RST} $*"; }

info "Stopping and disabling service..."
systemctl --user disable --now radio-scrobbler.service 2>/dev/null || warn "Service was not active."
rm -f "$SVC_FILE"
systemctl --user daemon-reload
ok "Service unit removed."

rm -f "$BIN_FILE" "$LEGACY_BIN"
ok "Script(s) removed."

echo
read -r -p "Remove config ($CFG_DIR) and log cache ($CACHE_DIR) too? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy] ]]; then
    rm -rf "$CFG_DIR" "$CACHE_DIR"
    ok "Config and cache removed."
else
    info "Config and cache preserved. Delete manually with: rm -rf '$CFG_DIR' '$CACHE_DIR'"
fi

echo
ok "Uninstall done."
