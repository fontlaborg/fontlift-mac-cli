# WORK.md
<!-- this_file: WORK.md -->

## Project Status

**Current Version**: v1.1.28 (RELEASED)
**Last Updated**: 2025-11-01

### Core Metrics

- **Test Suite**: 65 tests passing (23 Swift + 25 Scripts + 17 Integration)
- **Test Execution**: ~20s
- **Build Time**: ~6-8s (release mode)
- **Binary Size**: 1.6M (native), 3.2M (universal)
- **Compiler Warnings**: 0
- **Platform**: macOS 12.0+ (Intel + Apple Silicon)

### Recent Changes

**v1.1.28** (2025-11-01):
- Added `./test.sh --check-all` for comprehensive quality checks
- Enhanced commit-helper.sh with untracked files warning
- Fixed shellcheck warnings across all scripts

**v1.1.27** (2025-11-01):
- Added CI/CD configuration validation
- Enhanced error messages with actionable guidance
- Added build progress indicators for universal builds

### Current Work

See TODO.md for pending enhancements.

### Core Functionality

**Working**:
- ✅ `fontlift list` - List installed fonts by path/name
- ✅ `fontlift install <font>` - Install font files
- ✅ `fontlift uninstall <font>` - Uninstall fonts (keep files)
- ✅ `fontlift remove <font>` - Remove fonts (delete files)
- ✅ Universal binary support (x86_64 + arm64)

### Build & Test

```bash
./build.sh          # Build release binary
./build.sh --ci     # CI mode (fast)
./test.sh           # Run all tests
./test.sh --ci      # CI mode (silent)
```

### Release Process

```bash
# 1. Update version in Sources/fontlift/fontlift.swift
# 2. Update CHANGELOG.md
# 3. Commit and tag
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin main --tags
# 4. GitHub Actions creates release automatically
```

---

For development guidelines, see CLAUDE.md.
For planned enhancements, see TODO.md.
For version history, see CHANGELOG.md.
