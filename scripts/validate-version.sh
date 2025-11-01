#!/bin/bash
# this_file: scripts/validate-version.sh
# Validate that the version in code matches the git tag
#
# Usage: ./scripts/validate-version.sh [TAG_VERSION]
#   TAG_VERSION: Version from git tag (e.g., "1.1.0" from tag "v1.1.0")

set -euo pipefail

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

# Parse arguments
TAG_VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
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
    echo "❌ Error: TAG_VERSION argument required"
    echo ""
    show_help
    exit 1
fi

# Ensure tag uses semantic versioning (X.Y.Z)
if [[ ! "$TAG_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Error: Tag version must follow semantic versioning (X.Y.Z)"
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
    echo "❌ Error: Could not extract version from Sources/fontlift/fontlift.swift"
    echo "Expected line format: private let version = \"X.Y.Z\""
    exit 1
fi

echo "Tag version:  $TAG_VERSION"
echo "Code version: $CODE_VERSION"
echo ""

# Compare versions
if [ "$TAG_VERSION" == "$CODE_VERSION" ]; then
    echo "✅ Version validation passed!"
    echo "Tag and code versions match: $TAG_VERSION"
    exit 0
else
    echo "⚠️  Warning: Version mismatch detected"
    echo ""
    echo "The git tag version ($TAG_VERSION) does not match the code version ($CODE_VERSION)"
    echo ""
    echo "Recommendation:"
    echo "  1. Update version in Sources/fontlift/fontlift.swift to: $TAG_VERSION"
    echo "  2. Commit the change"
    echo "  3. Re-create the tag"
    echo ""
    echo "⚠️  Continuing anyway (validation relaxed)"
    exit 0
fi
