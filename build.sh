#!/bin/bash
# this_file: build.sh
# Build fontlift in release mode
#
# Usage: ./build.sh [OPTIONS]
#
# Options:
#   --ci          CI mode (minimal output)
#   --universal   Build universal binary (Intel + Apple Silicon)
#   --help        Show this help message

set -euo pipefail  # Exit on error, undefined vars, pipe failures
cd "$(dirname "$0")"

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Build fontlift in release mode.

Options:
  --ci          CI mode (minimal output)
  --universal   Build universal binary (Intel + Apple Silicon)
  --help        Show this help message

Examples:
  $0                # Build for current architecture
  $0 --universal    # Build universal binary (both architectures)
  $0 --ci           # Build in CI mode
  CI=true $0        # Build in CI mode (environment variable)

Environment:
  CI                  Set to "true" to enable CI mode
  UNIVERSAL_BUILD     Set to "true" to build universal binary
EOF
}

# Parse arguments
CI_MODE=false
UNIVERSAL_BUILD=false

if [[ "${CI:-}" == "true" ]]; then
    CI_MODE=true
fi

if [[ "${UNIVERSAL_BUILD:-}" == "true" ]]; then
    UNIVERSAL_BUILD=true
fi

for arg in "$@"; do
    case $arg in
        --ci)
            CI_MODE=true
            ;;
        --universal)
            UNIVERSAL_BUILD=true
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

if [ "$UNIVERSAL_BUILD" = true ]; then
    # Build universal binary (Intel + Apple Silicon)
    if [ "$CI_MODE" = false ]; then
        echo "🔨 Building universal binary (x86_64 + arm64)..."
        echo ""
    fi

    # Build for x86_64 (Intel)
    if [ "$CI_MODE" = false ]; then
        echo "📦 Phase 1/3: Building for x86_64 (Intel)..."
    fi

    if ! swift build -c release --arch x86_64; then
        echo "❌ Error: Failed to build for x86_64"
        exit 1
    fi

    if [ "$CI_MODE" = false ]; then
        echo "   ✅ x86_64 build complete"
        echo ""
    fi

    # Build for arm64 (Apple Silicon)
    if [ "$CI_MODE" = false ]; then
        echo "📦 Phase 2/3: Building for arm64 (Apple Silicon)..."
    fi

    if ! swift build -c release --arch arm64; then
        echo "❌ Error: Failed to build for arm64"
        exit 1
    fi

    if [ "$CI_MODE" = false ]; then
        echo "   ✅ arm64 build complete"
        echo ""
    fi

    # Create universal binary using lipo
    if [ "$CI_MODE" = false ]; then
        echo "🔗 Phase 3/3: Creating universal binary..."
    fi

    BINARY_X86=".build/x86_64-apple-macosx/release/fontlift"
    BINARY_ARM=".build/arm64-apple-macosx/release/fontlift"
    BINARY_UNIVERSAL=".build/release/fontlift"

    # Ensure output directory exists
    mkdir -p .build/release

    # Combine binaries
    if ! lipo -create "${BINARY_X86}" "${BINARY_ARM}" -output "${BINARY_UNIVERSAL}"; then
        echo "❌ Error: Failed to create universal binary with lipo"
        exit 1
    fi

    BINARY_PATH="${BINARY_UNIVERSAL}"

    if [ "$CI_MODE" = false ]; then
        echo "   ✅ Universal binary created"
        echo ""
        echo "Architectures in binary:"
        lipo -info "${BINARY_PATH}"
    else
        echo "Universal binary created: x86_64 + arm64"
    fi
else
    # Standard build for current architecture
    if [ "$CI_MODE" = false ]; then
        echo "🔨 Building fontlift (release mode)..."
        echo ""
    fi

    swift build -c release
    BINARY_PATH=".build/release/fontlift"
fi

if [ "$CI_MODE" = false ]; then
    echo ""
    echo "✅ Build complete!"
    echo "📦 Binary location: ${BINARY_PATH}"
    if [ "$UNIVERSAL_BUILD" = true ]; then
        echo "🏗️  Universal binary (supports Intel + Apple Silicon)"
    fi
    echo ""
    echo "Run with: .build/release/fontlift --help"
    echo "Install with: ./publish.sh"
else
    if [ "$UNIVERSAL_BUILD" = true ]; then
        echo "✅ Build complete (universal): ${BINARY_PATH}"
    else
        echo "✅ Build complete: ${BINARY_PATH}"
    fi
fi
