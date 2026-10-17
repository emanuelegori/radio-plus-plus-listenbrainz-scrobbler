# radio-plus-plus-listenbrainz-scrobbler

[Italiano](./README.it-IT.md) • **English**

ListenBrainz scrobbler for the [Radio++ Cinnamon applet](https://cinnamon-spices.linuxmint.com/applets/view/280)
(`radio@driglu4it`). Runs as a `systemd --user` service, reads the ICY
metadata exposed by `mpv` through MPRIS, enriches with MusicBrainz when
possible and submits listens to [ListenBrainz](https://listenbrainz.org/).

- Author: Emanuele Gori
- License: GPL-3.0-or-later
- Forgejo: <https://git.emanuelegori.uno/emanuelegori/radio-plus-plus-listenbrainz-scrobbler>
- GitHub mirror: <https://github.com/emanuelegori/radio-plus-plus-listenbrainz-scrobbler>

---

## Features

- Fully local, no third-party service beyond ListenBrainz and MusicBrainz.
- Automatic reading of favourite station names from the Radio++ applet
  config, with mtime-based hot reload when favourites change.
- Non-blocking MusicBrainz enrichment: when a strong match is found the
  listen is tagged with `recording_mbid`, `artist_mbids`, `release_mbid`;
  otherwise it is submitted with the raw ICY artist/title (important for
  tracks absent from MusicBrainz, as often happens for Italian radio).
- Anti-spot filters: configurable blacklist of keywords (`pubblicit`,
  `advertisement`, `jingle`, `news`, `promo`, ...), station name stripping
  from title and artist, `require_separator` flag.
- Diagnostics: `radio-scrobbler --check` and `--about`.

## Requirements

- A Debian/Ubuntu-based distribution with `apt-get`.
- Cinnamon desktop with the Radio++ applet (`radio@driglu4it`) installed
  and at least one favourite station configured.
- `playerctl`, `python3`, `python3-requests`.
- systemd user instance (standard on modern Debian/Ubuntu).
- A ListenBrainz account and a user token
  (from <https://listenbrainz.org/settings/>).

## Install

```bash
git clone https://git.emanuelegori.uno/emanuelegori/radio-plus-plus-listenbrainz-scrobbler.git
cd radio-plus-plus-listenbrainz-scrobbler
./install.sh
```

The installer:

1. Checks `apt-get`, Cinnamon, Radio++ applet and its config.
2. Detects missing packages among `playerctl` and `python3-requests`.
   If any are missing it shows a list and asks for confirmation; on
   `Y` it runs `sudo apt-get update && sudo apt-get install -y ...`
   (you will be prompted for your sudo password). If you reply `n`
   the installer aborts.
3. Copies `radio-scrobbler` to `~/.local/bin/` and the service unit to
   `~/.config/systemd/user/`.
4. Creates `~/.config/radio-scrobbler/config.json` from the template if
   missing and asks for the ListenBrainz token with hidden input
   (characters not echoed; the token is written straight into the
   JSON with `chmod 600`).
5. Runs `systemctl --user daemon-reload` and `enable --now
   radio-scrobbler.service`: the scrobbler starts immediately and
   will auto-start at every login from now on. No reboot needed.

### After install

The cloned folder is **no longer needed**. All runtime files have
been copied under your home:

- `~/.local/bin/radio-scrobbler`
- `~/.config/systemd/user/radio-scrobbler.service`
- `~/.config/radio-scrobbler/config.json`

You can safely delete the cloned repo (keep it only if you want to
run `./uninstall.sh` or `git pull` for updates later):

```bash
cd ~ && rm -rf radio-plus-plus-listenbrainz-scrobbler
```

All the commands shown below (`radio-scrobbler`, `journalctl`,
`systemctl --user`) work from **any terminal, in any directory**:
`~/.local/bin` is in your `PATH` on standard Debian/Ubuntu profiles.
If `radio-scrobbler --version` is "command not found" after install,
open a new terminal (or run `source ~/.profile`) and retry.

## Uninstall

```bash
./uninstall.sh
```

Stops and disables the service, removes the script and the unit. Asks
whether to also remove the config and log directories.

## Usage

All commands run from **any terminal** (no need to `cd` into any
directory):

```bash
radio-scrobbler --about     # author, license, repository links
radio-scrobbler --version
radio-scrobbler --check     # config and MPRIS diagnostics

systemctl --user status radio-scrobbler    # current state
systemctl --user restart radio-scrobbler   # apply config changes
systemctl --user stop radio-scrobbler
systemctl --user start radio-scrobbler
```

Start the applet, press play on any station and follow the logs
(again, from any terminal):

```bash
journalctl --user -u radio-scrobbler -f
```

Key log messages:

| Line | Meaning |
|---|---|
| `New track: X — Y` | Change detected and considered valid; `playing_now` sent. |
| `Now playing sent: ...` | ListenBrainz "now playing" updated on the profile. |
| `MB match: <uuid>` | MusicBrainz returned a recording MBID (enrichment). |
| **`Scrobbled: X — Y`** | **Listen successfully submitted** after the stability threshold. |
| `Filtered: ...` | Track skipped (blacklist / missing separator / station name only). |
| `playing_now failed` / `scrobble failed` | ListenBrainz API error. |

## Configuration

File: `~/.config/radio-scrobbler/config.json` (`chmod 600`).

| Key | Default | Description |
|---|---|---|
| `listenbrainz_token` | `""` | Required. User token from the ListenBrainz settings page. |
| `poll_interval_s` | `10` | Seconds between MPRIS polls. |
| `scrobble_after_s` | `60` | Seconds a stable title must play before being scrobbled. |
| `min_title_length` | `3` | Reject titles shorter than this. |
| `require_separator` | `true` | Reject tracks without an artist (common for jingles / DJ talk). |
| `mb_min_score` | `90` | Minimum MusicBrainz match score to attach MBIDs. |
| `user_agent` | ... | Sent to MusicBrainz; MB requires contact info. |
| `use_applet_stations` | `true` | Read favourite names from the applet config. |
| `blacklist_substrings` | ... | Case-insensitive substrings that mark a title as spot/jingle. |
| `station_names` | `[]` | Extra station names (adds to the ones read from the applet). |

Apply changes with:

```bash
systemctl --user restart radio-scrobbler
```

## Tips & tricks

**Favourite names in the applet are used to clean the StreamTitle.**
The scrobbler reads the list of your Radio++ favourite names and uses
them to remove the station name from the ICY `StreamTitle` before
submitting the listen. The match is exact (case-insensitive): if the
saved name in Radio++ is `Awesome`, only the literal string `Awesome`
is stripped, surrounded by a common separator (`-`, `|`, `:`, ...).

That means the favourite name must match what the stream actually
broadcasts, otherwise the station name slips through and ends up as
the artist. Concrete real-world case:

- Stream sends: `Italia Dance Music Radio - Stay with me in the network`
- Favourite in applet is named: `Italia Dance Music`
- The scrobbler looks for `Italia Dance Music` immediately followed by
  a separator, does not find it (the stream has `Italia Dance Music`
  followed by ` Radio -`), does **not** strip anything, splits on the
  first ` - ` and submits:
    - artist = `Italia Dance Music Radio`
    - title  = `Stay with me in the network`

Fix: open Radio++ settings, rename the favourite from
`Italia Dance Music` to `Italia Dance Music Radio`. The scrobbler
reloads the list automatically within one poll (10 s), no restart
required.

If renaming is not an option (for stations you only tune in on the fly
without saving), add the name to `station_names` in your config:

```json
"station_names": ["Italia Dance Music Radio"]
```

Then: `systemctl --user restart radio-scrobbler`.

**Dance / HLS stations are mostly not scrobblable.**
Many dance stations distribute via HLS (`.m3u8`) and either do not
expose ICY metadata at all (StreamTitle shows the segment filename like
`master_ma.m3u8` or `stream2`) or send only `Station Name - Track Title`
without a real artist. In both cases the scrobbler correctly filters
them out: there is nothing meaningful to submit. If you care about
scrobbling, prefer FM-style radios that broadcast proper
`Artist - Title` metadata (news/music radios, most generalist ones).

**Make the scrobbler ignore a specific wording.**
Add the problematic substring to `blacklist_substrings`. Example: a
station that occasionally sends `IDENT - Call sign xyz`:

```json
"blacklist_substrings": ["call sign", "ident "]
```

Then: `systemctl --user restart radio-scrobbler`.

**Dropped listens due to transient errors.**
If `scrobble failed: ...` appears due to a one-off network/API hiccup,
the listen for that specific track is lost (there is no retry queue by
design: this tool is intentionally minimal). ListenBrainz has a manual
"add listen" page if you want to add a specific track by hand.

## Troubleshooting

- `radio-scrobbler --check` prints config path, token presence, applet
  config, number of stations and current MPRIS state.
- No logs after installing: verify Cinnamon session is active and run
  `systemctl --user status radio-scrobbler`.
- Listens not showing on ListenBrainz: confirm the token (regenerate on
  the settings page), check for `playing_now failed` lines in the log.
- Everything filtered: check `require_separator` and look at the raw
  StreamTitle with `playerctl --player=mpv metadata`.

## License

GNU General Public License v3.0 or later. See [LICENSE](./LICENSE).
