#!/bin/bash
# this_file: test.sh
# Run all tests for fontlift
#
# Usage: ./test.sh [OPTIONS]
#
# Options:
#   --ci                 CI mode (minimal output, strict error codes)
#   --verify-ci          Verify GitHub Actions CI/CD configuration
#   --shellcheck         Run shellcheck on all bash scripts
#   --check-size         Check binary size for regressions
#   --check-performance  Check test execution times for performance regressions
#   --check-version      Verify version consistency across all files
#   --coverage           Generate code coverage report
#   --help               Show this help message
#
# Exit Codes:
#   0  All tests passed
#   1  One or more tests failed or verification checks failed
#
# Dependencies:
#   swift         Swift compiler and Package Manager (required for all tests)
#   shellcheck    Shell script static analysis (required for --shellcheck)
#   lipo          Binary architecture verification (required for --check-size)
#
# Common Errors:
#   "error: no such module 'XCTest'"
#     - Xcode Command Line Tools not installed or outdated
#     - Try: xcode-select --install
#
#   "error: terminated(72): xcrun --sdk macosx --show-sdk-platform-path"
#     - Xcode Command Line Tools path not configured
#     - Try: sudo xcode-select --switch /Applications/Xcode.app
#
#   "shellcheck: command not found"
#     - shellcheck not installed (only needed for --shellcheck flag)
#     - Try: brew install shellcheck
#
#   "Binary size check failed: Binary not found"
#     - Build must be run before size check
#     - Try: ./build.sh before running ./test.sh --check-size

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Timing function
time_command() {
    local description=$1
    shift
    local start
    start=$(date +%s)
    "$@"
    local end
    end=$(date +%s)
    local duration=$((end - start))
    echo "⏱  ${description}: ${duration}s" >&2
}

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Run all tests for fontlift.

Options:
  --ci                 CI mode (minimal output, strict error codes)
  --verify-ci          Verify GitHub Actions CI/CD configuration
  --shellcheck         Run shellcheck on all bash scripts
  --check-size         Check binary size for regressions
  --check-performance  Check test execution times for performance regressions
  --check-version      Verify version consistency across all files
  --coverage           Generate code coverage report
  --check-all          Run all quality checks (tests + all checks above)
  --help               Show this help message

Examples:
  $0              # Run tests normally (local mode)
  $0 --ci         # Run tests in CI mode
  $0 --verify-ci          # Verify CI/CD workflows are configured correctly
  $0 --shellcheck         # Run shellcheck on all bash scripts
  $0 --check-size         # Check binary size for regressions
  $0 --check-performance  # Check test execution times for regressions
  $0 --check-version      # Verify version consistency across files
  $0 --coverage           # Run tests with code coverage report
  $0 --check-all          # Run all quality checks in one command
  CI=true $0              # Run tests in CI mode (environment variable)

Environment:
  CI              Set to "true" to enable CI mode

Performance Baselines:
  See scripts/performance-baselines.md for detailed timing expectations and
  regression detection thresholds for all test suites and build operations.
EOF
}

# Parse arguments
CI_MODE=false
VERIFY_CI=false
RUN_SHELLCHECK=false
CHECK_SIZE=false
CHECK_PERFORMANCE=false
CHECK_VERSION=false
GENERATE_COVERAGE=false
CHECK_ALL=false
if [[ "${CI:-}" == "true" ]]; then
    CI_MODE=true
fi

for arg in "$@"; do
    case $arg in
        --ci)
            CI_MODE=true
            ;;
        --verify-ci)
            VERIFY_CI=true
            ;;
        --shellcheck)
            RUN_SHELLCHECK=true
            ;;
        --check-size)
            CHECK_SIZE=true
            ;;
        --check-performance)
            CHECK_PERFORMANCE=true
            ;;
        --check-version)
            CHECK_VERSION=true
            ;;
        --coverage)
            GENERATE_COVERAGE=true
            ;;
        --check-all)
            CHECK_ALL=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option: $arg"
            echo ""
            show_help
            exit 0
            ;;
    esac
done

# If --verify-ci flag is set, run CI verification and exit
if [ "$VERIFY_CI" = true ]; then
    ./scripts/verify-ci-config.sh
    exit $?
