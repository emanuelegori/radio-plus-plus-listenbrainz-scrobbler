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

_lang="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
if [[ "$_lang" == it* ]]; then LOCALE="it"; else LOCALE="en"; fi
t() { if [ "$LOCALE" = "it" ]; then echo "$2"; else echo "$1"; fi; }

info "$(t 'Stopping and disabling service...' \
     'Arresto e disabilitazione del servizio...')"
systemctl --user disable --now radio-scrobbler.service 2>/dev/null || \
    warn "$(t 'Service was not active.' 'Il servizio non era attivo.')"
rm -f "$SVC_FILE"
systemctl --user daemon-reload
ok "$(t 'Service unit removed.' 'Unit del servizio rimosso.')"

rm -f "$BIN_FILE" "$LEGACY_BIN"
ok "$(t 'Script(s) removed.' 'Script rimossi.')"

echo
read -r -p "$(t \
    "Remove config ($CFG_DIR) and log cache ($CACHE_DIR) too? [y/N] " \
    "Rimuovere anche il config ($CFG_DIR) e la cache dei log ($CACHE_DIR)? [y/N] ")" ans
if [[ "${ans:-N}" =~ ^[Yy] ]]; then
    rm -rf "$CFG_DIR" "$CACHE_DIR"
    ok "$(t 'Config and cache removed.' 'Config e cache rimossi.')"
else
    info "$(t \
        "Config and cache preserved. Delete manually with: rm -rf '$CFG_DIR' '$CACHE_DIR'" \
        "Config e cache preservati. Eliminali a mano con: rm -rf '$CFG_DIR' '$CACHE_DIR'")"
fi

echo
ok "$(t 'Uninstall done.' 'Disinstallazione completata.')"
