#!/bin/bash
# this_file: test.sh
# Run all tests for fontlift
# Usage: ./test.sh

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Change to project root (where this script is located)
cd "$(dirname "$0")"

# Verify Swift is installed
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed or not in PATH"
    exit 1
fi

echo "🧪 Running fontlift tests..."
echo ""

# Run tests with verbose output
swift test --parallel

echo ""
echo "✅ All tests passed!"