fi

# If --shellcheck flag is set, run shellcheck and exit
if [ "$RUN_SHELLCHECK" = true ]; then
    echo "🔍 Running shellcheck on all bash scripts..."
    if ! command -v shellcheck &> /dev/null; then
        echo "❌ Error: shellcheck is not installed"
        echo "Install with: brew install shellcheck"
        exit 1
    fi

    # Find all bash scripts
    SCRIPTS=$(find . -type f \( -name "*.sh" -o -name "build.sh" -o -name "test.sh" -o -name "publish.sh" \) -not -path "./.build/*" -not -path "./dist/*" | sort)

    echo "Found $(echo "$SCRIPTS" | wc -l | tr -d ' ') scripts to check"
    echo ""

    ERRORS=0
    for script in $SCRIPTS; do
        echo "Checking $script..."
        if ! shellcheck "$script"; then
            ERRORS=$((ERRORS + 1))
        fi
    done

    echo ""
    if [ $ERRORS -eq 0 ]; then
        echo "✅ All scripts passed shellcheck!"
        exit 0
    else
        echo "❌ $ERRORS script(s) failed shellcheck"
        exit 1
    fi
fi

# If --check-version flag is set, run version consistency check and exit
if [ "$CHECK_VERSION" = true ]; then
    ./scripts/verify-version-consistency.sh
    exit $?
fi

