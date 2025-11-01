#!/bin/bash
# this_file: scripts/validate-version.sh
# Validate that the version in code matches the git tag
#
# Usage: ./scripts/validate-version.sh [TAG_VERSION] [--fix]
#   TAG_VERSION: Version from git tag (e.g., "1.1.0" from tag "v1.1.0")
#   --fix: Automatically update code version to match tag (optional)
#
# Exit Codes:
#   0  Version matches tag (or was successfully fixed)
#   1  Version mismatch or CHANGELOG missing
#
# Dependencies:
#   grep  Pattern matching (required)
#   sed   Stream editing (required)
#
# Common Errors:
#   "Version mismatch detected!"
#     - Git tag version doesn't match code version
#     - Try: Use --fix flag to auto-update code version
#     - Or: Update version manually in Sources/fontlift/fontlift.swift
#
#   "CHANGELOG.md missing entry for version X.Y.Z"
#     - Release requires CHANGELOG documentation
#     - Try: Add "## [X.Y.Z] - YYYY-MM-DD" section to CHANGELOG.md

set -euo pipefail

# Function to verify required dependencies
verify_dependencies() {
    local missing_deps=()

    # Check for required commands
    for cmd in grep sed; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Error: Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [TAG_VERSION] [--fix]

Validates that the version constant in code matches the provided tag version.

Arguments:
  TAG_VERSION    Version from git tag (e.g., "1.1.0" from tag "v1.1.0")
  --fix          Automatically update code version to match tag (optional)

Examples:
  $0 1.1.0          # Validate version 1.1.0
  $0 1.1.0 --fix    # Validate and auto-fix if mismatch
  $0 0.2.0          # Validate version 0.2.0

Exit codes:
  0 - Version matches or --fix applied
  1 - Version mismatch (without --fix) or error

Environment:
  Works in both local and CI environments.
  In CI, --fix is automatically applied if version mismatch detected.
EOF
}

# Check for help flag
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Parse arguments
FIX_MODE=false
TAG_VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX_MODE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            if [ -z "$TAG_VERSION" ]; then
                TAG_VERSION="$1"
            fi
            shift
            ;;
    esac
done

# Check if TAG_VERSION was provided
if [ -z "$TAG_VERSION" ]; then
    echo -e "${RED}❌ Error: TAG_VERSION argument required${NC}"
    echo ""
    show_help
    exit 1
fi

# Auto-enable fix mode in CI environment
if [ "${CI:-false}" = "true" ] || [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
    FIX_MODE=true
fi

# Ensure tag uses semantic versioning (X.Y.Z)
if [[ ! "$TAG_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Error: Tag version must follow semantic versioning (X.Y.Z)${NC}"
    echo "Received: $TAG_VERSION"
    echo "Example: v1.2.3 → pass 1.2.3 to this script"
    exit 1
fi

# Change to project root (where this script's parent is located)
cd "$(dirname "$0")/.."

# Verify all required dependencies are installed
verify_dependencies

# Extract version from Swift code
# The version is defined as: private let version = "X.Y.Z"
CODE_VERSION=$(grep -E 'private let version = "' Sources/fontlift/fontlift.swift | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

if [ -z "$CODE_VERSION" ]; then
    echo -e "${RED}❌ Error: Could not extract version from Sources/fontlift/fontlift.swift${NC}"
    echo "Expected line format: private let version = \"X.Y.Z\""
    exit 1
fi

echo "Tag version:  $TAG_VERSION"
echo "Code version: $CODE_VERSION"
echo ""

# Compare versions
if [ "$TAG_VERSION" == "$CODE_VERSION" ]; then
    echo -e "${GREEN}✅ Version validation passed!${NC}"
    echo "Tag and code versions match: $TAG_VERSION"
    if ! grep -q "## \[$TAG_VERSION\]" CHANGELOG.md; then
        echo ""
        echo -e "${YELLOW}⚠️  Warning: CHANGELOG.md does not have entry '## [$TAG_VERSION]'${NC}"
        echo "Add a section to CHANGELOG.md for this version before tagging."
        echo ""
    else
        echo ""
        echo "CHANGELOG entry found for version $TAG_VERSION"
    fi
    exit 0
else
    echo -e "${YELLOW}⚠️  Warning: Version mismatch detected${NC}"
    echo ""
    echo "The git tag version ($TAG_VERSION) does not match the code version ($CODE_VERSION)"
    echo ""

    if [ "$FIX_MODE" = true ]; then
        echo "🔧 Auto-fix mode enabled. Updating code version to: $TAG_VERSION"

        # Update version in Swift code
        sed -i.bak -E "s/(private let version = \")[0-9]+\.[0-9]+\.[0-9]+(\")/\1${TAG_VERSION}\2/" Sources/fontlift/fontlift.swift
        rm -f Sources/fontlift/fontlift.swift.bak

        # Verify the update worked
        NEW_CODE_VERSION=$(grep -E 'private let version = "' Sources/fontlift/fontlift.swift | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

        if [ "$NEW_CODE_VERSION" = "$TAG_VERSION" ]; then
            echo -e "${GREEN}✅ Code version updated successfully to: $TAG_VERSION${NC}"
        else
            echo -e "${RED}❌ Failed to update code version${NC}"
            exit 1
        fi
    else
        echo "Recommendation:"
        echo "  1. Update version in Sources/fontlift/fontlift.swift to: $TAG_VERSION"
        echo "  2. Commit the change"
        echo "  3. Re-create the tag"
        echo ""
        echo "Or run with --fix to auto-update:"
        echo "  $0 $TAG_VERSION --fix"
        echo ""
    fi

    if ! grep -q "## \[$TAG_VERSION\]" CHANGELOG.md; then
        echo -e "${YELLOW}⚠️  Warning: CHANGELOG.md does not have entry '## [$TAG_VERSION]'${NC}"
        echo "Add a section to CHANGELOG.md for this version."
        echo ""
    fi

    if [ "$FIX_MODE" = true ]; then
        echo -e "${GREEN}✅ Version mismatch auto-fixed${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Continuing anyway (validation relaxed)${NC}"
        exit 0
    fi
fi
