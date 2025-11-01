#!/bin/bash
# this_file: Tests/integration_test.sh
# Integration smoke tests for fontlift binary
# Tests end-to-end functionality with real operations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Change to project root
cd "$(dirname "$0")/.."

echo "🧪 Running integration smoke tests..."
echo ""

# Ensure binary exists
if [ ! -f ".build/release/fontlift" ]; then
    echo -e "${RED}❌ Binary not found at .build/release/fontlift${NC}"
    echo "Run ./build.sh first"
    exit 1
fi

BINARY=".build/release/fontlift"

# Helper function to run a test
run_test() {
    local test_name="$1"
    local command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: Binary metadata
echo "Testing binary metadata..."
run_test "Binary is executable" "[ -x $BINARY ]"
run_test "Binary size >1MB (universal)" "[ $(stat -f%z $BINARY) -gt 1048576 ]"
run_test "Binary --version outputs version" "$BINARY --version | grep -q '^[0-9]'"
run_test "Binary --help shows usage" "$BINARY --help | grep -q 'USAGE:'"
echo ""

# Test 2: List command (non-destructive)
echo "Testing list command..."
run_test "List command works" "$BINARY list | wc -l | grep -q '[0-9]'"
run_test "List -n works" "$BINARY list -n | wc -l | grep -q '[0-9]'"
run_test "List -p works" "$BINARY list -p | wc -l | grep -q '[0-9]'"
run_test "List -s reduces output" "[ $($BINARY list -n | wc -l) -gt $($BINARY list -n -s | wc -l) ]"
echo ""

# Test 3: Help texts for all commands
echo "Testing command help texts..."
run_test "Install help" "$BINARY install --help | grep -q 'Install fonts'"
run_test "Uninstall help" "$BINARY uninstall --help | grep -q 'Uninstall fonts'"
run_test "Remove help" "$BINARY remove --help | grep -q 'Remove fonts'"
run_test "Verify-version help" "$BINARY verify-version --help | grep -q 'Verify version'"
echo ""

# Test 4: Error handling
echo "Testing error handling..."
run_test "Install nonexistent file fails" "! $BINARY install /nonexistent/font.ttf 2>&1 | grep -q 'File not found'"
run_test "Uninstall nonexistent font fails" "! $BINARY uninstall -n NonExistentFont12345 2>&1 | grep -q 'not found'"
run_test "Install without args fails" "! $BINARY install 2>&1"
run_test "Uninstall without args fails" "! $BINARY uninstall 2>&1"
echo ""

# Test 5: Version verification
echo "Testing version verification..."
run_test "Verify-version detects match" "$BINARY verify-version | grep -q 'Version consistency verified'"
echo ""

# Print summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Integration Test Summary:"
echo "  Total:  $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✅ All integration tests passed!${NC}"
    exit 0
fi
