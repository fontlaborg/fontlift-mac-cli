# Aggressive Codebase Streamlining Plan

**Goal**: Strip fontlift-mac-cli down to bare essentials - a simple, focused macOS font management CLI tool.

**One-sentence scope**: Install, uninstall, list, and remove fonts on macOS via CLI.

---

## Phase 1: Documentation Cleanup (IMMEDIATE)

### 1.1 WORK.md - Reduce from 2600+ lines to ~50 lines
**Current**: Verbose phase-by-phase historical documentation (Phases 4-42)
**Target**: Simple status document with current version and basic info

**KEEP**:
- Current version (v1.1.28)
- Test count (65 tests passing)
- Basic project status

**REMOVE**:
- All phase-by-phase historical documentation (Phases 4-42)
- Detailed task breakdowns
- Implementation details
- Test results from historical phases

### 1.2 TODO.md - Reduce from 1300+ lines to ~30 lines
**Current**: 42 completed phases documented in detail
**Target**: Simple future enhancements list

**KEEP**:
- Future enhancements section (low priority items)

**REMOVE**:
- All completed phase documentation (Phases 4-42)
- Detailed task descriptions
- Implementation notes

### 1.3 PLAN.md - Reduce from 2100+ lines to ~100 lines
**Current**: Detailed technical documentation of phases 3-41
**Target**: Simple project overview and core features list

**KEEP**:
- Project overview (one-sentence scope)
- Current version
- Core features list (list, install, uninstall, remove)
- Simple success metrics

**REMOVE**:
- All phase documentation (Phases 3-41)
- Detailed task breakdowns
- Implementation details
- Historical development tracking

### 1.4 CHANGELOG.md - Keep as-is (already concise)
**Action**: No changes - CHANGELOG should maintain version history

---

## Phase 2: Remove Enterprise Features (CODE)

### 2.1 test.sh - Remove excessive test flags
**Current**: 8 flags (--ci, --verify-ci, --shellcheck, --check-size, --check-performance, --check-version, --check-all, --coverage)
**Target**: 2 flags (--ci, --help)

**REMOVE**:
- `--verify-ci` (CI/CD configuration validation)
- `--shellcheck` (automated shellcheck)
- `--check-size` (binary size regression)
- `--check-performance` (performance regression)
- `--check-version` (version consistency)
- `--check-all` (comprehensive quality checks)
- `--coverage` (code coverage reporting)
- All associated validation functions
- Performance baseline comparisons
- Timing displays beyond basic execution time

**KEEP**:
- `--ci` flag for CI mode (silent, fast)
- `--help` flag
- Basic test execution (3 test suites)
- Simple pass/fail output

### 2.2 build.sh - Remove validation bloat
**Current**: Extensive pre-build validation (Swift version, Xcode CLT, disk space, permissions)
**Target**: Simple build script

**REMOVE**:
- `check_swift_version()` function
- `check_xcode_clt()` function
- `check_disk_space()` function
- `check_build_permissions()` function
- `--verify-reproducible` flag
- `--clean` flag (users can rm -rf .build themselves)
- Build progress indicators for universal builds
- Performance timing and baseline comparisons

**KEEP**:
- `--ci` flag for CI mode
- `--universal` flag for universal binary
- Basic build execution
- Simple error messages

### 2.3 Remove Entire Scripts (DELETE FILES)

**DELETE**:
- `scripts/verify-ci-config.sh` (CI/CD validation)
- `scripts/verify-version-consistency.sh` (version checking)
- `scripts/verify-release-artifact.sh` (release verification)
- `scripts/commit-helper.sh` (commit workflow helper)
- `scripts/performance-baselines.md` (performance documentation)
- `.git-hooks/pre-commit` (pre-commit hook template)

**KEEP**:
- `scripts/get-version.sh` (needed for version extraction)
- `scripts/validate-version.sh` (needed for releases)
- `scripts/prepare-release.sh` (needed for releases)

### 2.4 Remove Documentation Files (DELETE FILES)

**DELETE**:
- `TROUBLESHOOTING.md` (500+ lines of troubleshooting)
- Move essential troubleshooting to README.md (10-20 lines max)

**KEEP**:
- `README.md` (but simplify - see Phase 3)
- `CHANGELOG.md` (version history)
- `CLAUDE.md` (project instructions)

### 2.5 Simplify publish.sh
**Current**: Extensive validation and error handling
**Target**: Simple binary copy script

**REMOVE**:
- Dependency verification functions
- Extensive error messages with "Try:" suggestions
- Performance timing

