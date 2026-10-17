# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- README: clarified how the installer handles missing packages
  (shows the list, asks for confirmation, then runs
  `sudo apt-get install -y`).
- README: rewrote the "favourite station name" tip with a concrete,
  worked example showing why the saved name must match the ICY
  broadcast; added fallback via `station_names` config entry.
- README: added an "After install" section stating that the service
  starts immediately (`enable --now`), that the cloned folder can be
  deleted afterwards (keeping it only for `uninstall.sh` / `git pull`),
  and that all post-install commands (`radio-scrobbler`,
  `journalctl --user`, `systemctl --user`) work from any terminal
  thanks to `~/.local/bin` being on the default Debian/Ubuntu
  `PATH`.
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
