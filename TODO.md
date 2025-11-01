# TODO.md
<!-- this_file: TODO.md -->

## ALWAYS

test the build & publish GH actions via `gh run`, analyze the logs, fix, iterate, keep updating @WORK.md @TODO.md @PLAN.md @CHANGELOG.md 

## Phase 3: Production Polish & Documentation ✅

### Task 1: Improve .gitignore Coverage ✅
- [x] Review current .gitignore file
- [x] Add Swift/Xcode build artifact patterns
- [x] Add .DS_Store and OS temp files
- [x] Verify .build/ is ignored
- [x] Verify Package.resolved is tracked (NOT ignored)
- [x] Test: Build and check git status is clean

### Task 2: Enhance Build Script Safety ✅
- [x] Add `set -euo pipefail` to build.sh
- [x] Add `set -euo pipefail` to test.sh
- [x] Add `set -euo pipefail` to publish.sh
- [x] Improve error messages in all scripts
- [x] Test: Scripts fail fast on errors

### Task 3: Add Inline Code Documentation ✅
- [x] Add doc comments to List command
- [x] Add doc comments to Install command (already has docs)
- [x] Add doc comments to Uninstall command (already has docs)
- [x] Add doc comments to Remove command (already has docs)
- [x] Document validation logic
- [x] Review all comments for clarity

---

## Phase 4: Quality & Reliability Improvements (In Progress)

### Task 1: Create Scripts Test Suite
**Goal**: Verify all bash scripts work correctly and handle errors properly.

- [ ] Create tests/scripts_test.sh
- [ ] Test build.sh (success, failure, --ci mode, --help)
- [ ] Test test.sh (success, --ci mode, --help)
- [ ] Test publish.sh (--ci mode verification, --help)
- [ ] Test validate-version.sh (match, mismatch, --fix, invalid input)
- [ ] Test get-version.sh (extraction, error cases)
- [ ] Add to ./test.sh workflow

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
