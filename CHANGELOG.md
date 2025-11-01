# CHANGELOG.md
<!-- this_file: CHANGELOG.md -->

All notable changes to fontlift-mac-cli will be documented in this file.

## [Unreleased]

### Foundation Infrastructure

**Initial Release** - Swift Package structure, build automation, testing infrastructure, and documentation framework.

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
