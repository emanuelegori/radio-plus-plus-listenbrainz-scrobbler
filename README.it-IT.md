# radio-plus-plus-listenbrainz-scrobbler

**Italiano** • [English](./README.md)

Scrobbler verso ListenBrainz per l'applet Cinnamon
[Radio++](https://cinnamon-spices.linuxmint.com/applets/view/280)
(`radio@driglu4it`). Gira come servizio `systemd --user`, legge i
metadati ICY esposti da `mpv` tramite MPRIS, arricchisce con MusicBrainz
quando possibile e invia gli ascolti a
[ListenBrainz](https://listenbrainz.org/).

- Autore: Emanuele Gori
- Licenza: GPL-3.0-or-later
- Forgejo: <https://git.emanuelegori.uno/emanuelegori/radio-plus-plus-listenbrainz-scrobbler>
- Mirror GitHub: <https://github.com/emanuelegori/radio-plus-plus-listenbrainz-scrobbler>

---

## Caratteristiche

- Completamente locale: nessun servizio terzo oltre a ListenBrainz e
  MusicBrainz.
- Lettura automatica dei nomi delle stazioni preferite dall'applet
  Radio++, con hot reload basato su mtime quando modifichi le preferite.
- Arricchimento MusicBrainz non bloccante: se trova un match forte
  aggiunge `recording_mbid`, `artist_mbids` e `release_mbid`; altrimenti
  invia l'ascolto con artist/title grezzi (importante per i brani
  assenti da MusicBrainz, come spesso capita per la musica italiana
  trasmessa in radio).
- Filtri anti pubblicità: blacklist di parole chiave configurabile
  (`pubblicit`, `advertisement`, `jingle`, `news`, `promo` eccetera),
  rimozione del nome stazione dal titolo e dall'artista, flag
  `require_separator`.
- Strumenti di diagnostica: `radio-scrobbler --check` e `--about`.

## Requisiti

- Distribuzione basata su Debian/Ubuntu con `apt-get`.
- Desktop Cinnamon con l'applet Radio++ (`radio@driglu4it`) installata e
  almeno una stazione preferita configurata.
- `playerctl`, `python3`, `python3-requests`.
- Istanza systemd utente (presente di default su Debian/Ubuntu moderni).
- Un account ListenBrainz e il token utente (da
  <https://listenbrainz.org/settings/>).

## Installazione

```bash
git clone https://git.emanuelegori.uno/emanuelegori/radio-plus-plus-listenbrainz-scrobbler.git
cd radio-plus-plus-listenbrainz-scrobbler
./install.sh
```

L'installer esegue:

1. Verifica di `apt-get`, Cinnamon, applet Radio++ e relativa
   configurazione.
2. Proposta di installare i pacchetti mancanti con `sudo apt-get`
   (`playerctl`, `python3-requests`).
3. Copia di `radio-scrobbler` in `~/.local/bin/` e del servizio in
   `~/.config/systemd/user/`.
4. Creazione di `~/.config/radio-scrobbler/config.json` dal template se
   non presente e richiesta del token ListenBrainz con input nascosto.
5. `systemctl --user daemon-reload` ed `enable --now`.

## Disinstallazione

```bash
./uninstall.sh
```

Ferma e disabilita il servizio, rimuove script e unit. Chiede se
eliminare anche le directory di configurazione e di log.

## Uso

```bash
radio-scrobbler --about     # autore, licenza, link ai repo
radio-scrobbler --version
radio-scrobbler --check     # diagnostica configurazione e MPRIS
```

Avvia l'applet, premi play su una stazione e segui i log:

```bash
journalctl --user -u radio-scrobbler -f
```

Significato delle righe principali:

| Riga | Significato |
|---|---|
| `New track: X — Y` | Rilevato cambio brano valido, inviato `playing_now`. |
| `Now playing sent: ...` | Aggiornato "sta ascoltando" sul profilo ListenBrainz. |
| `MB match: <uuid>` | MusicBrainz ha restituito un recording MBID. |
| **`Scrobbled: X — Y`** | **Ascolto inviato con successo** dopo la soglia di stabilità. |
| `Filtered: ...` | Brano scartato (blacklist, assenza di separatore, solo nome stazione). |
| `playing_now failed` / `scrobble failed` | Errore API ListenBrainz. |

## Configurazione

File: `~/.config/radio-scrobbler/config.json` (`chmod 600`).

| Chiave | Default | Descrizione |
|---|---|---|
| `listenbrainz_token` | `""` | Obbligatorio. Token utente dalla pagina impostazioni di ListenBrainz. |
| `poll_interval_s` | `10` | Secondi tra due interrogazioni MPRIS. |
| `scrobble_after_s` | `60` | Secondi di stabilità del titolo prima dello scrobble. |
| `min_title_length` | `3` | Scarta i titoli piu corti di questo valore. |
| `require_separator` | `true` | Scarta i brani senza artista (tipico di jingle e voce DJ). |
| `mb_min_score` | `90` | Punteggio minimo del match MusicBrainz per allegare gli MBID. |
| `user_agent` | ... | Inviato a MusicBrainz, che richiede un contatto nello UA. |
| `use_applet_stations` | `true` | Legge i nomi delle preferite dalla configurazione dell'applet. |
| `blacklist_substrings` | ... | Sottostringhe case-insensitive che identificano uno spot o un jingle. |
| `station_names` | `[]` | Nomi di stazioni aggiuntivi (si somma a quelli letti dall'applet). |

Per applicare le modifiche:

```bash
systemctl --user restart radio-scrobbler
```

## Consigli pratici

**Il nome della preferita deve coincidere con lo StreamTitle ICY.**
Se una stazione invia `Radio Fantasia - Artista - Titolo` ma nelle
preferite dell'applet l'hai salvata come `Fantasia`, lo scrobbler non
riconoscera il nome stazione e `Radio Fantasia` finira come "artista".
Rinomina la preferita in Radio++ in modo da far coincidere il nome con
cio che la stazione annuncia davvero (per esempio `Radio Fantasia`). Lo
scrobbler se ne accorge in automatico al poll successivo, senza
riavvii.

**Le stazioni dance (e in generale gli stream HLS) spesso non sono
scrobblabili.**
Molte radio dance distribuiscono via HLS (`.m3u8`): o non espongono per
niente i metadati ICY (lo StreamTitle contiene il nome del segmento,
tipo `master_ma.m3u8` o `stream2`), oppure inviano solo
`Nome Stazione - Titolo Brano` senza l'artista reale. In entrambi i
casi lo scrobbler fa la cosa giusta e li filtra: non c'e nulla di
sensato da inviare. Se tieni allo scrobbling, preferisci le radio in
stile FM che trasmettono metadati `Artista - Titolo` corretti (radio
news/musica, buona parte delle generaliste).

**Far ignorare una formula ricorrente.**
Aggiungi la sottostringa fastidiosa a `blacklist_substrings`. Esempio:
una stazione che manda ciclicamente `IDENT - Call sign xyz`:

```json
"blacklist_substrings": ["call sign", "ident "]
```

Poi: `systemctl --user restart radio-scrobbler`.

**Ascolti persi per errori temporanei.**
Se compare `scrobble failed: ...` per un singolo errore di rete o API,
quello specifico ascolto va perso: non esiste una coda di retry (scelta
voluta, per mantenere lo strumento essenziale). ListenBrainz offre una
pagina "add listen" manuale se vuoi inserire a mano un brano specifico.

## Risoluzione problemi

- `radio-scrobbler --check` stampa percorso configurazione, presenza
  token, configurazione applet, numero di stazioni e stato MPRIS
  attuale.
- Nessun log dopo l'installazione: verifica che la sessione Cinnamon
  sia attiva ed esegui `systemctl --user status radio-scrobbler`.
- Ascolti non visibili su ListenBrainz: controlla il token (rigeneralo
  dalla pagina impostazioni), cerca righe `playing_now failed` nel log.
- Tutto viene filtrato: controlla `require_separator` e ispeziona lo
  StreamTitle grezzo con `playerctl --player=mpv metadata`.

## Licenza

GNU General Public License v3.0 o successiva. Vedi [LICENSE](./LICENSE).
