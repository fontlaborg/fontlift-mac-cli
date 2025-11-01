#!/bin/bash
# this_file: scripts/commit-helper.sh
# Git commit helper - validates changes before committing
# Usage: ./scripts/commit-helper.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Git Commit Helper - Pre-Commit Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check 1: Git Status
echo "📋 Git Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git status --short
echo ""

# Count changes
MODIFIED=$(git diff --name-only | wc -l | tr -d ' ')
STAGED=$(git diff --cached --name-only | wc -l | tr -d ' ')
UNTRACKED=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

echo -e "${BLUE}Summary:${NC} ${MODIFIED} modified, ${STAGED} staged, ${UNTRACKED} untracked"

# Warn if there are untracked files
if [ "$UNTRACKED" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Warning:${NC} ${UNTRACKED} untracked file(s) found"
    echo "   These files will NOT be included in this commit."
    echo "   Review with: ${BLUE}git status${NC}"
    echo "   To include: ${BLUE}git add <file>${NC}"
fi
echo ""

# Check 2: Version Consistency
echo "🔍 Check 1: Version Consistency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "./scripts/get-version.sh" ]; then
    VERSION=$(./scripts/get-version.sh)
    echo -e "${GREEN}✅${NC} Current version: ${VERSION}"
else
    echo -e "${YELLOW}⚠️${NC}  Could not determine version"
fi
echo ""

# Check 3: CHANGELOG.md Update
echo "📝 Check 2: CHANGELOG.md Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if git diff --name-only | grep -q "CHANGELOG.md"; then
    echo -e "${GREEN}✅${NC} CHANGELOG.md has been updated"
elif git diff --cached --name-only | grep -q "CHANGELOG.md"; then
    echo -e "${GREEN}✅${NC} CHANGELOG.md is staged for commit"
elif git diff --name-only | grep -qE "Sources/|\.swift$|\.sh$|scripts/"; then
    echo -e "${YELLOW}⚠️${NC}  Code changes detected but CHANGELOG.md not updated"
    echo "   Consider documenting your changes in CHANGELOG.md"
else
    echo -e "${GREEN}✅${NC} No code changes (documentation only)"
fi
echo ""

# Check 4: Run Tests
echo "🧪 Check 3: Running Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ./test.sh --ci 2>&1 | tail -1 | grep -q "All tests passed"; then
    echo -e "${GREEN}✅${NC} All tests passed"
else
    echo -e "${RED}❌${NC} Tests failed - fix before committing"
    echo ""
    echo "Run './test.sh' to see detailed errors"
    exit 1
fi
echo ""

# Check 5: CI Configuration
echo "⚙️  Check 4: CI/CD Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ./test.sh --verify-ci > /dev/null 2>&1; then
    echo -e "${GREEN}✅${NC} CI/CD workflows configured correctly"
else
    echo -e "${YELLOW}⚠️${NC}  CI/CD configuration warnings detected"
    echo "   Run './test.sh --verify-ci' for details"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Pre-commit validation complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Offer to stage all changes
if [ "$STAGED" -eq 0 ] && [ "$MODIFIED" -gt 0 ]; then
    echo "Would you like to stage all modified files? (y/n)"
    read -r RESPONSE
    if [ "$RESPONSE" = "y" ] || [ "$RESPONSE" = "Y" ]; then
        git add -u
        echo -e "${GREEN}✅${NC} All modified files staged"
        echo ""
    fi
fi

# Suggest commit message template
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Suggested Commit Message Template:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "feat: [short description]"
echo ""
echo "[Detailed description of changes]"
echo ""
echo "- Change 1"
echo "- Change 2"
echo "- Change 3"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Ready to commit!"
echo "Run: git commit"
echo ""
