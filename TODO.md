# TODO.md
<!-- this_file: TODO.md -->

## Quality & Robustness Improvements - Round 7 (Completed)

### Round 7 Tasks (Test Coverage) ✅
1. **Added comprehensive unit tests for helper functions**
   - Created new test file: Tests/fontliftTests/HelperFunctionTests.swift (119 lines)
   - Added 16 unit tests providing direct coverage for 3 critical helper functions
   - Previously these were only tested indirectly through integration tests

2. **shellEscape() test coverage (4 tests)**
   - testShellEscapeSimplePath: Basic path wrapping in single quotes
   - testShellEscapePathWithSpaces: Spaces preserved within quotes
   - testShellEscapePathWithSingleQuote: Proper escaping with '\''
   - testShellEscapeEmptyPath: Empty string handling

3. **isSystemFontPath() test coverage (5 tests)**
   - testIsSystemFontPathSystemLibrary: /System/Library/Fonts/ detection
   - testIsSystemFontPathLibrary: /Library/Fonts/ detection
   - testIsSystemFontPathUserLibrary: User fonts correctly excluded
   - testIsSystemFontPathHomeDirectory: Home directory fonts excluded
   - testIsSystemFontPathRelative: Relative paths excluded

4. **isValidFontExtension() test coverage (7 tests)**
   - testIsValidFontExtensionTTF: .ttf and .TTF (case-insensitive)
   - testIsValidFontExtensionOTF: .otf and .OTF (case-insensitive)
   - testIsValidFontExtensionTTC: .ttc font collections
   - testIsValidFontExtensionOTC: .otc font collections
   - testIsValidFontExtensionDFont: .dfont Mac legacy format
   - testIsValidFontExtensionInvalidExtensions: .txt, .pdf, .zip rejected
   - testIsValidFontExtensionNoExtension: Files without extension rejected

5. **Test suite metrics**
   - Test count: 65 → 81 tests (+16, +24.6% increase)
   - Swift tests: 27 → 43 tests (+16, +59% increase)
   - All 81 tests passing (43 Swift + 23 Scripts + 15 Integration)
   - Execution time: ~22s (5s Swift + 14s Scripts + 3s Integration)

---

## Quality & Robustness Improvements - Round 6 (Completed)

### Round 6 Tasks (Documentation & Correctness) ✅
1. **Fixed incorrect command suggestion**
   - Corrected `sudo atsutil databases -remove` to `atsutil databases -remove`
   - atsutil doesn't require sudo for user-level operations
   - Fixed in 3 locations across error messages

2. **Updated PLAN.md for v1.1.29**
   - Updated version from v1.1.28 to v1.1.29
   - Updated test count from 61 to 65 tests
   - Ensures documentation consistency

---

## Quality & Robustness Improvements - Round 5 (Completed)

### Round 5 Tasks (Consistency & Polish) ✅
1. **Standardized font list retrieval error messages**
   - Unified error handling across uninstall and remove commands
   - Both now show same comprehensive troubleshooting steps
   - Consistent with list command's error messaging

2. **Enhanced shell-escaped command suggestions**
   - Applied `shellEscape()` to actual font paths in ambiguous name errors
   - Provides ready-to-run commands when multiple fonts match name
   - Users can copy-paste commands directly, even with spaces in paths
   - Format: shows both path and escaped command for each match

---

## Quality & Robustness Improvements - Round 4 (Completed)

### Round 4 Tasks (Polish & User Experience) ✅
1. **Version number synchronization**
   - Updated version constant from 1.1.28 to 1.1.29
   - Synced with CHANGELOG.md and WORK.md documentation
   - Ensures consistency across codebase

2. **Shell-safe path escaping**
   - Added `shellEscape()` helper function for path sanitization
   - Properly escapes special characters (spaces, quotes) in file paths
   - Used in error messages that suggest shell commands
   - Prevents copy-paste errors when paths contain special characters

3. **Enhanced duplicate detection in install command**
   - Detects "already installed" errors specifically
   - Displays font name when duplicate detected
   - Provides clear guidance: "Use 'fontlift uninstall' to remove before reinstalling"
   - Better user experience vs. generic error message

---

## Quality & Robustness Improvements - Round 3 (Completed)

### Round 3 Tasks (Bug Fixes & Robustness) ✅
1. **Fixed font name extraction bug in remove command**
   - Critical bug: was reading font metadata AFTER file deletion
   - Now extracts name before deletion for accurate success messages
   - Added fallback to filename if metadata unavailable

2. **Race condition protection**
   - Added file existence check immediately before deletion
   - Graceful handling if file removed by another process
   - Prevents confusing errors in concurrent scenarios

3. **Enhanced error specificity in remove command**
   - Parse NSError codes for targeted guidance
   - Distinguish file-not-found (success) from permission-denied (error)
   - Specific suggestions based on error type (e.g., suggest sudo)

---

## Quality & Robustness Improvements - Round 2 (Completed)

### Round 2 Tasks (Error Handling & Validation) ✅
1. **Enhanced list command error messaging**
   - Added descriptive error with troubleshooting steps for font database failures
   - Suggests atsutil database rebuild and Console.app checks

2. **Font format validation**
   - Added `isValidFontExtension()` helper function
   - Validates .ttf, .otf, .ttc, .otc, .dfont extensions
   - Integrated into file validation for early error detection
   - Prevents cryptic Core Text errors from invalid files
   - Added 2 new tests for format validation

---

## Quality & Robustness Improvements - Round 1 (Completed v1.1.29)

### Task 1: System Font Protection ✅
- [x] Add safeguard to prevent modifying system fonts in `/System/Library/Fonts/` and `/Library/Fonts/`
- [x] Implement path validation in `uninstall` and `remove` commands
- [x] Add clear error message explaining system fonts cannot be modified
- [x] Add test cases for system font protection (2 new tests)
- **Result**: Prevents catastrophic user errors that could destabilize macOS

### Task 2: Ambiguous Name Resolution ✅
- [x] Detect when multiple font files match a provided name with `-n` flag
- [x] Fail with descriptive error listing all matching fonts
- [x] Advise users to use unique PostScript name or direct file path
- [x] Implementation in both `uninstall` and `remove` commands
- **Result**: Ensures deterministic behavior, prevents accidental removal of wrong font variant

### Task 3: Automated Version Management (Deferred)
- [ ] Enhance `scripts/prepare-release.sh` to accept version number as argument
- [ ] Auto-update version constant in `Sources/fontlift/fontlift.swift`
- [ ] Auto-update `CHANGELOG.md` with new version section
- [ ] Auto-commit changes and create git tag
- [ ] Add validation to ensure version consistency
- **Rationale**: Eliminates human error in release workflow, ensures version consistency
- **Status**: Deferred - current manual process works reliably; automation adds complexity

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
