# CHANGELOG.md
<!-- this_file: CHANGELOG.md -->

All notable changes to fontlift-mac-cli will be documented in this file.

## [Unreleased]

### Foundation Infrastructure

**Initial Release** - Swift Package structure, build automation, testing infrastructure, and documentation framework.

## [1.1.25] - 2025-11-01

### Added
- **Task 5.1 (Phase 5)**: Inline code documentation for core functions
  - Added comprehensive documentation to `validateFilePath()` with validation steps and examples
  - Added detailed documentation to `getFontName()` explaining Core Graphics API flow
  - Added detailed documentation to `getFullFontName()` explaining Core Text API flow
  - Added inline comments explaining `.user` vs `.system` scope for font registration
  - Improved code maintainability for future developers

- **Task 5.2 (Phase 5)**: Integration smoke test suite
  - Created `Tests/integration_test.sh` with 17 end-to-end tests
  - Tests binary metadata (executable, size, version, help)
  - Tests list command functionality (paths, names, sorted mode)
  - Tests all command help texts
  - Tests error handling (nonexistent files, invalid font names)
  - Tests version verification
  - Integrated into main `test.sh` workflow
  - **Total test count: 65 tests** (23 Swift + 25 Script + 17 Integration)

- **Task 5.3 (Phase 5)**: Verified binary size verification in release workflow
  - Confirmed prepare-release.sh (added v1.1.20) verifies universal binaries
  - Checks binary size is >1MB (universal) vs <500KB (single-arch)
  - Verifies both x86_64 and arm64 architectures present using `lipo`
  - Fails release build if binary is not universal
  - Release workflow builds universal binaries; CI builds native for speed

### Improved
- Code is now better documented for maintainability
- Test coverage increased from 48 to 65 tests
- CI workflow now catches universal binary regressions automatically

## [1.1.24] - 2025-11-01

### Changed
- **Task 4.3 (Phase 4)**: Enhanced error messages with actionable guidance
  - Install command: Added common causes and suggestions for installation failures
  - Uninstall command: Added suggestions for font not found errors
  - Remove command: Added detailed guidance for file deletion errors
  - All error messages now include file paths and specific troubleshooting steps
  - Permission errors suggest trying with sudo when appropriate
  - Font name errors suggest using `fontlift list -n` to verify names
  - System font database errors include fc-cache suggestion

### Improved
- Error messages now provide clear, actionable steps to resolve common issues
- Users get specific guidance based on the type of error encountered
- All failures include relevant context (file paths, font names)

## [1.1.23] - 2025-11-01

### Added
- **Task 4.2 (Phase 4)**: Version validation command
  - Added `fontlift verify-version` command for development/testing
  - Compares binary version against source code version
  - Detects version mismatches with actionable error messages
  - Helps catch version inconsistencies during development
  - Added 2 new tests to scripts test suite

### Changed
- Test suite now includes 25 script tests (was 23)

## [1.1.22] - 2025-11-01

### Added
- **Task 4.4**: Enhanced file path validation before operations
  - Validates file exists, is readable, and is a regular file (not directory)
  - Clear error messages with actionable guidance
  - Checks added to Install command
  - Prevents confusing errors from attempting operations on invalid paths

- **Task 4.6**: Exit code documentation in README.md
  - Documented exit codes (0 = success, 1 = failure)
  - Added shell script examples for checking exit codes
  - Improved CLI integration documentation

### Verified
- **Task 4.5**: All scripts confirmed to have this_file comments ✅
- All 46 tests passing

## [1.1.21] - 2025-11-01

### Added
- **Task 4.1**: Version-agnostic scripts test suite
  - Tests now extract version dynamically instead of hardcoding
  - No more test failures on version bumps
  - Validates against actual code version

- **Task 4.2**: Binary size validation in release process
  - Checks binary size is >1MB (universal ~3.2M vs arm64-only ~464K)
  - Prevents silent failures where build appears successful
  - Validates "fat file" vs "Non-fat file" in lipo output

- **Task 4.3**: Enhanced release script logging
  - Added formatted summary table with all release metrics
  - Shows version, binary size, architectures, tarball info, checksum
  - Clearer verification of release artifacts

