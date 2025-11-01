# TODO.md
<!-- this_file: TODO.md -->

## Phase 3: Production Polish & Documentation

### Task 1: Improve .gitignore Coverage
- [ ] Review current .gitignore file
- [ ] Add Swift/Xcode build artifact patterns
- [ ] Add .DS_Store and OS temp files
- [ ] Verify .build/ is ignored
- [ ] Verify Package.resolved is tracked (NOT ignored)
- [ ] Test: Build and check git status is clean

### Task 2: Enhance Build Script Safety
- [ ] Add `set -euo pipefail` to build.sh
- [ ] Add `set -euo pipefail` to test.sh
- [ ] Add `set -euo pipefail` to publish.sh
- [ ] Improve error messages in all scripts
- [ ] Test: Scripts fail fast on errors

### Task 3: Add Inline Code Documentation
- [ ] Add doc comments to List command
- [ ] Add doc comments to Install command (already has basic docs)
- [ ] Add doc comments to Uninstall command (already has basic docs)
- [ ] Add doc comments to Remove command (already has basic docs)
- [ ] Document validation logic
- [ ] Review all comments for clarity

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
