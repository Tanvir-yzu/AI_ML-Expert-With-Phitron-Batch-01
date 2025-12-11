@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: === Basic setup ===
chcp 65001 >nul
set "ESC="
set "COLOR_RED=!ESC![31m"
set "COLOR_GREEN=!ESC![32m"
set "COLOR_YELLOW=!ESC![33m"
set "COLOR_CYAN=!ESC![36m"
set "COLOR_RESET=!ESC![0m"

set "ICON_OK=✔"
set "ICON_FAIL=✖"
set "ICON_WARN=⚠"
set "ICON_STEP=»"
set "SEP_LINE=────────────────────────────────────"

:: CONFIGURATION
set "DEEPSEEK_API_KEY=sk-89562a5baec04f668588519e3a45b143"
set "DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions"

:: Banner
echo !COLOR_CYAN!┌!SEP_LINE!┐!COLOR_RESET!
echo !COLOR_CYAN!│!COLOR_RESET!  !COLOR_GREEN!AI/ML Git Automation Script!COLOR_RESET!        !COLOR_CYAN!│!COLOR_RESET!
echo !COLOR_CYAN!└!SEP_LINE!┘!COLOR_RESET!
echo.

:: Check Git
echo !COLOR_CYAN!!ICON_STEP! Checking Git availability...!COLOR_RESET!
where git >nul 2>&1 || (
    echo !COLOR_RED!!ICON_FAIL! Git is not installed or not in PATH.!COLOR_RESET!
    endlocal & exit /b 1
)
echo !COLOR_GREEN!!ICON_OK!  Git is available.!COLOR_RESET!
echo.

:: Check Git Repo
echo !COLOR_CYAN!!ICON_STEP!  Checking repository...!COLOR_RESET!
git rev-parse --is-inside-work-tree >nul 2>&1 || (
    echo !COLOR_YELLOW!!ICON_WARN!  No Git repo found. Initializing...!COLOR_RESET!
    git init || (
        echo !COLOR_RED!!ICON_FAIL!  Failed to initialize Git repository.!COLOR_RESET!
        endlocal & exit /b 1
    )
    echo !COLOR_GREEN!!ICON_OK!  Repository initialized.!COLOR_RESET!
) && (
    echo !COLOR_GREEN!!ICON_OK!  Repository OK.!COLOR_RESET!
)
echo.

:: Detect Changes
set "hasChanges="
for /f "delims=" %%s in ('git status --porcelain 2^>nul') do set "hasChanges=1"

if not defined hasChanges (
    echo !COLOR_YELLOW!!ICON_WARN!  No changes detected. Skipping add/commit.!COLOR_RESET!
    goto :push_section
)

:: Stage Changes
echo !COLOR_CYAN!!ICON_STEP!  Staging changes...!COLOR_RESET!
git add -A
if errorlevel 1 (
    echo !COLOR_RED!!ICON_FAIL!  git add failed.!COLOR_RESET!
    endlocal & exit /b 1
)
echo !COLOR_GREEN!!ICON_OK!  Staged.!COLOR_RESET!
echo.

:: === SIMPLIFIED APPROACH: Skip API for now, use smart defaults ===
echo !COLOR_CYAN!!ICON_STEP!  Analyzing changes for auto-comment...!COLOR_RESET!

:: Get list of changed files
set "changed_files="
for /f "delims=" %%f in ('git diff --cached --name-only') do (
    set "changed_files=!changed_files! %%f"
)

:: Generate smart commit message based on file types and count
set "commit_msg=Update project files"

:: Count different types of files
set "py_count=0"
set "md_count=0"
set "txt_count=0"
set "other_count=0"

for /f "delims=" %%f in ('git diff --cached --name-only') do (
    echo %%f | findstr /i "\.py$" >nul && set /a py_count+=1
    echo %%f | findstr /i "\.md$" >nul && set /a md_count+=1
    echo %%f | findstr /i "\.txt$" >nul && set /a txt_count+=1
    if not defined py_count if not defined md_count if not defined txt_count set /a other_count+=1
)

