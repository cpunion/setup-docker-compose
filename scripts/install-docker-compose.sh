#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

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

# Get operating system
os=$(uname -s | tr '[:upper:]' '[:lower:]')
case $os in
    darwin) os="darwin" ;;
    linux) os="linux" ;;
    *) echo "Unsupported operating system: $os"; exit 1 ;;
esac

# Installation path
INSTALL_PATH="/usr/local/bin/docker-compose"

# Get version
if [ "$DOCKER_COMPOSE_VERSION" = "latest" ] || [ -z "$DOCKER_COMPOSE_VERSION" ]; then
    echo "Fetching latest Docker Compose version..."
    VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    if [ -z "$VERSION" ]; then
        echo "Failed to fetch latest version. Using fallback version 2.31.0"
        VERSION="2.31.0"
    fi
else
    VERSION="$DOCKER_COMPOSE_VERSION"
fi

# Download URL prefix
BASE_URL="https://github.com/docker/compose/releases/download/v${VERSION}"

# Build filenames
BINARY="docker-compose-${os}-${arch}"
CHECKSUM="${BINARY}.sha256"

# Create a temporary directory for downloading
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download files
echo "Downloading Docker Compose ${VERSION} for ${os}-${arch}..."
curl -L "${BASE_URL}/${BINARY}" -o "docker-compose"
curl -L "${BASE_URL}/${CHECKSUM}" -o "docker-compose.sha256"

# Verify checksum
echo "Verifying download..."
echo "$(cat docker-compose.sha256) docker-compose" | sha256sum -c -

# Move to installation path and set permissions
echo "Installing to ${INSTALL_PATH}..."
mv docker-compose "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

# Clean up
cd - > /dev/null
rm -rf "$TMP_DIR"

# Output version for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "docker-compose-version=${VERSION}" >> "$GITHUB_OUTPUT"
fi

echo "Installation complete! Docker Compose ${VERSION} installed at ${INSTALL_PATH}"
