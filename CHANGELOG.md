# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
