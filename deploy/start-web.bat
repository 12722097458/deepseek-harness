@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."

where pwsh.exe >nul 2>&1
if not errorlevel 1 goto :pwsh

where powershell.exe >nul 2>&1
if not errorlevel 1 goto :powershell

echo [start-web] PowerShell was not found. Install PowerShell and try again.
exit /b 1

:pwsh
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%start-web.ps1" %*
set "EXIT_CODE=%errorlevel%"
exit /b %EXIT_CODE%

:powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%start-web.ps1" %*
set "EXIT_CODE=%errorlevel%"
exit /b %EXIT_CODE%
