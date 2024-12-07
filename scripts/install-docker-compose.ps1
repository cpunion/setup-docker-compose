# Get version from environment variable or use default
$defaultVersion = "latest"
$version = if ($env:DOCKER_COMPOSE_VERSION) { $env:DOCKER_COMPOSE_VERSION } else { $defaultVersion }

# If version is 'latest', fetch from GitHub API
if ($version -eq "latest") {
    Write-Host "Fetching latest Docker Compose version..."
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/docker/compose/releases/latest"
        $version = $response.tag_name -replace '^v'
        Write-Host "Latest version is: $version"
    }
    catch {
        Write-Host "Failed to fetch latest version. Using fallback version 2.31.0"
        $version = "2.31.0"
    }
}

# Installation path
$installPath = "C:\Program Files\Docker\cli-plugins"
$binaryPath = "$installPath\docker-compose.exe"

# Create installation directory if it doesn't exist
if (-not (Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}

# Determine architecture
$arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "x86" }

# Build download URLs
$baseUrl = "https://github.com/docker/compose/releases/download/v${version}"
$binaryName = "docker-compose-windows-${arch}.exe"
$checksumName = "${binaryName}.sha256"
$binaryUrl = "${baseUrl}/${binaryName}"
$checksumUrl = "${baseUrl}/${checksumName}"

Write-Host "Downloading Docker Compose ${version} for Windows-${arch}..."

# Create temporary directory
$tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
$tempBinaryPath = Join-Path $tempDir "docker-compose.exe"
$tempChecksumPath = Join-Path $tempDir "docker-compose.sha256"

try {
    # Download files
    Invoke-WebRequest -Uri $binaryUrl -OutFile $tempBinaryPath
    Invoke-WebRequest -Uri $checksumUrl -OutFile $tempChecksumPath

    # Verify checksum
    Write-Host "Verifying download..."
    $expectedHash = (Get-Content $tempChecksumPath).Split(" ")[0]
    $actualHash = (Get-FileHash -Algorithm SHA256 $tempBinaryPath).Hash.ToLower()
    
    if ($expectedHash -ne $actualHash) {
        throw "Checksum verification failed"
    }

    # Install docker-compose
    Write-Host "Installing to $binaryPath..."
    Move-Item -Force $tempBinaryPath $binaryPath

    # Add to PATH if not already present
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*$installPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$installPath", "Machine")
        $env:PATH = "$env:PATH;$installPath"
    }

    # Output version for GitHub Actions
    if ($env:GITHUB_OUTPUT) {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "docker-compose-version=$version"
    }

    Write-Host "Installation complete! Docker Compose ${version} installed at $binaryPath"
}
catch {
    Write-Host "Error: $_"
    exit 1
}
finally {
    # Clean up
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}
