#!/bin/bash
# this_file: publish.sh
# Install fontlift-mac to /usr/local/bin (local mode) or verify binary (CI mode)
#
# Usage: ./publish.sh [OPTIONS]
#
# Options:
#   --ci        CI mode (skip installation, just verify binary)
#   --help      Show this help message

set -euo pipefail  # Exit on error, undefined vars, pipe failures
cd "$(dirname "$0")"

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Install fontlift-mac to /usr/local/bin (local mode) or verify binary (CI mode).

Options:
  --ci        CI mode (skip installation, just verify binary)
  --help      Show this help message

Examples:
  $0              # Install to /usr/local/bin (local mode)
  $0 --ci         # Verify binary only (CI mode)
  CI=true $0      # Verify binary only (environment variable)

In CI mode:
  - Skips installation (no write to /usr/local/bin)
  - Verifies binary exists and is executable
  - Runs --version and --help to ensure binary works

In local mode:
  - Builds if needed
  - Installs to /usr/local/bin
  - May require sudo permissions
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

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="fontlift-mac"
SOURCE_BINARY=".build/release/${BINARY_NAME}"

# CI mode: Just verify the binary
if [ "$CI_MODE" = true ]; then
    echo "🔍 Verifying binary (CI mode)..."

    if [ ! -f "${SOURCE_BINARY}" ]; then
        echo "❌ Error: Binary not found at ${SOURCE_BINARY}"
        exit 1
    fi

    if [ ! -x "${SOURCE_BINARY}" ]; then
        echo "❌ Error: Binary is not executable"
        exit 1
    fi

    # Test binary works
    echo "Testing binary..."
    "${SOURCE_BINARY}" --version >/dev/null 2>&1
    "${SOURCE_BINARY}" --help >/dev/null 2>&1

    echo "✅ Binary verified successfully"
    exit 0
fi

# Local mode: Install to /usr/local/bin
echo "📦 Publishing fontlift-mac to ${INSTALL_DIR}..."
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
if command -v fontlift-mac &> /dev/null; then
    echo ""
    echo "✅ Installation successful!"
    echo "Version: $(fontlift-mac --version 2>&1 | head -1)"
    echo ""
    echo "Usage: fontlift-mac --help"
else
    echo ""
    echo "⚠️  Installation complete but fontlift-mac not in PATH"
    echo "You may need to add ${INSTALL_DIR} to your PATH"
fi
