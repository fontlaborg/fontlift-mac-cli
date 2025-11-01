# TODO.md
<!-- this_file: TODO.md -->

## ALWAYS

test the build & publish GH actions via `gh run`, analyze the logs, fix, iterate, keep updating @WORK.md @TODO.md @PLAN.md @CHANGELOG.md

---

## ~~CRITICAL: Fix Universal Binary in GitHub Actions~~ ✅ RESOLVED (v1.1.20)

**Problem**: GitHub Actions releases were producing arm64-only binaries instead of universal (x86_64 + arm64) binaries.

**Root Cause**: `swift test` in release workflow was overwriting the universal binary with an arm64-only debug binary.

**Solution**: Removed test step from release workflow (tests already run in CI workflow).

**Verification**: v1.1.20 release produces true universal binary (x86_64 + arm64, 3.2M).

---

## Phase 4: Quality & Reliability Improvements

### ~~⚡ Quick Wins (Small-Scale Improvements)~~ ✅ COMPLETED (v1.1.21)

#### ~~Task 4.1: Make Scripts Test Suite Version-Agnostic~~ ✅
- ✅ Extract version dynamically from get-version.sh instead of hardcoding
- ✅ Update validate-version.sh test to use dynamic version
- ✅ Update get-version.sh match test to use dynamic version
- ✅ Tests pass after change - now maintenance-free

#### ~~Task 4.2: Add Binary Size Validation to Release Process~~ ✅
- ✅ Add size check to prepare-release.sh (>1M minimum)
- ✅ Fail fast if binary size is suspiciously small
- ✅ Add "fat file" verification (no "Non-fat file")
- ✅ Validation catches arm64-only binaries
- ✅ Documented in CHANGELOG

#### ~~Task 4.3: Enhance Release Script Logging~~ ✅
- ✅ Added formatted summary table with all metrics
- ✅ Shows version, size, architectures, tarball, checksum
- ✅ Clear visual separation with box drawing
- ✅ Tested and working

---

### ~~⚡ Next Quick Wins (Small-Scale Improvements)~~ ✅ COMPLETED (v1.1.22)

#### ~~Task 4.4: Add File Path Validation Before Operations~~ ✅
- ✅ Add path validation function (exists, readable, is file)
- ✅ Use validation in Install command before attempting installation
- ✅ Improve error message to include actual file path and issue
- ✅ Tested with nonexistent file and directory
- ✅ Documented in CHANGELOG

#### ~~Task 4.5: Add .this_file Comments to All Scripts~~ ✅
- ✅ Verified all scripts already have this_file comments
- ✅ All scripts compliant with CLAUDE.md guidelines

#### ~~Task 4.6: Add Exit Code Documentation~~ ✅
- ✅ Document exit codes in README.md
- ✅ Add examples of checking exit codes in shell scripts
- ✅ All exit codes are consistent (0=success, 1=failure)

---

### ~~Task 2: Add Version Command Validation~~ ✅ COMPLETED (v1.1.23)
**Goal**: Prevent runtime version mismatches between binary and code.

- ✅ Add runtime version check in main CLI
- ✅ Compare binary version with actual code version
- ✅ Warn if mismatch detected (for development builds)
- ✅ Add test for version consistency
- ✅ Document version verification process

### ~~Task 3: Enhance Error Messages with Actionable Guidance~~ ✅ COMPLETED (v1.1.24)
**Goal**: Provide clear, actionable error messages that help users fix problems.

- ✅ Review all error messages in fontlift.swift
- ✅ Add specific file path in "file not found" errors
- ✅ Add suggestions for common mistakes (e.g., missing sudo)
- ✅ Add examples in permission errors
- ✅ Test error scenarios and verify messages are helpful
- ✅ Document common error patterns

---

## ~~Phase 5: Final Polish & Code Quality~~ ✅ COMPLETED (v1.1.25)

### ~~Task 5.1: Add Inline Code Documentation for Core Functions~~ ✅
**Goal**: Improve code maintainability by documenting complex Core Text API usage.

- ✅ Add detailed comments to getFontName() explaining PostScript name extraction
- ✅ Add detailed comments to getFullFontName() explaining CTFontDescriptor usage
- ✅ Document validateFilePath() parameters and return behavior
- ✅ Add comments explaining CTFontManager scope (.user vs .system)
- ✅ Verify all non-trivial functions have clear explanatory comments

### ~~Task 5.2: Add Integration Smoke Test~~ ✅
**Goal**: Verify binary works end-to-end with real filesystem operations.

- ✅ Create Tests/integration_test.sh for end-to-end testing
- ✅ Test binary --version, --help, list commands work correctly
- ✅ 17 integration tests covering binary metadata, list command, help texts, error handling
- ✅ Integrate into main test.sh workflow
- ✅ Total test count: 65 tests (23 Swift + 25 Script + 17 Integration)

### ~~Task 5.3: Binary Size Verification in Release Workflow~~ ✅
**Goal**: Prevent regression where universal binary becomes single-arch.

- ✅ Binary size verification already exists in prepare-release.sh (added v1.1.20)
- ✅ Verifies binary is >1MB (universal) not <500KB (single-arch)
- ✅ Uses lipo to verify both x86_64 and arm64 architectures present
- ✅ Fails release if binary is not universal
- ✅ Release workflow builds universal binaries with --universal flag
- ✅ CI workflow builds native binaries for speed (testing only)

---

## Future Enhancements (Low Priority)

### Testing & Quality
- [ ] Create test font files for integration tests
- [ ] Add functional tests for each command
- [ ] Test permission handling
- [ ] Test font collection handling
- [ ] Add edge case tests (invalid files, missing fonts)
- [ ] Increase test coverage to 80%+

### Feature Enhancements
- [ ] Add confirmation prompts for destructive operations (remove command)
- [ ] Add `--force` flag to skip confirmations
- [ ] Add `--dry-run` flag for previewing operations
- [ ] Add batch operations (multiple fonts at once)
- [ ] Add font metadata display command
- [ ] Add search/filter capabilities for list command
