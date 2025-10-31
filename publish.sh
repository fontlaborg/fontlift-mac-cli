#!/bin/bash
# this_file: publish.sh
# Install fontlift to /usr/local/bin
# Usage: ./publish.sh

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Change to project root (where this script is located)
cd "$(dirname "$0")"

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="fontlift"
SOURCE_BINARY=".build/release/${BINARY_NAME}"

echo "📦 Publishing fontlift to ${INSTALL_DIR}..."
echo ""

# Build if binary doesn't exist
if [ ! -f "${SOURCE_BINARY}" ]; then
    echo "Binary not found. Building first..."
    ./build.sh
    echo ""
fi

# Check if install directory exists
if [ ! -d "${INSTALL_DIR}" ]; then
    echo "❌ Error: ${INSTALL_DIR} does not exist"
    echo "Create it with: sudo mkdir -p ${INSTALL_DIR}"
    exit 1
fi

# Check if binary already exists
if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
    echo "⚠️  ${BINARY_NAME} already exists in ${INSTALL_DIR}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Copy binary (may require sudo)
echo "Installing ${BINARY_NAME} to ${INSTALL_DIR}..."
if cp "${SOURCE_BINARY}" "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null; then
    echo "✅ Installed without sudo"
else
    echo "Need sudo permission to install to ${INSTALL_DIR}"
    sudo cp "${SOURCE_BINARY}" "${INSTALL_DIR}/${BINARY_NAME}"
    echo "✅ Installed with sudo"
fi

# Verify installation
if command -v fontlift &> /dev/null; then
    echo ""
    echo "✅ Installation successful!"
    echo "Version: $(fontlift --version 2>&1 | head -1)"
    echo ""
    echo "Usage: fontlift --help"
else
    echo ""
    echo "⚠️  Installation complete but fontlift not in PATH"
    echo "You may need to add ${INSTALL_DIR} to your PATH"
fi
