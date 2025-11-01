#!/bin/bash
# this_file: build.sh
# Build fontlift in release mode
# Usage: ./build.sh [OPTIONS]
# Options:
#   --ci           CI mode (minimal output, strict error codes)
#   --universal    Build universal binary (Intel + Apple Silicon)
#   --help         Show this help message

set -euo pipefail  # Exit on error, undefined vars, pipe failures
cd "$(dirname "$0")"
# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Build fontlift in release mode.

Options:
  --ci           CI mode (minimal output, strict error codes)
  --universal    Build universal binary (Intel + Apple Silicon)
  --help         Show this help message

Examples:
  $0                  # Build for current architecture (local mode)
  $0 --universal      # Build universal binary (both architectures)
  $0 --ci             # Build in CI mode
  CI=true $0          # Build in CI mode (environment variable)

Environment:
  CI                  Set to "true" to enable CI mode
  UNIVERSAL_BUILD     Set to "true" to build universal binary

Note:
  Universal builds take longer as they compile for both x86_64 and arm64.
  In CI, universal builds are enabled by default for releases.
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
            shift
            ;;
        --universal)
            UNIVERSAL_BUILD=true
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

if [ "$UNIVERSAL_BUILD" = true ]; then
    # Build universal binary (Intel + Apple Silicon)
    if [ "$CI_MODE" = false ]; then
        echo "🔨 Building universal binary (x86_64 + arm64)..."
        echo ""
    fi

    # Build for x86_64 (Intel)
    if [ "$CI_MODE" = false ]; then
        echo "Building for x86_64 (Intel)..."
    fi

    if ! swift build -c release --arch x86_64; then
        echo "❌ Error: Failed to build for x86_64"
        echo "This may indicate cross-compilation is not supported on this system"
        exit 1
    fi

    # Build for arm64 (Apple Silicon)
    if [ "$CI_MODE" = false ]; then
        echo "Building for arm64 (Apple Silicon)..."
    fi

    if ! swift build -c release --arch arm64; then
        echo "❌ Error: Failed to build for arm64"
        exit 1
    fi

    # Create universal binary using lipo
    if [ "$CI_MODE" = false ]; then
        echo "Creating universal binary..."
    fi

    BINARY_X86=".build/x86_64-apple-macosx/release/fontlift"
    BINARY_ARM=".build/arm64-apple-macosx/release/fontlift"
    BINARY_UNIVERSAL=".build/release/fontlift"

    # Ensure output directory exists
    mkdir -p .build/release

    # Verify architecture-specific binaries exist
    if [ ! -f "${BINARY_X86}" ]; then
        echo "❌ Error: x86_64 binary not found at ${BINARY_X86}"
        echo "Cross-compilation to x86_64 may not be supported on this system"
        exit 1
    fi

    if [ ! -f "${BINARY_ARM}" ]; then
        echo "❌ Error: arm64 binary not found at ${BINARY_ARM}"
        exit 1
    fi

    # Verify each binary is the correct architecture
    if [ "$CI_MODE" = false ]; then
        echo "Verifying architecture-specific binaries..."
    fi

    X86_ARCH=$(lipo -info "${BINARY_X86}" 2>/dev/null | grep -o "x86_64" || echo "")
    ARM_ARCH=$(lipo -info "${BINARY_ARM}" 2>/dev/null | grep -o "arm64" || echo "")

    if [ -z "$X86_ARCH" ]; then
        echo "❌ Error: ${BINARY_X86} is not an x86_64 binary"
        lipo -info "${BINARY_X86}" || true
        exit 1
    fi

    if [ -z "$ARM_ARCH" ]; then
        echo "❌ Error: ${BINARY_ARM} is not an arm64 binary"
        lipo -info "${BINARY_ARM}" || true
        exit 1
    fi

    # Combine binaries
    if ! lipo -create "${BINARY_X86}" "${BINARY_ARM}" -output "${BINARY_UNIVERSAL}"; then
        echo "❌ Error: Failed to create universal binary with lipo"
        exit 1
    fi

    # Verify universal binary
    BINARY_PATH="${BINARY_UNIVERSAL}"

    # CRITICAL: Verify the output is actually universal
    LIPO_OUTPUT=$(lipo -info "${BINARY_PATH}" 2>&1)
    if ! echo "$LIPO_OUTPUT" | grep -q "x86_64"; then
        echo "❌ Error: Universal binary missing x86_64 architecture"
        echo "lipo output: $LIPO_OUTPUT"
        exit 1
    fi

    if ! echo "$LIPO_OUTPUT" | grep -q "arm64"; then
        echo "❌ Error: Universal binary missing arm64 architecture"
        echo "lipo output: $LIPO_OUTPUT"
        exit 1
    fi

    if [ "$CI_MODE" = false ]; then
        echo ""
        echo "Architectures in binary:"
        lipo -info "${BINARY_PATH}"
    else
        # In CI mode, still show architecture verification
        echo "Universal binary verified: x86_64 + arm64"
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

# Verify binary exists
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
