# TROUBLESHOOTING.md
<!-- this_file: TROUBLESHOOTING.md -->

Common issues and solutions for fontlift-mac-cli development and usage.

## Table of Contents

- [Build Issues](#build-issues)
- [Test Failures](#test-failures)
- [Installation Issues](#installation-issues)
- [Runtime Errors](#runtime-errors)
- [CI/CD Issues](#cicd-issues)
- [Release Issues](#release-issues)

---

## Build Issues

### Error: "Swift is not installed or not in PATH"

**Symptom:**
```
❌ Error: Missing required dependencies:
  - swift
```

**Solution:**
1. Install Swift from https://swift.org/download/
2. Verify installation: `swift --version`
3. Ensure Swift is in your PATH

**macOS:** Swift comes with Xcode Command Line Tools:
```bash
xcode-select --install
```

---

### Error: "lipo: can't open input file"

**Symptom:**
```
❌ Error: x86_64 binary not found at .build/x86_64-apple-macosx/release/fontlift
```

**Cause:** Cross-compilation to x86_64 failed or is not supported on this system

**Solution:**
1. Build for native architecture only (remove `--universal` flag):
   ```bash
   ./build.sh
   ```

2. For releases, ensure you're on macOS with Rosetta 2 support:
   ```bash
   softwareupdate --install-rosetta
   ```

3. Verify lipo is available:
   ```bash
   which lipo
   ```

---

### Error: "Binary size is suspiciously small"

**Symptom:**
```
❌ Error: Binary size is suspiciously small
Expected: ~3.2M (universal binary)
Actual: 464K
```

**Cause:** Built an architecture-specific binary instead of universal

**Solution:**
1. Build with universal flag:
   ```bash
   ./build.sh --universal
   ```

2. Verify universal binary:
   ```bash
   lipo -info .build/release/fontlift
   # Should show: Architectures in the fat file: fontlift are: x86_64 arm64
   ```

---

## Test Failures

### Error: "test.sh hangs indefinitely"

**Symptom:** `./test.sh` runs but never completes

**Cause:** Recursive test invocation (test.sh calling itself)

**Solution:**
Tests already handle this with `SKIP_SCRIPT_TESTS` flag. If you see this:
1. Kill the hanging process: `Ctrl+C`
2. Check if `SKIP_SCRIPT_TESTS` is being set correctly
3. Verify Tests/scripts_test.sh line 82-85

---

### Error: "Version mismatch detected"

**Symptom:**
```
❌ Version mismatch detected!
Binary version: 1.1.24
Source version: 1.1.25
```

**Cause:** Binary was compiled with old version constant

**Solution:**
1. Rebuild the binary:
   ```bash
   ./build.sh
   ```

2. Or use the verify-version command:
   ```bash
   .build/release/fontlift verify-version
   ```

---

## Installation Issues

### Error: "Permission denied" when installing to /usr/local/bin

**Symptom:**
```
cp: /usr/local/bin/fontlift: Permission denied
```

**Solution:**
1. Install with sudo:
   ```bash
   sudo ./publish.sh
   ```

2. Or change INSTALL_DIR in publish.sh to a user-writable location:
   ```bash
   INSTALL_DIR="$HOME/.local/bin"
   ```

---

### Error: "fontlift: command not found" after installation

**Symptom:** Installed successfully but `fontlift` command not found

**Cause:** Install directory not in PATH

**Solution:**
1. Check if `/usr/local/bin` is in your PATH:
   ```bash
   echo $PATH | grep /usr/local/bin
   ```

2. Add to PATH if missing (add to `~/.zshrc` or `~/.bashrc`):
   ```bash
   export PATH="/usr/local/bin:$PATH"
   ```

3. Reload shell:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

---

## Runtime Errors

### Error: "File not found" when installing font

**Full Error:**
```
❌ File not found at path: /path/to/font.ttf

Common causes:
  - Path is incorrect or file was moved
  - Path contains spaces (use quotes)
  - File extension is wrong (.ttf, .otf, .ttc, .otc)
```

**Solution:**
1. Verify file exists:
   ```bash
   ls -la /path/to/font.ttf
   ```

2. Use quotes for paths with spaces:
   ```bash
   fontlift install "/path/with spaces/font.ttf"
   ```

3. Use absolute paths:
   ```bash
   fontlift install "$(pwd)/font.ttf"
   ```

---

### Error: "Not a regular file (is it a directory?)"

**Symptom:**
```
❌ Not a regular file (is it a directory?): /Users/name/Fonts
```

**Cause:** Provided path is a directory, not a file

**Solution:**
Specify the individual font file, not the directory:
```bash
# Wrong:
fontlift install ~/Fonts

# Correct:
fontlift install ~/Fonts/MyFont.ttf
```

---

### Error: "Font already installed"

**Full Error:**
```
❌ Error installing font: Font already registered
File: /path/to/font.ttf

Common causes:
  - Font already installed (use 'fontlift list' to check)
  - Invalid or corrupted font file
```

**Solution:**
1. List installed fonts:
   ```bash
   fontlift list -n | grep "FontName"
   ```

2. Uninstall first if needed:
   ```bash
   fontlift uninstall -n "FontName"
   ```

3. Then install:
   ```bash
   fontlift install /path/to/font.ttf
   ```

---

### Error: "Font not found" when uninstalling

**Full Error:**
```
❌ Font not found with name: Helvetica Neue

Common causes:
  - Font name is misspelled
  - Font uses different PostScript name
  - Font is not installed

Try:
  - List all installed fonts: fontlift list -n
```

**Solution:**
1. List fonts to find exact name:
   ```bash
   fontlift list -n | grep -i "helvetica"
   ```

2. Use sorted mode to find family:
   ```bash
   fontlift list -n -s | grep -i "helvetica"
   ```

3. Uninstall by path instead:
   ```bash
   fontlift list -p | grep -i "helvetica"
   fontlift uninstall -p "/path/from/above"
   ```

---

## CI/CD Issues

### Error: GitHub Actions build fails with "numfmt: command not found"

**Symptom:**
```
/Users/runner/work/_temp/xxx.sh: line 15: numfmt: command not found
```

**Cause:** `numfmt` is not available on macOS GitHub Actions runners

**Solution:**
Already fixed in v1.1.25. Use simple arithmetic instead:
```bash
BINARY_SIZE_MB=$((BINARY_SIZE / 1048576))
```

---

### Error: CI produces arm64-only binary instead of universal

**Symptom:**
```
lipo -info fontlift
# Shows: Non-fat file: fontlift is architecture: arm64
```

**Cause:** `swift test` overwrites universal binary with debug build

**Solution:**
Already fixed in v1.1.20. CI workflow now:
1. Builds native binary for testing (fast)
2. Release workflow builds universal binary
3. prepare-release.sh verifies universal binary

---

### Error: "CHANGELOG.md does not have entry for version"

**Symptom:**
```
⚠️  Warning: CHANGELOG.md does not have entry '## [1.1.X]'
```

**Cause:** Forgot to add CHANGELOG entry before tagging release

**Solution:**
1. Add entry to CHANGELOG.md:
   ```markdown
   ## [1.1.X] - 2025-11-01

   ### Added
   - Feature description
   ```

2. Commit:
   ```bash
   git add CHANGELOG.md
   git commit -m "docs: add CHANGELOG entry for v1.1.X"
   ```

3. Re-create tag:
   ```bash
   git tag -d v1.1.X
   git tag -a v1.1.X -m "Release v1.1.X"
   git push --force origin v1.1.X
   ```

---

## Release Issues

### Error: Release artifacts missing from GitHub

**Symptom:** GitHub Release created but no tarball/checksum files attached

**Cause:** prepare-release.sh failed or didn't run

**Solution:**
1. Check GitHub Actions logs for release workflow
2. Run prepare-release.sh locally to debug:
   ```bash
   ./build.sh --universal
   ./scripts/prepare-release.sh
   ls -la dist/
   ```

3. Verify dist/ contains:
   - `fontlift-vX.Y.Z-macos.tar.gz`
   - `fontlift-vX.Y.Z-macos.tar.gz.sha256`

---

### Error: Downloaded binary doesn't work on Intel Mac

**Symptom:**
```
zsh: bad CPU type in executable: fontlift
```

**Cause:** Binary is arm64-only, not universal

**Solution:**
1. Verify binary is universal:
   ```bash
   curl -L -o fontlift.tar.gz "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/vX.Y.Z/fontlift-vX.Y.Z-macos.tar.gz"
   tar -xzf fontlift.tar.gz
   lipo -info fontlift
   # Should show: x86_64 arm64
   ```

2. If single-arch, report issue and use previous version

---

### Error: Checksum verification fails

**Symptom:**
```
❌ Error: Checksum verification failed
```

**Cause:** Tarball was corrupted during download or modified

**Solution:**
1. Re-download the tarball:
   ```bash
   rm fontlift-vX.Y.Z-macos.tar.gz*
   curl -L -O "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/vX.Y.Z/fontlift-vX.Y.Z-macos.tar.gz"
   curl -L -O "https://github.com/fontlaborg/fontlift-mac-cli/releases/download/vX.Y.Z/fontlift-vX.Y.Z-macos.tar.gz.sha256"
   shasum -a 256 -c fontlift-vX.Y.Z-macos.tar.gz.sha256
   ```

2. If still fails, report issue on GitHub

---

## Debugging Tips

### Enable verbose output

Most scripts support CI mode which reduces output. For debugging, run without `--ci`:

```bash
./build.sh           # Verbose output
./test.sh            # Verbose output
./publish.sh         # Verbose output
```

### Check binary information

```bash
# Version
.build/release/fontlift --version

# Architecture
lipo -info .build/release/fontlift

# Size
ls -lh .build/release/fontlift

# Dependencies
otool -L .build/release/fontlift
```

### Verify version consistency

```bash
# Extract version from source
./scripts/get-version.sh

# Compare with binary
.build/release/fontlift verify-version
```

### Clean build cache

If experiencing strange build issues:

```bash
# Remove build artifacts
rm -rf .build/

# Rebuild
swift package clean
./build.sh
```

---

## Getting Help

If you encounter issues not covered here:

1. Check GitHub Issues: https://github.com/fontlaborg/fontlift-mac-cli/issues
2. Search closed issues for similar problems
3. Create new issue with:
   - Error message (full output)
   - macOS version: `sw_vers`
   - Swift version: `swift --version`
   - Steps to reproduce
   - Expected vs actual behavior

---

## Quick Reference

### Common Commands

```bash
# Build
./build.sh                    # Native build
./build.sh --universal        # Universal binary
./build.sh --ci               # CI mode

# Test
./test.sh                     # All tests
./test.sh --ci                # CI mode
swift test                    # Swift tests only

# Install
./publish.sh                  # Install locally
sudo ./publish.sh             # Install with sudo

# Release
./scripts/validate-version.sh 1.1.X    # Validate version
./scripts/prepare-release.sh           # Prepare release artifacts
./scripts/verify-release-artifact.sh 1.1.X  # Verify published release

# Version management
./scripts/get-version.sh                    # Extract version
.build/release/fontlift verify-version      # Verify consistency
```

### Environment Variables

```bash
CI=true ./build.sh            # Enable CI mode
SKIP_SCRIPT_TESTS=true ./test.sh  # Skip scripts tests
UNIVERSAL_BUILD=true ./build.sh   # Build universal binary
```

---

**Last Updated:** 2025-11-01
**Version:** 1.1.26 (draft)
