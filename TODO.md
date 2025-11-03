# TODO.md
<!-- this_file: TODO.md -->

## Current Tasks

### Micro-Improvements Round 15 (In Progress)

**Goal:** Prepare v2.0.0 for production release with final polish

1. **Create comprehensive git commit for v2.0.0**
   - Review all 8 modified files
   - Create detailed commit message documenting breaking change
   - Ensure commit message follows conventional commits format
   - Stage and commit all changes atomically

2. **Add binary size regression check to test suite**
   - Add test to verify universal binary is >1MB
   - Catches accidental single-architecture builds
   - Prevents release of non-universal binaries
   - Quick sanity check integrated into `./test.sh`

3. **Verify release workflow readiness**
   - Confirm GitHub Actions workflow exists and is correct
   - Verify CHANGELOG.md extraction pattern works for v2.0.0
   - Check release artifact naming matches expected pattern
   - Document release process in commit message

## Completed Tasks - Micro-Improvements Round 14 ✅

**Goal:** Add explicit examples and edge case documentation

1. **Add example output to README.md for clarity** ✅
   - ✅ Added concrete example at lines 73-77 showing `::` separator format
   - ✅ Shows actual `list -p -n` output with Helvetica fonts
   - ✅ Demonstrates `path::name` format visually for users
   - Helps users understand format change immediately

2. **Verify `.` character behavior in font names** ✅
   - ✅ Tested actual font output with `grep` and `awk` parsing
   - ✅ Confirmed NO font names contain `::` naturally
   - ✅ Confirmed NO font paths contain `::` naturally
   - ✅ Verified file extensions (`.ttf`, `.otf`, `.ttc`) are in path part, before `::` separator
   - ✅ Tested parsing with `awk -F'::'` - works perfectly
   - ✅ Tested fonts with spaces, dots, special characters - all work correctly
   - ✅ Single-flag modes (`-p` or `-n` only) correctly omit `::` separator
   - **Verdict:** The `::` separator is robust and unambiguous in all edge cases

3. **Verify error messages are user-friendly** ✅
   - ✅ Reviewed all 30+ error messages in source code
   - ✅ All errors start with ❌ emoji for visibility
   - ✅ All errors include specific context (path/name)
   - ✅ Every error includes actionable guidance:
     - "Common causes:" sections
     - "Troubleshooting:" sections
     - Copy-paste ready commands with `shellEscape()`
     - Specific suggestions based on error type
   - ✅ Good formatting with blank lines and indented bullets
   - **Verdict:** Error messages are excellent - clear, actionable, and user-friendly

4. **Run final test suite** ✅
   - ✅ All 94 tests passing (52 Swift + 23 Scripts + 19 Integration)
   - ✅ Execution time: 33s total (6s Swift + 20s Scripts + 7s Integration)
   - ✅ 0 compiler warnings
   - ✅ All output format tests working correctly
   - **Verdict:** Test suite healthy and comprehensive

**All Round 14 tasks complete! v2.0.0 ready for production release.**

## Completed Tasks - Micro-Improvements Round 13 ✅

**Goal:** Absolute final checks for production readiness

1. **Verify git status is clean and summarize changes** ✅
   - ✅ No untracked files
   - ✅ Exactly 8 files modified as expected (+197/-23 lines)
   - ✅ No debug code or temporary changes
   - ✅ Clean git status confirmed

2. **Test binary functionality one more time with actual fonts** ✅
   - ✅ Verified `list -p -n` output: `/path/to/font.ttf::FontName`
   - ✅ Confirmed `::` separator in real-world usage
   - ✅ Verified NO `::` in single-flag modes (-p or -n only)
   - ✅ All functionality working as designed

3. **Generate final git commit summary for release** ✅
   - ✅ Comprehensive commit message created
   - ✅ All 8 files documented
   - ✅ Breaking changes clearly stated
   - ✅ Ready for v2.0.0 tag

**All final checks complete! Project ready for production release.**

## Completed Tasks - Quality & Robustness Round 12 ✅

**Goal:** Final documentation consistency and test reliability improvements

1. **Update PLAN.md with current test counts** ✅
   - Updated from 90 to 94 tests total
   - Ensures documentation accuracy for new contributors
   - Documentation now consistent

2. **Update WORK.md with final v2.0.0 summary** ✅
   - Documented all Round 11 and 12 improvements
   - Finalized metrics and status
   - Ready for git commit

3. **Verify all documentation is consistent** ✅
   - ✅ README.md has correct examples with `::` separator
   - ✅ CHANGELOG.md v2.0.0 section complete with migration guide
   - ✅ PLAN.md updated with current test counts (94)
   - ✅ No stale references found (historical references in CHANGELOG are correct)

