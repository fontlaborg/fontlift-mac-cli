#!/bin/bash
# this_file: build.sh
# Build fontlift in release mode
# Usage: ./build.sh [OPTIONS]
# Options:
#   --ci        CI mode (minimal output, strict error codes)
#   --help      Show this help message

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Build fontlift in release mode.

Options:
  --ci        CI mode (minimal output, strict error codes)
  --help      Show this help message

Examples:
  $0              # Build normally (local mode)
  $0 --ci         # Build in CI mode
  CI=true $0      # Build in CI mode (environment variable)

Environment:
  CI              Set to "true" to enable CI mode
EOF
}

# Parse arguments
CI_MODE=false
if [[ "${CI:-}" == "true" ]]; then
    CI_MODE=true
fi

for arg in "$@"; do
    case $arg in
        --ci)
            CI_MODE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option: $arg"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Change to project root (where this script is located)
cd "$(dirname "$0")"

# Verify Swift is installed
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed or not in PATH"
    echo "Install Swift from: https://swift.org/download/"
    exit 1
fi

if [ "$CI_MODE" = false ]; then
    echo "🔨 Building fontlift (release mode)..."
    echo ""
fi

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

if [ "$CI_MODE" = false ]; then
    echo ""
    echo "✅ Build complete!"
    echo "📦 Binary location: ${BINARY_PATH}"
    echo ""
    echo "Run with: .build/release/fontlift --help"
    echo "Install with: ./publish.sh"
else
    echo "✅ Build complete: ${BINARY_PATH}"
fi
