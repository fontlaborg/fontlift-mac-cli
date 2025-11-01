#!/bin/bash
# this_file: scripts/prepare-release.sh
# Package fontlift binary for GitHub Release
#
# Usage: ./scripts/prepare-release.sh
#
# Creates: dist/fontlift-vX.Y.Z-macos.tar.gz and checksum file

set -euo pipefail

# Function to display help
show_help() {
    cat << EOF
Usage: $0

Prepares release artifacts for GitHub Release distribution.

Creates:
  - dist/fontlift-vX.Y.Z-macos.tar.gz     Compressed binary tarball
  - dist/fontlift-vX.Y.Z-macos.tar.gz.sha256   SHA256 checksum file

Prerequisites:
  - Release binary must exist at .build/release/fontlift
  - Run ./build.sh first to build the binary

Examples:
  ./build.sh                    # Build first
  $0                            # Prepare release artifacts

The version is extracted from the binary itself using --version.
EOF
}

# Check for help flag
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Change to project root (where this script's parent is located)
cd "$(dirname "$0")/.."

BINARY_PATH=".build/release/fontlift"
DIST_DIR="dist"

# Verify binary exists
if [ ! -f "${BINARY_PATH}" ]; then
    echo "❌ Error: Binary not found at ${BINARY_PATH}"
    echo "Run ./build.sh first to build the release binary"
    exit 1
fi

# Verify binary is executable
if [ ! -x "${BINARY_PATH}" ]; then
    echo "❌ Error: Binary is not executable"
    exit 1
fi

echo "📦 Extracting version from binary..."
VERSION=$("${BINARY_PATH}" --version 2>&1 | head -1 | awk '{print $NF}')

if [ -z "$VERSION" ]; then
    echo "❌ Error: Could not extract version from binary"
    exit 1
fi

echo "Version: $VERSION"

# Create dist directory
mkdir -p "${DIST_DIR}"

# Define artifact names
TARBALL_NAME="fontlift-v${VERSION}-macos.tar.gz"
CHECKSUM_NAME="${TARBALL_NAME}.sha256"
TARBALL_PATH="${DIST_DIR}/${TARBALL_NAME}"
CHECKSUM_PATH="${DIST_DIR}/${CHECKSUM_NAME}"

echo ""
echo "📦 Creating release tarball..."

# Create tarball with just the binary
# Use temp directory to avoid including .build path in tarball
TEMP_DIR=$(mktemp -d)
cp "${BINARY_PATH}" "${TEMP_DIR}/fontlift"

# Create tarball from temp directory
tar -czf "${TARBALL_PATH}" -C "${TEMP_DIR}" fontlift

# Clean up temp directory
rm -rf "${TEMP_DIR}"

# Verify tarball was created
if [ ! -f "${TARBALL_PATH}" ]; then
    echo "❌ Error: Failed to create tarball"
    exit 1
fi

TARBALL_SIZE=$(du -h "${TARBALL_PATH}" | awk '{print $1}')
echo "✅ Created: ${TARBALL_NAME} (${TARBALL_SIZE})"

# Generate SHA256 checksum
echo ""
echo "🔐 Generating SHA256 checksum..."

# Generate checksum (just the filename, not the full path)
(cd "${DIST_DIR}" && shasum -a 256 "${TARBALL_NAME}") > "${CHECKSUM_PATH}"

# Verify checksum file was created
if [ ! -f "${CHECKSUM_PATH}" ]; then
    echo "❌ Error: Failed to create checksum file"
    exit 1
fi

CHECKSUM=$(cat "${CHECKSUM_PATH}" | awk '{print $1}')
echo "✅ Created: ${CHECKSUM_NAME}"
echo "Checksum: ${CHECKSUM}"

# Summary
echo ""
echo "✅ Release artifacts prepared successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Release Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-20s %s\n" "Version:" "${VERSION}"
printf "%-20s %s\n" "Tarball:" "${TARBALL_NAME}"
printf "%-20s %s\n" "Tarball Size:" "${TARBALL_SIZE}"
printf "%-20s %s\n" "Checksum:" "${CHECKSUM}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To test extraction:"
echo "  tar -xzf ${TARBALL_PATH} && ./fontlift --version"
echo ""
echo "To verify checksum:"
echo "  cd ${DIST_DIR} && shasum -a 256 -c ${CHECKSUM_NAME}"
