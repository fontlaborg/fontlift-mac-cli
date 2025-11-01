#!/bin/bash
# this_file: scripts/prepare-release.sh
# Package fontlift binary for GitHub Release
# Usage: ./scripts/prepare-release.sh
# Creates: dist/fontlift-vX.Y.Z-macos.tar.gz and checksum file

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${RED}❌ Error: Binary not found at ${BINARY_PATH}${NC}"
    echo "Run ./build.sh first to build the release binary"
    exit 1
fi

# Verify binary is executable
if [ ! -x "${BINARY_PATH}" ]; then
    echo -e "${RED}❌ Error: Binary is not executable${NC}"
    exit 1
fi

# Verify binary is universal (contains both x86_64 and arm64)
echo -e "${BLUE}🔍 Verifying binary architecture...${NC}"
LIPO_INFO=$(lipo -info "${BINARY_PATH}" 2>&1)

if ! echo "$LIPO_INFO" | grep -q "x86_64"; then
    echo -e "${RED}❌ Error: Binary is missing x86_64 architecture${NC}"
    echo "Expected: Universal binary (x86_64 + arm64)"
    echo "Actual: $LIPO_INFO"
    exit 1
fi

if ! echo "$LIPO_INFO" | grep -q "arm64"; then
    echo -e "${RED}❌ Error: Binary is missing arm64 architecture${NC}"
    echo "Expected: Universal binary (x86_64 + arm64)"
    echo "Actual: $LIPO_INFO"
    exit 1
fi

echo -e "${GREEN}✅ Binary is universal (x86_64 + arm64)${NC}"

# Extract version from binary
echo -e "${BLUE}📦 Extracting version from binary...${NC}"
VERSION=$("${BINARY_PATH}" --version 2>&1 | head -1 | awk '{print $NF}')

if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ Error: Could not extract version from binary${NC}"
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
echo -e "${BLUE}📦 Creating release tarball...${NC}"

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
    echo -e "${RED}❌ Error: Failed to create tarball${NC}"
    exit 1
fi

TARBALL_SIZE=$(du -h "${TARBALL_PATH}" | awk '{print $1}')
echo -e "${GREEN}✅ Created: ${TARBALL_NAME} (${TARBALL_SIZE})${NC}"

# Generate SHA256 checksum
echo ""
echo -e "${BLUE}🔐 Generating SHA256 checksum...${NC}"

# Generate checksum (just the filename, not the full path)
(cd "${DIST_DIR}" && shasum -a 256 "${TARBALL_NAME}") > "${CHECKSUM_PATH}"

# Verify checksum file was created
if [ ! -f "${CHECKSUM_PATH}" ]; then
    echo -e "${RED}❌ Error: Failed to create checksum file${NC}"
    exit 1
fi

CHECKSUM=$(cat "${CHECKSUM_PATH}" | awk '{print $1}')
echo -e "${GREEN}✅ Created: ${CHECKSUM_NAME}${NC}"
echo "Checksum: ${CHECKSUM}"

# Verify checksum
echo ""
echo -e "${BLUE}🔍 Verifying checksum...${NC}"
if (cd "${DIST_DIR}" && shasum -a 256 -c "${CHECKSUM_NAME}" >/dev/null 2>&1); then
    echo -e "${GREEN}✅ Checksum verified successfully${NC}"
else
    echo -e "${RED}❌ Error: Checksum verification failed${NC}"
    exit 1
fi

# Summary
echo ""
echo -e "${GREEN}✅ Release artifacts prepared successfully!${NC}"
echo ""
echo "Artifacts in ${DIST_DIR}:"
echo "  - ${TARBALL_NAME} (${TARBALL_SIZE})"
echo "  - ${CHECKSUM_NAME}"
echo ""
echo "Version: ${VERSION}"
echo ""
echo "To test extraction:"
echo "  tar -xzf ${TARBALL_PATH} && ./fontlift --version"
echo ""
echo "To verify checksum:"
echo "  cd ${DIST_DIR} && shasum -a 256 -c ${CHECKSUM_NAME}"
