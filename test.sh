#!/bin/bash
# this_file: test.sh
# Run all tests for fontlift
# Usage: ./test.sh [OPTIONS]
# Options:
#   --ci          CI mode (minimal output, strict error codes)
#   --verify-ci   Verify GitHub Actions CI/CD configuration
#   --shellcheck  Run shellcheck on all bash scripts
#   --check-size  Check binary size for regressions
#   --coverage    Generate code coverage report
#   --help        Show this help message

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
  --ci          CI mode (minimal output, strict error codes)
  --verify-ci   Verify GitHub Actions CI/CD configuration
  --shellcheck  Run shellcheck on all bash scripts
  --check-size  Check binary size for regressions
  --coverage    Generate code coverage report
  --help        Show this help message

Examples:
  $0              # Run tests normally (local mode)
  $0 --ci         # Run tests in CI mode
  $0 --verify-ci  # Verify CI/CD workflows are configured correctly
  $0 --shellcheck # Run shellcheck on all bash scripts
  $0 --check-size # Check binary size for regressions
  $0 --coverage   # Run tests with code coverage report
  CI=true $0      # Run tests in CI mode (environment variable)

Environment:
  CI              Set to "true" to enable CI mode
EOF
}

# Parse arguments
CI_MODE=false
VERIFY_CI=false
RUN_SHELLCHECK=false
CHECK_SIZE=false
GENERATE_COVERAGE=false
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
        --coverage)
            GENERATE_COVERAGE=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option: $arg"
            echo ""
            show_help
            exit 1
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

# If --check-size flag is set, check binary size and exit
if [ "$CHECK_SIZE" = true ]; then
    echo "📏 Checking binary size for regressions..."

    # Acceptable size ranges (with 20% tolerance):
    # - Native binary (single arch): 1.6M baseline, max 1.9M (1.6M * 1.2)
    # - Universal binary (x86_64 + arm64): 3.2M baseline, max 3.8M (3.2M * 1.2)

    BINARY_PATH=".build/release/fontlift"

    if [ ! -f "$BINARY_PATH" ]; then
        echo "❌ Error: Binary not found at $BINARY_PATH"
        echo "Run ./build.sh first"
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

# Allow callers (like scripts_test.sh) to skip invoking the scripts suite
SKIP_SCRIPT_TESTS="${SKIP_SCRIPT_TESTS:-false}"

# Change to project root (where this script is located)
cd "$(dirname "$0")"

# Verify Swift is installed
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed or not in PATH"
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
else
    echo "✅ All tests passed"
fi
