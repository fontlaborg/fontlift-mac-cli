# CHANGELOG.md
<!-- this_file: CHANGELOG.md -->

All notable changes to fontlift-mac-cli will be documented in this file.

## [Unreleased] - 2025-10-31

### Added - Foundation Infrastructure

#### Swift Package Structure
- Initialized Swift Package Manager project with executable target
- Configured macOS-only platform (macOS 12+)
- Set Swift tools version to 6.2
- Created main CLI entry point with ArgumentParser
- Implemented command structure:
  - `list` - List installed fonts (with -p/--path and -n/--name flags)
  - `install` - Install fonts from file paths
  - `uninstall` - Uninstall fonts (keep files)
  - `remove` - Remove fonts (delete files)
- Added help system and version flag
- Placeholder implementations for all commands

#### Build & Release Automation
- Created `build.sh` - Release build script with verification
  - Builds in release mode
  - Verifies binary exists and is executable
  - Shows binary location and next steps
- Created `test.sh` - Test runner script
  - Runs tests with parallel execution
  - Clear pass/fail output
- Created `publish.sh` - Installation script
  - Builds if needed
  - Copies to /usr/local/bin
  - Handles permissions (sudo when needed)
  - Confirms before overwriting
  - Verifies installation
- All scripts made executable with proper permissions

#### Testing Infrastructure
- Created project validation test suite
- Tests verify critical files exist:
  - Package.swift
  - README.md
  - PRINCIPLES.md
  - build.sh, test.sh, publish.sh (and are executable)
- Fixed path resolution in tests using #filePath
- All tests passing with parallel execution
- Zero compiler warnings

#### Documentation
- Created CLAUDE.md - Project-specific guidance for Claude Code
- Created PRINCIPLES.md - Core project principles
- Created PLAN.md - Detailed implementation plan
- Created TODO.md - Task list
- Created WORK.md - Work progress log
- Created DEPENDENCIES.md - Dependency documentation
- Created CHANGELOG.md - This file

### Dependencies
- Swift Argument Parser 1.6.2 - CLI argument parsing

### Bug Fixes
- Fixed README.md typo: `u` is synonym for `uninstall` (not `install`)
- Fixed script robustness: All scripts now `cd` to project root before executing
- Fixed test path resolution using `#filePath` instead of `#file`

### Test Results
- ✅ Package builds successfully (debug: 162s first build, release: 29s)
- ✅ All validation tests passing (6/6)
- ✅ CLI help system working
- ✅ All scripts functional
- ✅ Scripts work from any directory
- ✅ Zero compiler warnings
- ✅ Code follows Swift conventions
- ✅ PRINCIPLES.md requirements met
- ✅ Build time: <1s incremental, 29s release
- ✅ Test time: <1s

## [Report] - 2025-10-31

### Test Execution Summary
- All 6 validation tests passing
- Zero compiler warnings
- Zero test failures
- Build time: 0.63s (incremental)
- Test time: <1s
- Total Swift code: 219 lines

### Code Quality Verification
- ✅ All functions under 20 lines
- ✅ All files under 200 lines
- ✅ All `this_file` comments present
- ✅ Swift conventions followed
- ✅ PRINCIPLES.md requirements met

### Foundation Tasks Status
All 3 foundation infrastructure tasks completed:
1. ✅ Swift Package Structure
2. ✅ Build & Release Scripts  
3. ✅ Project Validation Suite

### Additional Improvements
- ✅ README.md typo fixed
- ✅ Scripts work from any directory
- ✅ Comprehensive documentation created

### What's Ready
- Swift Package Manager project configured
- CLI skeleton with 4 subcommands
- Build automation scripts
- Test infrastructure
- Complete documentation

### What's Next
Future feature implementation tasks remain in TODO.md for next iteration.

## [Phase 2 Improvements] - 2025-10-31

### Added

#### Command Aliases
- Added `l` as alias for `list` command
- Added `i` as alias for `install` command
- Added `u` as alias for `uninstall` command
- Added `rm` as alias for `remove` command
- All aliases shown in help text
- Aliases work with all flags and arguments

#### Comprehensive CLI Error Tests
- Created `CLIErrorTests.swift` with 17 test cases
- Tests for all 4 command aliases
- Tests for invalid subcommands
- Tests for missing required arguments
- Tests for invalid flag combinations
- Tests for version and help flags
- All error messages validated
- Test suite runs in <2s

#### Version Management
- Centralized version constant in code
- Added version update checklist in CLAUDE.md
- Documented semantic versioning guidelines
- Clear process for version updates
- Single source of truth for version number

### Test Results
- ✅ 23 tests passing (6 validation + 17 CLI error tests)
- ✅ All aliases functional
- ✅ Error handling comprehensive
- ✅ Zero compiler warnings
- ✅ Test time: <2s
- ✅ Build time: <1s (incremental)

### Quality Improvements
- Improved CLI usability with aliases
- Better error message validation
- Simplified version management
- More comprehensive test coverage
