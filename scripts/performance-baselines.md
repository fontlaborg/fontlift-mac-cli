# Performance Baselines
<!-- this_file: scripts/performance-baselines.md -->

This document defines expected performance baselines for all major operations in fontlift-mac-cli. These baselines are used for regression detection and performance monitoring.

**Environment**: Baselines established on macOS 14.x (M-series Mac, 2025-11-01)

---

## Test Suite Performance

### Overall Test Suite
- **Total execution time**: ~20s (acceptable range: 16-24s)
- **Warning threshold**: >26s (>30% slower than baseline)
- **Critical threshold**: >30s (>50% slower than baseline, fails CI)

### Individual Test Suites

#### Swift Unit Tests
- **Baseline**: 4s
- **Test count**: 23 tests
- **Acceptable range**: 3-5s
- **Warning threshold**: >5.2s (>30% slower)
- **Critical threshold**: >6s (>50% slower)

#### Scripts Tests
- **Baseline**: 13s
- **Test count**: 25 tests
- **Acceptable range**: 11-16s
- **Warning threshold**: >16.9s (>30% slower)
- **Critical threshold**: >19.5s (>50% slower)

#### Integration Tests
- **Baseline**: 3s
- **Test count**: 17 tests
- **Acceptable range**: 2-4s
- **Warning threshold**: >3.9s (>30% slower)
- **Critical threshold**: >4.5s (>50% slower)

### Running Performance Checks
```bash
# Automatic performance check during test run
./test.sh --check-performance

# Full test suite with performance monitoring
./test.sh
```

---

## Build Script Performance

### Clean Build
- **Baseline**: ~30s
- **Acceptable range**: 25-35s
- **Command**: `./build.sh --clean`
- **Notes**: First build or after removing `.build/` directory

### Incremental Build
- **Baseline**: <2s
- **Acceptable range**: 1-3s
- **Command**: `./build.sh`
- **Notes**: Rebuilding after small code changes

### Universal Binary Build
- **Baseline**: ~30s
- **Acceptable range**: 25-35s
- **Command**: `./build.sh --universal`
- **Notes**:
  - Builds for both x86_64 and arm64 architectures
  - Includes `lipo` to create fat binary
  - Comparable to clean build time

### Performance Regression
If build times exceed baselines by >20%:
- **Warning**: Build slower than expected (~2s + 20% = 3s for incremental)
- **Try**:
  - Remove `.build/` directory and rebuild clean
  - Check available disk space (requires >100MB)
  - Restart Xcode Command Line Tools

---

## Script Execution Performance

### publish.sh
- **CI mode baseline**: <2s
- **Local install baseline**: <3s
- **Command**: `./publish.sh --ci` (CI mode) or `./publish.sh` (local install)
- **Warning threshold**: >3s for CI mode
- **Notes**: Local mode may require sudo prompt (not counted in timing)

### prepare-release.sh
- **Baseline**: <2s
- **Acceptable range**: 1-3s
- **Command**: `./scripts/prepare-release.sh`
- **Operations**: Verify binary, create tarball, generate checksum
- **Warning threshold**: >3s

### validate-version.sh
- **Baseline**: <1s
- **Acceptable range**: <2s
- **Command**: `./scripts/validate-version.sh X.Y.Z`
- **Operations**: Extract and compare version strings

### verify-ci-config.sh
- **Baseline**: <1s
- **Acceptable range**: <2s
- **Command**: `./test.sh --verify-ci`
- **Operations**: Verify 18 CI/CD configuration checks

### verify-version-consistency.sh
- **Baseline**: <1s
- **Acceptable range**: <2s
- **Command**: `./test.sh --check-version`
- **Operations**: Compare version across 4 critical files

---

## Binary Performance

### Binary Size
- **Native (single architecture)**: ~1.6MB (x86_64 or arm64)
- **Universal (fat binary)**: ~3.2MB (x86_64 + arm64)
- **Size check command**: `./test.sh --check-size`
- **Warning thresholds**:
  - Native binary: >2MB (baseline 1.6M + 20% tolerance)
  - Universal binary: >4MB (baseline 3.2M + 20% tolerance)
- **Critical threshold**: Universal binary <1MB (indicates build failure)

### Startup Time
- **--version flag**: <100ms
- **--help flag**: <100ms
- **list command**: Varies by font count (~200ms for 5000+ fonts)

---

## Performance Monitoring Tools

### Automatic Checks
```bash
# Test suite performance
./test.sh --check-performance

# Binary size regression
./test.sh --check-size

# Version consistency
./test.sh --check-version

# CI/CD configuration
./test.sh --verify-ci
```

### Manual Timing
```bash
# Measure build time
time ./build.sh

# Measure test time
time ./test.sh

# Measure specific script
time ./scripts/prepare-release.sh
```

---

## Regression Detection

### When Performance Degrades
1. **Identify the component**: Test suite, build, or script?
2. **Compare to baseline**: How much slower (percentage)?
3. **Check for changes**: Recent code changes that might impact performance?
4. **Profile if needed**: Use macOS Instruments for deep analysis

### Common Causes
- **Test suite slowdown**: Network latency, disk I/O, resource contention
- **Build slowdown**: Disk I/O, low disk space, resource contention
- **Script slowdown**: External command changes, file system performance

### Resolution Steps
1. Re-run to confirm regression (eliminate transient issues)
2. Check system resources (disk space, CPU, memory)
3. Run on different machine to isolate environment issues
4. Profile with Instruments if persistent
5. Revert recent changes if regression correlates with specific commit

---

## Updating Baselines

When hardware or macOS versions change significantly:

1. **Document environment**: macOS version, hardware (Intel vs M-series)
2. **Run full test suite 3 times**: Take median time
3. **Update this document**: Record new baseline with date and environment
4. **Update test.sh thresholds**: Adjust warning/critical thresholds if needed

**Historical Baselines**:
- **2025-11-01**: macOS 14.x, M-series Mac - Current baselines documented above

---

## References

- **Test performance monitoring**: Implemented in Phase 14 (v1.1.27)
- **Build performance monitoring**: Implemented in Phase 28 (v1.1.27)
- **Binary size validation**: Implemented in Phase 27 (v1.1.27)
- **Regression detection thresholds**: Warning at 30% slower, critical at 50% slower
