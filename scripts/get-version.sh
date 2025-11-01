#!/bin/bash
# this_file: scripts/get-version.sh
# Extract version from Swift code as fallback when git tags are unreliable
# Usage: ./scripts/get-version.sh

set -euo pipefail

# Change to project root
cd "$(dirname "$0")/.."

# Extract version from Swift code
# The version is defined as: private let version = "X.Y.Z"
CODE_VERSION=$(grep -E 'private let version = "' Sources/fontlift/fontlift.swift | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

if [ -z "$CODE_VERSION" ]; then
    echo "Error: Could not extract version from Sources/fontlift/fontlift.swift" >&2
    echo "Expected line format: private let version = \"X.Y.Z\"" >&2
    exit 1
fi

echo "$CODE_VERSION"
