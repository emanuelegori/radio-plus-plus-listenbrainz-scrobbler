# radio-plus-plus-listenbrainz-scrobbler

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
2. Rileva eventuali pacchetti mancanti fra `playerctl` e
   `python3-requests`. Se ne trova, mostra l'elenco e chiede
   conferma; rispondendo `Y` esegue
   `sudo apt-get update && sudo apt-get install -y ...` (ti verra
   chiesta la password sudo). Se rispondi `n`, l'installer si ferma.
3. Copia di `radio-scrobbler` in `~/.local/bin/` e del servizio in
   `~/.config/systemd/user/`.
4. Creazione di `~/.config/radio-scrobbler/config.json` dal template
   se non presente e richiesta del token ListenBrainz con input
   nascosto (i caratteri non vengono mostrati, il token viene
   scritto direttamente nel JSON con `chmod 600`).
5. `systemctl --user daemon-reload` ed `enable --now
   radio-scrobbler.service`: lo scrobbler parte subito ed e
   configurato per avviarsi automaticamente a ogni login. Non serve
   riavviare il sistema.

### Dopo l'installazione

Il servizio e **gia attivo** e verra avviato automaticamente a ogni
login. Non devi fare altro: premi play su una stazione in Radio++
e lo scrobbler inviera gli ascolti a ListenBrainz al raggiungimento
della soglia di stabilita.

File di esecuzione copiati sotto la tua home:

- `~/.local/bin/radio-scrobbler`
- `~/.config/systemd/user/radio-scrobbler.service`
- `~/.config/radio-scrobbler/config.json`

**Tieni la cartella clonata.** Serve per `./uninstall.sh` e per
aggiornare con `git pull && ./install.sh`. Non e necessario
eliminarla.

Tutti i comandi riportati sotto (`radio-scrobbler`, `journalctl`,
`systemctl --user`) funzionano da **qualunque terminale, in
qualunque directory**: `~/.local/bin` e gia nel `PATH` sui profili
standard Debian/Ubuntu. Se subito dopo l'installazione
`radio-scrobbler --version` risponde "command not found", esegui
`cd ~` e riprova (oppure apri un nuovo terminale).

## Aggiornamento

L'installer e **idempotente**: lo si rilancia per aggiornare
un'installazione gia esistente. In quel caso:

- I pacchetti gia installati vengono saltati (nessun prompt
  `sudo`).
- `~/.local/bin/radio-scrobbler` e il service unit vengono
  sovrascritti con le nuove versioni.
- `~/.config/radio-scrobbler/config.json` viene **preservato**: il
  tuo token e le tue personalizzazioni restano intatti, il token
  **non** viene richiesto di nuovo.
- systemd viene ricaricato e il service riparte con il nuovo
  binario.

Se hai conservato la cartella clonata:

```bash
cd radio-plus-plus-listenbrainz-scrobbler
git pull
./install.sh
```

Se l'avevi eliminata, ribasta riclonare ed eseguire `install.sh`
sopra l'installazione esistente, senza alcun effetto collaterale.

## Disinstallazione

```bash
./uninstall.sh
```

Ferma e disabilita il servizio, rimuove script e unit. Chiede se
eliminare anche le directory di configurazione e di log.

## Uso

Tutti i comandi si lanciano da **qualunque terminale** (non serve
spostarsi in alcuna directory):

```bash
radio-scrobbler --about     # autore, licenza, link ai repo
radio-scrobbler --version
radio-scrobbler --check     # diagnostica service, configurazione, MPRIS

systemctl --user status  radio-scrobbler   # stato attuale (active/inactive)
systemctl --user start   radio-scrobbler   # avvia il servizio
systemctl --user stop    radio-scrobbler   # ferma il servizio
systemctl --user restart radio-scrobbler   # applica modifiche al config
```

Avvia l'applet, premi play su una stazione e segui i log (anche
questo da qualunque terminale):

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

**I nomi delle preferite servono a ripulire lo StreamTitle.**
Lo scrobbler legge l'elenco dei nomi delle tue preferite in Radio++ e
li usa per rimuovere il nome della stazione dallo `StreamTitle` ICY
prima di inviare l'ascolto. Il confronto e esatto (ma
case-insensitive): se nelle preferite il nome salvato e `Fantasia`,
viene rimossa solo esattamente la stringa `Fantasia` quando compare
accanto a un separatore comune (`-`, `|`, `:`, ...).

Significa che il nome della preferita deve coincidere con quello che la
stazione annuncia davvero nei metadati, altrimenti il nome stazione
sfugge al filtro e finisce come artista. Caso reale, concreto:

- Lo stream invia: `Italia Dance Music Radio - Stay with me in the network`
- Nelle preferite la stazione e salvata come: `Italia Dance Music`
- Lo scrobbler cerca `Italia Dance Music` subito seguito da un
  separatore, non lo trova (nello stream dopo `Italia Dance Music` c'e
  ` Radio -`), **non** rimuove nulla, divide sul primo ` - ` e invia:
    - artista = `Italia Dance Music Radio`
    - titolo  = `Stay with me in the network`

Rimedio: apri le impostazioni di Radio++, rinomina la preferita da
`Italia Dance Music` a `Italia Dance Music Radio`. Lo scrobbler
ricarica l'elenco in automatico entro un poll (10 s), nessun riavvio
necessario.

Se la rinomina non e possibile (per stazioni che ascolti al volo
senza salvarle), aggiungi il nome a `station_names` nel tuo config:

```json
"station_names": ["Italia Dance Music Radio"]
```

Poi: `systemctl --user restart radio-scrobbler`.

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