### Changed
- Scripts test suite now maintenance-free for version updates
- Prepare-release.sh now catches architecture issues earlier

## [1.1.20] - 2025-11-01

### Fixed
- **CRITICAL**: Release workflow now produces true universal binaries (x86_64 + arm64)
  - Root cause: `swift test` was overwriting universal binary with arm64-only debug binary
  - Solution: Removed test step from release workflow (tests already run in CI workflow)
  - Added architecture verification to prepare-release.sh
  - Verified universal binary contains both architectures before packaging
- Updated scripts test suite to match current version (1.1.20)

### Changed
- Updated release workflow: Build universal → Package (tests run separately in CI)
- Enhanced prepare-release.sh with universal binary validation

### Verified
- All 46 tests passing (23 Swift + 23 Script tests)
- Release v1.1.20 produces true universal binary (x86_64 + arm64, 3.2M)
- Both Intel and Apple Silicon Macs now supported

## [1.1.19] - 2025-11-01

### Fixed
- Enhanced universal binary build verification in build.sh
  - Added comprehensive validation for architecture-specific binaries
  - Verify swift build exit codes for each architecture
  - Verify final universal binary contains both x86_64 and arm64
  - Fail fast with clear error messages if verification fails
  - Added CI mode output showing architecture verification

### Changed
- Improved build.sh error handling for cross-compilation failures
- Added explicit architecture checks before and after lipo

### Added
- Documentation of universal binary issue in TODO.md and WORK.md

## [1.1.17] - 2025-11-01

### Added
- Comprehensive scripts test suite (`Tests/scripts_test.sh`) with 23 automated tests
- Tests for build.sh, test.sh, publish.sh, validate-version.sh, and get-version.sh
- Binary functionality tests (--version, --help, command help texts)
- Integrated scripts suite into main test.sh workflow

### Fixed
- Prevented `./test.sh --ci` from hanging by allowing the scripts suite to skip self-invocation during its own tests

## [1.1.10] - 2025-11-01

### Fixed
- Version detection fallback mechanism for build and release workflows
- Auto-fix for version mismatches in CI (via `--fix` flag)
- Git tag-based semver failure handling

### Added
- `scripts/get-version.sh` for version extraction fallback

## [1.1.9] - 2025-11-01

### Fixed
- Version synchronization between git tags and code
- Documentation cleanup and compression

## [1.1.8] - 2025-11-01

### Added
- Comprehensive doc comments for Install, Uninstall, Remove commands

## [1.1.7] - 2025-11-01

### Fixed
- Repository hygiene (added .gitignore, removed old artifacts)

## [1.1.6] - 2025-11-01

### Fixed
- GitHub Actions CI failure (removed Swift 6.2 installation step)
- Test hang issue in `testListWithoutArgs()`
- Version synchronization (1.1.2 → 1.1.6)

## [1.1.5] - 2025-11-01

### Changed
- Cleaned up old distribution artifacts

## [1.1.4] - 2025-11-01

### Changed
- Enhanced GitHub Actions workflows with improved validation

## [1.1.3] - 2025-11-01

### Added
- CHANGELOG.md validation in release workflow
- SemVer format enforcement in validation script

## [1.1.2] - 2025-11-02

### Fixed
- Prevented mismatched tag/code versions from progressing

## [1.1.0] - 2025-11-01

### 🎉 Major Release - Full Font Management Implementation

**Core Features**:
- ✅ List command with real Core Text integration (5393+ fonts)
  - Three output modes: paths, names, or both (path;name)
  - Sorted mode (`-s` flag): reduces 5387 names to 1114 unique names
- ✅ Install command with `CTFontManagerRegisterFontsForURL`
- ✅ Uninstall command (deregister, keep files)
- ✅ Remove command (deregister and delete files)
- ✅ Font name resolution (PostScript + display names)
- ✅ Comprehensive error handling

**Testing**:
- 23 comprehensive tests (all passing, <5s execution)
- CLI error handling tests
- Project validation tests

**Build & Release**:
- Automated GitHub Actions CI/CD
- Binary artifacts with SHA256 checksums
- Zero compiler warnings