:: Build appropriate message
if !py_count! GTR 0 (
    if !py_count! EQU 1 (
        set "commit_msg=Update Python ML code"
    ) else (
        set "commit_msg=Update !py_count! Python ML files"
    )
) else if !md_count! GTR 0 (
    if !md_count! EQU 1 (
        set "commit_msg=Update documentation"
    ) else (
        set "commit_msg=Update !md_count! documentation files"
    )
) else if !txt_count! GTR 0 (
    set "commit_msg=Update text resources"
) else if !other_count! GTR 0 (
    set "commit_msg=Update project files"
)

:: Add "and X more" if multiple file types
set "total_files=0"
for /f %%i in ('git diff --cached --name-only ^| find /c /v ""') do set "total_files=%%i"

if !total_files! GTR 3 (
    set "commit_msg=!commit_msg! and !total_files! total changes"
)

echo !COLOR_GREEN!!ICON_OK!  Generated smart commit message.!COLOR_RESET!

:: Show generated message and confirm
echo.
echo !COLOR_YELLOW!Generated commit message: !commit_msg!!COLOR_RESET!
set /p "confirm=!COLOR_YELLOW!Use this message? (Y/n): !COLOR_RESET!"
if /i not "!confirm!"=="Y" (
    set /p "custom_msg=!COLOR_YELLOW!!ICON_STEP! Enter custom commit message: !COLOR_RESET!"
    :: Remove quotes and trim
    set "custom_msg=!custom_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!custom_msg!") do set "custom_msg=%%A"
    if "!custom_msg!"=="" set "custom_msg=Manual update"
    set "commit_msg=!custom_msg!"
)

:: Commit
echo.
echo !COLOR_CYAN!!ICON_STEP!  Committing...!COLOR_RESET!
git commit -m "!commit_msg!" || (
    echo !COLOR_RED!!ICON_FAIL!  Commit failed.!COLOR_RESET!
    endlocal & exit /b 1
)
echo !COLOR_GREEN!!ICON_OK!  Committed with message: !commit_msg!!COLOR_RESET!
echo.

:push_section

:: Get Current Branch
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%B"
if "!CURRENT_BRANCH!"=="" set "CURRENT_BRANCH=(unknown)"

echo.
echo !COLOR_CYAN!┌!SEP_LINE!┐!COLOR_RESET!
echo !COLOR_CYAN!│!COLOR_RESET!  !COLOR_GREEN!Current Git Branch:!COLOR_RESET!             !COLOR_CYAN!│!COLOR_RESET!
echo !COLOR_CYAN!│!COLOR_RESET!      !COLOR_YELLOW![ !CURRENT_BRANCH! ]!COLOR_RESET!              !COLOR_CYAN!│!COLOR_RESET!
echo !COLOR_CYAN!└!SEP_LINE!┘!COLOR_RESET!
echo.

:: Ask for Branch to Push
set /p "branch_input=!COLOR_YELLOW!!ICON_STEP! Enter branch to push [default: !CURRENT_BRANCH!]: !COLOR_RESET!"
set "branch_name=!branch_input!"
if "!branch_name!"=="" set "branch_name=!CURRENT_BRANCH!"

:: Check Remote
echo !COLOR_CYAN!!ICON_STEP!  Checking remote 'origin'...!COLOR_RESET!
git remote get-url origin >nul 2>&1 || (
    echo !COLOR_RED!!ICON_FAIL! Remote 'origin' not configured.!COLOR_RESET!
    echo !COLOR_CYAN!Run: git remote add origin https://github.com/Tanvir-yzu/AI_ML-Expert-With-Phitron-Batch-01.git!COLOR_RESET!
    endlocal & exit /b 1
)
echo !COLOR_GREEN!!ICON_OK!  Remote 'origin' detected.!COLOR_RESET!
echo.

:: Push
echo !COLOR_CYAN!!ICON_STEP! Pushing to origin/!branch_name!...!COLOR_RESET!
git push origin "!branch_name!" || (
    echo !COLOR_RED!!ICON_FAIL! Push failed.!COLOR_RESET!
    endlocal & exit /b 1
)

echo !COLOR_GREEN!!ICON_OK!  Done.!COLOR_RESET!
echo !COLOR_CYAN!┌!SEP_LINE!┐!COLOR_RESET!
echo !COLOR_CYAN!│!COLOR_RESET!  !COLOR_GREEN!✔ Completed!COLOR_RESET!                   !COLOR_CYAN!│!COLOR_RESET!
echo !COLOR_CYAN!└!SEP_LINE!┘!COLOR_RESET!

endlocal
exit /b 0