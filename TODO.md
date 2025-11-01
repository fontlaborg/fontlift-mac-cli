# TODO.md
<!-- this_file: TODO.md -->

## ALWAYS

test the build & publish GH actions via `gh run`, analyze the logs, fix, iterate, keep updating @WORK.md @TODO.md @PLAN.md @CHANGELOG.md

---

## Phase 4: Quality & Reliability Improvements

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
