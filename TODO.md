# TODO.md
<!-- this_file: TODO.md -->

## IMPORTANT

- [x] @issues/101.md - ✅ COMPLETED in v1.1.3-1.1.5 (CI/CD with GitHub Actions and semantic versioning)
- [x] @issues/103.md - ✅ COMPLETED in v1.1.0 (Font management functionality implemented)
- [x] Note: `fontlift list` must not print any "prolog" like "Listing font paths..." or any "epilog" like "Total fonts: 5393" —— we want the pure list of outputs ✅ FIXED in v1.1.0

## Phase 2: Quality & Reliability Improvements - COMPLETED ✅

### Task 1: Implement Command Aliases ✅
- [x] Add "l" alias to List command
- [x] Add "i" alias to Install command
- [x] Add "u" alias to Uninstall command
- [x] Add "rm" alias to Remove command
- [x] Update CommandConfiguration for each subcommand
- [x] Verify aliases appear in help text
- [x] Test `fontlift l --help` works
- [x] Test `fontlift i`, `fontlift u`, `fontlift rm` work
- [x] Build and verify zero warnings

### Task 2: Add CLI Error Handling Tests ✅
- [x] Create `Tests/fontliftTests/CLIErrorTests.swift`
- [x] Add helper to run binary and capture output
- [x] Test: Invalid subcommand shows error
- [x] Test: `fontlift list` without args works
- [x] Test: `fontlift install` without args shows error
- [x] Test: `fontlift uninstall` without args shows error
- [x] Test: `fontlift remove` without args shows error
- [x] Test: `fontlift uninstall` with both -n and path shows error
- [x] Test: `fontlift remove` with both -n and path shows error
- [x] Test: `fontlift --version` shows version
- [x] Test: Each alias (l, i, u, rm) works
- [x] Test: Help text for each command
- [x] Verify all tests pass
- [x] Ensure tests run in <2s

### Task 3: Version Management & Consistency ✅
- [x] Extract version to constant at top of file
- [x] Add comment explaining version update process
- [x] Update CHANGELOG.md with version management notes
- [x] Create version update checklist in CLAUDE.md
- [x] Test version flag shows correct format
- [x] Verify semantic versioning (x.y.z)
- [x] Build and verify zero warnings

---

## Foundation Infrastructure Tasks - COMPLETED ✅

### Task 1: Initialize Swift Package Structure ✅
- [x] Run `swift package init --type executable --name fontlift`
- [x] Verify Package.swift created
- [x] Add Swift Argument Parser dependency
- [x] Configure macOS-only platform constraint
- [x] Set Swift language version to 5.9+
- [x] Create basic main.swift with help text
- [x] Test: `swift build` succeeds
- [x] Test: `swift run fontlift --help` works
- [x] Add `this_file` comments to all Swift files

### Task 2: Create Build & Release Scripts ✅
- [x] Create `./build.sh` script
- [x] Add clean release build command
- [x] Show binary location in output
- [x] Verify binary exists and is executable
- [x] Create `./test.sh` script
- [x] Add verbose test execution
- [x] Stop on first failure
- [x] Create `./publish.sh` script
- [x] Build and copy to /usr/local/bin
- [x] Add sudo prompt with clear message
- [x] Verify installation successful
- [x] Make all scripts executable (`chmod +x`)
- [x] Add documentation comments to scripts
- [x] Test scripts work from any directory

### Task 3: Add Project Validation Suite ✅
- [x] Create `Tests/fontliftTests/ProjectValidationTests.swift`
- [x] Test: Package builds without errors
- [x] Test: Binary is executable
- [x] Test: Help flag works
- [x] Test: Unknown command shows error
- [x] Test: Version information present
- [x] Add file structure validation tests
- [x] Verify PRINCIPLES.md requirements
- [x] Check `this_file` comments exist
- [x] Run `swift test` and verify all pass
- [x] Ensure zero compiler warnings
- [x] Verify tests run in < 5 seconds

### Additional Improvements Completed ✅
- [x] Fixed README.md typo (u = uninstall, not install)
- [x] Improved script robustness (cd to project root)
- [x] Created CHANGELOG.md
- [x] Created DEPENDENCIES.md
- [x] All files have `this_file` comments

---

## Phase 3: Production Polish & Documentation

### Task 1: Improve .gitignore Coverage
- [ ] Review current .gitignore file
- [ ] Add Swift/Xcode build artifact patterns
- [ ] Add .DS_Store and OS temp files
- [ ] Verify .build/ is ignored
- [ ] Verify Package.resolved is tracked (NOT ignored)
- [ ] Test: Build and check git status is clean
- [ ] Test: No unwanted files appear in git status

