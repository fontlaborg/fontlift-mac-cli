#!/bin/bash
# this_file: build.sh
# Build fontlift in release mode
# Usage: ./build.sh

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Change to project root (where this script is located)
cd "$(dirname "$0")"

# Verify Swift is installed
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed or not in PATH"
    echo "Install Swift from: https://swift.org/download/"
    exit 1
fi

echo "🔨 Building fontlift (release mode)..."
echo ""

# Clean and build
swift build -c release

# Verify binary exists
BINARY_PATH=".build/release/fontlift"
if [ ! -f "${BINARY_PATH}" ]; then
    echo "❌ Error: Binary not found at ${BINARY_PATH}"
    exit 1
fi

# Verify binary is executable
if [ ! -x "${BINARY_PATH}" ]; then
    echo "❌ Error: Binary is not executable"
    exit 1
fi

echo ""
echo "✅ Build complete!"
echo "📦 Binary location: ${BINARY_PATH}"
echo ""
echo "Run with: .build/release/fontlift --help"
echo "Install with: ./publish.sh"
