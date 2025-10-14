@echo off
REM GitHub repository management script with color

:: Define ANSI color codes
set "COLOR_RED=[31m"
set "COLOR_GREEN=[32m"
set "COLOR_YELLOW=[33m"
set "COLOR_CYAN=[36m"
set "COLOR_RESET=[0m"

echo %COLOR_CYAN%===================================%COLOR_RESET%
echo %COLOR_GREEN%Git Repository Management Script%COLOR_RESET%
echo %COLOR_CYAN%===================================%COLOR_RESET%
echo.

call git add .

set /p commit_text=%COLOR_YELLOW%Enter the git commit message: %COLOR_RESET%
if "%commit_text%"=="" (
    call git commit -m "No commit message provided"
    echo %COLOR_RED%No commit message provided, using default.%COLOR_RESET%
) else (
    call git commit -m "%commit_text%"
    echo %COLOR_GREEN%Committed with message: %commit_text%%COLOR_RESET%
)
echo.

set /p origin_name=%COLOR_YELLOW%Enter the git origin branch (default is main): %COLOR_RESET%
if "%origin_name%"=="" (
    call git push origin main
    echo %COLOR_GREEN%Pushed to origin main%COLOR_RESET%
) else (
    call git push origin "%origin_name%"
    echo %COLOR_GREEN%Pushed to origin %origin_name%%COLOR_RESET%
)
echo.

echo %COLOR_CYAN%=====================================%COLOR_RESET%
echo %COLOR_GREEN%Git push successful origin by "%origin_name%" %COLOR_RESET%
echo %COLOR_CYAN%=====================================%COLOR_RESET%
exit /b