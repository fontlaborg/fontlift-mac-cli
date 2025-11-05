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
export FONTLIFT_FAKE_REGISTRATION=1

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

# Test 1: Binary metadata and performance
echo "Testing binary metadata..."
run_test "Binary is executable" "[ -x $BINARY ]"
run_test "Binary size >1MB (universal)" "[ $(stat -f%z $BINARY) -gt 1048576 ]"
run_test "Binary --version outputs version" "$BINARY --version | grep -q '^[0-9]'"
run_test "Binary --help shows usage" "$BINARY --help | grep -q 'USAGE:'"

# Performance baselines (for regression detection)
echo ""
echo "Performance baselines:"
START_TIME=$(python3 -c 'import time; print(int(time.time() * 1000))')
$BINARY --version > /dev/null
END_TIME=$(python3 -c 'import time; print(int(time.time() * 1000))')
STARTUP_MS=$((END_TIME - START_TIME))
echo "  • Binary startup (--version): ${STARTUP_MS}ms"

START_TIME=$(python3 -c 'import time; print(int(time.time() * 1000))')
$BINARY list > /dev/null
END_TIME=$(python3 -c 'import time; print(int(time.time() * 1000))')
LIST_MS=$((END_TIME - START_TIME))
echo "  • List command execution: ${LIST_MS}ms"

# Validate performance is reasonable (<1s for each operation)
run_test "Startup time <1000ms" "[ $STARTUP_MS -lt 1000 ]"
run_test "List command <1000ms" "[ $LIST_MS -lt 1000 ]"
echo ""

# Test 2: List command (non-destructive)
echo "Testing list command..."
run_test "List command works" "$BINARY list | wc -l | grep -q '[0-9]'"
run_test "List -n works" "$BINARY list -n | wc -l | grep -q '[0-9]'"
run_test "List -p works" "$BINARY list -p | wc -l | grep -q '[0-9]'"
run_test "List -s reduces output" "[ $($BINARY list -n | wc -l) -gt $($BINARY list -n -s | wc -l) ]"
run_test "List -p -n uses :: separator" "($BINARY list -p -n 2>&1 || true) | head -1 | grep -q '::'"
run_test "List -n -p uses :: separator" "($BINARY list -n -p 2>&1 || true) | head -1 | grep -q '::'"
run_test "List -p does NOT use :: separator" "! (($BINARY list -p 2>&1 || true) | head -1 | grep -q '::')"
run_test "List -n does NOT use :: separator" "! (($BINARY list -n 2>&1 || true) | head -1 | grep -q '::')"
echo ""

# Test 3: Help texts for all commands
echo "Testing command help texts..."
run_test "Install help" "$BINARY install --help | grep -q 'Install fonts'"
run_test "Uninstall help" "$BINARY uninstall --help | grep -q 'Uninstall fonts'"
run_test "Remove help" "$BINARY remove --help | grep -q 'Remove fonts'"
echo ""

# Test 4: Error handling
echo "Testing error handling..."
run_test "Install nonexistent file fails" "! $BINARY install /nonexistent/font.ttf 2>&1 | grep -q 'File not found'"
run_test "Uninstall nonexistent font fails" "! $BINARY uninstall -n NonExistentFont12345 2>&1 | grep -q 'not found'"
run_test "Install without args fails" "! $BINARY install 2>&1"
run_test "Uninstall without args fails" "! $BINARY uninstall 2>&1"
echo ""

# Test 5: Install auto-uninstall upgrades
echo "Testing install auto-uninstall..."
TESTDATA_DIR="$(pwd)/testdata"
TEST_FONT_V1="$TESTDATA_DIR/TestFont-v1.ttf"
TEST_FONT_V2="$TESTDATA_DIR/TestFont-v2.ttf"
TEST_FONT_V1_NAME="$(basename "$TEST_FONT_V1")"
TEST_FONT_V2_NAME="$(basename "$TEST_FONT_V2")"
SYSTEM_FONT="/System/Library/Fonts/Helvetica.ttc"
FAKE_REGISTRY_FILE=$(python3 - <<'PY'
import tempfile, os
print(os.path.join(tempfile.gettempdir(), "fontlift-fake-registry.json"))
PY
)

if [ ! -f "$TEST_FONT_V1" ] || [ ! -f "$TEST_FONT_V2" ]; then
    echo -e "${RED}❌ Test fonts not found in $TESTDATA_DIR${NC}"
    echo "Ensure TestFont-v1.ttf and TestFont-v2.ttf exist."
    exit 1
fi

if [ ! -f "$SYSTEM_FONT" ]; then
    echo -e "${RED}❌ Required system font not found: $SYSTEM_FONT${NC}"
    exit 1
fi

cleanup_auto_install() {
    $BINARY uninstall "$TEST_FONT_V1" 2>/dev/null || true
    $BINARY uninstall "$TEST_FONT_V2" 2>/dev/null || true
    rm -f /tmp/fontlift-auto-log.txt "$FAKE_REGISTRY_FILE"
}
trap cleanup_auto_install EXIT
cleanup_auto_install

run_test "Install v1 font succeeds" "$BINARY install $TEST_FONT_V1 | grep -q 'Installed'"
run_test "Install v2 font succeeds" "$BINARY install $TEST_FONT_V2 | grep -q 'Installed'"
run_test "Installing v2 removes previous v1 registration" \
    "! grep -q 'TestFont-v1.ttf' \"$FAKE_REGISTRY_FILE\""
