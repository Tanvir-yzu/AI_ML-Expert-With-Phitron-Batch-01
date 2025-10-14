@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Define ANSI color codes (best viewed in Windows Terminal)
set "COLOR_RED=[31m"
set "COLOR_GREEN=[32m"
set "COLOR_YELLOW=[33m"
set "COLOR_CYAN=[36m"
set "COLOR_RESET=[0m"

echo %COLOR_CYAN%===================================%COLOR_RESET%
echo %COLOR_GREEN%Simple Git Script%COLOR_RESET%
echo %COLOR_CYAN%===================================%COLOR_RESET%
echo.

:: Ensure Git is available
where git >nul 2>&1
if errorlevel 1 (
    echo %COLOR_RED%Git is not installed or not available in PATH.%COLOR_RESET%
    endlocal & exit /b 1
)

:: Ensure we are inside a Git repository (initialize if missing)
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo %COLOR_YELLOW%No Git repository detected. Initializing...%COLOR_RESET%
    git init
    if errorlevel 1 (
        echo %COLOR_RED%Failed to initialize git repository.%COLOR_RESET%
        endlocal & exit /b 1
    )
)

:: Check for changes
set "hasChanges="
for /f "delims=" %%s in ('git status --porcelain') do set hasChanges=1

if not defined hasChanges (
    echo %COLOR_YELLOW%No changes detected. Skipping add/commit.%COLOR_RESET%
    goto push_section
)

:: Stage all changes
git add -A
if errorlevel 1 (
    echo %COLOR_RED%git add failed.%COLOR_RESET%
    endlocal & exit /b 1
)

:: Prompt for commit message (sanitize quotes and trim)
set /p commit_text=%COLOR_YELLOW%Enter the git commit message:%COLOR_RESET% 
set "commit_text=%commit_text:"=%"
for /f "tokens=* delims= " %%A in ("%commit_text%") do set "commit_text=%%A"

:: Decide final commit message
if "%commit_text%"=="" (
    set "commit_msg=Auto commit"
) else (
    set "commit_msg=%commit_text%"
)

:: Commit outside of IF to avoid parser issues
git commit -m "%commit_msg%"
if errorlevel 1 (
    echo %COLOR_RED%Commit failed.%COLOR_RESET%
    endlocal & exit /b 1
)
echo %COLOR_GREEN%Committed with message: %commit_msg%%COLOR_RESET%
echo.

:push_section
:: Determine branch to push
set /p branch_input=%COLOR_YELLOW%Enter the branch to push (blank = current or main): %COLOR_RESET%
set "branch_name=%branch_input%"

if "%branch_name%"=="" (
    for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "branch_name=%%b"
    if "%branch_name%"=="" set "branch_name=main"
)

:: Ensure remote 'origin' exists
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo %COLOR_RED%Remote 'origin' is not configured.%COLOR_RESET%
    echo %COLOR_CYAN%Add it with: git remote add origin https://github.com/<your-username>/<your-repo>.git%COLOR_RESET%
    endlocal & exit /b 1
)

:: Push to origin
git push origin "%branch_name%"
if errorlevel 1 (
    echo %COLOR_RED%Push failed.%COLOR_RESET%
    endlocal & exit /b 1
)

echo %COLOR_GREEN%Done.%COLOR_RESET%
endlocal
exit /b