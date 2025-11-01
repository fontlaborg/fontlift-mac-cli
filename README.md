# fontlift-mac-cli

[![CI](https://github.com/fontlaborg/fontlift-mac-cli/workflows/CI/badge.svg)](https://github.com/fontlaborg/fontlift-mac-cli/actions)

CLI tool written in Swift for macOS to install/uninstall fonts

## Installation

### From GitHub Releases (Recommended)

Download the latest pre-built binary:

```bash
# Download latest release
curl -L https://github.com/fontlaborg/fontlift-mac-cli/releases/latest/download/fontlift-v1.1.10-macos.tar.gz -o fontlift.tar.gz

# Extract
tar -xzf fontlift.tar.gz

# Install to /usr/local/bin
sudo mv fontlift /usr/local/bin/

# Verify installation
fontlift --version
```

### From Source

Requires Swift 5.9+ and macOS 12+:

```bash
git clone https://github.com/fontlaborg/fontlift-mac-cli.git
cd fontlift-mac-cli
./build.sh
./publish.sh  # Installs to /usr/local/bin
```

## Usage

### Listing installed fonts

- `fontlift list` or `fontlift list -p` lists the paths of all installed fonts, one path per line
- `fontlift list -n` lists the internal font names of all installed fonts, one name per line
- `fontlift list -n -p` or `fontlift list -n -p` lists the the paths and internal font names of all installed fonts; each line consists of the path followed by semicolon followed by the internal font name
- `l` should be a synonym for `list`

### Installing fonts

- `fontlift install FILEPATH` or `fontlift install -p FILEPATH` installs on the system the font (or all fonts in case of a .ttc or .otc) from the FILEPATH 
- `i` should be a synonym for `install`

### Uninstalling fonts while keeping the font files

- `fontlift uninstall FILEPATH` or `fontlift uninstall -p FILEPATH` uninstalls from the system the font (or all fonts in case of a .ttc or .otc) with the FILEPATH (keeps the file)
- `fontlift uninstall -n FONTNAME` uninstalls the font with the given internal font name from the system (keeps the file)
- `u` should be the synonym for `uninstall`

### Uninstalling fonts and removing the font files

- `fontlift remove FILEPATH` or `fontlift remove -p FILEPATH` uninstalls from the system the font (or all fonts in case of a .ttc or .otc) with the FILEPATH (and removes the file)
- `fontlift remove -n FONTNAME` uninstalls the font with the given internal font name from the system (and removes the file) 
- `rm` should be the synonym for `remove`

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

### CI/CD

This project uses GitHub Actions for automated testing and releases:
- **CI**: Runs on every push/PR (builds and tests)
- **CD**: Triggered by version tags (`vX.Y.Z`) to create GitHub Releases

View build status: [GitHub Actions](https://github.com/fontlaborg/fontlift-mac-cli/actions)

---

- Copyright 2025 by Fontlab Ltd.
- Licensed under Apache 2.0
- Repo: https://github.com/fontlaborg/fontlift-mac-cli