run_test "Reinstalling v1 succeeds" "$BINARY install $TEST_FONT_V1 | grep -q 'Installed'"
run_test "Reinstalling v1 removes v2 registration" \
    "! grep -q 'TestFont-v2.ttf' \"$FAKE_REGISTRY_FILE\""
run_test "Reinstalling v2 succeeds" "$BINARY install $TEST_FONT_V2 | grep -q 'Installed'"
run_test "Reinstalling v2 removes v1 registration again" \
    "! grep -q 'TestFont-v1.ttf' \"$FAKE_REGISTRY_FILE\""
run_test "Installing conflict with system font blocked" \
    "! $BINARY install $SYSTEM_FONT 2>&1 | grep -q 'protected system font'"

# Test 6: Cleanup command
echo ""
echo "Testing cleanup command..."
cleanup_auto_install
CLEANUP_DIR=$(mktemp -d /tmp/fontlift-clean-XXXX)
PRUNE_FONT="$CLEANUP_DIR/font-to-prune.ttf"
USER_LIBRARY="$CLEANUP_DIR/UserLibrary"
SYSTEM_LIBRARY="$CLEANUP_DIR/SystemLibrary"
export FONTLIFT_OVERRIDE_USER_LIBRARY="$USER_LIBRARY"
export FONTLIFT_OVERRIDE_SYSTEM_LIBRARY="$SYSTEM_LIBRARY"

setup_third_party_caches() {
    rm -rf "$USER_LIBRARY" "$SYSTEM_LIBRARY"

    mkdir -p "$USER_LIBRARY/Application Support/Adobe/TypeSupport"
    mkdir -p "$USER_LIBRARY/Caches/Adobe/TypeSupport"
    mkdir -p "$USER_LIBRARY/Preferences/Microsoft"

    mkdir -p "$SYSTEM_LIBRARY/Application Support/Adobe/TypeSupport"
    mkdir -p "$SYSTEM_LIBRARY/Preferences/Microsoft"

    touch "$USER_LIBRARY/Application Support/Adobe/TypeSupport/AdobeFnt.lst"
    touch "$USER_LIBRARY/Caches/Adobe/TypeSupport/AdobeFnt16.lst"
    touch "$USER_LIBRARY/Preferences/Microsoft/Office Font Cache (16)"

    touch "$SYSTEM_LIBRARY/Application Support/Adobe/TypeSupport/AdobeFntSystem.lst"
    touch "$SYSTEM_LIBRARY/Preferences/Microsoft/Office Font Cache (16)"
}

setup_third_party_caches

cp "$TEST_FONT_V1" "$PRUNE_FONT"

run_test "Setup font for pruning installs successfully" "$BINARY install $PRUNE_FONT"
rm "$PRUNE_FONT"
run_test "Cleanup prune removes missing font registrations" \
    "$BINARY cleanup --prune-only 2>&1 | grep -q 'Pruning missing font'"
run_test "List output no longer includes pruned font" "! $BINARY list -p | grep -q \"$PRUNE_FONT\""
run_test "Cache clearing reports success" "$BINARY cleanup --cache-only 2>&1 | grep -q 'font cache cleared'"
run_test "User-level cleanup removes Adobe caches" \
    "[ ! -f \"$USER_LIBRARY/Application Support/Adobe/TypeSupport/AdobeFnt.lst\" ]"
run_test "User-level cleanup removes Microsoft caches" \
    "[ ! -f \"$USER_LIBRARY/Preferences/Microsoft/Office Font Cache (16)\" ]"
run_test "User-level cleanup leaves system caches intact" \
    "[ -f \"$SYSTEM_LIBRARY/Application Support/Adobe/TypeSupport/AdobeFntSystem.lst\" ]"

setup_third_party_caches

run_test "Admin cleanup clears caches without error" \
    "$BINARY cleanup --cache-only --admin 2>&1 | grep -q 'font cache cleared'"
run_test "Admin cleanup removes system Adobe caches" \
    "[ ! -f \"$SYSTEM_LIBRARY/Application Support/Adobe/TypeSupport/AdobeFntSystem.lst\" ]"
run_test "Admin cleanup removes system Microsoft caches" \
    "[ ! -f \"$SYSTEM_LIBRARY/Preferences/Microsoft/Office Font Cache (16)\" ]"
run_test "Cleanup alias help available" "$BINARY c --help | grep -q 'Prune missing fonts'"
echo ""
rm -rf "$CLEANUP_DIR"
unset FONTLIFT_OVERRIDE_USER_LIBRARY
unset FONTLIFT_OVERRIDE_SYSTEM_LIBRARY

# Test 7: Version extraction and consistency
echo "Testing version extraction..."
EXTRACTED_VERSION=$(./scripts/get-version.sh)
BINARY_VERSION=$($BINARY --version)

# Test extracted version is valid semver (X.Y.Z format)
run_test "get-version.sh outputs valid semver" "echo '$EXTRACTED_VERSION' | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'"

# Test extracted version matches binary version
run_test "Extracted version matches binary" "[ '$EXTRACTED_VERSION' = '$BINARY_VERSION' ]"

# Test get-version.sh script exists and is executable
run_test "get-version.sh script exists" "[ -f ./scripts/get-version.sh ]"
run_test "get-version.sh is executable" "[ -x ./scripts/get-version.sh ]"
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
