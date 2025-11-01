# TODO.md
<!-- this_file: TODO.md -->

## Quality & Robustness Improvements (Current Sprint)

### Task 1: System Font Protection
- [ ] Add safeguard to prevent modifying system fonts in `/System/Library/Fonts/` and `/Library/Fonts/`
- [ ] Implement path validation in `uninstall` and `remove` commands
- [ ] Add clear error message explaining system fonts cannot be modified
- [ ] Add test cases for system font protection
- **Rationale**: Prevents catastrophic user errors that could destabilize macOS

### Task 2: Ambiguous Name Resolution
- [ ] Detect when multiple font files match a provided name with `-n` flag
- [ ] Fail with descriptive error listing all matching fonts
- [ ] Advise users to use unique PostScript name or direct file path
- [ ] Add test cases for ambiguous name scenarios
- **Rationale**: Ensures deterministic behavior, prevents accidental removal of wrong font variant

### Task 3: Automated Version Management
- [ ] Enhance `scripts/prepare-release.sh` to accept version number as argument
- [ ] Auto-update version constant in `Sources/fontlift/fontlift.swift`
- [ ] Auto-update `CHANGELOG.md` with new version section
- [ ] Auto-commit changes and create git tag
- [ ] Add validation to ensure version consistency
- **Rationale**: Eliminates human error in release workflow, ensures version consistency

---

## Future Enhancements (Low Priority)

### Testing & Quality
- [ ] Create test font files for integration tests
- [ ] Add functional tests for each command
- [ ] Test permission handling edge cases
- [ ] Test font collection handling (.ttc/.otc files)
- [ ] Increase test coverage to 80%+

### Feature Enhancements
- [ ] Add confirmation prompts for destructive operations (remove command)
- [ ] Add `--force` flag to skip confirmations
- [ ] Add `--dry-run` flag for previewing operations
- [ ] Add batch operations (multiple fonts at once)
- [ ] Add font metadata display command
- [ ] Add search/filter capabilities for list command

### Distribution
- [ ] Submit to Homebrew core (homebrew/core)
- [ ] Create installation guide for package managers
- [ ] Add binary notarization for macOS Gatekeeper

---

All current development complete. See WORK.md for status.
