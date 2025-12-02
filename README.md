# fontlift-mac-cli

[![CI](https://github.com/fontlaborg/fontlift-mac-cli/workflows/CI/badge.svg)](https://github.com/fontlaborg/fontlift-mac-cli/actions)

CLI tool written in Swift for macOS to install/uninstall fonts

## Installation

### From GitHub Releases (Recommended)

Download and install the latest pre-built universal binary (supports both Intel and Apple Silicon):

```bash
# Set version (or use 'latest')
VERSION="2.0.0"  # Or check https://github.com/fontlaborg/fontlift-mac-cli/releases

# Download release tarball and checksum
curl -L "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/v${VERSION}/fontlift-mac-v${VERSION}-macos.tar.gz" -o fontlift-mac.tar.gz
curl -L "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/v${VERSION}/fontlift-mac-v${VERSION}-macos.tar.gz.sha256" -o fontlift-mac.tar.gz.sha256

# Verify checksum (recommended)
shasum -a 256 -c fontlift-mac.tar.gz.sha256

# Extract binary
tar -xzf fontlift-mac.tar.gz

# Install to /usr/local/bin (may require sudo)
sudo mv fontlift-mac /usr/local/bin/

# Verify installation
fontlift-mac --version
```

**Troubleshooting:** If you encounter issues, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

### Via Homebrew (Coming Soon)

Homebrew formula submission is planned for a future release:

```bash
# Future installation method (not yet available)
brew tap fontlaborg/fontlift
brew install fontlift-mac
```

**Requirements:**
- macOS 12.0 (Monterey) or later
- Intel (x86_64) or Apple Silicon (arm64) Mac

### From Source

Requires Swift 5.9+ and macOS 12+:

```bash
git clone https://github.com/fontlaborg/fontlift-mac-cli.git
cd fontlift-mac-cli
./build.sh
./publish.sh  # Installs to /usr/local/bin
```

## Quick Start

Here are the most common workflows:

### Discover available fonts
```bash
# List all installed fonts (sorted by family)
fontlift-mac list -n -s

# Find fonts matching a name
fontlift-mac list -n | grep -i "helvetica"

# See where a font is installed (shows path::name format)
fontlift-mac list -p -n | grep "Helvetica"
# Example output:
# /System/Library/Fonts/Helvetica.ttc::Helvetica
# /System/Library/Fonts/Helvetica.ttc::Helvetica-Bold
# Output is always sorted. Path-only listings are deduped automatically; add -s to dedupe names or path::name pairs.
```

### Install a new font
```bash
# Install a single font file
fontlift-mac install ~/Downloads/MyFont.ttf

# Install works with .ttf, .otf, .ttc, .otc files
fontlift-mac install /path/to/font.otf
```

### Uninstall a font (keep file)
```bash
# Uninstall by file path
fontlift-mac uninstall ~/Library/Fonts/MyFont.ttf

# Uninstall by font name
fontlift-mac list -n | grep "MyFont"  # Find exact name first
fontlift-mac uninstall -n "MyFont-Regular"
```

### Remove a font (delete file)
```bash
# Remove by file path (deletes file)
fontlift-mac remove ~/Downloads/OldFont.ttf

# Remove by font name (deletes file)
fontlift-mac remove -n "OldFont-Bold"
```

### Clean up font registrations and caches
```bash
# Prune missing font registrations and clear caches for the current user
fontlift-mac cleanup

# Only prune registrations (skip caches)
fontlift-mac cleanup --prune-only

# Only clear caches (prunes are skipped)
fontlift-mac cleanup --cache-only

# Run a system-level cleanup (clears caches for all users; requires sudo)
sudo fontlift-mac cleanup --admin
```

The default cleanup command performs two safety tasks:

- **Prunes missing fonts** – removes registrations for fonts whose files were deleted or moved (skips protected system directories)
- **Clears caches** – purges Core Text caches and third-party caches for Adobe and Microsoft apps (user scope by default, system scope with `--admin`)

## Advanced Usage Examples

### Installing a Custom Font Family

Installing all fonts from a downloaded font family:

```bash
# Download and install a font family (e.g., Inter from Google Fonts)
cd ~/Downloads
unzip Inter.zip -d Inter/

# Install all font files in the directory
for font in Inter/*.ttf; do
    fontlift-mac install "$font"
done

# Verify installation
fontlift-mac list -n | grep "Inter"
```

### Batch Font Management

Managing multiple fonts at once:

```bash
# List all fonts in a specific directory
ls ~/Library/Fonts/*.ttf

# Remove all fonts from a specific directory
for font in ~/Library/Fonts/CustomFonts/*.ttf; do
    fontlift-mac remove "$font"
done

# Reinstall fonts after system upgrade
find ~/FontBackup -name "*.ttf" -o -name "*.otf" | while read font; do
    fontlift-mac install "$font"
done
```

### Troubleshooting Font Installation

If you encounter issues installing fonts:

```bash
# 1. Check if font file exists and is readable
ls -la /path/to/font.ttf
file /path/to/font.ttf

# 2. Try installing with full path
fontlift-mac install "$(pwd)/MyFont.ttf"

# 3. Check if font is already installed
fontlift-mac list -n | grep -i "myfont"

# 4. If installation fails, check system font cache
# (macOS will rebuild it automatically)
atsutil databases -remove  # Requires sudo
```

### Verifying Installed Fonts

Comprehensive font verification:

```bash
# List all installed fonts (sorted alphabetically)
fontlift-mac list -n -s > installed-fonts.txt

# Count total installed fonts
fontlift-mac list -n | wc -l

# Find duplicate font names
fontlift-mac list -n | sort | uniq -d

# Find fonts by family
fontlift-mac list -n | grep -i "helvetica"

# Get both path and name for specific font
fontlift-mac list -n -p | grep "Helvetica"
```

## Usage

### Listing installed fonts

- `fontlift-mac list` or `fontlift-mac list -p` lists the paths of all installed fonts, one path per line
- `fontlift-mac list -n` lists the internal font names of all installed fonts, one name per line
- `fontlift-mac list -n -p` or `fontlift-mac list -p -n` lists the paths and internal font names of all installed fonts; each line consists of the path followed by double colon (`::`) followed by the internal font name
- `l` should be a synonym for `list`

### Installing fonts

- `fontlift-mac install FILEPATH` or `fontlift-mac install -p FILEPATH` installs on the system the font (or all fonts in case of a .ttc or .otc) from the FILEPATH for the current user
- `sudo fontlift-mac install --admin FILEPATH` or `sudo fontlift-mac install -a FILEPATH` installs the font at system level (all users in current login session)
- `i` should be a synonym for `install`

**User-level vs System-level:**
- User-level (default): Font available only to the current user, no sudo required
- System-level (`--admin` flag): Font available to all users in the current login session, requires sudo

### Uninstalling fonts while keeping the font files

- `fontlift-mac uninstall FILEPATH` or `fontlift-mac uninstall -p FILEPATH` uninstalls from the system the font (or all fonts in case of a .ttc or .otc) with the FILEPATH (keeps the file, user-level)
- `fontlift-mac uninstall -n FONTNAME` uninstalls the font with the given internal font name from the system (keeps the file, user-level)
- `sudo fontlift-mac uninstall --admin FILEPATH` or `sudo fontlift-mac uninstall -a -n FONTNAME` uninstalls at system level (all users, requires sudo)
- `u` should be the synonym for `uninstall`

### Uninstalling fonts and removing the font files

- `fontlift-mac remove FILEPATH` or `fontlift-mac remove -p FILEPATH` uninstalls from the system the font (or all fonts in case of a .ttc or .otc) with the FILEPATH (and removes the file, user-level)
- `fontlift-mac remove -n FONTNAME` uninstalls the font with the given internal font name from the system (and removes the file, user-level)
- `sudo fontlift-mac remove --admin FILEPATH` or `sudo fontlift-mac remove -a -n FONTNAME` removes at system level (all users, requires sudo)
- `rm` should be the synonym for `remove`

### Exit Codes

`fontlift-mac` follows standard Unix exit code conventions:

- `0` - Success: Command completed successfully
- `1` - Failure: Command failed (file not found, permission denied, invalid input, etc.)

**Examples in shell scripts:**

```bash
# Check if font installed successfully
if fontlift-mac install /path/to/font.ttf; then
    echo "Font installed successfully"
else
    echo "Failed to install font"
fi

# Capture exit code
fontlift-mac list > fonts.txt
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "Successfully listed fonts"
fi
```

---

## Development

For development instructions, build automation, and release process:
- See [CLAUDE.md](./CLAUDE.md) for detailed development guidelines
- See [CHANGELOG.md](./CHANGELOG.md) for version history
- See [PLAN.md](./PLAN.md) for implementation plans

### Quick Start

```bash
# Build
./build.sh

# Test
./test.sh

# Local install
./publish.sh
```

### Developer Tools

The project includes several developer tools for quality assurance:

```bash
# Verify CI/CD workflows are configured correctly
./test.sh --verify-ci

# Verify build reproducibility (detects non-deterministic builds)
./build.sh --verify-reproducible

# Install pre-commit hook (optional, helps catch issues before committing)
cp .git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Pre-commit hook checks**:
- Version consistency between source and commits
- CHANGELOG.md updates when code changes
- Quick smoke test (build + unit tests)

To bypass the hook when needed: `git commit --no-verify`

### Developer Scripts Reference

**build.sh** - Build the binary

```bash
./build.sh              # Normal release build
./build.sh --ci         # CI mode (quiet output)
./build.sh --clean      # Clean rebuild (removes .build/)
./build.sh --universal  # Build universal binary (x86_64 + arm64)
./build.sh --verify-reproducible  # Check build reproducibility
```

**test.sh** - Run all tests

```bash
./test.sh                    # Run all 124 tests (57 Swift + 23 Scripts + 44 Integration)
./test.sh --ci               # CI mode (quiet output, no colors)
./test.sh --swift            # Run only Swift unit tests (57 tests)
./test.sh --scripts          # Run only scripts tests (23 tests)
./test.sh --integration      # Run only integration tests (44 tests)
./test.sh --swift --ci       # Combine flags: Swift tests in CI mode
./test.sh --help             # Show all available options
```

**When to use selective test suite execution:**
- `--swift`: During core logic development, fast iteration (~6s)
- `--scripts`: When modifying build/test scripts (~20s)
- `--integration`: After binary changes, end-to-end validation (~10s)
- Combined: `--swift --integration` for focused testing without scripts
- Full suite: Default behavior, recommended before commits (~35s)

**scripts/prepare-release.sh** - Prepare release artifacts

```bash
./scripts/prepare-release.sh
# Creates dist/fontlift-mac-vX.Y.Z-macos.tar.gz and SHA256 checksum
# Requires universal binary (x86_64 + arm64)
```

**scripts/commit-helper.sh** - Guided commit workflow

```bash
./scripts/commit-helper.sh
# Validates: version consistency, CHANGELOG updates, tests, CI config
# Provides commit message template
# Safer than manual git commit
```

**scripts/verify-release-artifact.sh** - Verify published releases

```bash
./scripts/verify-release-artifact.sh 1.1.27
# Downloads release from GitHub
# Verifies checksum integrity
# Tests binary functionality
```

### CI/CD

This project uses GitHub Actions for automated testing and releases:
- **CI**: Runs on every push/PR (builds and tests)
- **CD**: Triggered by version tags (`vX.Y.Z`) to create GitHub Releases

View build status: [GitHub Actions](https://github.com/fontlaborg/fontlift-mac-cli/actions)

---

- Copyright 2025 by Fontlab Ltd.
- made by FontLab https://www.fontlab.com/
- Licensed under Apache 2.0
- Repo: https://github.com/fontlaborg/fontlift-mac-cli
