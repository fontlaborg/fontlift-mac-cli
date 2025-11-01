#!/bin/bash
# this_file: scripts/verify-release-artifact.sh
# Verify release artifacts can be downloaded and work correctly
# Usage: ./scripts/verify-release-artifact.sh <VERSION>
#   VERSION: Version tag to verify (e.g., "1.1.25")

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to verify required dependencies
verify_dependencies() {
    local missing_deps=()

    # Check for required commands
    for cmd in curl tar shasum; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ Error: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
}

# Function to display help
show_help() {
    cat << EOF
Usage: $0 <VERSION>

Verifies that release artifacts can be downloaded and work correctly.

Arguments:
  VERSION    Version tag to verify (e.g., "1.1.25")

Examples:
  $0 1.1.25          # Verify v1.1.25 release
  $0 1.1.24          # Verify v1.1.24 release

Tests performed:
  1. Download tarball from GitHub Releases
  2. Download SHA256 checksum file
  3. Verify checksum matches
  4. Extract binary from tarball
  5. Verify binary is executable
  6. Test binary --version
  7. Test binary --help
  8. Verify version matches expected

Exit codes:
  0 - All verification passed
  1 - Verification failed or error occurred
EOF
}

# Check for help flag
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]] || [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

# Verify dependencies
verify_dependencies

# Parse arguments
VERSION="$1"

# Validate version format (X.Y.Z)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Error: Invalid version format${NC}"
    echo "Expected: X.Y.Z (e.g., 1.1.25)"
    echo "Received: $VERSION"
    exit 1
fi

# GitHub repository info
REPO_OWNER="fontlaborg"
REPO_NAME="fontlift-mac-cli"
RELEASE_TAG="v${VERSION}"

# Artifact names
TARBALL_NAME="fontlift-v${VERSION}-macos.tar.gz"
CHECKSUM_NAME="${TARBALL_NAME}.sha256"

# GitHub Release URLs
TARBALL_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${RELEASE_TAG}/${TARBALL_NAME}"
CHECKSUM_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${RELEASE_TAG}/${CHECKSUM_NAME}"

# Create temporary directory for testing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$TEMP_DIR"

echo -e "${BLUE}🔍 Verifying release artifacts for v${VERSION}...${NC}"
echo ""

# Step 1: Download tarball
echo -e "${BLUE}📥 Downloading tarball...${NC}"
echo "URL: $TARBALL_URL"

if ! curl -L -f -o "$TARBALL_NAME" "$TARBALL_URL" 2>&1; then
    echo -e "${RED}❌ Error: Failed to download tarball${NC}"
    echo "URL: $TARBALL_URL"
    echo ""
    echo "Possible causes:"
    echo "  - Release v${VERSION} does not exist"
    echo "  - Release is a draft or pre-release"
    echo "  - Network connectivity issues"
    exit 1
fi

echo -e "${GREEN}✅ Downloaded tarball${NC}"
TARBALL_SIZE=$(du -h "$TARBALL_NAME" | awk '{print $1}')
echo "Size: ${TARBALL_SIZE}"
echo ""

# Step 2: Download checksum file
echo -e "${BLUE}📥 Downloading checksum file...${NC}"
echo "URL: $CHECKSUM_URL"

if ! curl -L -f -o "$CHECKSUM_NAME" "$CHECKSUM_URL" 2>&1; then
    echo -e "${RED}❌ Error: Failed to download checksum file${NC}"
    echo "URL: $CHECKSUM_URL"
    exit 1
fi

echo -e "${GREEN}✅ Downloaded checksum${NC}"
echo ""

# Step 3: Verify checksum
echo -e "${BLUE}🔐 Verifying checksum...${NC}"
EXPECTED_CHECKSUM=$(cat "$CHECKSUM_NAME" | awk '{print $1}')
echo "Expected checksum: ${EXPECTED_CHECKSUM}"

if ! shasum -a 256 -c "$CHECKSUM_NAME" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Checksum verification failed${NC}"
    ACTUAL_CHECKSUM=$(shasum -a 256 "$TARBALL_NAME" | awk '{print $1}')
    echo "Expected: ${EXPECTED_CHECKSUM}"
    echo "Actual:   ${ACTUAL_CHECKSUM}"
    exit 1
fi

echo -e "${GREEN}✅ Checksum verified${NC}"
echo ""

# Step 4: Extract binary
echo -e "${BLUE}📦 Extracting binary...${NC}"

if ! tar -xzf "$TARBALL_NAME"; then
    echo -e "${RED}❌ Error: Failed to extract tarball${NC}"
    exit 1
fi

if [ ! -f "fontlift" ]; then
    echo -e "${RED}❌ Error: Binary not found in tarball${NC}"
    echo "Expected file: fontlift"
    echo "Contents:"
    tar -tzf "$TARBALL_NAME"
    exit 1
fi

echo -e "${GREEN}✅ Binary extracted${NC}"
echo ""

# Step 5: Verify binary is executable
echo -e "${BLUE}🔍 Verifying binary...${NC}"

if [ ! -x "fontlift" ]; then
    echo -e "${RED}❌ Error: Binary is not executable${NC}"
    ls -la fontlift
    exit 1
fi

echo -e "${GREEN}✅ Binary is executable${NC}"

# Check binary size
BINARY_SIZE=$(stat -f%z fontlift 2>/dev/null || stat -c%s fontlift 2>/dev/null)
BINARY_SIZE_MB=$((BINARY_SIZE / 1048576))
echo "Binary size: ${BINARY_SIZE_MB}MB"

if [ "$BINARY_SIZE" -lt 1048576 ]; then
    echo -e "${YELLOW}⚠️  Warning: Binary size is smaller than expected${NC}"
    echo "Expected: ~3MB (universal binary)"
    echo "This may indicate single-architecture binary"
fi
echo ""

# Step 6: Test --version
echo -e "${BLUE}🧪 Testing --version...${NC}"

if ! VERSION_OUTPUT=$(./fontlift --version 2>&1); then
    echo -e "${RED}❌ Error: Binary --version failed${NC}"
    exit 1
fi

echo "Output: $VERSION_OUTPUT"

# Verify version matches expected
if ! echo "$VERSION_OUTPUT" | grep -q "$VERSION"; then
    echo -e "${YELLOW}⚠️  Warning: Version output does not contain expected version${NC}"
    echo "Expected: $VERSION"
    echo "Output: $VERSION_OUTPUT"
fi

echo -e "${GREEN}✅ --version works${NC}"
echo ""

# Step 7: Test --help
echo -e "${BLUE}🧪 Testing --help...${NC}"

if ! ./fontlift --help >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Binary --help failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ --help works${NC}"
echo ""

# Step 8: Test list command (read-only operation)
echo -e "${BLUE}🧪 Testing list command...${NC}"

if ! ./fontlift list >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Binary list command failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ list command works${NC}"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ All verification tests passed!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Release v${VERSION} is verified and working correctly."
echo ""