**KEEP**:
- Basic binary installation
- `--ci` flag
- Simple error messages

### 2.6 Simplify prepare-release.sh
**Current**: Extensive validation, size checks, architecture verification
**Target**: Simple tarball creation

**REMOVE**:
- Binary size validation
- Architecture verification (assume build.sh does it)
- Extensive logging and summary tables

**KEEP**:
- Tarball creation
- Checksum generation
- Basic verification

### 2.7 Simplify validate-version.sh
**Current**: Complex validation with --fix flag, CHANGELOG checking
**Target**: Simple version comparison

**REMOVE**:
- `--fix` flag (auto-fix functionality)
- CHANGELOG entry verification
- Extensive error messages

**KEEP**:
- Basic version comparison
- Simple pass/fail

### 2.8 Remove Swift Code Features

**In Sources/fontlift/fontlift.swift - REMOVE**:
- `VerifyVersion` subcommand (development-only tool)
- Extensive error message context (keep simple errors)
- Validation helper functions (keep minimal validation)

**KEEP**:
- Core commands: List, Install, Uninstall, Remove
- Basic error messages
- Help/version flags

### 2.9 Simplify Test Suites

**Tests/scripts_test.sh - REMOVE**:
- Tests for removed scripts (verify-ci-config, verify-version-consistency, etc.)
- Tests for removed flags (--verify-reproducible, --clean, etc.)
- Binary size regression tests

**Tests/integration_test.sh - REMOVE**:
- Tests for VerifyVersion command
- Extensive error scenario tests (keep basic ones)

**KEEP**:
- Core Swift unit tests (23 tests)
- Essential scripts tests (~10-15 tests)
- Essential integration tests (~10 tests)
- Target: ~40-50 total tests (down from 65)

---

## Phase 3: Simplify README.md

**Current**: Extensive documentation with advanced examples, developer tools, CI/CD info
**Target**: Simple, user-focused documentation (~150 lines)

**KEEP**:
- Installation instructions (Homebrew + manual)
- Quick Start (4 basic examples)
- Core commands documentation
- Basic troubleshooting (10 lines)
- License

**REMOVE**:
- "For Developers" section
- Advanced Usage Examples (keep in Quick Start only)
- Developer Scripts Reference
- CI/CD documentation
- Pre-commit hooks documentation
- Build reproducibility documentation
- Extensive troubleshooting (move to inline --help)

---

## Phase 4: Homebrew Installation Setup

### 4.1 Create Homebrew Formula
**File**: `fontlift.rb` (for homebrew-core or personal tap)

```ruby
class Fontlift < Formula
  desc "Simple macOS font management CLI"
  homepage "https://github.com/fontlaborg/fontlift-mac-cli"
  url "https://github.com/fontlaborg/fontlift-mac-cli/archive/refs/tags/v1.1.28.tar.gz"
  sha256 "CALCULATE_AFTER_RELEASE"
  license "Apache-2.0"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/fontlift"
  end

  test do
    assert_match "1.1.28", shell_output("#{bin}/fontlift --version")
  end
end
```

### 4.2 Update README.md Installation Section

```markdown
## Installation

### Via Homebrew (Recommended)

```bash
brew install fontlaborg/fontlift/fontlift
```

### Manual Installation

Download the latest release from GitHub:

```bash
VERSION="1.1.28"
curl -LO "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/v${VERSION}/fontlift-v${VERSION}-macos.tar.gz"
tar -xzf "fontlift-v${VERSION}-macos.tar.gz"
sudo mv fontlift /usr/local/bin/
```
```

### 4.3 Create Personal Homebrew Tap (if not submitting to homebrew-core)

**Repository**: `https://github.com/fontlaborg/homebrew-fontlift`

Structure:
```
homebrew-fontlift/
├── Formula/
│   └── fontlift.rb
└── README.md
```

Installation command:
```bash
brew tap fontlaborg/fontlift
brew install fontlift
```

---

## Phase 5: GitHub Actions Simplification

### 5.1 .github/workflows/ci.yml - Simplify
**Current**: Extensive testing, validation, verification
**Target**: Basic build and test

**KEEP**:
- Swift build step
- Test execution (`./test.sh --ci`)
- Basic binary verification

**REMOVE**:
- Shellcheck validation
- Binary size validation
- Architecture verification (redundant with build)
- Version consistency checks
- Performance checks

### 5.2 .github/workflows/release.yml - Simplify
**Current**: Complex validation and verification
**Target**: Basic release creation

