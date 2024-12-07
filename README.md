# setup-docker-compose

GitHub Action to install Docker Compose on your GitHub Actions runners. Supports Linux, macOS, and Windows platforms.

## Usage

```yaml
steps:
  # Install latest version (default)
  - uses: cpunion/setup-docker-compose@v1
    id: docker-compose

  # Or specify a specific version
  - uses: cpunion/setup-docker-compose@v1
    id: docker-compose-specific
    with:
      version: '2.31.0'  # specify a version if needed

  # Access the installed version in subsequent steps
  - name: Check Docker Compose Version
    run: echo "Installed Docker Compose version: ${{ steps.docker-compose.outputs.docker-compose-version }}"
```

## Features

- Cross-platform support (Linux, macOS, Windows)
- Automatically installs latest version by default
- Configurable version if needed
- Automatic architecture detection
- Checksum verification for secure downloads
- Adds Docker Compose to system PATH
- Outputs installed version for use in subsequent steps

## License

MIT License
