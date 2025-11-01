# CHANGELOG.md
<!-- this_file: CHANGELOG.md -->

All notable changes to fontlift-mac-cli will be documented in this file.

## [Unreleased]

## [1.1.29] - 2025-11-01

### Added
- **System Font Protection**: Critical safety feature to prevent modifying system fonts
  - Added `isSystemFontPath()` helper function to detect protected directories
  - Blocks uninstall/remove operations on `/System/Library/Fonts/` and `/Library/Fonts/`
  - Clear error messages explain why system fonts cannot be modified
  - Protects macOS stability by preventing accidental system font deletion
  - Added 2 new Swift unit tests: `testUninstallSystemFontProtection`, `testRemoveSystemFontProtection`

- **Ambiguous Name Resolution**: Ensures deterministic behavior when using `-n` flag
  - Detects when multiple font files match a provided font name
  - Fails with descriptive error listing all matching font file paths
  - Advises users to specify font by file path instead of ambiguous name
  - Prevents accidental removal of wrong font variant (e.g., Bold vs Regular)
  - Implemented in both `uninstall -n` and `remove -n` commands

### Changed
- Modified name resolution logic to collect all matches instead of using first match
- Test count: 61 → 63 tests (added 2 system font protection tests)
- Swift test count: 23 → 25 tests
- Source file size: 564 → 630 lines (+66 lines for safety features)

### Improved
- **Safety**: Major improvement - tool can no longer accidentally break macOS
- **Predictability**: Ambiguous operations now fail explicitly with guidance
- **User Experience**: Clear error messages with actionable solutions
- **Code Quality**: All 63 tests passing, zero compiler warnings

## [1.1.28] - 2025-11-01

### Removed (Streamlining)
- **Enterprise tooling and development helpers**:
  - Removed `VerifyVersion` command (replaced by scripts/validate-version.sh)
  - Removed `.git-hooks/pre-commit` template
  - Removed `TROUBLESHOOTING.md` (excessive for simple tool)
  - Removed `scripts/commit-helper.sh`
  - Removed `scripts/verify-ci-config.sh`
  - Removed `scripts/verify-release-artifact.sh`
  - Removed `scripts/verify-version-consistency.sh`
  - Removed `scripts/performance-baselines.md`

### Changed
- **Simplified scripts**:
  - build.sh: Removed enterprise validation checks (Swift version, disk space, permissions)
  - publish.sh: Removed enterprise dependency verification
  - prepare-release.sh: Streamlined to core release artifact creation
  - validate-version.sh: Simplified version checking logic
  - test.sh: Removed `--verify-ci`, `--shellcheck`, `--check-size`, `--check-performance`, `--check-version`, `--check-all` flags

### Improved
- **Codebase simplification**: Removed 8 enterprise helper files and ~500 lines of code
- **Test suite**: Streamlined from 65 → 61 tests (removed 4 enterprise feature tests)
- **Focus**: Back to core font management functionality only
- **Maintainability**: Simpler codebase, easier to understand and modify

## [1.1.27] - 2025-11-01

### Added
- **Phase 10 (CI/CD Robustness & Developer Experience)**:
  - **Task 10.1**: GitHub Actions workflow status verification
    - Created `scripts/verify-ci-config.sh` for CI/CD configuration validation
    - Added `--verify-ci` flag to test.sh
    - Verifies CI and Release workflows are correctly configured
    - Checks for required jobs, steps, and scripts

  - **Task 10.2**: Pre-commit hook template
    - Created `.git-hooks/pre-commit` template for developer use
    - Hook checks version consistency before commits
    - Warns if CHANGELOG.md hasn't been updated
    - Runs quick smoke test (build + unit tests)
    - Installation and bypass instructions included

  - **Task 10.3**: Build reproducibility verification
    - Added `--verify-reproducible` flag to build.sh
    - Builds binary twice and compares checksums
    - Detects non-deterministic build behavior
    - Tested: Swift builds are NOT reproducible (expected - timestamps embedded)

- **Phase 14 (Release Polish & Workflow Refinement)**:
  - **Task 14.1**: CHANGELOG extraction verification
    - Verified release.yml's sed command extracts release notes correctly
    - Tested extraction with v1.1.27 section (28 lines)
    - Confirmed proper isolation of version-specific sections

  - **Task 14.2**: Test execution time baseline
    - Added timing to test.sh for all test suites
    - Displays execution times: Swift (4s), Scripts (13s), Integration (3s)
    - Total baseline: ~20s on macOS 14 M-series
    - Helps detect performance regressions

  - **Task 14.3**: Git commit helper script
    - Created scripts/commit-helper.sh for streamlined commits
    - Validates version, CHANGELOG, tests, and CI config before commit
    - Provides commit message template
    - Shows clear git status summary

