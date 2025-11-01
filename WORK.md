# WORK.md
<!-- this_file: WORK.md -->

## Project Status

**Current Version**: v1.1.29 (IN DEVELOPMENT)
**Last Updated**: 2025-11-01

### Core Metrics

- **Test Suite**: 63 tests passing (25 Swift + 23 Scripts + 15 Integration)
- **Test Execution**: ~22-25s
- **Build Time**: ~6-8s (release mode)
- **Binary Size**: 1.6M (native), 3.2M (universal)
- **Compiler Warnings**: 0
- **Platform**: macOS 12.0+ (Intel + Apple Silicon)
- **Source Lines**: 630 lines (main file)

### Recent Changes

**v1.1.29** (2025-11-01 - IN DEVELOPMENT):
- **System Font Protection**: Prevents uninstall/remove operations on `/System/Library/Fonts/` and `/Library/Fonts/`
- **Ambiguous Name Resolution**: Fails when multiple fonts match `-n` name, lists all matches, advises using file path
- Added 2 new Swift unit tests for system font protection
- Test count: 61 → 63 tests (+2 safety feature tests)
- Source lines: 564 → 630 lines (+66 lines for safety checks)
- **Impact**: Major safety improvement - prevents catastrophic system font deletion and ambiguous operations

**v1.1.28** (2025-11-01):
- Streamlined codebase by removing enterprise tooling
- Removed VerifyVersion command (use scripts/validate-version.sh instead)
- Removed development helper scripts (commit-helper, verify-ci-config, etc.)
- Simplified to core font management functionality
- Test count: 65 → 61 tests (removed enterprise feature tests)

**v1.1.27** (2025-11-01):
- Added CI/CD configuration validation
- Enhanced error messages with actionable guidance
- Added build progress indicators for universal builds

### Current Work

Quality & robustness improvements complete! See TODO.md for completed tasks and future enhancements.

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
