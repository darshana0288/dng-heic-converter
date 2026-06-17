@echo off
REM DNG/HEIC Converter - Auto Installer
REM This batch file runs the PowerShell installer script

setlocal enabledelayedexpansion

REM Check if PowerShell is available
where powershell >nul 2>&1
if errorlevel 1 (
    color 0C
    cls
    echo.
    echo ERROR: PowerShell is not available on this system
    echo This installer requires Windows PowerShell or PowerShell Core
    echo.
    pause
    exit /b 1
)

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0

REM Run the PowerShell installer
echo Running DNG/HEIC Converter installer...
echo.

REM Execute PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%INSTALL.ps1"

REM Check if installation was successful
if errorlevel 1 (
    color 0C
    echo.
    echo Installation script exited with an error
    pause
    exit /b 1
)

color 0A
echo.
echo ✓ Installer completed!
echo.
pause
