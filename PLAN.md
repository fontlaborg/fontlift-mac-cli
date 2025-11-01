# PLAN.md
<!-- this_file: PLAN.md -->

## Project Overview

**fontlift-mac-cli** - Simple macOS CLI tool for font management

**One-sentence scope**: Install, uninstall, list, and remove fonts on macOS via CLI.

**Current Version**: v1.1.29 (IN DEVELOPMENT)

---

## Core Functionality

### Commands
- **`list`** (`l`) - List installed fonts
  - `-p` or `--path`: Show file paths (default)
  - `-n` or `--name`: Show internal font names
  - `-s`: Sorted/deduplicated output

- **`install`** (`i`) - Install fonts
  - By path: `fontlift install /path/to/font.ttf`
  - Registers fonts with macOS Core Text

- **`uninstall`** (`u`) - Uninstall fonts (keep files)
  - By path: `fontlift uninstall /path/to/font.ttf`
  - By name: `fontlift uninstall -n "Font Name"`

- **`remove`** (`rm`) - Remove fonts (delete files)
  - By path: `fontlift remove /path/to/font.ttf`
  - By name: `fontlift remove -n "Font Name"`

### Global Flags
- `--version` - Show version
- `--help` - Show help

---

## Technology Stack

- **Language**: Swift 5.9+
- **Platform**: macOS 12.0+ (Intel + Apple Silicon)
- **Build**: Swift Package Manager
- **APIs**: Core Text (CTFontManager)
- **CI/CD**: GitHub Actions
- **Distribution**: GitHub Releases, Homebrew

---

## Project Structure

```
fontlift-mac-cli/
├── Sources/fontlift/
│   └── fontlift.swift          # Main CLI implementation
├── Tests/
│   ├── fontliftTests/          # Swift unit tests (23)
│   ├── scripts_test.sh         # Script tests (23)
│   └── integration_test.sh     # Integration tests (15)
├── scripts/
│   ├── get-version.sh          # Extract version from code
│   ├── validate-version.sh     # Validate version consistency
│   └── prepare-release.sh      # Prepare release artifacts
├── build.sh                    # Build script
├── test.sh                     # Test runner
├── publish.sh                  # Installation script
├── Package.swift               # Swift package manifest
├── README.md                   # User documentation
└── CHANGELOG.md                # Version history
```

---

## Success Metrics

**Code Quality**:
- ✅ Zero compiler warnings
- ✅ All tests passing (65 total)
- ✅ Functions <20 lines
- ✅ Clean, readable code

**Build & Test**:
- ✅ Build time: <10s
- ✅ Test time: ~20s
- ✅ Universal binary: x86_64 + arm64

**Distribution**:
- ✅ GitHub Releases with artifacts
- ⏳ Homebrew Formula (planned)

**User Experience**:
- ✅ Simple, intuitive commands
- ✅ Clear error messages
- ✅ Fast execution
- ✅ Comprehensive help text

---

## Future Enhancements

See TODO.md for planned improvements.

---

For development status, see WORK.md.
For version history, see CHANGELOG.md.
For development guidelines, see CLAUDE.md.
