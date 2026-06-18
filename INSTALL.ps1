# DNG/HEIC Converter - Auto Installer

Clear-Host
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  DNG/HEIC to JPEG Converter - Full Auto Installer         " -ForegroundColor Cyan
Write-Host "  This will install everything you need                    " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

$imageMagickUrl = "https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-25/ImageMagick-7.1.2-25-Q16-HDRI-x64-dll.exe"
$exiftoolUrl = "https://github.com/darshana0288/dng-heic-converter/releases/download/exiftool/exiftool.zip"

Write-Host "[1/7] Checking Node.js..." -ForegroundColor Cyan

$nodeExe = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeExe) {
    Write-Host "Node.js not found. Downloading and setting up..." -ForegroundColor Yellow

    $url = "https://nodejs.org/dist/v26.3.0/node-v26.3.0-win-x64.zip"
    $zipFile = "$env:TEMP\node-v26.3.0-win-x64.zip"
    $tempExtractPath = "$env:TEMP\node-extract"
    $extractPath = "C:\nodejs"

    Write-Host "Downloading Node.js portable from: $url" -ForegroundColor Yellow
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing

    Write-Host "Extracting Node.js..." -ForegroundColor Cyan
    if (Test-Path $tempExtractPath) {
        Remove-Item $tempExtractPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempExtractPath -Force | Out-Null
    Expand-Archive -Path $zipFile -DestinationPath $tempExtractPath -Force

    $nodeFolder = Get-ChildItem -Path $tempExtractPath -Directory | Select-Object -First 1
    if ($nodeFolder) {
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }
        Move-Item -Path $nodeFolder.FullName -Destination $extractPath -Force
    }

    Write-Host "Cleaning up..." -ForegroundColor Yellow
    Remove-Item $zipFile -Force
    Remove-Item $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Configuring PATH..." -ForegroundColor Yellow
    $env:Path = $extractPath + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    [Environment]::SetEnvironmentVariable("Path", $env:Path, "User")

    Write-Host "OK - Node.js installed to $extractPath" -ForegroundColor Green
} else {
    Write-Host "OK - Node.js already installed" -ForegroundColor Green
}

