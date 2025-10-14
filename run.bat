@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo ===================================
echo Simple Git Script
echo ===================================
echo.

:: Ensure Git is available
where git >nul 2>&1
if errorlevel 1 (
    echo Git is not installed or not available in PATH.
    exit /b 1
)

:: Ensure we are inside a Git repository (initialize if missing)
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo No Git repository detected. Initializing...
    git init
    if errorlevel 1 (
        echo Failed to initialize git repository.
        exit /b 1
    )
)

:: Check for changes
set "hasChanges="
for /f "delims=" %%s in ('git status --porcelain') do set hasChanges=1

if not defined hasChanges (
    echo No changes detected. Skipping add/commit.
    goto push_section
)

:: Stage all changes
git add -A
if errorlevel 1 (
    echo git add failed.
    exit /b 1
)

:: Prompt for commit message
set /p commit_text=Enter the git commit message: 

:: Sanitize: remove surrounding quotes and trim leading spaces
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
    echo Commit failed.
    exit /b 1
)

:push_section
:: Determine branch to push
set /p branch_input=Enter the branch to push (blank = current or main): 
set "branch_name=%branch_input%"

if "%branch_name%"=="" (
    for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "branch_name=%%b"
    if "%branch_name%"=="" set "branch_name=main"
)

:: Ensure remote 'origin' exists
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo Remote 'origin' is not configured.
    echo Add it with: git remote add origin https://github.com/<your-username>/<your-repo>.git
    exit /b 1
)

:: Push to origin
git push origin "%branch_name%"
if errorlevel 1 (
    echo Push failed.
    exit /b 1
)

echo Done.
endlocal
exit /b