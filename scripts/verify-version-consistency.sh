#!/bin/bash
# this_file: scripts/verify-version-consistency.sh
#
# Verifies that version is consistent across all critical files
#
# Version sources checked:
# 1. Sources/fontlift/fontlift.swift (source of truth via get-version.sh)
# 2. README.md (VERSION variable in installation examples)
# 3. PLAN.md (Current Version header)
# 4. WORK.md (Project Summary Current Version)
#
# Usage: ./scripts/verify-version-consistency.sh
#
# Exit codes:
#   0 - All versions consistent
#   1 - Version mismatch detected

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get expected version from source code
EXPECTED_VERSION=$(./scripts/get-version.sh)

if [ -z "$EXPECTED_VERSION" ]; then
    echo -e "${RED}❌ Error: Could not extract version from source code${NC}"
    echo "   Try: Check Sources/fontlift/fontlift.swift has 'private let version = \"X.Y.Z\"'"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Verifying Version Consistency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Expected version (from source): $EXPECTED_VERSION"
echo ""

MISMATCH_FOUND=false

# Check README.md
echo "Checking README.md..."
README_VERSION=$(grep -E '^VERSION=' README.md | head -1 | sed -E 's/VERSION="([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
if [ "$README_VERSION" = "$EXPECTED_VERSION" ]; then
    echo -e "${GREEN}✅ README.md: $README_VERSION${NC}"
else
    echo -e "${RED}❌ README.md: $README_VERSION (expected: $EXPECTED_VERSION)${NC}"
    echo "   File: README.md"
    echo "   Try: Update VERSION variable to \"$EXPECTED_VERSION\""
    MISMATCH_FOUND=true
fi

# Check PLAN.md
echo "Checking PLAN.md..."
PLAN_VERSION=$(grep -E '^\*\*Current Version\*\*:' PLAN.md | head -1 | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ "$PLAN_VERSION" = "$EXPECTED_VERSION" ]; then
    echo -e "${GREEN}✅ PLAN.md: $PLAN_VERSION${NC}"
else
    echo -e "${RED}❌ PLAN.md: $PLAN_VERSION (expected: $EXPECTED_VERSION)${NC}"
    echo "   File: PLAN.md (line ~10)"
    echo "   Try: Update 'Current Version' header to v$EXPECTED_VERSION"
    MISMATCH_FOUND=true
fi

# Check WORK.md (most recent project summary)
echo "Checking WORK.md..."
WORK_VERSION=$(grep -E '^\*\*Current Version\*\*:' WORK.md | tail -1 | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ "$WORK_VERSION" = "$EXPECTED_VERSION" ]; then
    echo -e "${GREEN}✅ WORK.md: $WORK_VERSION${NC}"
else
    echo -e "${RED}❌ WORK.md: $WORK_VERSION (expected: $EXPECTED_VERSION)${NC}"
    echo "   File: WORK.md (Project Summary section)"
    echo "   Try: Update 'Current Version' in latest Project Summary"
    MISMATCH_FOUND=true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$MISMATCH_FOUND" = true ]; then
    echo -e "${RED}❌ Version consistency check FAILED${NC}"
    echo ""
    echo "Version mismatches detected. All files should use version: $EXPECTED_VERSION"
    echo ""
    echo "To fix:"
    echo "  1. Update mismatched files to use version $EXPECTED_VERSION"
    echo "  2. Run this script again to verify"
    echo "  3. Commit changes before releasing"
    exit 1
else
    echo -e "${GREEN}✅ Version consistency check PASSED${NC}"
    echo ""
    echo "All files use version: $EXPECTED_VERSION"
    exit 0
fi