### Task 2: Enhance Build Script Safety
- [ ] Add `set -euo pipefail` to build.sh
- [ ] Add `set -euo pipefail` to test.sh
- [ ] Add `set -euo pipefail` to publish.sh
- [ ] Improve error messages in all scripts
- [ ] Add consistent error output format
- [ ] Test: Scripts fail fast on errors
- [ ] Verify scripts still work correctly

### Task 3: Add Inline Code Documentation
- [ ] Add doc comments to List command
- [ ] Add doc comments to Install command
- [ ] Add doc comments to Uninstall command
- [ ] Add doc comments to Remove command
- [ ] Document validation logic
- [ ] Document ArgumentParser choices
- [ ] Explain version management section
- [ ] Review all comments for clarity
- [ ] Build and verify zero warnings

---

---

## Phase 4: Semantic Versioning & CI/CD Automation

### Task 1: Version Management Strategy
- [ ] Create `scripts/` directory
- [ ] Create `scripts/validate-version.sh` script
- [ ] Add version validation logic (check tag matches code)
- [ ] Add help text to validate-version.sh
- [ ] Make validate-version.sh executable
- [ ] Test validation script with matching version
- [ ] Test validation script with mismatched version
- [ ] Update CLAUDE.md with enhanced version management section
- [ ] Document tag format requirement (vX.Y.Z)
- [ ] Add pre-release checklist to CLAUDE.md
- [ ] Add examples for MAJOR, MINOR, PATCH bumps

### Task 2: Adapt Scripts for CI/CD
- [ ] Add `set -euo pipefail` to build.sh
- [ ] Add `set -euo pipefail` to test.sh
- [ ] Add `set -euo pipefail` to publish.sh
- [ ] Add `--help` flag support to build.sh
- [ ] Add `--help` flag support to test.sh
- [ ] Add `--help` flag support to publish.sh
- [ ] Add `--ci` flag support to build.sh
- [ ] Add `--ci` flag support to test.sh
- [ ] Add CI environment detection to publish.sh
- [ ] Create `scripts/prepare-release.sh`
- [ ] Implement tarball creation in prepare-release.sh
- [ ] Implement SHA256 checksum generation
- [ ] Add --help to prepare-release.sh
- [ ] Make prepare-release.sh executable
- [ ] Test prepare-release.sh creates dist/ directory
- [ ] Test tarball extraction works
- [ ] Test checksum validation works
- [ ] Test all scripts with CI=true locally

### Task 3: GitHub Actions - CI Workflow
- [ ] Create `.github/workflows/` directory
- [ ] Create `.github/workflows/ci.yml`
- [ ] Add this_file comment to ci.yml
- [ ] Configure triggers (push, PR, workflow_dispatch)
- [ ] Add checkout step
- [ ] Add Swift version display step
- [ ] Add build step (calls build.sh --ci)
- [ ] Add test step (calls test.sh --ci)
- [ ] Add binary verification step
- [ ] Add build caching (optional optimization)
- [ ] Commit and push ci.yml
- [ ] Verify CI runs on push to main
- [ ] Verify CI runs on pull requests
- [ ] Check CI passes successfully

### Task 4: GitHub Actions - Release Workflow
- [ ] Create `.github/workflows/release.yml`
- [ ] Add this_file comment to release.yml
- [ ] Configure tag trigger (v*.*.*)
- [ ] Set permissions (contents: write)
- [ ] Add validation job
- [ ] Add extract tag version step
- [ ] Add version validation step
- [ ] Add build job (depends on validate)
- [ ] Add build release binary step
- [ ] Add prepare artifacts step
- [ ] Add upload artifacts step
- [ ] Add release job (depends on build)
- [ ] Add download artifacts step
- [ ] Add extract release notes step
- [ ] Add create GitHub Release step
- [ ] Configure repository permissions (Actions → General)
- [ ] Set workflow permissions to "Read and write"
- [ ] Commit and push release.yml

