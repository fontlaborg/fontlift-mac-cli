---
title: fontlift-mac-cli
layout: default
nav_order: 1
description: macOS CLI for font install, uninstall, list, and cache cleanup
---

<!-- this_file: docs/index.md -->

# fontlift-mac-cli

macOS CLI for font install, uninstall, list, and cache cleanup. Written in Swift.

Made by [FontLab](https://www.fontlab.com/).

---

## How font installation works on macOS

Installing a font on macOS means two things:

1. **Copy the file** into a directory Core Text watches:
   - User scope (default): `~/Library/Fonts/` — no admin needed, visible only to the current account.
   - System scope (`--admin`): `/Library/Fonts/` — visible to all users, requires `sudo`.
2. **Register it** with Core Text via `CTFontManagerRegisterFontsForURL`. Core Text
   notifies running applications immediately. No reboot or log-out needed.

`/System/Library/Fonts/` is managed by macOS itself and protected by System Integrity
Protection (SIP). fontlift-mac never touches that directory.

**Supported formats:** `.ttf` (TrueType), `.otf` (OpenType), `.ttc`/`.otc` (collections
with multiple faces per file).

---

## Comparison with fontlift (Rust)

This Swift binary shares its command surface with the cross-platform
[fontlift](https://github.com/fontlaborg/fontlift) tool written in Rust. Same verbs,
same flags, two engines.

Use **fontlift-mac** (this tool) for a single self-contained macOS binary with zero
Rust or Python runtime behind it — good for CI runners and minimal images. Use
**fontlift** (Rust) when you need the same commands on Linux and Windows too, or when
you already pull in the `fontlift` Python package or Rust crates.

---

## Installation

### From GitHub Releases (recommended)

```bash
VERSION="2.0.10"

curl -L "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/v${VERSION}/fontlift-mac-v${VERSION}-macos.tar.gz" -o fontlift-mac.tar.gz
curl -L "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/v${VERSION}/fontlift-mac-v${VERSION}-macos.tar.gz.sha256" -o fontlift-mac.tar.gz.sha256

shasum -a 256 -c fontlift-mac.tar.gz.sha256
tar -xzf fontlift-mac.tar.gz
sudo mv fontlift-mac /usr/local/bin/
fontlift-mac --version
```

**Requirements:** macOS 12.0 (Monterey) or later, Intel or Apple Silicon.

### From source

```bash
git clone https://github.com/fontlaborg/fontlift-mac-cli.git
cd fontlift-mac-cli
./build.sh
./publish.sh   # installs to /usr/local/bin
```

Requires Swift 5.9+ and macOS 12+.

---

## Commands

### `list` (alias: `l`)

```bash
fontlift-mac list          # one path per line (default)
fontlift-mac list -n       # PostScript names
fontlift-mac list -p -n    # path::name pairs, one per line
fontlift-mac list -n -s    # names, sorted and deduplicated
```

Output is always sorted. Path-only listings are automatically deduplicated (a `.ttc`
collection file appears once even though it contains multiple faces). Add `-s` to also
deduplicate when listing names or path+name pairs.

### `install` (alias: `i`)

```bash
fontlift-mac install FILEPATH
sudo fontlift-mac install --admin FILEPATH   # system scope (all users)
```

Accepts `.ttf`, `.otf`, `.ttc`, `.otc`. For collection files, all faces are registered.
User scope needs no `sudo`; system scope (`--admin`) writes to `/Library/Fonts` and does.

### `uninstall` (alias: `u`)

```bash
fontlift-mac uninstall FILEPATH
fontlift-mac uninstall -n FONTNAME
```

Removes the Core Text registration. The file stays on disk. `FONTNAME` matches the
PostScript name (e.g. `MyFont-Regular`).

### `remove` (alias: `rm`)

```bash
fontlift-mac remove FILEPATH
fontlift-mac remove -n FONTNAME
```

Unregisters the font **and deletes the file**. Use `--dry-run` first if you are not certain.

### `cleanup`

```bash
fontlift-mac cleanup                   # prune + clear caches (user scope)
fontlift-mac cleanup --prune-only      # remove stale registrations only
fontlift-mac cleanup --cache-only      # clear caches only
sudo fontlift-mac cleanup --admin      # include system-wide caches
```

Cleanup prunes stale registrations (entries pointing to files deleted or moved outside
fontlift) and clears Core Text caches plus third-party caches for Adobe apps
(`AdobeFnt*.lst`) and Microsoft Office, forcing a rebuild on next launch.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Error (file not found, permission denied, invalid input, etc.) |

---

## Troubleshooting

**Font installed but not showing in apps.** Run `fontlift-mac cleanup --cache-only` to
force apps to reload their font lists.

**"Permission denied" installing system fonts.** Use `sudo fontlift-mac install --admin`.
Without sudo, Core Text refuses writes to `/Library/Fonts/`.

**Font won't uninstall.** Check the exact PostScript name first:
`fontlift-mac list -n | grep -i "fontname"`, then `fontlift-mac uninstall -n "ExactName"`.

**Font cache corruption.** As a last resort, `sudo atsutil databases -remove` rebuilds all
Core Text caches on next login. Only needed for severe corruption.

---

- Copyright 2025 by Fontlab Ltd.
- Licensed under Apache 2.0
- Repo: <https://github.com/fontlaborg/fontlift-mac-cli>