**KEEP**:
- Version validation
- Binary build (universal)
- Release creation
- Artifact upload

**REMOVE**:
- CHANGELOG entry verification (manual process)
- Extensive validation steps
- Binary size checks

---

## Phase 6: Final Cleanup

### 6.1 Update CLAUDE.md
- Remove references to removed scripts
- Remove references to removed flags
- Simplify development guidelines
- Focus on core functionality

### 6.2 Remove .DS_Store and hidden files
```bash
find . -name ".DS_Store" -delete
```

### 6.3 Final File Count Target

**Current**: ~50+ files (including docs, scripts, tests)
**Target**: ~30 files

**Core Files (~15)**:
- Sources/fontlift/fontlift.swift
- Tests/ (3 test files)
- Package.swift
- build.sh, test.sh, publish.sh
- 3 essential scripts (get-version, validate-version, prepare-release)
- README.md, CHANGELOG.md, CLAUDE.md, LICENSE
- .gitignore

**GitHub Workflows (~2)**:
- .github/workflows/ci.yml
- .github/workflows/release.yml

**Homebrew (~1)**:
- fontlift.rb (or in separate tap repo)

---

## Success Metrics (After Streamlining)

### Code Metrics
- Total lines of code: <1000 (down from ~3000+)
- Test count: ~40-50 (down from 65)
- Documentation lines: <500 (down from ~5000+)
- Scripts count: 6 (down from 12)

### File Metrics
- WORK.md: ~50 lines (down from 2600+)
- TODO.md: ~30 lines (down from 1300+)
- PLAN.md: ~100 lines (down from 2100+)
- README.md: ~150 lines (down from 400+)
- Total files: ~30 (down from 50+)

### Functionality
- ✅ Core commands work: list, install, uninstall, remove
- ✅ All tests pass
- ✅ Binary builds successfully
- ✅ Homebrew installable
- ✅ Zero compiler warnings

### Developer Experience
- Build time: <10s
- Test time: <15s (down from 20-50s)
- Clear, simple documentation
- Easy to understand codebase
- No enterprise bloat

---

## Execution Order

1. **Documentation Cleanup** (Phase 1) - IMMEDIATE
   - Backup originals: `cp WORK.md WORK.md.backup`
   - Aggressively trim WORK.md, TODO.md, PLAN.md
   - Update README.md

2. **Remove Enterprise Scripts** (Phase 2.3, 2.4) - IMMEDIATE
   - Delete files: verify-ci-config.sh, verify-version-consistency.sh, etc.
   - Delete TROUBLESHOOTING.md
   - Delete .git-hooks/pre-commit

3. **Simplify Core Scripts** (Phase 2.1, 2.2, 2.5-2.7) - IMMEDIATE
   - Strip down test.sh, build.sh, publish.sh
   - Remove validation functions
   - Remove excessive flags

4. **Simplify Code** (Phase 2.8) - IMMEDIATE
   - Remove VerifyVersion command
   - Simplify error messages

5. **Simplify Tests** (Phase 2.9) - AFTER code changes
   - Update test suites
   - Remove tests for deleted features
   - Verify ~40-50 tests pass

6. **Homebrew Setup** (Phase 4) - AFTER release v1.2.0
   - Create formula
   - Test installation
   - Update README

7. **CI/CD Cleanup** (Phase 5) - FINAL
   - Simplify workflows
   - Remove excessive validation

8. **Final Cleanup** (Phase 6) - FINAL
   - Update CLAUDE.md
   - Remove hidden files
   - Final verification

---

## Next Immediate Steps

Execute in this order:

1. Create backups:
   ```bash
   cp WORK.md WORK.md.backup
   cp TODO.md TODO.md.backup
   cp PLAN.md PLAN.md.backup
   ```

2. Trim WORK.md to ~50 lines
3. Trim TODO.md to ~30 lines
4. Trim PLAN.md to ~100 lines
5. Delete enterprise scripts
6. Simplify core scripts
7. Run tests to verify nothing breaks
8. Commit changes: "chore: aggressive streamlining - remove enterprise bloat"
9. Create v1.2.0 release with streamlined codebase
10. Set up Homebrew formula

---

## Estimated Impact

**Lines of Code Removed**: ~4000+
**Files Deleted**: ~15-20
**Test Execution Time**: 15s (down from 22-50s)
**Developer Cognitive Load**: 70% reduction
**User Experience**: Simpler, clearer, more focused

**Risk**: Low - Core functionality unchanged, only removing auxiliary features.
