#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SVC_DIR="$HOME/.config/systemd/user"
CFG_DIR="$HOME/.config/radio-scrobbler"
CFG_FILE="$CFG_DIR/config.json"
BIN_FILE="$BIN_DIR/radio-scrobbler"
SVC_FILE="$SVC_DIR/radio-scrobbler.service"

RED=$'\e[31m'; YLW=$'\e[33m'; GRN=$'\e[32m'; CYA=$'\e[36m'; RST=$'\e[0m'
info() { echo "${CYA}[info]${RST} $*"; }
ok()   { echo "${GRN}[ ok ]${RST} $*"; }
warn() { echo "${YLW}[warn]${RST} $*"; }
die()  { echo "${RED}[fail]${RST} $*" >&2; exit 1; }

info "Checking prerequisites..."

command -v apt-get >/dev/null 2>&1 || die "apt-get not found: this installer targets Debian/Ubuntu-based distros."

if [ -r /etc/os-release ]; then
    . /etc/os-release
    ok "Distro: ${PRETTY_NAME:-unknown}"
fi

[ -d /usr/share/cinnamon ] || warn "Cinnamon not detected in /usr/share/cinnamon. The service will still install but may not autostart without a Cinnamon session."

APPLET_LOCAL="$HOME/.local/share/cinnamon/applets/radio@driglu4it"
APPLET_SYS="/usr/share/cinnamon/applets/radio@driglu4it"
if [ -d "$APPLET_LOCAL" ] || [ -d "$APPLET_SYS" ]; then
    ok "Radio++ applet (radio@driglu4it) found."
else
    die "Radio++ applet not found. Install it from Cinnamon Spices before running this installer."
fi

APPLET_CFG="$HOME/.config/cinnamon/spices/radio@driglu4it/radio@driglu4it.json"
if [ -f "$APPLET_CFG" ]; then
    ok "Applet config present: $APPLET_CFG"
else
    warn "Applet config not yet created. Open Radio++ settings once and add at least one station."
fi

missing=()
if ! command -v playerctl >/dev/null 2>&1; then missing+=(playerctl); fi
if ! command -v python3 >/dev/null 2>&1; then missing+=(python3); fi
if ! python3 -c 'import requests' >/dev/null 2>&1; then missing+=(python3-requests); fi

if [ ${#missing[@]} -gt 0 ]; then
    warn "Missing packages: ${missing[*]}"
    read -r -p "Install them with sudo apt-get? [Y/n] " ans
    if [[ "${ans:-Y}" =~ ^[Nn] ]]; then
        die "Required packages missing. Aborting."
    fi
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
    ok "Packages installed."
else
    ok "Required packages already present (playerctl, python3-requests)."
fi

systemctl --user is-system-running >/dev/null 2>&1 || warn "systemd --user is not fully running. The service will be enabled anyway and should start at next login."

info "Installing files..."
mkdir -p "$BIN_DIR" "$SVC_DIR" "$CFG_DIR"
install -m 755 "$SCRIPT_DIR/radio-scrobbler" "$BIN_FILE"
install -m 644 "$SCRIPT_DIR/radio-scrobbler.service" "$SVC_FILE"
ok "Script:  $BIN_FILE"
ok "Service: $SVC_FILE"

if [ -f "$BIN_DIR/radio-listenbrainz-scrobbler.py" ]; then
    warn "Legacy script found: removing $BIN_DIR/radio-listenbrainz-scrobbler.py"
    rm -f "$BIN_DIR/radio-listenbrainz-scrobbler.py"
fi

if [ ! -f "$CFG_FILE" ]; then
    install -m 600 "$SCRIPT_DIR/config.default.json" "$CFG_FILE"
    ok "Config created: $CFG_FILE"
else
    ok "Config kept: $CFG_FILE"
fi

TOKEN_PRESENT=$(python3 -c "
import json, sys
try:
    d = json.load(open('$CFG_FILE'))
    print('1' if d.get('listenbrainz_token') else '0')
except Exception:
    print('0')
")

if [ "$TOKEN_PRESENT" != "1" ]; then
    echo
    info "ListenBrainz user token required."
    info "Get it from: https://listenbrainz.org/settings/   (field: User token)"
    read -r -s -p "Paste your token (hidden input): " token
    echo
    [ -n "$token" ] || die "Empty token. Aborting."
    LB_TOKEN="$token" CFG="$CFG_FILE" python3 - <<'PY'
import json, os
p = os.environ["CFG"]
d = json.load(open(p))
d["listenbrainz_token"] = os.environ["LB_TOKEN"]
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
PY
    chmod 600 "$CFG_FILE"
    ok "Token saved to $CFG_FILE (chmod 600)."
else
    ok "Token already present in config, keeping it."
fi

info "Enabling systemd user service..."
systemctl --user daemon-reload
systemctl --user enable --now radio-scrobbler.service
sleep 1
systemctl --user --no-pager --quiet is-active radio-scrobbler.service \
    && ok "radio-scrobbler.service is active." \
    || warn "Service not active yet. Check: journalctl --user -u radio-scrobbler -n 30"

echo
ok "Install done."
echo
echo "The radio-scrobbler service is ACTIVE and will auto-start at every"
echo "login from now on. Nothing else to do: press play on a station in"
echo "Radio++ and the scrobbler will submit listens to ListenBrainz once"
echo "the stability threshold is reached."
echo
echo "Keep the folder \"$(basename "$SCRIPT_DIR")\": it is used for"
echo "'./uninstall.sh' and for 'git pull && ./install.sh' to update."
echo "You do NOT need to delete it."
echo
echo "All the commands below work from ANY terminal, in ANY directory:"
echo
echo "  radio-scrobbler --about       # author, license, repo links"
echo "  radio-scrobbler --version"
echo "  radio-scrobbler --check       # service + config + MPRIS diagnostics"
echo
echo "  systemctl --user status  radio-scrobbler"
echo "  systemctl --user start   radio-scrobbler"
echo "  systemctl --user stop    radio-scrobbler"
echo "  systemctl --user restart radio-scrobbler"
echo
echo "  journalctl --user -u radio-scrobbler -f   # follow live logs"
echo
echo "Config:  $CFG_FILE"
echo "Log:     $HOME/.cache/radio-scrobbler/scrobbler.log"
echo
echo "If 'radio-scrobbler --version' returns 'command not found',"
echo "run 'cd ~' and retry (or open a new terminal)."
