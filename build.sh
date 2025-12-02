#!/bin/bash
# this_file: build.sh
# Build fontlift-mac in release mode
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

Build fontlift-mac in release mode.

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

# Verify Swift version ≥5.9
REQUIRED_SWIFT_VERSION="5.9"
SWIFT_VERSION=$(swift --version 2>&1 | head -n 1 | grep -oE 'Swift version [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' | head -n 1)

if [ -z "$SWIFT_VERSION" ]; then
    echo "❌ Error: Failed to detect Swift version"
    echo ""
    echo "Please ensure Swift is installed and in your PATH."
    echo "Run: swift --version"
    exit 1
fi

# Compare versions (supports X.Y format)
REQUIRED_MAJOR=$(echo "$REQUIRED_SWIFT_VERSION" | cut -d. -f1)
REQUIRED_MINOR=$(echo "$REQUIRED_SWIFT_VERSION" | cut -d. -f2)
CURRENT_MAJOR=$(echo "$SWIFT_VERSION" | cut -d. -f1)
CURRENT_MINOR=$(echo "$SWIFT_VERSION" | cut -d. -f2)

if [ "$CURRENT_MAJOR" -lt "$REQUIRED_MAJOR" ] || \
   ([ "$CURRENT_MAJOR" -eq "$REQUIRED_MAJOR" ] && [ "$CURRENT_MINOR" -lt "$REQUIRED_MINOR" ]); then
    echo "❌ Error: Swift version $REQUIRED_SWIFT_VERSION or later is required"
    echo ""
    echo "Current version: Swift $SWIFT_VERSION"
    echo "Required version: Swift $REQUIRED_SWIFT_VERSION+"
    echo ""
    echo "Common causes:"
    echo "  • Xcode version is too old (requires Xcode 15.0+)"
    echo "  • Using outdated system Swift instead of Xcode's Swift"
    echo ""
    echo "Solutions:"
    echo "  1. Update Xcode from the Mac App Store"
    echo "  2. Select correct Xcode: sudo xcode-select -s /Applications/Xcode.app"
    echo "  3. Download Swift from https://swift.org/download/"
    echo "  4. Check installed version: swift --version"
    exit 1
fi

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

    BINARY_X86=".build/x86_64-apple-macosx/release/fontlift-mac"
    BINARY_ARM=".build/arm64-apple-macosx/release/fontlift-mac"
    BINARY_UNIVERSAL=".build/release/fontlift-mac"

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
        echo "🔨 Building fontlift-mac (release mode)..."
        echo ""
    fi

    swift build -c release
    BINARY_PATH=".build/release/fontlift-mac"
fi

if [ "$CI_MODE" = false ]; then
    echo ""
    echo "✅ Build complete!"
    echo "📦 Binary location: ${BINARY_PATH}"
    if [ "$UNIVERSAL_BUILD" = true ]; then
        echo "🏗️  Universal binary (supports Intel + Apple Silicon)"
    fi
    echo ""
    echo "Run with: .build/release/fontlift-mac --help"
    echo "Install with: ./publish.sh"
else
    if [ "$UNIVERSAL_BUILD" = true ]; then
        echo "✅ Build complete (universal): ${BINARY_PATH}"
    else
        echo "✅ Build complete: ${BINARY_PATH}"
    fi
fi
