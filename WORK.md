# WORK.md
<!-- this_file: WORK.md -->

## Project Status

**Current Version**: v1.1.29 (IN DEVELOPMENT)
**Last Updated**: 2025-11-01

### Core Metrics

- **Test Suite**: 65 tests passing (27 Swift + 23 Scripts + 15 Integration)
- **Test Execution**: ~26s
- **Build Time**: ~7s (release mode)
- **Binary Size**: 1.6M (native), 3.2M (universal)
- **Compiler Warnings**: 0
- **Platform**: macOS 12.0+ (Intel + Apple Silicon)
- **Source Lines**: 741 lines (main file)

### Recent Changes

**v1.1.29** (2025-11-01 - IN DEVELOPMENT):
- **Round 6: Documentation & Correctness**
  - Fixed incorrect command suggestion (removed sudo from atsutil)
  - Updated PLAN.md to v1.1.29 and 65 tests

- **Round 5: Consistency & Polish**
  - Standardized error messages for font list retrieval
  - Enhanced shell-escaped command suggestions in ambiguous name errors
  - Source lines: 733 → 741 lines (+8 lines)

- **Round 4: Polish & User Experience**
  - Version synchronization: 1.1.28 → 1.1.29
  - Shell-safe path escaping for suggested commands
  - Enhanced duplicate detection with font name display
  - Source lines: 698 → 733 lines (+35 lines)

- **Round 3: Bug Fixes & Robustness**
  - Fixed critical bug: font name extraction after file deletion
  - Added race condition protection for concurrent operations
  - Enhanced error specificity with NSError code parsing
  - Source lines: 669 → 698 lines (+29 lines)

- **Round 2: Error Handling & Validation**
  - Enhanced list command error with troubleshooting steps
  - Added font format validation (.ttf, .otf, .ttc, .otc, .dfont)
  - Added 2 new tests for format validation
  - Test count: 63 → 65 tests
  - Source lines: 630 → 669 lines (+39 lines)

- **Round 1: Safety Features**
  - System Font Protection: Prevents operations on system font directories
  - Ambiguous Name Resolution: Fails when multiple fonts match `-n` name
  - Added 2 new tests for system font protection
  - Test count: 61 → 63 tests
  - Source lines: 564 → 630 lines (+66 lines)

- **Overall Impact**: Major safety, usability, and reliability improvements - fixed actual bugs, prevents catastrophic errors, provides clear guidance

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
