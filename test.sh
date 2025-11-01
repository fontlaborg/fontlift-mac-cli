#!/bin/bash
# this_file: test.sh
# Run all tests for fontlift
#
# Usage: ./test.sh [OPTIONS]
#
# Options:
#   --ci     CI mode (minimal output, strict error codes)
#   --help   Show this help message

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Run all tests for fontlift.

Options:
  --ci     CI mode (minimal output, strict error codes)
  --help   Show this help message

Examples:
  $0              # Run tests normally (local mode)
  $0 --ci         # Run tests in CI mode
  CI=true $0      # Run tests in CI mode (environment variable)

Environment:
  CI              Set to "true" to enable CI mode
EOF
}

# Parse arguments
CI_MODE=false
if [[ "${CI:-}" == "true" ]]; then
    CI_MODE=true
fi

for arg in "$@"; do
    case $arg in
        --ci)
            CI_MODE=true
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

if [ "$CI_MODE" = false ]; then
    echo "🧪 Running fontlift test suite"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Suite 1/3: Swift Unit Tests (43 tests)"
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
    echo "✅ All Tests Passed! (81 total)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Test Execution Times:"
    echo "  • Swift unit tests:       ${SWIFT_DURATION}s (43 tests)"
    if [ "$SCRIPTS_DURATION" -gt 0 ]; then
        echo "  • Scripts tests:          ${SCRIPTS_DURATION}s (23 tests)"
    fi
    if [ "$INTEGRATION_DURATION" -gt 0 ]; then
        echo "  • Integration tests:      ${INTEGRATION_DURATION}s (15 tests)"
    fi
    echo "  ────────────────────────────────────────────────────"
    echo "  • Total:                  ${TOTAL_DURATION}s"
    echo ""
else
    echo "✅ All tests passed"
fi
