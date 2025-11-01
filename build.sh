#!/bin/bash
# this_file: build.sh
# Build fontlift in release mode
#
# Usage: ./build.sh [OPTIONS]
#
# Options:
#   --ci                   CI mode (minimal output, strict error codes)
#   --universal            Build universal binary (Intel + Apple Silicon)
#   --verify-reproducible  Verify builds are reproducible (same checksum)
#   --clean                Force clean rebuild (remove .build directory)
#   --help                 Show this help message
#
# Exit Codes:
#   0  Build successful
#   1  Build failed or verification checks failed
#
# Dependencies:
#   swift  Swift compiler and Package Manager (required)
#   lipo   Binary architecture manipulation (required for --universal)
#
# Common Errors:
#   "Swift version X.Y is older than required version 5.9"
#     - Swift version too old for this project
#     - Try: xcode-select --switch to newer Xcode, or download Swift from swift.org
#
#   "xcrun: error: unable to find utility 'xctest'"
#     - Xcode Command Line Tools not installed
#     - Try: xcode-select --install
#
#   "error: disk I/O error"
#     - Not enough disk space (requires >100MB)
#     - Try: Remove .build/ directory or clean Xcode caches
#
#   "Permission denied" when writing to .build/
#     - Build directory not writable
#     - Try: chmod -R u+w .build/ or rm -rf .build/ and rebuild

set -euo pipefail  # Exit on error, undefined vars, pipe failures
cd "$(dirname "$0")"

# Function to verify required dependencies
verify_dependencies() {
    local missing_deps=()

    # Check for Swift (required for all builds)
    if ! command -v swift &> /dev/null; then
        missing_deps+=("swift")
    fi

    # Check for lipo (required for universal builds on macOS)
    if ! command -v lipo &> /dev/null; then
        missing_deps+=("lipo")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Error: Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Installation instructions:"
        echo "  - swift: Install from https://swift.org/download/"
        echo "  - lipo: Comes with Xcode Command Line Tools (xcode-select --install)"
        exit 1
    fi
}

# Function to check Swift version
check_swift_version() {
    local swift_version
    # Extract version from "Apple Swift version X.Y" format (first line only)
    swift_version=$(swift --version 2>&1 | head -1 | grep -oE 'version [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' | head -1)

    if [ -z "$swift_version" ]; then
        echo "⚠️  Warning: Could not determine Swift version"
        return 0
    fi

    local major minor
    major=$(echo "$swift_version" | cut -d. -f1)
    minor=$(echo "$swift_version" | cut -d. -f2)

    # Require Swift 5.9+
    if [ "$major" -lt 5 ] || { [ "$major" -eq 5 ] && [ "$minor" -lt 9 ]; }; then
        echo "❌ Error: Swift version too old"
        echo ""
        echo "  Current:  Swift $swift_version"
        echo "  Required: Swift 5.9 or later"
        echo ""
        echo "Common causes:"
        echo "  • Xcode version too old (need Xcode 15.0+ for Swift 5.9)"
        echo "  • Using system Swift instead of Xcode Swift"
        echo ""
        echo "Solutions:"
        echo "  1. Update Xcode: xcode-select --switch /Applications/Xcode.app"
        echo "  2. Install latest Swift: https://swift.org/download/"
        echo "  3. Check Xcode version: xcodebuild -version"
        exit 1
    fi
}

# Function to check Xcode Command Line Tools
check_xcode_clt() {
    if ! xcode-select -p &> /dev/null; then
        echo "❌ Error: Xcode Command Line Tools not installed"
        echo ""
        echo "The build requires Xcode Command Line Tools for:"
        echo "  • Swift compiler and linker"
        echo "  • macOS SDK headers"
        echo "  • Build tools (lipo, codesign, etc.)"
        echo ""
        echo "Solution:"
        echo "  Install with: xcode-select --install"
        exit 1
    fi
}

# Function to check available disk space
check_disk_space() {
    local available_kb
    available_kb=$(df -k . | tail -1 | awk '{print $4}')
    local available_mb=$((available_kb / 1024))

    # Require at least 100MB
    if [ "$available_mb" -lt 100 ]; then
        echo "❌ Error: Insufficient disk space"
        echo ""
        echo "  Available: ${available_mb}MB"
        echo "  Required:  100MB minimum"
        echo ""
        echo "Suggestions to free up space:"
        echo "  • Remove .build directory: rm -rf .build"
        echo "  • Clean Swift build cache: rm -rf ~/Library/Caches/org.swift.swiftpm"
        echo "  • Check disk usage: du -sh .build .git"
        echo "  • Remove old Xcode caches: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
        exit 1
    fi
}

# Function to check .build directory permissions
check_build_permissions() {
    if [ -d .build ]; then
        if [ ! -w .build ]; then
            echo "❌ Error: .build directory is not writable"
            echo ""
            echo "The build process cannot write to .build directory."
            echo ""
            echo "Common causes:"
            echo "  • Directory owned by another user (root, etc.)"
            echo "  • Filesystem permissions too restrictive"
            echo "  • Directory created with sudo"
            echo ""
            echo "Solutions:"
            echo "  1. Fix permissions: chmod -R u+w .build"
            echo "  2. Change ownership: sudo chown -R \$(whoami) .build"
            echo "  3. Remove and rebuild: rm -rf .build && ./build.sh"
            exit 1
        fi
    fi
}

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Build fontlift in release mode.

