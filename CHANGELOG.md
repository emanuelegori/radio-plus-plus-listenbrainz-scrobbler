# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
