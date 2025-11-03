# Release Process

<!-- this_file: .github/RELEASING.md -->

This document describes the process for creating a new release of fontlift-mac-cli.

## Pre-Release Checklist

Before creating a release, ensure:

- [ ] All tests passing locally (`./test.sh`)
- [ ] All changes committed to `main` branch
- [ ] Git working directory is clean
- [ ] You're on the latest `main` branch (`git pull origin main`)

## Release Steps

### 1. Update Version Number

Edit `Sources/fontlift/fontlift.swift`:

```swift
private let version = "X.Y.Z"  // Update this line
```

**Version Number Guidelines:**
- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (0.X.0): New features, backwards-compatible
- **PATCH** (0.0.X): Bug fixes, backwards-compatible

### 2. Update CHANGELOG.md

Add a new version section at the top (after `[Unreleased]`):

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing features

### Fixed
- Bug fixes

### ⚠️ BREAKING CHANGES (if applicable)
- Description of breaking changes
- Migration instructions
```

**Important:** The release workflow extracts notes from CHANGELOG.md, so this section must exist and be properly formatted.

### 3. Commit Version Changes

```bash
git add Sources/fontlift/fontlift.swift CHANGELOG.md
git commit -m "chore: bump version to X.Y.Z"
```

### 4. Run Final Tests

```bash
./test.sh
```

Verify all 94 tests pass.

### 5. Create Git Tag

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
```

**Note:** Tag format must be `vX.Y.Z` (with `v` prefix).

### 6. Push to GitHub

```bash
git push origin main
git push origin vX.Y.Z
```

Pushing the tag triggers the automated release workflow.

### 7. Monitor Release Workflow

Watch the GitHub Actions workflow:

```bash
gh run watch
```

Or visit: https://github.com/fontlaborg/fontlift-mac-cli/actions

The release workflow will:
1. **Validate** version matches between tag and code (4-5s)
2. **Build** universal binary (x86_64 + arm64) (~60s)
3. **Create** GitHub Release with artifacts (~6s)

Total time: ~70 seconds

### 8. Verify Release

Check the release was created successfully:

```bash
gh release view vX.Y.Z
```

Or visit: https://github.com/fontlaborg/fontlift-mac-cli/releases/latest

Verify:
- [ ] Release page shows correct version
- [ ] CHANGELOG notes are extracted correctly
- [ ] Artifacts are attached: `fontlift-vX.Y.Z-macos.tar.gz` and `.sha256`
- [ ] Binary is universal (contains x86_64 and arm64)

### 9. Test Release Artifact (Optional)

Download and test the release binary:

```bash
# Download
cd /tmp
gh release download vX.Y.Z

# Verify checksum
shasum -a 256 -c fontlift-vX.Y.Z-macos.tar.gz.sha256

# Extract and test
tar -xzf fontlift-vX.Y.Z-macos.tar.gz
./fontlift --version  # Should show X.Y.Z
lipo -info ./fontlift  # Should show: x86_64 arm64

# Test functionality
./fontlift list | head -5
```

## Troubleshooting

### Version Mismatch Error

If the release workflow fails with "Version mismatch":

```bash
# The tag version doesn't match the code version
# Fix the version in Sources/fontlift/fontlift.swift
# Then delete and recreate the tag:
git tag -d vX.Y.Z
git push origin :vX.Y.Z
# Update the version, commit, and create tag again
```

### CHANGELOG Extraction Failed

If release notes are empty:

- Ensure CHANGELOG.md has a section: `## [X.Y.Z] - YYYY-MM-DD`
- Check the version number matches exactly (no `v` prefix in CHANGELOG)
- Ensure there's a blank line after the version header

### Build Failed

Check the workflow logs:

```bash
gh run view --log
```

Common issues:
- Swift compilation errors (check `swift build` locally)
- Universal build issues (check `./build.sh --universal` locally)

### Release Not Created

Verify:
- [ ] Tag was pushed: `git ls-remote --tags origin`
- [ ] Workflow was triggered: `gh run list --workflow=release.yml`
- [ ] Repository has Actions write permissions (Settings → Actions → General)

## Post-Release

After successful release:

1. Update local repository:
   ```bash
   git pull origin main --tags
   ```

2. Announce the release (if applicable):
   - Update project documentation
   - Notify users of breaking changes
   - Update Homebrew formula (if applicable)

3. Monitor for issues:
   - Watch GitHub Issues for bug reports
   - Check release download counts
   - Verify users can install successfully

## Rollback (Emergency)

If a critical bug is found after release:

1. **Quick fix**: Release a patch version (X.Y.Z+1) with the fix
2. **Major issue**: Mark the release as pre-release on GitHub while fixing

```bash
# Mark release as pre-release
gh release edit vX.Y.Z --prerelease

# After fix, create new release and unmark old one
gh release edit vX.Y.Z --not-prerelease=false
```

## Automation

The release process is largely automated via GitHub Actions:

- **CI Workflow** (`.github/workflows/ci.yml`): Runs on every push/PR
  - Validates version consistency:
    - Checks version format matches semver (X.Y.Z)
    - Verifies CHANGELOG.md has entry for current version
    - **Catches common errors:**
      - Invalid format like `1.0.0.0` (fails build)
      - Missing CHANGELOG entry (warns, but continues)
      - Non-numeric version components (fails build)
  - Builds the project
  - Runs all 94 tests
  - Validates code quality

- **Release Workflow** (`.github/workflows/release.yml`): Runs on version tags
  - Validates version consistency
  - Builds universal binary
  - Creates GitHub Release
  - Uploads artifacts with checksums

## Tips

- **Test the workflow**: Create a test tag like `v0.0.0-test` to verify the workflow works
- **Use semantic versioning**: Follow semver strictly for user expectations
- **Document breaking changes**: Always include migration guides for breaking changes
- **Keep CHANGELOG updated**: Update it with every significant change, not just at release time
- **Verify locally first**: Always test the full build and test suite before pushing tags

## Questions?

If you encounter issues not covered here:
1. Check recent release workflow logs: `gh run list --workflow=release.yml`
2. Review the GitHub Actions workflow files in `.github/workflows/`
3. Open an issue for documentation improvements

---

Last updated: 2025-11-03 (v2.0.0 release process)
