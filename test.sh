#!/bin/bash
# this_file: test.sh
# Run all tests for fontlift
# Usage: ./test.sh [OPTIONS]
# Options:
#   --ci        CI mode (minimal output, strict error codes)
#   --help      Show this help message

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Run all tests for fontlift.

Options:
  --ci        CI mode (minimal output, strict error codes)
  --help      Show this help message

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
            shift
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
    exit 1
fi

if [ "$CI_MODE" = false ]; then
    echo "🧪 Running fontlift tests..."
    echo ""
fi

# Run Swift tests with verbose output
swift test --parallel

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
        echo "Running scripts test suite..."
        echo ""
    fi
    ./Tests/scripts_test.sh
fi

# Run integration tests if they exist
if [ -f "Tests/integration_test.sh" ]; then
    if [ "$CI_MODE" = false ]; then
        echo ""
        echo "Running integration smoke tests..."
        echo ""
    fi
    ./Tests/integration_test.sh
fi

if [ "$CI_MODE" = false ]; then
    echo ""
    echo "✅ All tests passed!"
else
    echo "✅ All tests passed"
fi
