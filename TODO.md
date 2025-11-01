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

### Task 2: Add Version Command Validation
**Goal**: Prevent runtime version mismatches between binary and code.

- [ ] Add runtime version check in main CLI
- [ ] Compare binary version with actual code version
- [ ] Warn if mismatch detected (for development builds)
- [ ] Add test for version consistency
- [ ] Document version verification process

### Task 3: Enhance Error Messages with Actionable Guidance
**Goal**: Provide clear, actionable error messages that help users fix problems.

- [ ] Review all error messages in fontlift.swift
- [ ] Add specific file path in "file not found" errors
- [ ] Add suggestions for common mistakes (e.g., missing sudo)
- [ ] Add examples in permission errors
- [ ] Test error scenarios and verify messages are helpful
- [ ] Document common error patterns

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
