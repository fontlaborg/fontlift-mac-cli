# PLAN.md
<!-- this_file: PLAN.md -->

## Project Overview

**fontlift-mac-cli** - macOS CLI tool for font management

**One-sentence scope**: Install, uninstall, list, and remove fonts on macOS via CLI, supporting both file paths and internal font names.

**Current Version**: v1.1.17

## Project Status

### ✅ Completed Features

**Core Functionality** (v1.1.0):
- List fonts with paths and/or names
- Install fonts with Core Text APIs
- Uninstall fonts (keep files)
- Remove fonts (delete files)
- Sorted mode for list command
- All command aliases (l, i, u, rm)

**CI/CD Automation** (v1.1.3-v1.1.10):
- GitHub Actions for automated testing (CI workflow)
- GitHub Actions for automated releases (Release workflow)
- Version validation with auto-fix capability
- Binary artifact creation with checksums
- CHANGELOG enforcement
- Automatic release note extraction
- Version detection fallback mechanism

**Quality & Testing** (v1.1.0-v1.1.17):
- 23 comprehensive tests (unit + scripts test suite)
- CLI error handling tests
- Project validation tests
- Scripts workflow validation (build, test, publish)
- Zero compiler warnings
- Fast test execution (<5 seconds)

---

## Phase 3: Production Polish ✅

**Completed**: All tasks finished in v1.1.7-v1.1.10
- ✅ Improved .gitignore coverage
- ✅ Enhanced build script safety with `set -euo pipefail`
- ✅ Added comprehensive inline code documentation

---

## Phase 4: Quality & Reliability Improvements (In Progress)

**Objective**: Strengthen testing infrastructure and improve error handling.

### ✅ Task 1: Create Scripts Test Suite (Completed v1.1.17)
**Goal**: Verify all bash scripts work correctly and handle errors properly.

**Completed**:
- Created Tests/scripts_test.sh with 23 automated tests
- Tested build.sh, test.sh, publish.sh workflows (success, --ci, --help, error cases)
- Tested validate-version.sh and get-version.sh
- Integrated into main test.sh workflow
- Prevented recursive invocation with SKIP_SCRIPT_TESTS environment flag

**Results**:
- 23/23 tests passing
- All scripts verified for success and failure modes
- CI mode verification working
- Help text validation complete

### ✅ Task 2: Add Version Command Validation (Completed v1.1.23)
**Goal**: Prevent runtime version mismatches between binary and code.

**Completed**:
- Added `fontlift verify-version` command
- Compares binary version with source code version (via get-version.sh)
- Provides clear error messages when mismatches detected
- Added 2 tests to scripts test suite
- Command available for development and debugging

**Results**:
- 25 script tests passing (was 23)
- Version consistency verification working correctly
- Helpful error messages guide users to rebuild

### ✅ Task 3: Enhance Error Messages (Completed v1.1.24)
**Goal**: Provide clear, actionable error messages.

**Completed**:
- Reviewed all error messages in fontlift.swift
- Added file paths to all error messages
- Added "Common causes" sections with specific suggestions
- Added sudo guidance for permission errors
- Added `fontlift list -n` suggestions for font name errors
- Added fc-cache suggestion for font database errors
- Tested error scenarios to verify helpfulness

**Results**:
- All error messages now include actionable guidance
- Users get specific troubleshooting steps based on error type
- Permission errors suggest appropriate escalation
- Font not found errors guide users to discovery commands

---

## Future Enhancements (Backlog)

### Testing Improvements
- Create test font files for integration tests
- Add functional tests for each command
- Test permission handling edge cases
- Test font collection handling thoroughly
- Increase test coverage to 80%+

### User Experience Features
- Add confirmation prompts for destructive operations
- Add `--force` flag to skip confirmations
- Add `--dry-run` flag for previewing operations
- Add progress indicators for large operations
- Better error messages with actionable guidance

### Advanced Features
- Batch operations (install/uninstall multiple fonts)
- Font metadata display command
- Search/filter capabilities for list command
- Support for font validation before installation
- System-level font operations (with sudo handling)

---

## Success Metrics

**Code Quality**:
- Zero compiler warnings ✅
- All tests passing ✅
- Functions <20 lines ✅
- Files <400 lines ✅

**CI/CD**:
- Automated testing on every push ✅
- Automated releases on version tags ✅
- Auto-fix for version mismatches ✅
- Build completes in <2 minutes ✅
- Release completes in <10 minutes ✅

**Documentation**:
- README clear and concise ✅
- CHANGELOG maintained ✅
- Version management documented ✅
- All `this_file` comments present ✅

**Performance**:
- Build time: <10s (release mode) ✅
- Test time: <5s ✅
- Binary size: <1MB ✅
