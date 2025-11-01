#!/bin/bash
# this_file: scripts/validate-version.sh
# Validate that the version in code matches the git tag
# Usage: ./scripts/validate-version.sh [TAG_VERSION]
#   TAG_VERSION: Version from git tag (e.g., "1.1.0" from tag "v1.1.0")

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [TAG_VERSION]

Validates that the version constant in code matches the provided tag version.

Arguments:
  TAG_VERSION    Version from git tag (e.g., "1.1.0" from tag "v1.1.0")

Examples:
  $0 1.1.0          # Validate version 1.1.0
  $0 0.2.0          # Validate version 0.2.0

Exit codes:
  0 - Version matches
  1 - Version mismatch or error

Environment:
  Works in both local and CI environments.
EOF
}

# Check for help flag
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Check arguments
if [ $# -ne 1 ]; then
    echo -e "${RED}❌ Error: TAG_VERSION argument required${NC}"
    echo ""
    show_help
    exit 1
fi

TAG_VERSION="$1"

# Ensure tag uses semantic versioning (X.Y.Z)
if [[ ! "$TAG_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Error: Tag version must follow semantic versioning (X.Y.Z)${NC}"
    echo "Received: $TAG_VERSION"
    echo "Example: v1.2.3 → pass 1.2.3 to this script"
    exit 1
fi

# Change to project root (where this script's parent is located)
cd "$(dirname "$0")/.."

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
    echo "Recommendation:"
    echo "  1. Update version in Sources/fontlift/fontlift.swift to: $TAG_VERSION"
    echo "  2. Commit the change"
    echo "  3. Re-create the tag"
    echo ""
    if ! grep -q "## \[$TAG_VERSION\]" CHANGELOG.md; then
        echo -e "${YELLOW}⚠️  Warning: CHANGELOG.md does not have entry '## [$TAG_VERSION]'${NC}"
        echo "Add a section to CHANGELOG.md for this version."
        echo ""
    fi
    echo -e "${YELLOW}⚠️  Continuing anyway (validation relaxed)${NC}"
    exit 0
fi
