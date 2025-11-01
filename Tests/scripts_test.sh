#!/bin/bash
# this_file: Tests/scripts_test.sh
# Test suite for all bash scripts in the project
# Usage: ./tests/scripts_test.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Change to project root
cd "$(dirname "$0")/.."

echo "🧪 Running scripts test suite..."
echo ""

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

# Test build.sh
echo "Testing build.sh..."
run_test "build.sh --help shows help" "./build.sh --help | grep -q 'Usage:'"
run_test "build.sh --ci builds successfully" "./build.sh --ci"
run_test "build.sh rejects invalid option" "! ./build.sh --invalid-option 2>&1 | grep -q 'Error:'"
run_test "build.sh produces binary" "[ -f .build/release/fontlift ]"
run_test "build.sh binary is executable" "[ -x .build/release/fontlift ]"
echo ""

# Test test.sh
echo "Testing test.sh..."
run_test "test.sh --help shows help" "./test.sh --help | grep -q 'Usage:'"
run_test "test.sh --ci runs tests" "SKIP_SCRIPT_TESTS=true ./test.sh --ci"
run_test "test.sh rejects invalid option" "! ./test.sh --invalid-option 2>&1 | grep -q 'Error:'"
echo ""

# Test publish.sh
echo "Testing publish.sh..."
run_test "publish.sh --help shows help" "./publish.sh --help | grep -q 'Usage:'"
run_test "publish.sh --ci verifies binary" "./publish.sh --ci"
run_test "publish.sh rejects invalid option" "! ./publish.sh --invalid-option 2>&1 | grep -q 'Error:'"
echo ""

# Test validate-version.sh
echo "Testing validate-version.sh..."
run_test "validate-version.sh --help shows help" "./scripts/validate-version.sh --help | grep -q 'Usage:'"
run_test "validate-version.sh matches current version" "./scripts/validate-version.sh $(./scripts/get-version.sh)"
run_test "validate-version.sh rejects invalid semver" "! ./scripts/validate-version.sh 1.1 2>&1"
run_test "validate-version.sh requires argument" "! ./scripts/validate-version.sh 2>&1"
echo ""

# Test get-version.sh
echo "Testing get-version.sh..."
run_test "get-version.sh extracts version" "./scripts/get-version.sh | grep -q '^[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+$'"
# Dynamically extract version from code to avoid hardcoding
CODE_VERSION=$(grep "private let version = " Sources/fontlift/fontlift.swift | sed "s/.*\"\(.*\)\".*/\1/")
run_test "get-version.sh matches code" "[ \"$(./scripts/get-version.sh)\" = \"${CODE_VERSION}\" ]"
echo ""

# Test fontlift binary
echo "Testing fontlift binary..."
run_test "fontlift --version works" ".build/release/fontlift --version | grep -q '^[0-9]'"
run_test "fontlift --help works" ".build/release/fontlift --help | grep -q 'USAGE:'"
run_test "fontlift list --help works" ".build/release/fontlift list --help | grep -q 'List installed fonts'"
run_test "fontlift install --help works" ".build/release/fontlift install --help | grep -q 'Install fonts'"
run_test "fontlift uninstall --help works" ".build/release/fontlift uninstall --help | grep -q 'Uninstall fonts'"
run_test "fontlift remove --help works" ".build/release/fontlift remove --help | grep -q 'Remove fonts'"
echo ""

# Print summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary:"
echo "  Total:  $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✅ All scripts tests passed!${NC}"
    exit 0
fi
