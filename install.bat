@echo off
setlocal
echo Installing Git Helper...

:: Set the target directory
set "TARGET=%ProgramFiles%\run"

:: Check for administrative privileges
>nul 2>&1 "%SystemRoot%\System32\cacls.exe" "%SystemRoot%\System32\config\system"
if '%errorlevel%' NEQ '0' (
    echo This script requires administrative privileges. Please run as Administrator.
    pause
    exit /b
)

:: Create the target directory if it doesn't exist
if not exist "%TARGET%" (
    mkdir "%TARGET%" || (
        echo Unable to create directory - %TARGET%
        pause
        exit /b
    )
)

:: Copy files to the target directory
xcopy "%~dp0GitHelper\\" "%TARGET%\\" /E /Y >nul || (
    echo Failed to copy files to %TARGET%.
    pause
    exit /b
)

:: Add to PATH permanently if not already present
for %%I in ("%TARGET%") do (
    echo %PATH% | find "%%~I" >nul || setx PATH "%PATH%;%%~I" >nul
)

echo Installed! You can now run: git-helper
endlocal
pause