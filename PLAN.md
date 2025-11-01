# PLAN.md
<!-- this_file: PLAN.md -->

## Project Overview

**fontlift-mac-cli** - macOS CLI tool for font management

**One-sentence scope**: Install, uninstall, list, and remove fonts on macOS via CLI, supporting both file paths and internal font names.

**Current Version**: v1.1.10

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

**Quality & Testing** (v1.1.0+):
- 23 comprehensive tests
- CLI error handling tests
- Project validation tests
- Zero compiler warnings
- Fast test execution (<5 seconds)

---

## Phase 3: Production Polish (In Progress)

**Objective**: Small-scale refinements for better maintainability and robustness.

### Task 1: Improve .gitignore Coverage
**Goal**: Ensure all build artifacts and temporary files are properly ignored.

**Implementation**:
- Review current .gitignore file
- Add common Swift/Xcode patterns
- Add .DS_Store and OS temp files
- Verify .build/ covered
- Verify Package.resolved tracked (not ignored)

**Success Criteria**:
- Clean `git status` after build
- No unwanted files committable

### Task 2: Enhance Build Script Safety
**Goal**: Add stricter error handling to all bash scripts.

**Implementation**:
- Add `set -euo pipefail` to all scripts
- Improve error messages
- Ensure consistent error output

**Success Criteria**:
- Scripts fail fast on any error
- Clear error messages on failures

### Task 3: Add Inline Code Documentation
**Goal**: Document all functions and complex logic.

**Implementation**:
- Add Swift doc comments (///) to all commands
- Explain validation logic in Uninstall/Remove
- Document ArgumentParser choices

**Success Criteria**:
- All functions documented
- Complex logic explained
- Focus on "why" not "what"

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
