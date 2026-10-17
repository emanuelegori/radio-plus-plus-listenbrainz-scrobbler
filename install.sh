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

_lang="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
if [[ "$_lang" == it* ]]; then LOCALE="it"; else LOCALE="en"; fi
t() { if [ "$LOCALE" = "it" ]; then echo "$2"; else echo "$1"; fi; }

info "$(t 'Checking prerequisites...' 'Verifica dei prerequisiti...')"

command -v apt-get >/dev/null 2>&1 || die "$(t \
    'apt-get not found: this installer targets Debian/Ubuntu-based distros.' \
    'apt-get non trovato: questo installer è per distribuzioni Debian/Ubuntu.')"

if [ -r /etc/os-release ]; then
    . /etc/os-release
    ok "$(t "Distro: ${PRETTY_NAME:-unknown}" "Distribuzione: ${PRETTY_NAME:-sconosciuta}")"
fi

[ -d /usr/share/cinnamon ] || warn "$(t \
    'Cinnamon not detected in /usr/share/cinnamon. The service will still install but may not autostart without a Cinnamon session.' \
    'Cinnamon non rilevato in /usr/share/cinnamon. Il servizio verrà comunque installato ma potrebbe non partire in automatico senza una sessione Cinnamon.')"

APPLET_LOCAL="$HOME/.local/share/cinnamon/applets/radio@driglu4it"
APPLET_SYS="/usr/share/cinnamon/applets/radio@driglu4it"
if [ -d "$APPLET_LOCAL" ] || [ -d "$APPLET_SYS" ]; then
    ok "$(t 'Radio++ applet (radio@driglu4it) found.' \
         'Applet Radio++ (radio@driglu4it) trovata.')"
else
    die "$(t \
        'Radio++ applet not found. Install it from Cinnamon Spices before running this installer.' \
        'Applet Radio++ non trovata. Installala da Cinnamon Spices prima di eseguire questo installer.')"
fi

APPLET_CFG="$HOME/.config/cinnamon/spices/radio@driglu4it/radio@driglu4it.json"
if [ -f "$APPLET_CFG" ]; then
    ok "$(t "Applet config present: $APPLET_CFG" \
         "Config applet presente: $APPLET_CFG")"
else
    warn "$(t \
        'Applet config not yet created. Open Radio++ settings once and add at least one station.' \
        'Config applet non ancora creato. Apri le impostazioni di Radio++ e aggiungi almeno una stazione.')"
fi

missing=()
if ! command -v playerctl >/dev/null 2>&1; then missing+=(playerctl); fi
if ! command -v python3 >/dev/null 2>&1; then missing+=(python3); fi
if ! python3 -c 'import requests' >/dev/null 2>&1; then missing+=(python3-requests); fi

