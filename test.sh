#!/bin/bash
# this_file: test.sh
# Run all tests for fontlift
#
# Usage: ./test.sh [OPTIONS]
#
# Options:
#   --ci            CI mode (minimal output, strict error codes)
#   --swift         Run only Swift unit tests
#   --scripts       Run only scripts tests
#   --integration   Run only integration tests
#   --help          Show this help message
#
# Test Suite Breakdown (Total: 94 tests):
#   • Swift Unit Tests: 52 tests (CLIErrorTests, HelperFunctionTests, ProjectValidationTests)
#   • Scripts Tests: 23 tests (build.sh, test.sh, publish.sh, validate-version.sh, get-version.sh, binary)
#   • Integration Tests: 19 tests (binary metadata, list command, help texts, error handling, output format)
#
# Note: Test counts in output are hardcoded and must be manually updated when tests are added/removed.
#       Run `swift test` to get accurate Swift test count, then update lines 83, 146, 150.

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Run all tests for fontlift.

Options:
  --ci            CI mode (minimal output, strict error codes)
  --swift         Run only Swift unit tests (52 tests)
  --scripts       Run only scripts tests (23 tests)
  --integration   Run only integration tests (19 tests)
  --help          Show this help message

Examples:
  $0                  # Run all tests (default)
  $0 --ci             # Run all tests in CI mode
  $0 --swift          # Run only Swift unit tests
  $0 --scripts        # Run only scripts tests
  $0 --integration    # Run only integration tests
  $0 --swift --ci     # Run Swift tests in CI mode

Environment:
  CI                  Set to "true" to enable CI mode
EOF
}

# Parse arguments
CI_MODE=false
RUN_SWIFT=true
RUN_SCRIPTS=true
RUN_INTEGRATION=true

if [[ "${CI:-}" == "true" ]]; then
    CI_MODE=true
fi

# Check if any suite-specific flags are set
SUITE_SPECIFIC=false
for arg in "$@"; do
    case $arg in
        --swift|--scripts|--integration)
            SUITE_SPECIFIC=true
            break
            ;;
    esac
done

# If suite-specific flags are present, disable all suites by default
if [ "$SUITE_SPECIFIC" = true ]; then
    RUN_SWIFT=false
    RUN_SCRIPTS=false
    RUN_INTEGRATION=false
fi

for arg in "$@"; do
    case $arg in
        --ci)
            CI_MODE=true
            ;;
        --swift)
            RUN_SWIFT=true
            ;;
        --scripts)
            RUN_SCRIPTS=true
            ;;
        --integration)
            RUN_INTEGRATION=true
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

# Allow callers (like scripts_test.sh) to skip invoking the scripts suite
SKIP_SCRIPT_TESTS="${SKIP_SCRIPT_TESTS:-false}"

# Change to project root (where this script is located)
cd "$(dirname "$0")"

# Verify Swift is installed
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed or not in PATH"
    echo "   Try: Install Xcode Command Line Tools with: xcode-select --install"
    exit 1
fi

# Count which suites are running
SUITES_RUNNING=0
if [ "$RUN_SWIFT" = true ]; then ((SUITES_RUNNING++)); fi
if [ "$RUN_SCRIPTS" = true ] && [ "$SKIP_SCRIPT_TESTS" != "true" ]; then ((SUITES_RUNNING++)); fi
if [ "$RUN_INTEGRATION" = true ]; then ((SUITES_RUNNING++)); fi

SUITE_NUM=0

if [ "$CI_MODE" = false ]; then
    echo "🧪 Running fontlift test suite"
    echo ""
fi

# Track total start time
TOTAL_START=$(date +%s)

# Run Swift tests with verbose output
SWIFT_DURATION=0
if [ "$RUN_SWIFT" = true ]; then
    ((SUITE_NUM++))
    if [ "$CI_MODE" = false ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if [ "$SUITES_RUNNING" -gt 1 ]; then
            echo "Suite $SUITE_NUM/$SUITES_RUNNING: Swift Unit Tests (52 tests)"
        else
            echo "Swift Unit Tests (52 tests)"
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
    SWIFT_START=$(date +%s)
    swift test --parallel
    SWIFT_END=$(date +%s)
    SWIFT_DURATION=$((SWIFT_END - SWIFT_START))
fi

if [ "$CI_MODE" = false ]; then
    echo ""
fi

# Run scripts tests if they exist and we're not skipping them
SCRIPTS_DURATION=0
should_run_scripts_tests=true
if [[ "$SKIP_SCRIPT_TESTS" == "true" || "$SKIP_SCRIPT_TESTS" == "1" ]]; then
    should_run_scripts_tests=false
fi

if [ "$RUN_SCRIPTS" = true ] && [ "$should_run_scripts_tests" = true ] && [ -f "Tests/scripts_test.sh" ]; then
    ((SUITE_NUM++))
    if [ "$CI_MODE" = false ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if [ "$SUITES_RUNNING" -gt 1 ]; then
            echo "Suite $SUITE_NUM/$SUITES_RUNNING: Scripts Tests (23 tests)"
        else
            echo "Scripts Tests (23 tests)"
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
    SCRIPTS_START=$(date +%s)
    ./Tests/scripts_test.sh
    SCRIPTS_END=$(date +%s)
    SCRIPTS_DURATION=$((SCRIPTS_END - SCRIPTS_START))
fi

# Run integration tests if they exist
INTEGRATION_DURATION=0
if [ "$RUN_INTEGRATION" = true ] && [ -f "Tests/integration_test.sh" ]; then
    ((SUITE_NUM++))
    if [ "$CI_MODE" = false ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if [ "$SUITES_RUNNING" -gt 1 ]; then
            echo "Suite $SUITE_NUM/$SUITES_RUNNING: Integration Tests (19 tests)"
        else
            echo "Integration Tests (19 tests)"
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
    INTEGRATION_START=$(date +%s)
    ./Tests/integration_test.sh
    INTEGRATION_END=$(date +%s)
    INTEGRATION_DURATION=$((INTEGRATION_END - INTEGRATION_START))
fi

TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

if [ "$CI_MODE" = false ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All Tests Passed! (94 total)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Test Execution Times:"
    echo "  • Swift unit tests:       ${SWIFT_DURATION}s (52 tests)"
    if [ "$SCRIPTS_DURATION" -gt 0 ]; then
        echo "  • Scripts tests:          ${SCRIPTS_DURATION}s (23 tests)"
    fi
    if [ "$INTEGRATION_DURATION" -gt 0 ]; then
        echo "  • Integration tests:      ${INTEGRATION_DURATION}s (19 tests)"
    fi
    echo "  ────────────────────────────────────────────────────"
    echo "  • Total:                  ${TOTAL_DURATION}s"
    echo ""
else
    echo "✅ All tests passed"
fi