Start-Sleep -Seconds 1
$env:Path = "C:\nodejs;" + [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$nodeExePath = "C:\nodejs\node.exe"
if (-not (Test-Path $nodeExePath)) {
    Write-Host "ERROR: Node.js executable not found at $nodeExePath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$nodeVersion = & $nodeExePath -v 2>$null
if (-not $nodeVersion) {
    Write-Host "ERROR: Could not run Node.js" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Using Node.js $nodeVersion" -ForegroundColor Green

Write-Host "[2/7] Installing npm dependencies..." -ForegroundColor Cyan

if (-not (Test-Path "package.json")) {
    Write-Host "ERROR: package.json not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$npmExePath = "C:\nodejs\npm.cmd"
if (-not (Test-Path $npmExePath)) {
    $npmExePath = "C:\nodejs\npm"
}

& $npmExePath install 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: npm install failed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "OK - npm dependencies installed" -ForegroundColor Green

Write-Host "[3/7] Downloading ImageMagick..." -ForegroundColor Cyan
Write-Host "Downloading from: $imageMagickUrl" -ForegroundColor Yellow

$tempDir = $env:TEMP
$imageMagickExe = Join-Path $tempDir "ImageMagick-installer.exe"

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $imageMagickUrl -OutFile $imageMagickExe -UseBasicParsing -ErrorAction Stop
    Write-Host "OK - ImageMagick downloaded" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to download ImageMagick" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Installing ImageMagick to C:\ImageMagick..." -ForegroundColor Cyan

$installArgs = @("/SILENT", "/NORESTART", "/D=C:\ImageMagick")

try {
    $process = Start-Process -FilePath $imageMagickExe -ArgumentList $installArgs -Wait -PassThru -ErrorAction Stop
    Write-Host "OK - ImageMagick installed" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to install ImageMagick" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Remove-Item $imageMagickExe -Force -ErrorAction SilentlyContinue

Write-Host "[4/7] Downloading exiftool..." -ForegroundColor Cyan
Write-Host "Downloading from: $exiftoolUrl" -ForegroundColor Yellow

$exiftoolZip = Join-Path $tempDir "exiftool.zip"

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $exiftoolUrl -OutFile $exiftoolZip -UseBasicParsing -ErrorAction Stop
    Write-Host "OK - exiftool downloaded" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to download exiftool" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Extracting to C:\exiftool..." -ForegroundColor Cyan

$tempExiftoolPath = "$env:TEMP\exiftool-extract"
if (Test-Path $tempExiftoolPath) {
    Remove-Item $tempExiftoolPath -Recurse -Force
}
New-Item -ItemType Directory -Path $tempExiftoolPath -Force -ErrorAction SilentlyContinue | Out-Null

try {
    $ProgressPreference = 'SilentlyContinue'
    Expand-Archive -Path $exiftoolZip -DestinationPath $tempExiftoolPath -Force -ErrorAction Stop

    $exiftoolFolder = Get-ChildItem -Path $tempExiftoolPath -Directory | Select-Object -First 1
    if ($exiftoolFolder) {
        if (Test-Path "C:\exiftool") {
            Remove-Item "C:\exiftool" -Recurse -Force
        }
        Move-Item -Path $exiftoolFolder.FullName -Destination "C:\exiftool" -Force
    } else {
        if (Test-Path "C:\exiftool") {
            Remove-Item "C:\exiftool" -Recurse -Force
        }
        Move-Item -Path $tempExiftoolPath -Destination "C:\exiftool" -Force
    }

    Write-Host "OK - exiftool extracted" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to extract exiftool" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Remove-Item $exiftoolZip -Force -ErrorAction SilentlyContinue
Remove-Item $tempExiftoolPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[5/7] Updating system PATH..." -ForegroundColor Cyan

$regPath = "HKCU:\Environment"

try {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    $paths = @("C:\ImageMagick\bin", "C:\exiftool")
    $pathsAdded = 0

    foreach ($p in $paths) {
        if ($currentPath -notlike "*$p*") {
            Write-Host "Adding: $p" -ForegroundColor Yellow
            $currentPath = $currentPath + ";" + $p
            $pathsAdded++
        }
    }

    if ($pathsAdded -gt 0) {
        Set-ItemProperty -Path $regPath -Name "Path" -Value $currentPath -ErrorAction Stop
        Write-Host "OK - PATH updated" -ForegroundColor Green
    } else {
        Write-Host "OK - All paths already in PATH" -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Could not update PATH" -ForegroundColor Yellow
}

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "[6/7] Testing installations..." -ForegroundColor Cyan

Write-Host "Testing exiftool..." -ForegroundColor Yellow
$exiftoolTest = & exiftool -ver 2>$null
if ($exiftoolTest) {
    Write-Host "OK - exiftool: $exiftoolTest" -ForegroundColor Green
} else {
    Write-Host "WARNING: exiftool not found (restart PowerShell if needed)" -ForegroundColor Yellow
}

Write-Host "Testing ImageMagick..." -ForegroundColor Yellow
$imageMagickTest = & magick -version 2>$null | Select-Object -First 1
if ($imageMagickTest) {
    Write-Host "OK - ImageMagick: $imageMagickTest" -ForegroundColor Green
} else {
    Write-Host "WARNING: ImageMagick not found (restart PowerShell if needed)" -ForegroundColor Yellow
}

Write-Host "[7/7] Starting converter..." -ForegroundColor Cyan

$endTime = Get-Date
$duration = [Math]::Round(($endTime - $startTime).TotalSeconds)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Installation Complete!                                   " -ForegroundColor Green
Write-Host "  Duration: $($duration) seconds                            " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Starting the converter..." -ForegroundColor Cyan
Write-Host ""

Write-Host "The converter will be available at: http://localhost:3000" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

npm start
