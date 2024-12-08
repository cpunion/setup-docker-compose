#!/bin/bash

# Debug: Print environment variable
echo "Debug: DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION}"

# Get system architecture
arch=$(uname -m)
case $arch in
    x86_64) arch="x86_64" ;;
    arm64|aarch64) arch="aarch64" ;;    # Handle both macOS M series and Linux aarch64
    armv6l) arch="armv6" ;;
    armv7l) arch="armv7" ;;
    ppc64le) arch="ppc64le" ;;
    riscv64) arch="riscv64" ;;
    s390x) arch="s390x" ;;
    *) echo "Unsupported architecture: $arch"; exit 1 ;;
esac

# Get operating system and set installation path
os=$(uname -s | tr '[:upper:]' '[:lower:]')
case $os in
    darwin)
        os="darwin"
        INSTALL_DIR="$HOME/bin"
        BINARY_NAME="docker-compose"
        ;;
    linux)
        os="linux"
        INSTALL_DIR="$HOME/bin"
        BINARY_NAME="docker-compose"
        ;;
    msys*|mingw*|cygwin*)
        os="windows"
        INSTALL_DIR="$HOME/bin"
        BINARY_NAME="docker-compose.exe"
        ;;
    *)
        echo "Unsupported operating system: $os"
        exit 1
        ;;
esac

INSTALL_PATH="$INSTALL_DIR/$BINARY_NAME"

# Get version
if [ "$DOCKER_COMPOSE_VERSION" = "latest" ] || [ -z "$DOCKER_COMPOSE_VERSION" ]; then
    echo "Fetching latest Docker Compose version..."
    VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    if [ -z "$VERSION" ]; then
        echo "Failed to fetch latest version. Using fallback version 2.31.0"
        VERSION="2.31.0"
    fi
else
    # Remove 'v' prefix if present
    VERSION="${DOCKER_COMPOSE_VERSION#v}"
fi

# Download URL prefix
BASE_URL="https://github.com/docker/compose/releases/download/v${VERSION}"

# Build filenames
if [ "$os" = "windows" ]; then
    BINARY="docker-compose-windows-${arch}.exe"
else
    BINARY="docker-compose-${os}-${arch}"
fi
CHECKSUM="${BINARY}.sha256"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Downloading Docker Compose ${VERSION} for ${os}-${arch}..."

# Download files
curl -SL "${BASE_URL}/${BINARY}" -o "${TEMP_DIR}/${BINARY}"
curl -SL "${BASE_URL}/${CHECKSUM}" -o "${TEMP_DIR}/${CHECKSUM}"

# Verify download
echo "Verifying download..."
cd "${TEMP_DIR}"

# Use shasum on macOS and sha256sum on Linux/Windows
if [ "$os" = "darwin" ]; then
    # Extract just the hash from the checksum file
    EXPECTED_HASH=$(cat "${CHECKSUM}" | awk '{print $1}')
    # Calculate hash of the binary
    ACTUAL_HASH=$(shasum -a 256 "${BINARY}" | awk '{print $1}')

    if [ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]; then
        echo "Checksum verification failed!"
        echo "Expected: $EXPECTED_HASH"
        echo "Got: $ACTUAL_HASH"
        exit 1
    fi
else
    # For Linux and Windows (in Git Bash)
    sha256sum -c "${CHECKSUM}" || exit 1
fi

echo "Installing to ${INSTALL_PATH}..."

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Install the binary
mv "${BINARY}" "${INSTALL_PATH}" || {
    echo "Failed to move file to $INSTALL_PATH"
    exit 1
}

# Make binary executable (skip on Windows)
if [ "$os" != "windows" ]; then
    chmod +x "$INSTALL_PATH"
fi

echo "Docker Compose ${VERSION} installed successfully to $INSTALL_PATH"

# Set output for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "docker-compose-version=${VERSION}" >> "$GITHUB_OUTPUT"
fi