### Task 5: Testing & Validation
- [ ] Test build.sh with CI=true locally
- [ ] Test test.sh with CI=true locally
- [ ] Test publish.sh with CI=true locally
- [ ] Create test git tag (v0.1.0)
- [ ] Test validate-version.sh with matching version
- [ ] Test validate-version.sh with mismatched version
- [ ] Run prepare-release.sh locally
- [ ] Verify dist/ directory created
- [ ] Verify tarball exists and is valid
- [ ] Verify checksum file exists
- [ ] Extract tarball and verify contents
- [ ] Validate checksum with shasum
- [ ] Push small change to trigger CI
- [ ] Monitor CI workflow in Actions tab
- [ ] Verify all CI jobs succeed
- [ ] Check build logs for errors
- [ ] Prepare test release (v0.1.1)
- [ ] Update version in code to 0.1.1
- [ ] Update CHANGELOG.md with v0.1.1 section
- [ ] Commit version bump
- [ ] Create annotated tag v0.1.1
- [ ] Push tag to trigger release
- [ ] Monitor release workflow
- [ ] Verify validate job passes
- [ ] Verify build job passes
- [ ] Verify release job creates GitHub Release
- [ ] Download release artifact
- [ ] Test downloaded binary runs
- [ ] Verify version shows 0.1.1
- [ ] Validate checksum
- [ ] Test version mismatch scenario
- [ ] Tag without updating code
- [ ] Verify validation job fails
- [ ] Clean up failed tag

### Task 6: Documentation & Integration
- [ ] Update CLAUDE.md Version Management section
- [ ] Add "Releasing a New Version" procedure
- [ ] Add "Automated steps" documentation
- [ ] Add "Version Number Guidelines"
- [ ] Add "Checking Build Status" with URLs
- [ ] Add "Troubleshooting" section
- [ ] Update README.md with Installation section
- [ ] Add GitHub Releases download instructions
- [ ] Add CI badge to README.md
- [ ] Add Development section linking to CLAUDE.md
- [ ] Update DEPENDENCIES.md with CI/CD section
- [ ] Document actions/checkout@v4
- [ ] Document actions/cache@v4
- [ ] Document actions/upload-artifact@v4
- [ ] Document actions/download-artifact@v4
- [ ] Document softprops/action-gh-release@v1
- [ ] Add --help output to all scripts
- [ ] Document CI vs local mode differences
- [ ] Configure branch protection rules (optional)
- [ ] Add repository topics

### Task 7: Final Integration & Testing
- [ ] Run all tests locally (./test.sh)
- [ ] Verify zero compiler warnings
- [ ] Verify version updated in code
- [ ] Verify CHANGELOG.md has release notes
- [ ] Verify all this_file comments correct
- [ ] Commit all Phase 4 changes
- [ ] Verify clean git status
- [ ] Push to GitHub
- [ ] Wait for CI to pass
- [ ] Verify .github/workflows/ci.yml exists
- [ ] Verify .github/workflows/release.yml exists
- [ ] Verify scripts/validate-version.sh exists
- [ ] Verify scripts/prepare-release.sh exists
- [ ] Verify all scripts executable
- [ ] Verify CLAUDE.md documentation complete
- [ ] Verify README.md updated
- [ ] Verify DEPENDENCIES.md updated
- [ ] Prepare release v0.2.0
- [ ] Update version to 0.2.0 in code
- [ ] Add ## [0.2.0] section to CHANGELOG.md
- [ ] Commit: "chore: bump version to 0.2.0"
- [ ] Push to main
- [ ] Wait for CI pass
- [ ] Create tag: git tag -a v0.2.0 -m "Release v0.2.0"
- [ ] Push tag: git push origin v0.2.0
- [ ] Monitor release workflow
- [ ] Verify validate job passes
- [ ] Verify build job passes
- [ ] Verify release job creates release
- [ ] Check GitHub Releases page
- [ ] Download fontlift-v0.2.0-macos.tar.gz
- [ ] Extract and test binary
- [ ] Verify version shows 0.2.0
- [ ] Verify checksum
- [ ] Test user installation from release
- [ ] Verify CI badge shows "passing"
- [ ] Verify release visible on GitHub
- [ ] Verify installation instructions work
- [ ] Update TODO.md marking completed items
- [ ] Update WORK.md with Phase 4 completion

---

## Font Feature Implementation - COMPLETED ✅ (v1.1.0)

- [x] Research Core Text APIs for font operations
- [x] Implement `list` command with real font enumeration (5,387 fonts)
- [x] Add sorted mode (`-s`) to list command
- [x] Implement `install` command with font registration
- [x] Implement `uninstall` command with deregistration
- [x] Implement `remove` command with file deletion
- [x] Handle font collections (.ttc/.otc)
- [ ] Add confirmation prompts for destructive operations (future enhancement)

### Testing & Quality
- [ ] Create test font files for integration tests
- [ ] Add functional tests for each command
- [ ] Test permission handling
- [ ] Test font collection handling
- [ ] Add edge case tests (invalid files, missing fonts)
- [ ] Increase test coverage to 80%+
