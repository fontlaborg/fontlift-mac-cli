#!/usr/bin/env bash
# this_file: install.sh
# Install fontlift-mac to /usr/local/bin.
#
# fontlift manages cross-platform font install/uninstall/list/cleanup.
# This installs the macOS CLI binary built by build.sh.
#
# Usage: ./install.sh [--ci] [--help]
#
# made by FontLab https://www.fontlab.com/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="fontlift-mac"
SOURCE_BINARY=".build/release/${BINARY_NAME}"

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Install fontlift-mac to ${INSTALL_DIR}.

Options:
  --ci        CI mode: skip installation, verify binary only
  --help      Show this help

made by FontLab https://www.fontlab.com/
EOF
}

CI_MODE=false
if [[ "${CI:-}" == "true" ]]; then
    CI_MODE=true
fi

for arg in "$@"; do
    case $arg in
        --ci)   CI_MODE=true ;;
        --help|-h) show_help; exit 0 ;;
        *) echo "Unknown option: $arg"; show_help; exit 1 ;;
    esac
done

# CI mode: verify binary exists and works
if [[ "$CI_MODE" == "true" ]]; then
    echo "Verifying binary (CI mode)..."
    if [[ ! -f "${SOURCE_BINARY}" ]]; then
        echo "Error: binary not found at ${SOURCE_BINARY}"
        exit 1
    fi
    if [[ ! -x "${SOURCE_BINARY}" ]]; then
        echo "Error: binary is not executable"
        exit 1
    fi
    "${SOURCE_BINARY}" --version >/dev/null 2>&1
    "${SOURCE_BINARY}" --help >/dev/null 2>&1
    echo "Binary verified."
    exit 0
fi

# Build if not already built
if [[ ! -f "${SOURCE_BINARY}" ]]; then
    echo "Binary not found; building first..."
    bash "$SCRIPT_DIR/build.sh"
fi

if [[ ! -d "${INSTALL_DIR}" ]]; then
    echo "Error: ${INSTALL_DIR} does not exist"
    exit 1
fi

echo "Installing ${BINARY_NAME} to ${INSTALL_DIR}..."
if cp "${SOURCE_BINARY}" "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null; then
    echo "Installed (no sudo needed)."
else
    echo "Requires sudo..."
    sudo cp "${SOURCE_BINARY}" "${INSTALL_DIR}/${BINARY_NAME}"
    echo "Installed with sudo."
fi

if command -v "${BINARY_NAME}" &>/dev/null; then
    echo "Installation successful. Version: $(${BINARY_NAME} --version 2>&1 | head -1)"
else
    echo "Installed but ${BINARY_NAME} not in PATH. Add ${INSTALL_DIR} to your PATH."
fi
