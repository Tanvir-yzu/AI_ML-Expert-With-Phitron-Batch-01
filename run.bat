@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: === Clean CMD Setup ===
chcp 65001 >nul
title AI ML Git Automation Script

:: Simple text formatting
set "ICON_OK=OK"
set "ICON_FAIL=FAIL"
set "ICON_WARN=WARN"
set "ICON_STEP=STEP"
set "LINE=----------------------------------------"

:: CONFIGURATION
set "DEEPSEEK_API_KEY=sk-89562a5baec04f668588519e3a45b143"
set "DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions"

:: Banner (simple ASCII)
echo STEP AI ML Git Automation Script
echo STEP ========================================
echo.

:: Check Git
echo STEP Checking Git availability...
where git >nul 2>&1
if errorlevel 1 (
    echo FAIL Git is not installed or not in PATH.
    pause
    endlocal & exit /b 1
)
echo OK Git is available.
echo.

:: Check Git Repo
echo STEP Checking repository...
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo WARN No Git repo found. Initializing...
    git init
    if errorlevel 1 (
        echo FAIL Failed to initialize git repository.
        pause
        endlocal & exit /b 1
    )
    echo OK Repository initialized.
) else (
    echo OK Repository OK.
)
echo.

:: Detect Changes
set "hasChanges="
for /f "delims=" %%s in ('git status --porcelain 2^>nul') do set "hasChanges=1"

if not defined hasChanges (
    echo WARN No changes detected. Skipping add/commit.
    goto SKIP_COMMIT
)

:: Stage Changes
echo STEP Staging changes...
git add -A
if errorlevel 1 (
    echo FAIL git add failed.
    pause
    endlocal & exit /b 1
)
echo OK Staged.
echo.

:: Smart commit message generation
echo STEP Analyzing changes for commit message...

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

echo OK Generated smart commit message.

:: Show generated message and confirm
echo.
echo Suggested commit message:
echo   !commit_msg!
echo.
set /p "choice=Use this message (Y/n/custom): "

:: Handle choice
if "!choice!"=="" set "choice=Y"
if /i "!choice!"=="y" (
    echo Using suggested message.
) else if /i "!choice!"=="n" (
    set /p "commit_msg=Enter custom commit message: "
    set "commit_msg=!commit_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_msg!") do set "commit_msg=%%A"
    if "!commit_msg!"=="" set "commit_msg=Manual update"
) else (
    :: Custom message entered directly
    set "commit_msg=!choice!"
    set "commit_msg=!commit_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_msg!") do set "commit_msg=%%A"
    if "!commit_msg!"=="" set "commit_msg=Manual update"
)

:: Commit
echo.
echo STEP Committing...
git commit -m "!commit_msg!"
if errorlevel 1 (
    echo FAIL Commit failed.
    pause
    endlocal & exit /b 1
)
echo OK Committed: !commit_msg!
echo.

:SKIP_COMMIT

:: Get Current Branch
set "CURRENT_BRANCH=main"
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%B"

echo.
echo STEP Current Git Branch: !CURRENT_BRANCH!
echo STEP ========================================
echo.

:: Branch input handling
set "branch_name=!CURRENT_BRANCH!"
set /p "branch_input=Branch to push [!CURRENT_BRANCH!]: "

if not "!branch_input!"=="" (
    set "branch_name=!branch_input!"
)

echo STEP Checking remote origin...
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo FAIL Remote origin not configured.
    echo Add with: git remote add origin [your-repo-url]
    pause
    endlocal & exit /b 1
)
echo OK Remote origin detected.
echo.

:: Push
echo STEP Pushing to origin/!branch_name!...
git push origin "!branch_name!"
if errorlevel 1 (
    echo FAIL Push failed.
    echo.
    echo Possible solutions:
    echo 1. Check if branch exists on GitHub
    echo 2. Try: git pull origin !branch_name! first
    echo 3. Check your GitHub permissions
    echo 4. Verify remote URL is correct
    pause
    endlocal & exit /b 1
)

echo.
echo OK Successfully completed!
echo OK ========================================
echo.

pause
endlocal
exit /b 0