@echo off
setlocal enabledelayedexpansion

color 0A
cls

echo.
echo ============================================
echo DNG/HEIC to JPEG Converter - Auto Installer
echo ============================================
echo.
echo This will install everything automatically:
echo - Node.js dependencies
echo - exiftool
echo - ImageMagick
echo.
echo Press any key to continue...
pause >nul

REM ==========================================
REM CHECK NODE.JS
REM ==========================================
echo.
echo [1/5] Checking Node.js...
node -v >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    echo Then add it to your Windows PATH and restart this installer.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node -v') do set NODE_VER=%%i
echo ✓ Node.js !NODE_VER! found

REM ==========================================
REM INSTALL NPM DEPENDENCIES
REM ==========================================
echo.
echo [2/5] Installing npm dependencies...
call npm install
if errorlevel 1 (
    echo ERROR: npm install failed
    pause
    exit /b 1
)
echo ✓ Dependencies installed

REM ==========================================
REM INSTALL EXIFTOOL
REM ==========================================
echo.
echo [3/5] Installing exiftool...

REM Check if exiftool.exe exists in tools folder
if not exist "tools\exiftool.exe" (
    echo ERROR: tools\exiftool.exe not found!
    echo Please add exiftool.exe to the tools folder.
    pause
    exit /b 1
)

REM Create C:\exiftool directory
if not exist "C:\exiftool" (
    mkdir "C:\exiftool"
    echo Created C:\exiftool directory
)

REM Copy exiftool to C:\exiftool
copy /Y "tools\exiftool.exe" "C:\exiftool\exiftool.exe" >nul
if errorlevel 1 (
    echo ERROR: Could not copy exiftool.exe to C:\exiftool
    pause
    exit /b 1
)

REM Add C:\exiftool to PATH
setx Path "%Path%;C:\exiftool" >nul 2>&1
if errorlevel 1 (
    echo WARNING: Could not add C:\exiftool to PATH
    echo You may need to add it manually
)

echo ✓ exiftool installed to C:\exiftool

REM ==========================================
REM INSTALL IMAGEMAGICK
REM ==========================================
echo.
echo [4/5] Installing ImageMagick...
echo Downloading latest ImageMagick from GitHub...

REM Get latest release download URL
for /f "tokens=*" %%i in ('powershell -NoProfile -Command "(Invoke-WebRequest -Uri 'https://api.github.com/repos/ImageMagick/ImageMagick/releases/latest' -UseBasicParsing | ConvertFrom-Json).assets | Where-Object {$_.name -match 'Q16-HDRL-x64-dll.exe'} | Select-Object -First 1 -ExpandProperty browser_download_url"') do set IMAGEMAGICK_URL=%%i

if "!IMAGEMAGICK_URL!"=="" (
    echo WARNING: Could not find ImageMagick download link
    echo Please download manually from:
    echo https://github.com/ImageMagick/ImageMagick/releases
    echo And run the Q16-HDRL-x64-dll.exe installer
) else (
    REM Download ImageMagick
    set IMAGEMAGICK_FILE=%TEMP%\ImageMagick-installer.exe

    echo Downloading from: !IMAGEMAGICK_URL!
    powershell -NoProfile -Command "Invoke-WebRequest -Uri '!IMAGEMAGICK_URL!' -OutFile '!IMAGEMAGICK_FILE!' -UseBasicParsing" >nul 2>&1

    if exist "!IMAGEMAGICK_FILE!" (
        echo ✓ Downloaded ImageMagick installer
        echo.
        echo Running ImageMagick installer...
        echo Please select these options when prompted:
        echo - Accept license
        echo - Check "Install development headers and libraries"
        echo - Check "Add application directory to system path"
        echo.
        pause

        REM Run ImageMagick installer
        call "!IMAGEMAGICK_FILE!" /SILENT /NORESTART /D=C:\ImageMagick

        echo Installer started. Please wait...
        timeout /t 10 /nobreak

        echo ✓ ImageMagick installation complete
    ) else (
        echo ERROR: Could not download ImageMagick
        echo Please download manually from:
        echo https://github.com/ImageMagick/ImageMagick/releases
    )
)

REM ==========================================
REM TEST INSTALLATIONS
REM ==========================================
echo.
echo [5/5] Testing installations...

REM Restart command to refresh PATH
endlocal
setlocal enabledelayedexpansion

timeout /t 3 /nobreak

REM Test exiftool
exiftool -ver >nul 2>&1
if errorlevel 1 (
    echo ✗ exiftool not found in PATH
    echo Please restart Command Prompt and run this installer again
) else (
    for /f "tokens=*" %%i in ('exiftool -ver') do set EXIFTOOL_VER=%%i
    echo ✓ exiftool !EXIFTOOL_VER! working
)

REM Test ImageMagick
magick -version >nul 2>&1
if errorlevel 1 (
    echo ✗ ImageMagick not found in PATH
    echo Please restart Command Prompt and run this installer again
) else (
    echo ✓ ImageMagick installed and working
)

REM ==========================================
REM COMPLETE
REM ==========================================
echo.
echo ============================================
echo Installation complete!
echo ============================================
echo.
echo Next steps:
echo 1. Restart Command Prompt completely
echo 2. Run: npm start
echo 3. Open: http://localhost:3000
echo.
echo To start the converter anytime, run:
echo   START.bat
echo.
pause
