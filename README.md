# fontlift-mac-cli

[![CI](https://github.com/fontlaborg/fontlift-mac-cli/workflows/CI/badge.svg)](https://github.com/fontlaborg/fontlift-mac-cli/actions)

macOS CLI for font install, uninstall, list, and cache cleanup. Written in Swift.

Made by FontLab https://www.fontlab.com/

---

## How font installation works on macOS

Installing a font on macOS means two things:

1. **Copy the file** into a directory Core Text watches:
   - User scope (default): `~/Library/Fonts/` — no admin needed, visible only to the current account.
   - System scope (`--admin`): `/Library/Fonts/` — visible to all users, requires `sudo`.

2. **Register it** with Core Text via `CTFontManagerRegisterFontsForURL`.
   Core Text notifies running applications immediately. No reboot or log-out needed.

`/System/Library/Fonts/` is managed by macOS itself and protected by System Integrity
Protection (SIP). fontlift-mac never touches that directory.

**Font names explained:**
- *PostScript name* — the stable identifier applications use programmatically, e.g. `HelveticaNeue-BoldItalic`. This is what `--name` matches.
- *Family name* — the group name shown in font menus, e.g. `Helvetica Neue`.
- *Full name* — the human-readable face name, e.g. `Helvetica Neue Bold Italic`.

**Supported formats:** `.ttf` (TrueType), `.otf` (OpenType), `.ttc`/`.otc` (collections with multiple faces per file).

---

## Installation

### From GitHub Releases (recommended)

```bash
VERSION="2.0.0"

curl -L "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/v${VERSION}/fontlift-mac-v${VERSION}-macos.tar.gz" -o fontlift-mac.tar.gz
curl -L "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/v${VERSION}/fontlift-mac-v${VERSION}-macos.tar.gz.sha256" -o fontlift-mac.tar.gz.sha256

shasum -a 256 -c fontlift-mac.tar.gz.sha256
tar -xzf fontlift-mac.tar.gz
sudo mv fontlift-mac /usr/local/bin/
fontlift-mac --version
```

**Requirements:** macOS 12.0 (Monterey) or later, Intel or Apple Silicon.

### From Source

```bash
git clone https://github.com/fontlaborg/fontlift-mac-cli.git
cd fontlift-mac-cli
./build.sh
./publish.sh   # installs to /usr/local/bin
```

Requires Swift 5.9+ and macOS 12+.

---

## Quick start

```bash
# Install a font for the current user
fontlift-mac install ~/Downloads/MyFont.ttf

# Install system-wide (all users, requires sudo)
sudo fontlift-mac install --admin ~/Downloads/MyFont.ttf

# List all installed fonts — paths by default
fontlift-mac list

# List PostScript names (what apps use to reference a font)
fontlift-mac list -n

# List paths and names together
fontlift-mac list -p -n

# Find a font by name
fontlift-mac list -n | grep -i "helvetica"

# Uninstall (keep the file on disk)
fontlift-mac uninstall ~/Library/Fonts/MyFont.ttf
fontlift-mac uninstall -n "MyFont-Regular"

# Remove (uninstall + delete the file)
fontlift-mac remove ~/Library/Fonts/OldFont.ttf
fontlift-mac remove -n "OldFont-Bold"

# Clean up stale registrations and font caches
fontlift-mac cleanup
sudo fontlift-mac cleanup --admin   # also clears system caches
```

---

## Commands

### `list` (alias: `l`)

```bash
fontlift-mac list          # one path per line (default)
fontlift-mac list -p       # same as above
fontlift-mac list -n       # PostScript names
fontlift-mac list -p -n    # path::name pairs, one per line
fontlift-mac list -n -s    # names, sorted
```

Output is always sorted. Path-only listings are automatically deduplicated
(a `.ttc` collection file appears once even though it contains multiple faces).
Add `-s` to also deduplicate when listing names or path+name pairs.

### `install` (alias: `i`)

```bash
fontlift-mac install FILEPATH
fontlift-mac install -p FILEPATH       # explicit path flag
sudo fontlift-mac install --admin FILEPATH   # system scope (all users)
sudo fontlift-mac install -a FILEPATH        # same
```

Accepts `.ttf`, `.otf`, `.ttc`, `.otc`. For collection files, all faces in the
file are registered.

**User vs system scope:**
- User (default): registered for the current account only. No `sudo` needed.
  Core Text picks it up immediately.
- System (`--admin`): registered for all users under `/Library/Fonts`. Requires
  `sudo`. Core Text notifies running apps immediately.

### `uninstall` (alias: `u`)

```bash
fontlift-mac uninstall FILEPATH
fontlift-mac uninstall -p FILEPATH
fontlift-mac uninstall -n FONTNAME
sudo fontlift-mac uninstall --admin FILEPATH
sudo fontlift-mac uninstall -a -n FONTNAME
```

Removes the Core Text registration. The file stays on disk.
`FONTNAME` matches the PostScript name (e.g. `MyFont-Regular`).

### `remove` (alias: `rm`)

```bash
fontlift-mac remove FILEPATH
fontlift-mac remove -n FONTNAME
sudo fontlift-mac remove --admin FILEPATH
```

Unregisters the font **and deletes the file**. Use `--dry-run` first if you're
not certain.

### `cleanup`

```bash
fontlift-mac cleanup                   # prune + clear caches (user scope)
fontlift-mac cleanup --prune-only      # remove stale registrations only
fontlift-mac cleanup --cache-only      # clear caches only
sudo fontlift-mac cleanup --admin      # include system-wide caches
```

Cleanup performs two tasks by default:

- **Prune stale registrations:** removes entries pointing to font files that were
  deleted or moved outside of fontlift. Skips protected system directories.
- **Clear caches:** purges Core Text font caches under `~/Library/Caches/` and
  third-party caches for Adobe applications (`AdobeFnt*.lst` manifests) and
  Microsoft Office. These apps maintain their own font indexes on top of the OS
  list; clearing them forces a rebuild on next launch, which resolves rendering
  glitches after fonts are added or removed.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Error (file not found, permission denied, invalid input, etc.) |

---

## Troubleshooting

**Font installed but not showing in apps**
Run `fontlift-mac cleanup --cache-only` to force apps to reload their font lists.

**"Permission denied" installing system fonts**
Use `sudo fontlift-mac install --admin`. Without sudo, Core Text refuses writes
to `/Library/Fonts/`.

**Font won't uninstall**
Check the exact PostScript name first: `fontlift-mac list -n | grep -i "fontname"`.
Then use `fontlift-mac uninstall -n "ExactName"`.

**Font cache corruption**
```bash
sudo atsutil databases -remove   # nuclear option: rebuild all Core Text caches
```
macOS rebuilds on next login. Only needed for severe cache corruption.

---

## Development

```bash
./build.sh              # release build
./build.sh --universal  # universal binary (x86_64 + arm64)
./test.sh               # run all 124 tests
./test.sh --swift       # Swift unit tests only (~6 s)
./test.sh --integration # integration tests only (~10 s)
```

See [CLAUDE.md](./CLAUDE.md) for detailed development guidelines and
[CHANGELOG.md](./CHANGELOG.md) for version history.

---

- Copyright 2025 by Fontlab Ltd.
- Licensed under Apache 2.0
- Repo: https://github.com/fontlaborg/fontlift-mac-cli
