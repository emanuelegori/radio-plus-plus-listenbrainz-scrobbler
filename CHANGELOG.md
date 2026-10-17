# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Default `blacklist_substrings` expanded, in both Italian and
  English, to block common radio formulas that the new parser
  would otherwise accept as artist/title and scrobble as music:
    - Italian: `agenzia giornalistica`, `giornale radio`,
      `segnale orario`, `tgcom` (Italian Mediaset news brand,
      frequent on generalist stations).
    - English: `news update`, `news bulletin`, `news report`,
      `time signal`, `station id`.
  Deliberately NOT added, to avoid false positives against real
  song titles: `breaking news` (Michael Jackson), `weather
  report` (jazz band), `headlines` (Drake). Users can still add
  them locally.
  Note: existing installations keep their current config
  unchanged (the installer preserves `config.json`); to pick up
  the new default entries, add them manually to your config and
  `systemctl --user restart radio-scrobbler`.

### Fixed

- `install.sh`: on an idempotent re-run (upgrade), the service is
  now **restarted** explicitly instead of relying on
  `systemctl --user enable --now`. `--now` is a no-op on an
  already-active service, so after `git pull && ./install.sh`
  the file on disk was correctly replaced but the Python process
  in RAM kept running the previous version until the next login
  or a manual restart. Reproduced live via SSH on a user PC
  showing stale PID + stale behaviour; after the fix a single
  `./install.sh` is enough to pick up both new binary and new
  behaviour.
- `radio-scrobbler`: parse ICY titles in the form `ARTIST-TITLE`
  (bare hyphen, no surrounding spaces) when `xesam:artist` is
  empty. Previously only `" - "` (space-hyphen-space) was tried
  as a fallback separator, so stations that broadcast metadata
  like `ALESSANDRA AMOROSO-MEZZO ROTTO (FEAT. BIGMAMA)` or
  `STADIO-UN DISPERATO BISOGNO D'AMORE` ended up with an empty
  artist and were filtered out by `require_separator`. The
  fallback now tries, in order of specificity, `" - "`, `" – "`,
  `" — "`, then the bare `-` / `–` / `—`, so the first match
  wins and spaced separators keep priority (e.g. `JAY-Z - 99
  Problems` is still split as `JAY-Z` / `99 Problems`, not
  `JAY` / `Z - 99 Problems`).

### Added

- `install.sh` and `uninstall.sh`: bilingual output. The installer
  auto-detects the user locale via `LC_ALL` / `LC_MESSAGES` / `LANG`
  and prints Italian when the locale begins with `it`, English
  otherwise (default). All status messages, prompts, errors and
  the final post-install summary are localised. No new dependency.

### Changed

- `install.sh`: rewrote the final shell message. Now states clearly
  that the service is ACTIVE and will auto-start at every login,
  recommends **keeping** the cloned folder (needed for
  `./uninstall.sh` and `git pull && ./install.sh`), removed the
  previous "safe to delete" hint which contradicted the uninstall
  flow, and lists the full set of systemd user commands
  (`status`, `start`, `stop`, `restart`) in addition to
  `journalctl -f` and the `radio-scrobbler --*` CLI.
- `radio-scrobbler --check`: restructured output in readable
  sections (`[Service]`, `[Config]`, `[Applet]`, `[MPRIS mpv]`,
  `[Log]`, `[Commands]`), added systemd `is-active` /
  `is-enabled` status so a glance tells whether the service is
  running and whether autostart is wired up.
- README (en/it): "After install" now says the service is already
  active and auto-starts at login, and that the cloned folder
  must be kept (used by uninstall and update). "Usage" lists the
  full systemctl set (status/start/stop/restart) aligned with the
  installer output.
- README: clarified how the installer handles missing packages
  (shows the list, asks for confirmation, then runs
  `sudo apt-get install -y`).
- README: rewrote the "favourite station name" tip with a concrete,
  worked example showing why the saved name must match the ICY
  broadcast; added fallback via `station_names` config entry.
- README: added an "Update" section explaining that `install.sh` is
  idempotent (skips installed packages, overwrites binary/unit,
  preserves config and token, restarts the service).

## [1.0.0] - 2026-10-17

### Added

- Initial release.
- ListenBrainz scrobbling from the Radio++ Cinnamon applet via `mpv` MPRIS.
- Automatic reading of favourite station names from the applet config,
  with mtime-based cache (hot reload when the user edits favourites).
- Non-blocking MusicBrainz enrichment (adds `recording_mbid`, `artist_mbids`,
  `release_mbid` when match score >= 90, otherwise scrobbles the raw
  artist/title; important for tracks absent from MusicBrainz such as a lot
  of Italian radio music).
- Anti-spot filters: configurable blacklist substrings, `require_separator`
  flag, in-title / in-artist station name stripping with common separators
  (`-`, `|`, `•`, `·`, `:`, `/`, `,`).
- CLI flags: `--version`, `--about`, `--check` (diagnostics).
- `install.sh` with prerequisite checks, interactive token input (hidden)
  and systemd user service activation.
- `uninstall.sh` with optional config/cache removal.
