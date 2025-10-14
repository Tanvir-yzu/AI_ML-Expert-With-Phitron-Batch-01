@echo off
setlocal
echo Installing Git Helper...

set "TARGET=%ProgramFiles%\GitHelper"
if not exist "%TARGET%" mkdir "%TARGET%"

xcopy "%~dp0*" "%TARGET%\" /E /Y >nul

:: Add to PATH permanently if not already present
for %%I in ("%TARGET%") do ( 
    echo %PATH% | find "%%~I" >nul || setx PATH "%PATH%;%%~I" >nul
)

echo Installed! You can now run: git-helper
endlocal
pause