if [ ${#missing[@]} -gt 0 ]; then
    warn "$(t "Missing packages: ${missing[*]}" "Pacchetti mancanti: ${missing[*]}")"
    read -r -p "$(t 'Install them with sudo apt-get? [Y/n] ' 'Installarli con sudo apt-get? [Y/n] ')" ans
    if [[ "${ans:-Y}" =~ ^[Nn] ]]; then
        die "$(t 'Required packages missing. Aborting.' \
             'Pacchetti richiesti mancanti. Installazione annullata.')"
    fi
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
    ok "$(t 'Packages installed.' 'Pacchetti installati.')"
else
    ok "$(t 'Required packages already present (playerctl, python3-requests).' \
         'Pacchetti richiesti già presenti (playerctl, python3-requests).')"
fi

systemctl --user is-system-running >/dev/null 2>&1 || warn "$(t \
    'systemd --user is not fully running. The service will be enabled anyway and should start at next login.' \
    'systemd --user non è completamente attivo. Il servizio verrà comunque abilitato e dovrebbe partire al prossimo login.')"

info "$(t 'Installing files...' 'Installazione dei file...')"
mkdir -p "$BIN_DIR" "$SVC_DIR" "$CFG_DIR"
install -m 755 "$SCRIPT_DIR/radio-scrobbler" "$BIN_FILE"
install -m 644 "$SCRIPT_DIR/radio-scrobbler.service" "$SVC_FILE"
ok "$(t "Script:  $BIN_FILE" "Script:   $BIN_FILE")"
ok "$(t "Service: $SVC_FILE" "Servizio: $SVC_FILE")"

if [ -f "$BIN_DIR/radio-listenbrainz-scrobbler.py" ]; then
    warn "$(t "Legacy script found: removing $BIN_DIR/radio-listenbrainz-scrobbler.py" \
         "Script legacy trovato: rimozione di $BIN_DIR/radio-listenbrainz-scrobbler.py")"
    rm -f "$BIN_DIR/radio-listenbrainz-scrobbler.py"
fi

if [ ! -f "$CFG_FILE" ]; then
    install -m 600 "$SCRIPT_DIR/config.default.json" "$CFG_FILE"
    ok "$(t "Config created: $CFG_FILE" "Config creato: $CFG_FILE")"
else
    ok "$(t "Config kept: $CFG_FILE" "Config esistente mantenuto: $CFG_FILE")"
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
    if [ "$LOCALE" = "it" ]; then
        info "Serve il token utente di ListenBrainz."
        info "Ottienilo da: https://listenbrainz.org/settings/   (campo: User token)"
        read -r -s -p "Incolla il tuo token (input nascosto): " token
    else
        info "ListenBrainz user token required."
        info "Get it from: https://listenbrainz.org/settings/   (field: User token)"
        read -r -s -p "Paste your token (hidden input): " token
    fi
    echo
    [ -n "$token" ] || die "$(t 'Empty token. Aborting.' \
         'Token vuoto. Installazione annullata.')"
    LB_TOKEN="$token" CFG="$CFG_FILE" python3 - <<'PY'
import json, os
p = os.environ["CFG"]
d = json.load(open(p))
d["listenbrainz_token"] = os.environ["LB_TOKEN"]
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
PY
    chmod 600 "$CFG_FILE"
    ok "$(t "Token saved to $CFG_FILE (chmod 600)." \
         "Token salvato in $CFG_FILE (chmod 600).")"
else
    ok "$(t 'Token already present in config, keeping it.' \
         'Token già presente nel config, lo mantengo.')"
fi

info "$(t 'Enabling systemd user service...' \
     'Abilitazione del servizio systemd utente...')"
systemctl --user daemon-reload
systemctl --user enable --now radio-scrobbler.service
sleep 1
if systemctl --user --no-pager --quiet is-active radio-scrobbler.service; then
    ok "$(t 'radio-scrobbler.service is active.' \
         'radio-scrobbler.service è attivo.')"
else
    warn "$(t 'Service not active yet. Check: journalctl --user -u radio-scrobbler -n 30' \
         'Servizio non ancora attivo. Verifica con: journalctl --user -u radio-scrobbler -n 30')"
fi

echo
ok "$(t 'Install done.' 'Installazione completata.')"
echo

if [ "$LOCALE" = "it" ]; then
    cat <<EOF
Il servizio radio-scrobbler è ATTIVO e verrà avviato automaticamente a
ogni login. Non devi fare altro: premi play su una stazione in Radio++
e lo scrobbler invierà gli ascolti a ListenBrainz al raggiungimento
della soglia di stabilità.

Tieni la cartella "$(basename "$SCRIPT_DIR")": serve per
'./uninstall.sh' e per 'git pull && ./install.sh' per aggiornare.
Non è necessario eliminarla.

Tutti i comandi qui sotto funzionano da QUALUNQUE terminale, in
QUALUNQUE directory:

  radio-scrobbler --about       # autore, licenza, link ai repo
  radio-scrobbler --version
  radio-scrobbler --check       # diagnostica service + config + MPRIS

  systemctl --user status  radio-scrobbler
  systemctl --user start   radio-scrobbler
  systemctl --user stop    radio-scrobbler
  systemctl --user restart radio-scrobbler

  journalctl --user -u radio-scrobbler -f   # segui i log in diretta

Config: $CFG_FILE
Log:    $HOME/.cache/radio-scrobbler/scrobbler.log

Se 'radio-scrobbler --version' risponde 'command not found',
esegui 'cd ~' e riprova (oppure apri un nuovo terminale).
EOF
else
    cat <<EOF
The radio-scrobbler service is ACTIVE and will auto-start at every
login from now on. Nothing else to do: press play on a station in
Radio++ and the scrobbler will submit listens to ListenBrainz once
the stability threshold is reached.

Keep the folder "$(basename "$SCRIPT_DIR")": it is used for
'./uninstall.sh' and for 'git pull && ./install.sh' to update.
You do NOT need to delete it.

All the commands below work from ANY terminal, in ANY directory:

  radio-scrobbler --about       # author, license, repo links
  radio-scrobbler --version
  radio-scrobbler --check       # service + config + MPRIS diagnostics

  systemctl --user status  radio-scrobbler
  systemctl --user start   radio-scrobbler
  systemctl --user stop    radio-scrobbler
  systemctl --user restart radio-scrobbler

  journalctl --user -u radio-scrobbler -f   # follow live logs

Config: $CFG_FILE
Log:    $HOME/.cache/radio-scrobbler/scrobbler.log

If 'radio-scrobbler --version' returns 'command not found',
run 'cd ~' and retry (or open a new terminal).
EOF
fi