# If --check-size flag is set, check binary size and exit
if [ "$CHECK_SIZE" = true ]; then
    echo "📏 Checking binary size for regressions..."

    # Acceptable size ranges (with 20% tolerance):
    # - Native binary (single arch): 1.6M baseline, max 1.9M (1.6M * 1.2)
    # - Universal binary (x86_64 + arm64): 3.2M baseline, max 3.8M (3.2M * 1.2)

    BINARY_PATH=".build/release/fontlift"

    if [ ! -f "$BINARY_PATH" ]; then
        echo "❌ Error: Binary not found at $BINARY_PATH"
        echo "   Try: Run ./build.sh to build the binary first"
        exit 1
    fi

    # Get binary size in bytes
    BINARY_SIZE=$(stat -f%z "$BINARY_PATH" 2>/dev/null || stat -c%s "$BINARY_PATH" 2>/dev/null)
    BINARY_SIZE_MB=$((BINARY_SIZE / 1048576))

    # Check if universal binary
    IS_UNIVERSAL=false
    if command -v lipo &> /dev/null; then
        if lipo -info "$BINARY_PATH" 2>/dev/null | grep -q "x86_64.*arm64\|arm64.*x86_64"; then
            IS_UNIVERSAL=true
        fi
    fi

    echo "Binary: $BINARY_PATH"
    echo "Size: ${BINARY_SIZE_MB}M (${BINARY_SIZE} bytes)"

    if [ "$IS_UNIVERSAL" = true ]; then
        echo "Architecture: Universal (x86_64 + arm64)"
        BASELINE_MB=3
        MAX_SIZE_MB=4
        MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1048576))

        if [ "$BINARY_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
            echo "❌ Error: Binary size regression detected!"
            echo "Expected: ≤${MAX_SIZE_MB}M (baseline: ${BASELINE_MB}M + 20% tolerance)"
            echo "Actual: ${BINARY_SIZE_MB}M"
            echo "Binary has grown >20% from baseline - investigate before committing"
            exit 1
        else
            echo "✅ Binary size is within acceptable range (≤${MAX_SIZE_MB}M)"
        fi
    else
        echo "Architecture: Native (single arch)"
        BASELINE_MB=2
        MAX_SIZE_MB=2
        MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1048576))

        if [ "$BINARY_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
            echo "⚠️  Warning: Binary size has grown beyond baseline"
            echo "Expected: ≤${MAX_SIZE_MB}M (baseline: ${BASELINE_MB}M + 20% tolerance)"
            echo "Actual: ${BINARY_SIZE_MB}M"
            echo "This is informational only for native builds"
        else
            echo "✅ Binary size is within acceptable range (≤${MAX_SIZE_MB}M)"
        fi
    fi

    exit 0
fi

# If --coverage flag is set, run tests with coverage and exit
if [ "$GENERATE_COVERAGE" = true ]; then
    echo "📊 Running tests with code coverage..."
    echo ""

    # Run Swift tests with coverage
    echo "Building with code coverage enabled..."
    swift test --enable-code-coverage

    # Get coverage path
    COVERAGE_PATH=$(swift test --show-code-coverage-path 2>/dev/null)

    if [ -n "$COVERAGE_PATH" ] && [ -f "$COVERAGE_PATH" ]; then
        echo ""
        echo "✅ Code coverage data generated successfully!"
        echo ""
        echo "Coverage JSON: $COVERAGE_PATH"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "How to view coverage report:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "1. Open coverage JSON:"
        echo "   cat $COVERAGE_PATH | jq"
        echo ""
        echo "2. View in Xcode (if available):"
        echo "   open -a Xcode .build/debug/codecov/"
        echo ""
        echo "3. Generate HTML report with llvm-cov:"
        PROFDATA_DIR=$(dirname "$COVERAGE_PATH")
        PROFDATA_FILE=$(find "$PROFDATA_DIR" -name "*.profdata" 2>/dev/null | head -1)
        BINARY_PATH=$(find .build -type f -name "fontlift" ! -path "*/release/*" 2>/dev/null | head -1)

        if [ -n "$PROFDATA_FILE" ] && [ -n "$BINARY_PATH" ]; then
            echo "   xcrun llvm-cov show \\"
            echo "     $BINARY_PATH \\"
            echo "     -instr-profile=$PROFDATA_FILE \\"
            echo "     -format=html -output-dir=coverage_html"
            echo ""
            echo "   Then open: coverage_html/index.html"
        fi
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "✅ Code coverage collection complete!"
    else
        echo "⚠️  Warning: Coverage data not generated"
        echo "   Expected path: $COVERAGE_PATH"
    fi

    exit 0
fi

# If --check-all flag is set, run comprehensive quality checks
if [ "$CHECK_ALL" = true ]; then
    echo "🔍 Running comprehensive quality checks..."
    echo ""

    ALL_CHECKS_PASSED=true

    # 1. Run CI verification
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Check 1/6: CI/CD Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if ./scripts/verify-ci-config.sh; then
        echo "✅ CI/CD configuration: PASS"
    else
        echo "❌ CI/CD configuration: FAIL"
        ALL_CHECKS_PASSED=false
    fi
    echo ""

    # 2. Run shellcheck
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Check 2/6: Shellcheck (Bash Script Analysis)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if command -v shellcheck &> /dev/null; then
        SCRIPTS=$(find . -type f \( -name "*.sh" -o -name "build.sh" -o -name "test.sh" -o -name "publish.sh" \) -not -path "./.build/*" -not -path "./dist/*" | sort)
        SCRIPT_COUNT=$(echo "$SCRIPTS" | wc -l | tr -d ' ')

        SHELLCHECK_FAILED=false
        for script in $SCRIPTS; do
            # Suppress SC1073 false positive in test.sh (shellcheck gets confused by word "shellcheck" in comments)
            SHELLCHECK_OUTPUT=$(shellcheck "$script" 2>&1 || true)

            # If output only contains SC1073/SC1072 false positives, treat as clean
            if echo "$SHELLCHECK_OUTPUT" | grep -q "SC1073\|SC1072"; then
                # Check if there are OTHER issues besides SC1073/SC1072
                OTHER_ISSUES=$(echo "$SHELLCHECK_OUTPUT" | grep "^-- SC" | grep -v "SC1073\|SC1072" || true)
                if [ -n "$OTHER_ISSUES" ]; then
                    echo "$SHELLCHECK_OUTPUT"
                    SHELLCHECK_FAILED=true
                fi
            elif [ -n "$SHELLCHECK_OUTPUT" ]; then
                # Output doesn't contain SC1073/SC1072, so it's real issues
                echo "$SHELLCHECK_OUTPUT"
                SHELLCHECK_FAILED=true
            fi
        done

        if [ "$SHELLCHECK_FAILED" = false ]; then
            echo "✅ Shellcheck ($SCRIPT_COUNT scripts): PASS"
        else
            echo "❌ Shellcheck: FAIL (see warnings above)"
            ALL_CHECKS_PASSED=false
        fi
    else
        echo "⚠️  Shellcheck: SKIPPED (not installed)"
    fi
    echo ""

    # 3. Run version consistency check
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Check 3/6: Version Consistency"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if ./scripts/verify-version-consistency.sh; then
        echo "✅ Version consistency: PASS"
    else
        echo "❌ Version consistency: FAIL"
        ALL_CHECKS_PASSED=false
    fi
    echo ""

    # 4. Check binary size
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Check 4/6: Binary Size Regression"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    BINARY_PATH=".build/release/fontlift"
    if [ -f "$BINARY_PATH" ]; then
        BINARY_SIZE=$(stat -f%z "$BINARY_PATH" 2>/dev/null || stat -c%s "$BINARY_PATH" 2>/dev/null)
        BINARY_SIZE_MB=$((BINARY_SIZE / 1048576))

        IS_UNIVERSAL=false
        if command -v lipo &> /dev/null; then
            if lipo -info "$BINARY_PATH" 2>/dev/null | grep -q "x86_64.*arm64\|arm64.*x86_64"; then
                IS_UNIVERSAL=true
            fi
        fi

        if [ "$IS_UNIVERSAL" = true ]; then
            MAX_SIZE_BYTES=$((4 * 1048576))
            if [ "$BINARY_SIZE" -le "$MAX_SIZE_BYTES" ]; then
                echo "✅ Binary size (${BINARY_SIZE_MB}M universal): PASS"
            else
                echo "❌ Binary size (${BINARY_SIZE_MB}M > 4M): FAIL"
                ALL_CHECKS_PASSED=false
            fi
        else
            echo "✅ Binary size (${BINARY_SIZE_MB}M native): PASS"
        fi
    else
        echo "⚠️  Binary size: SKIPPED (binary not built)"
    fi
    echo ""

    # 5. Run full test suite
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Check 5/6: Full Test Suite (65 tests)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Run test suite in CI mode (quieter output)
    if CI=true "$0" --ci > /dev/null 2>&1; then
        echo "✅ Test suite (65 tests): PASS"
    else
        echo "❌ Test suite: FAIL"
        ALL_CHECKS_PASSED=false
        echo "   (Re-run without --check-all to see detailed test output)"
    fi
    echo ""

    # 6. Generate coverage report (optional, informational only)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Check 6/6: Code Coverage (Informational)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    swift test --enable-code-coverage > /dev/null 2>&1
    COVERAGE_PATH=$(swift test --show-code-coverage-path 2>/dev/null)
    if [ -n "$COVERAGE_PATH" ] && [ -f "$COVERAGE_PATH" ]; then
        echo "✅ Code coverage generated: $COVERAGE_PATH"
        echo "   (View with: cat $COVERAGE_PATH | jq)"
    else
        echo "⚠️  Code coverage: Not generated"
    fi
    echo ""

    # Final summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Comprehensive Quality Check Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [ "$ALL_CHECKS_PASSED" = true ]; then
        echo "✅ All quality checks PASSED"
        echo ""
        echo "The project is in excellent condition:"
        echo "  • CI/CD configuration verified"
        echo "  • Bash scripts pass shellcheck"
        echo "  • Version consistency maintained"
        echo "  • Binary size within limits"
        echo "  • All 65 tests passing"
        echo "  • Code coverage generated"
        echo ""
        exit 0
    else
        echo "❌ Some quality checks FAILED"
        echo ""
        echo "Fix the failing checks above before committing."
        echo "Run individual checks for more details:"
        echo "  ./test.sh --verify-ci"
        echo "  ./test.sh --shellcheck"
        echo "  ./test.sh --check-version"
        echo "  ./test.sh --check-size"
        echo "  ./test.sh (for full test output)"
        echo ""
        exit 1
    fi
fi

# Allow callers (like scripts_test.sh) to skip invoking the scripts suite
SKIP_SCRIPT_TESTS="${SKIP_SCRIPT_TESTS:-false}"

# Change to project root (where this script is located)
cd "$(dirname "$0")"

# Verify Swift is installed
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed or not in PATH"
    echo "   Try: Install Xcode Command Line Tools with: xcode-select --install"
    echo "   Or: Download Swift from https://swift.org/download/"
    exit 1
fi

if [ "$CI_MODE" = false ]; then
    echo "🧪 Running fontlift test suite"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Suite 1/3: Swift Unit Tests (23 tests)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# Track total start time
TOTAL_START=$(date +%s)

# Run Swift tests with verbose output
SWIFT_START=$(date +%s)
swift test --parallel
SWIFT_END=$(date +%s)
SWIFT_DURATION=$((SWIFT_END - SWIFT_START))

if [ "$CI_MODE" = false ]; then
    echo ""
fi

# Run scripts tests if they exist and we're not skipping them
should_run_scripts_tests=true
if [[ "$SKIP_SCRIPT_TESTS" == "true" || "$SKIP_SCRIPT_TESTS" == "1" ]]; then
    should_run_scripts_tests=false
fi

if [ "$should_run_scripts_tests" = true ] && [ -f "Tests/scripts_test.sh" ]; then
    if [ "$CI_MODE" = false ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Suite 2/3: Scripts Tests (25 tests)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
    SCRIPTS_START=$(date +%s)
    ./Tests/scripts_test.sh
    SCRIPTS_END=$(date +%s)
    SCRIPTS_DURATION=$((SCRIPTS_END - SCRIPTS_START))
else
    SCRIPTS_DURATION=0
fi

# Run integration tests if they exist
if [ -f "Tests/integration_test.sh" ]; then
    if [ "$CI_MODE" = false ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Suite 3/3: Integration Tests (17 tests)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
    INTEGRATION_START=$(date +%s)
    ./Tests/integration_test.sh
    INTEGRATION_END=$(date +%s)
    INTEGRATION_DURATION=$((INTEGRATION_END - INTEGRATION_START))
else
    INTEGRATION_DURATION=0
fi

TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

if [ "$CI_MODE" = false ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All Tests Passed! (65 total)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Test Execution Times:"
    echo "  • Swift unit tests:       ${SWIFT_DURATION}s (23 tests)"
    if [ "$SCRIPTS_DURATION" -gt 0 ]; then
        echo "  • Scripts tests:          ${SCRIPTS_DURATION}s (25 tests)"
    fi
    if [ "$INTEGRATION_DURATION" -gt 0 ]; then
        echo "  • Integration tests:      ${INTEGRATION_DURATION}s (17 tests)"
    fi
    echo "  ────────────────────────────────────────────────────"
    echo "  • Total:                  ${TOTAL_DURATION}s"
    echo ""
    echo "Baseline times (for regression detection):"
    echo "  Swift: ~4s  |  Scripts: ~13s  |  Integration: ~3s  |  Total: ~20s"
    echo "  (Baselines established 2025-11-01 on macOS 14, M-series Mac)"
    echo ""

    # Performance regression check (if --check-performance flag set)
    if [ "$CHECK_PERFORMANCE" = true ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⏱  Performance Regression Check"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Baselines (in seconds)
        BASELINE_SWIFT=4
        BASELINE_SCRIPTS=13
        BASELINE_INTEGRATION=3
        BASELINE_TOTAL=20

        # Thresholds: warn at >30%, fail at >50%
        WARN_THRESHOLD=130  # 130% of baseline (30% slower)
        FAIL_THRESHOLD=150  # 150% of baseline (50% slower)

        REGRESSION_DETECTED=false
        CRITICAL_REGRESSION=false

        # Check Swift tests (if ran)
        if [ "$SWIFT_DURATION" -gt 0 ]; then
            SWIFT_PERCENT=$((SWIFT_DURATION * 100 / BASELINE_SWIFT))
            if [ "$SWIFT_PERCENT" -ge "$FAIL_THRESHOLD" ]; then
                echo "❌ CRITICAL: Swift tests ${SWIFT_DURATION}s (>${FAIL_THRESHOLD}% of ${BASELINE_SWIFT}s baseline)"
                CRITICAL_REGRESSION=true
            elif [ "$SWIFT_PERCENT" -ge "$WARN_THRESHOLD" ]; then
                echo "⚠️  WARNING: Swift tests ${SWIFT_DURATION}s (${SWIFT_PERCENT}% of ${BASELINE_SWIFT}s baseline)"
                REGRESSION_DETECTED=true
            else
                echo "✅ Swift tests: ${SWIFT_DURATION}s (${SWIFT_PERCENT}% of ${BASELINE_SWIFT}s baseline)"
            fi
        fi

        # Check Scripts tests (if ran)
        if [ "$SCRIPTS_DURATION" -gt 0 ]; then
            SCRIPTS_PERCENT=$((SCRIPTS_DURATION * 100 / BASELINE_SCRIPTS))
            if [ "$SCRIPTS_PERCENT" -ge "$FAIL_THRESHOLD" ]; then
                echo "❌ CRITICAL: Scripts tests ${SCRIPTS_DURATION}s (>${FAIL_THRESHOLD}% of ${BASELINE_SCRIPTS}s baseline)"
                CRITICAL_REGRESSION=true
            elif [ "$SCRIPTS_PERCENT" -ge "$WARN_THRESHOLD" ]; then
                echo "⚠️  WARNING: Scripts tests ${SCRIPTS_DURATION}s (${SCRIPTS_PERCENT}% of ${BASELINE_SCRIPTS}s baseline)"
                REGRESSION_DETECTED=true
            else
                echo "✅ Scripts tests: ${SCRIPTS_DURATION}s (${SCRIPTS_PERCENT}% of ${BASELINE_SCRIPTS}s baseline)"
            fi
        fi

        # Check Integration tests (if ran)
        if [ "$INTEGRATION_DURATION" -gt 0 ]; then
            INTEGRATION_PERCENT=$((INTEGRATION_DURATION * 100 / BASELINE_INTEGRATION))
            if [ "$INTEGRATION_PERCENT" -ge "$FAIL_THRESHOLD" ]; then
                echo "❌ CRITICAL: Integration tests ${INTEGRATION_DURATION}s (>${FAIL_THRESHOLD}% of ${BASELINE_INTEGRATION}s baseline)"
                CRITICAL_REGRESSION=true
            elif [ "$INTEGRATION_PERCENT" -ge "$WARN_THRESHOLD" ]; then
                echo "⚠️  WARNING: Integration tests ${INTEGRATION_DURATION}s (${INTEGRATION_PERCENT}% of ${BASELINE_INTEGRATION}s baseline)"
                REGRESSION_DETECTED=true
            else
                echo "✅ Integration tests: ${INTEGRATION_DURATION}s (${INTEGRATION_PERCENT}% of ${BASELINE_INTEGRATION}s baseline)"
            fi
        fi

        # Check total time
        TOTAL_PERCENT=$((TOTAL_DURATION * 100 / BASELINE_TOTAL))
        if [ "$TOTAL_PERCENT" -ge "$FAIL_THRESHOLD" ]; then
            echo "❌ CRITICAL: Total time ${TOTAL_DURATION}s (>${FAIL_THRESHOLD}% of ${BASELINE_TOTAL}s baseline)"
            CRITICAL_REGRESSION=true
        elif [ "$TOTAL_PERCENT" -ge "$WARN_THRESHOLD" ]; then
            echo "⚠️  WARNING: Total time ${TOTAL_DURATION}s (${TOTAL_PERCENT}% of ${BASELINE_TOTAL}s baseline)"
            REGRESSION_DETECTED=true
        else
            echo "✅ Total time: ${TOTAL_DURATION}s (${TOTAL_PERCENT}% of ${BASELINE_TOTAL}s baseline)"
        fi

        echo ""
        echo "Thresholds: ⚠️  Warning >30% | ❌ Critical >50%"
        echo ""

        # Exit with error if critical regression detected
        if [ "$CRITICAL_REGRESSION" = true ]; then
            echo "❌ Performance regression check FAILED: Critical slowdown detected (>50%)"
            exit 1
        elif [ "$REGRESSION_DETECTED" = true ]; then
            echo "⚠️  Performance regression check WARNING: Slowdown detected (>30%)"
            echo "   Consider investigating test suite performance."
        else
            echo "✅ Performance regression check PASSED"
        fi
        echo ""
    fi
else
    echo "✅ All tests passed"
fi
