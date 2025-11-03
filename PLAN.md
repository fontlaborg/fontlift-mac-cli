# PLAN.md
<!-- this_file: PLAN.md -->

## Project Overview

**fontlift-mac-cli** - Simple macOS CLI tool for font management

**One-sentence scope**: Install, uninstall, list, and remove fonts on macOS via CLI.

**Current Version**: v2.0.0

---

## Recent Changes

### Output Format Standardization (Completed in v2.0.0)

**Completed:** Standardized output format across all fontlaborg CLI tools

**Previous Implementation:**
- `list -n -p` output: `path;name` (semicolon separator)

**New Implementation (v2.0.0):**
- `list -n -p` output: `path::name` (double colon separator)

**Rationale:**
- Consistency with fontnome and fontlift-win-cli
- Avoids confusion with semicolon-terminated shell commands
- Clearer visual separation between path and name
- Double colon is less commonly used in file paths, reducing parsing ambiguity

**Changes Made:**
- ✅ Updated fontlift.swift separator and documentation
- ✅ Tests verified (no changes needed - tests don't check specific format)
- ✅ Updated README.md documentation
- ✅ Updated CHANGELOG.md with breaking change notice and migration guide
- ✅ Bumped version to v2.0.0 (major version for breaking change)

---

## Core Functionality

### Commands
- **`list`** (`l`) - List installed fonts
  - `-p` or `--path`: Show file paths (default)
  - `-n` or `--name`: Show internal font names
  - `-s`: Sorted/deduplicated output

- **`install`** (`i`) - Install fonts
  - By path: `fontlift install /path/to/font.ttf`
  - System-wide: `sudo fontlift install --admin /path/to/font.ttf`
  - Registers fonts with macOS Core Text at user or session scope

- **`uninstall`** (`u`) - Uninstall fonts (keep files)
  - By path: `fontlift uninstall /path/to/font.ttf`
  - By name: `fontlift uninstall -n "Font Name"`
  - System-wide: `sudo fontlift uninstall --admin /path/to/font.ttf`

- **`remove`** (`rm`) - Remove fonts (delete files)
  - By path: `fontlift remove /path/to/font.ttf`
  - By name: `fontlift remove -n "Font Name"`
  - System-wide: `sudo fontlift remove --admin /path/to/font.ttf`

### Command Flags
- `-a` or `--admin` - System-level operations (all users, requires sudo)

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
│   ├── fontliftTests/          # Swift unit tests (43)
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
- ✅ All tests passing (94 total: 52 Swift + 23 Scripts + 19 Integration)
- ✅ Functions <20 lines (1 exception: validateFilePath at 40 lines - justified by comprehensive error messages)
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