- **Phase 21 (Production Deployment Readiness)**:
  - **Task 21.1**: Homebrew installation documentation
    - Added "Via Homebrew (Coming Soon)" section to README.md
    - Documented future installation: `brew tap fontlaborg/fontlift && brew install fontlift`
    - Documented system requirements (macOS 12.0+, Intel/arm64)

  - **Task 21.2**: Comprehensive usage examples
    - Added "Advanced Usage Examples" section to README.md
    - Example 1: Installing a Custom Font Family (batch installation)
    - Example 2: Batch Font Management (directory operations, reinstall)
    - Example 3: Troubleshooting Font Installation (file checks, cache rebuild)
    - Example 4: Verifying Installed Fonts (comprehensive verification)

  - **Task 21.3**: Release workflow verification
    - Verified CHANGELOG extraction pattern (extracts 47 lines for v1.1.27)
    - Verified artifact upload configuration (dist/* uploads tarball + checksum)
    - Confirmed release workflow ready for v1.1.27

- **Phase 29 (Error Handling & User Experience Refinements)**:
  - **Task 29.1**: Enhanced validation error messages with actionable guidance
    - Swift version check shows current vs required version side-by-side
    - Lists common causes (Xcode too old, using system Swift)
    - Provides specific solutions (xcode-select, Swift download, version checking)
    - Disk space error shows actual available space with suggestions for freeing space
    - Build permissions error includes common causes and 3 solutions
    - All validation failures now provide clear, actionable guidance

  - **Task 29.2**: Build progress indicators for long operations
    - Added phased progress messages for universal builds
    - "📦 Phase 1/3: Building for x86_64 (Intel)..."
    - "📦 Phase 2/3: Building for arm64 (Apple Silicon)..."
    - "🔗 Phase 3/3: Creating universal binary..."
    - Completion checkmarks after each phase (✅ x86_64 complete, etc.)
    - Prevents perceived hangs during long builds

  - **Task 29.3**: Enhanced test output readability
    - Added clear separators between test suite sections (━━━━ lines)
    - Added test counts to suite headers: "Suite 1/3: Swift Unit Tests (23 tests)"
    - Enhanced final summary: "✅ All Tests Passed! (65 total)"
    - Improved timing display with bullet points and test counts
    - Consistent formatting across all three test suites

### Improved
- Enhanced developer experience with pre-commit safety checks and commit helper
- Better CI/CD configuration validation tools
- Build process transparency with reproducibility checks
- Test performance monitoring with execution time baselines
- Significantly improved README with Homebrew section and 4 advanced usage examples
- Users can now quickly find solutions for common workflows with copy-paste ready commands
- Release workflow verified end-to-end for v1.1.27
- Error messages now provide actionable guidance with common causes and specific solutions
- Universal build process provides clear progress indicators (Phase 1/3, 2/3, 3/3)
- Test output is highly scannable with suite separators and comprehensive summaries
- Developer and user experience greatly enhanced with better feedback and guidance

## [1.1.26] - 2025-11-01

### Added
- **Phase 6 (Production Hardening)**:
  - **Task 6.1**: Comprehensive script error handling
    - Added dependency verification functions to build.sh, prepare-release.sh, validate-version.sh
    - Fixed incorrect `shift` commands in test.sh and publish.sh argument parsing
    - All scripts now verify required dependencies before execution
    - Clear error messages with installation instructions for missing dependencies

  - **Task 6.2**: Release artifact smoke testing
    - Created scripts/verify-release-artifact.sh for post-release verification
    - Downloads release tarball and checksum from GitHub
    - Verifies checksum integrity
    - Tests binary functionality (--version, --help, list command)
    - Ensures published releases are actually usable

  - **Task 6.3**: Common failure modes documentation
    - Created comprehensive TROUBLESHOOTING.md guide (500+ lines)
    - Documented 20+ common issues with solutions
    - Sections: Build, Test, Installation, Runtime, CI/CD, Release issues
    - Added debugging tips and quick reference guide

- **Phase 7 (Final Release Preparation)**:
  - **Task 7.1**: Enhanced README with release installation instructions
    - Added checksum verification steps
    - Updated installation section with VERSION variable
    - Added troubleshooting section reference

  - **Task 7.2**: README Quick Start section
    - Added 4 practical workflow examples
    - Discover, install, uninstall, remove workflows
    - Copy-paste ready commands

  - **Task 7.3**: Version bump to 1.1.26
    - Updated version constant in source code
    - Verified version consistency
    - All 65 tests passing

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
