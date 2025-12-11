@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: === Basic CMD Setup (No ANSI colors) ===
chcp 65001 >nul
title AI/ML Git Automation Script

:: Simple text formatting (no color codes that show as text)
set "ICON_OK=OK"
set "ICON_FAIL=FAIL"
set "ICON_WARN=WARN"
set "ICON_STEP=STEP"
set "SEP_LINE=----------------------------------------"

:: CONFIGURATION
set "DEEPSEEK_API_KEY=sk-89562a5baec04f668588519e3a45b143"
set "DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions"

:: Banner (plain text)
echo ┌%SEP_LINE%┐
echo │  AI/ML Git Automation Script        │
echo └%SEP_LINE%┘
echo.

:: Check Git
echo STEP Checking Git availability...
where git >nul 2>&1
if errorlevel 1 (
    echo FAIL Git is not installed or not in PATH.
    pause
    endlocal & exit /b 1
)
echo OK  Git is available.
echo.

:: Check Git Repo
echo STEP  Checking repository...
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo WARN  No Git repo found. Initializing...
    git init
    if errorlevel 1 (
        echo FAIL  Failed to initialize git repository.
        pause
        endlocal & exit /b 1
    )
    echo OK  Repository initialized.
) else (
    echo OK  Repository OK.
)
echo.

:: Detect Changes
set "hasChanges="
for /f "delims=" %%s in ('git status --porcelain 2^>nul') do set "hasChanges=1"

if not defined hasChanges (
    echo WARN  No changes detected. Skipping add/commit.
    goto push_section
)

:: Stage Changes
echo STEP  Staging changes...
git add -A
if errorlevel 1 (
    echo FAIL  git add failed.
    pause
    endlocal & exit /b 1
)
echo OK  Staged.
echo.

:: Smart commit message generation
echo STEP  Analyzing changes for commit message...

:: Get file statistics
set "py_count=0"
set "md_count=0"
set "txt_count=0"
set "total_changes=0"

for /f "delims=" %%f in ('git diff --cached --name-only') do (
    set /a total_changes+=1
    echo %%f | findstr /i "\.py$" >nul && set /a py_count+=1
    echo %%f | findstr /i "\.md$" >nul && set /a md_count+=1
    echo %%f | findstr /i "\.txt$" >nul && set /a txt_count+=1
)

:: Smart message selection
set "commit_msg=Update project files"

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
        set "commit_msg=Update !md_count! docs files"
    )
) else if !txt_count! GTR 0 (
    set "commit_msg=Update text resources"
) else (
    set "commit_msg=Update !total_changes! files"
)

:: Add context for multiple changes
if !total_changes! GTR 5 (
    set "commit_msg=!commit_msg! (!total_changes! total)"
)

:: Show analysis results
echo Files changed:
echo   Python files: !py_count!
echo   Documentation: !md_count!
echo   Text files: !txt_count!
echo   Total changes: !total_changes!
echo.

echo OK  Generated smart commit message.

:: Show generated message and confirm
echo.
echo Suggested commit message:
echo   !commit_msg!
echo.
set /p "choice=Use this message? (Y/n/custom): "

:: === FIXED: Better choice handling ===
if /i "!choice!"=="n" (
    set /p "commit_msg=Enter custom commit message: "
    :: Clean the message
    set "commit_msg=!commit_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_msg!") do set "commit_msg=%%A"
    if "!commit_msg!"=="" set "commit_msg=Manual update"
) else if /i not "!choice!"=="Y" (
    :: User typed custom message directly OR pressed enter (empty)
    if "!choice!"=="" (
        set "commit_msg=!commit_msg!"
    ) else (
        set "commit_msg=!choice!"
    )
    set "commit_msg=!commit_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_msg!") do set "commit_msg=%%A"
    if "!commit_msg!"=="" set "commit_msg=Manual update"
)
:: If choice was "Y" or empty, keep the original commit_msg

:: Commit
echo.
echo STEP  Committing...
git commit -m "!commit_msg!"
if errorlevel 1 (
    echo FAIL  Commit failed.
    pause
    endlocal & exit /b 1
)
echo OK  Committed: !commit_msg!
echo.

:push_section

:: Get Current Branch
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%B"
if "!CURRENT_BRANCH!"=="" set "CURRENT_BRANCH=main"

echo.
echo ┌%SEP_LINE%┐
echo │  Current Git Branch: !CURRENT_BRANCH!       │
echo └%SEP_LINE%┘
echo.

:: === FIXED: Better branch input handling ===
set "branch_name=!CURRENT_BRANCH!"
set /p "branch_input=Branch to push [!CURRENT_BRANCH!]: "

:: Only change branch_name if user actually entered something
if not "!branch_input!"=="" (
    if not "!branch_input!"=="!CURRENT_BRANCH!"" (
        set "branch_name=!branch_input!"
    )
)

:: Special case: if they just pressed enter, keep default
if "!branch_input!"=="" (
    set "branch_name=!CURRENT_BRANCH!"
)

echo STEP  Checking remote 'origin'...
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo FAIL Remote 'origin' not configured.
    echo Add with: git remote add origin [your-repo-url]
    pause
    endlocal & exit /b 1
)
echo OK  Remote 'origin' detected.
echo.

:: Push
echo STEP Pushing to origin/!branch_name!...
echo (Pushing to branch: !branch_name!)
git push origin "!branch_name!"
if errorlevel 1 (
    echo FAIL Push failed.
    echo You may need to:
    echo   1. Pull first: git pull origin !branch_name!
    echo   2. Check branch exists on remote
    echo   3. Verify your GitHub permissions
    pause
    endlocal & exit /b 1
)

echo OK  Successfully pushed!
echo ┌%SEP_LINE%┐
echo │  COMPLETED SUCCESSFULLY                │
echo └%SEP_LINE%┘

pause
endlocal
exit /b 0