Options:
  --ci                   CI mode (minimal output, strict error codes)
  --universal            Build universal binary (Intel + Apple Silicon)
  --verify-reproducible  Verify builds are reproducible (same checksum)
  --clean                Force clean rebuild (remove .build directory)
  --help                 Show this help message

Examples:
  $0                          # Build for current architecture (local mode)
  $0 --universal              # Build universal binary (both architectures)
  $0 --ci                     # Build in CI mode
  $0 --verify-reproducible    # Build twice and verify checksums match
  $0 --clean                  # Force clean rebuild
  CI=true $0                  # Build in CI mode (environment variable)

Environment:
  CI                  Set to "true" to enable CI mode
  UNIVERSAL_BUILD     Set to "true" to build universal binary

Note:
  Universal builds take longer as they compile for both x86_64 and arm64.
  In CI, universal builds are enabled by default for releases.
  Reproducibility verification builds twice to ensure deterministic builds.
EOF
}

# Parse arguments
CI_MODE=false
UNIVERSAL_BUILD=false
VERIFY_REPRODUCIBLE=false
CLEAN_BUILD=false

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
        --verify-reproducible)
            VERIFY_REPRODUCIBLE=true
            ;;
        --clean)
            CLEAN_BUILD=true
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

# If --verify-reproducible flag is set, build twice and compare checksums
if [ "$VERIFY_REPRODUCIBLE" = true ]; then
    echo "🔍 Verifying build reproducibility..."
    echo ""

    # Build first time
    echo "Building first time..."
    rm -rf .build/
    swift build -c release > /dev/null 2>&1
    CHECKSUM1=$(shasum -a 256 .build/release/fontlift | awk '{print $1}')
    echo "  First build checksum:  $CHECKSUM1"

    # Build second time
    echo "Building second time..."
    rm -rf .build/
    swift build -c release > /dev/null 2>&1
    CHECKSUM2=$(shasum -a 256 .build/release/fontlift | awk '{print $1}')
    echo "  Second build checksum: $CHECKSUM2"

    echo ""

    if [ "$CHECKSUM1" = "$CHECKSUM2" ]; then
        echo "✅ Build is reproducible! Checksums match."
        exit 0
    else
        echo "❌ Build is NOT reproducible! Checksums differ."
        echo ""
        echo "This indicates non-deterministic build behavior."
        echo "Common causes:"
        echo "  - Timestamps embedded in binary"
        echo "  - Random number generation during build"
        echo "  - Environment-dependent build inputs"
        exit 1
    fi
fi

# Change to project root (where this script is located)
cd "$(dirname "$0")"

# If --clean flag is set, remove .build directory
if [ "$CLEAN_BUILD" = true ]; then
    if [ "$CI_MODE" = false ]; then
        echo "🧹 Cleaning build directory..."
    fi
    rm -rf .build/
    if [ "$CI_MODE" = false ]; then
        echo "✅ .build directory removed"
        echo ""
    fi
fi

# Record start time for performance monitoring
BUILD_START=$(date +%s)

# Verify all required dependencies are installed
verify_dependencies

# Run pre-build validation checks
check_swift_version
check_xcode_clt
check_disk_space
check_build_permissions

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
        echo "This may indicate cross-compilation is not supported on this system"
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
        echo "   Verifying architectures..."
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
        echo "   ✅ Universal binary created"
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

# Calculate build duration
BUILD_END=$(date +%s)
BUILD_DURATION=$((BUILD_END - BUILD_START))

if [ "$CI_MODE" = false ]; then
    echo ""
    echo "✅ Build complete!"
    echo "📦 Binary location: ${BINARY_PATH}"
    if [ "$UNIVERSAL_BUILD" = true ]; then
        echo "🏗️  Universal binary (supports Intel + Apple Silicon)"
    fi
    echo "⏱️  Build time: ${BUILD_DURATION}s"

    # Baselines:
    # - Clean build (single arch): ~30s
    # - Incremental build (single arch): <2s
    # - Universal build: ~30s (builds both architectures)
    # Warning if >20% slower
    if [ "$CLEAN_BUILD" = true ]; then
        # Clean build
        if [ "$BUILD_DURATION" -gt 36 ]; then
            echo "⚠️  Warning: Clean build slower than baseline (~30s + 20% = 36s)"
        fi
    elif [ "$UNIVERSAL_BUILD" = true ]; then
        # Universal build (always takes ~30s)
        if [ "$BUILD_DURATION" -gt 36 ]; then
            echo "⚠️  Warning: Universal build slower than baseline (~30s + 20% = 36s)"
        fi
    else
        # Incremental build
        if [ "$BUILD_DURATION" -gt 3 ]; then
            echo "⚠️  Warning: Incremental build slower than baseline (~2s + 20% = 3s)"
        fi
    fi

    echo ""
    echo "Run with: .build/release/fontlift --help"
    echo "Install with: ./publish.sh"
else
    if [ "$UNIVERSAL_BUILD" = true ]; then
        echo "✅ Build complete (universal): ${BINARY_PATH} (${BUILD_DURATION}s)"
    else
        echo "✅ Build complete: ${BINARY_PATH} (${BUILD_DURATION}s)"
    fi
fi