**All 94 tests passing! v2.0.0 ready for release.**

## Completed Tasks - Quality & Robustness Round 11 ✅

**Goal:** Add test coverage for new v2.0.0 output format and edge cases

1. **Add integration test for `list -p -n` output format verification** ✅
   - Added test verifying `::` separator is present in combined mode
   - Catches format regressions in future changes
   - Fixed SIGPIPE issue with `set -euo pipefail` + `head -1` combination

2. **Add test for `list -n -p` (reversed flag order)** ✅
   - Verified flag order doesn't matter: `-n -p` same as `-p -n`
   - Both produce identical `path::name` format
   - Edge case now explicitly tested

3. **Add regression test for separator in single-flag modes** ✅
   - Verified `::` separator NOT used in `-p` only mode
   - Verified `::` separator NOT used in `-n` only mode
   - Ensures separator only appears in combined mode
   - Prevents accidental format changes

**Test Count Update:** 90 → 94 tests (15 → 19 integration tests, +4 new tests)
**All tests passing!**

## Completed Tasks - v2.0.0

### Output Format Standardization ✅
- [x] **Standardized `list -n -p` output format to use double colon separator**
  - Old format: `path;name` (semicolon separator)
  - New format: `path::name` (double colon separator)
  - Reason: Consistency with fontnome and fontlift-win-cli
  - Impact: `list` command when both `-n` and `-p` flags are used
  - Files modified:
    - ✅ `Sources/fontlift/fontlift.swift` - Updated separator and documentation
    - ✅ `Tests/fontliftTests/*.swift` - No changes needed (tests don't check format)
    - ✅ `Tests/scripts_test.sh` - No changes needed (doesn't test format)
    - ✅ `Tests/integration_test.sh` - No changes needed (doesn't test format)
    - ✅ `README.md` - Updated documentation and examples
    - ✅ `CHANGELOG.md` - Documented breaking change with migration guide
  - Breaking change: Version bumped to v2.0.0
  - All 90 tests passing

## Quality & Robustness Improvements - Round 10 (Completed)

### Round 10 Tasks (Repository Cleanup) ✅
1. **Remove duplicate documentation files**
   - AGENTS.md, GEMINI.md, LLXPRT.md, QWEN.md are all duplicates of CLAUDE.md
   - All 4 files are identical (26301 bytes each)
   - These appear to be LLM-specific copies that are no longer needed
   - Reduces repository bloat by ~102KB

2. **Remove outdated STREAMLINE files**
   - STREAMLINE_PLAN.md and STREAMLINE_STATUS.md are from earlier cleanup effort
   - Phase 1 completed, remaining phases not relevant to current state
   - Project is already streamlined (v1.1.29, 741 lines main file)
   - These files add confusion about project status

3. **Verify .gitignore correctness**
   - Ensure removed files aren't tracked
   - Confirm no unnecessary entries
   - Keep .gitignore minimal and relevant

---

## Quality & Robustness Improvements - Round 9 (Completed)

### Round 9 Tasks (Test Count Consistency) ✅
1. **Fixed test count mismatches in test.sh output banners**
   - Line 111: "Suite 2/3: Scripts Tests (25 tests)" → 23 tests
   - Line 128: "Suite 3/3: Integration Tests (17 tests)" → 15 tests
   - These were relics from earlier versions when counts were different
   - All test counts now consistent across header, banners, and summary

2. **Updated line number reference in test.sh header**
   - Line 17: Updated references from old line numbers (75, 138, 142)
   - Now correctly references current line numbers (83, 146, 150)
   - Ensures maintainability documentation remains accurate
   - Helps future contributors update test counts efficiently

---

## Quality & Robustness Improvements - Round 8 (Completed)

### Round 8 Tasks (Documentation Accuracy) ✅
1. **Updated PLAN.md test counts**
   - Fixed outdated Swift test count: 23 → 43 tests
   - Fixed outdated total: 65 → 81 tests
   - Updated success metrics to reflect current state
   - Documentation now accurate

2. **Enhanced test.sh internal documentation**
   - Added comprehensive test suite breakdown header comment
   - Documents all 3 test suites with counts and descriptions
   - Added maintenance notes for updating hardcoded counts
   - References specific line numbers (75, 138, 142)
   - Improves maintainability for future test additions

3. **Verified function length compliance**
   - All functions <20 lines except validateFilePath (40 lines)
   - validateFilePath exception documented in PLAN.md
   - Justification: 33 of 40 lines are comprehensive error messages
   - Function does 4 validation checks with user guidance
   - Exception justified: user experience > strict line limits

---

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
