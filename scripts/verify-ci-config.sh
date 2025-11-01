#!/bin/bash
# this_file: scripts/verify-ci-config.sh
# Verify GitHub Actions CI/CD workflows are correctly configured
# Usage: ./scripts/verify-ci-config.sh

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

error_count=0

echo "🔍 Verifying GitHub Actions CI/CD configuration..."
echo ""

# Function to check file exists
check_file_exists() {
    local file="$1"
    local description="$2"

    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $description exists: $file"
        return 0
    else
        echo -e "${RED}❌${NC} $description missing: $file"
        ((error_count++))
        return 1
    fi
}

# Function to check workflow has required job
check_workflow_job() {
    local workflow_file="$1"
    local job_name="$2"

    if grep -q "  ${job_name}:" "$workflow_file"; then
        echo -e "${GREEN}✅${NC} Workflow has required job: $job_name"
        return 0
    else
        echo -e "${RED}❌${NC} Workflow missing required job: $job_name"
        ((error_count++))
        return 1
    fi
}

# Function to check workflow has required step
check_workflow_step() {
    local workflow_file="$1"
    local step_pattern="$2"
    local description="$3"

    if grep -q "$step_pattern" "$workflow_file"; then
        echo -e "${GREEN}✅${NC} $description"
        return 0
    else
        echo -e "${RED}❌${NC} $description (missing)"
        ((error_count++))
        return 1
    fi
}

# Check CI workflow
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking CI Workflow"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if check_file_exists ".github/workflows/ci.yml" "CI workflow"; then
    check_workflow_job ".github/workflows/ci.yml" "test"
    check_workflow_step ".github/workflows/ci.yml" "run: ./build.sh" "CI runs build.sh"
    check_workflow_step ".github/workflows/ci.yml" "run: ./test.sh" "CI runs test.sh"
    check_workflow_step ".github/workflows/ci.yml" "runs-on: macos-14" "CI uses macOS runner"
fi

echo ""

# Check Release workflow
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Release Workflow"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if check_file_exists ".github/workflows/release.yml" "Release workflow"; then
    check_workflow_job ".github/workflows/release.yml" "validate"
    check_workflow_job ".github/workflows/release.yml" "build"
    check_workflow_job ".github/workflows/release.yml" "release"
    check_workflow_step ".github/workflows/release.yml" "run: ./scripts/validate-version.sh" "Release validates version"
    check_workflow_step ".github/workflows/release.yml" "run: ./build.sh --ci --universal" "Release builds universal binary"
    check_workflow_step ".github/workflows/release.yml" "run: ./scripts/prepare-release.sh" "Release prepares artifacts"
    check_workflow_step ".github/workflows/release.yml" "contents: write" "Release has write permissions"
fi

echo ""

# Check required scripts exist
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Required Scripts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_file_exists "./build.sh" "Build script"
check_file_exists "./test.sh" "Test script"
check_file_exists "./publish.sh" "Publish script"
check_file_exists "./scripts/validate-version.sh" "Version validation script"
check_file_exists "./scripts/prepare-release.sh" "Release preparation script"
check_file_exists "./scripts/get-version.sh" "Get version script"

echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $error_count -eq 0 ]; then
    echo -e "${GREEN}✅ All CI/CD configuration checks passed!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo -e "${RED}❌ CI/CD configuration has $error_count issue(s)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
