@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: === CMD-Friendly Setup ===
chcp 65001 >nul
title AI/ML Git Automation Script

:: Simple color codes that work in most CMD windows
set "COLOR_RED=[91m"
set "COLOR_GREEN=[92m" 
set "COLOR_YELLOW=[93m"
set "COLOR_CYAN=[96m"
set "COLOR_RESET=[0m"

set "ICON_OK=√"
set "ICON_FAIL=X"
set "ICON_WARN=!"
set "ICON_STEP=>"
set "SEP_LINE=----------------------------------------"

:: CONFIGURATION (API key ready but will use smart defaults)
set "DEEPSEEK_API_KEY=sk-89562a5baec04f668588519e3a45b143"
set "DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions"

:: Banner
echo %COLOR_CYAN%┌%SEP_LINE%┐%COLOR_RESET%
echo %COLOR_CYAN%│%COLOR_RESET%  %COLOR_GREEN%AI/ML Git Automation Script%COLOR_RESET%        %COLOR_CYAN%│%COLOR_RESET%
echo %COLOR_CYAN%└%SEP_LINE%┘%COLOR_RESET%
echo.

:: Check Git
echo %COLOR_CYAN%%ICON_STEP% Checking Git availability...%COLOR_RESET%
where git >nul 2>&1
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL% Git is not installed or not in PATH.%COLOR_RESET%
    pause
    endlocal & exit /b 1
)
echo %COLOR_GREEN%%ICON_OK%  Git is available.%COLOR_RESET%
echo.

:: Check Git Repo
echo %COLOR_CYAN%%ICON_STEP%  Checking repository...%COLOR_RESET%
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo %COLOR_YELLOW%%ICON_WARN%  No Git repo found. Initializing...%COLOR_RESET%
    git init
    if errorlevel 1 (
        echo %COLOR_RED%%ICON_FAIL%  Failed to initialize git repository.%COLOR_RESET%
        pause
        endlocal & exit /b 1
    )
    echo %COLOR_GREEN%%ICON_OK%  Repository initialized.%COLOR_RESET%
) else (
    echo %COLOR_GREEN%%ICON_OK%  Repository OK.%COLOR_RESET%
)
echo.

:: Detect Changes
set "hasChanges="
for /f "delims=" %%s in ('git status --porcelain 2^>nul') do set "hasChanges=1"

if not defined hasChanges (
    echo %COLOR_YELLOW%%ICON_WARN%  No changes detected. Skipping add/commit.%COLOR_RESET%
    goto push_section
)

:: Stage Changes
echo %COLOR_CYAN%%ICON_STEP%  Staging changes...%COLOR_RESET%
git add -A
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL%  git add failed.%COLOR_RESET%
    pause
    endlocal & exit /b 1
)
echo %COLOR_GREEN%%ICON_OK%  Staged.%COLOR_RESET%
echo.

:: === SMART CMD-BASED COMMIT MESSAGE GENERATION ===
echo %COLOR_CYAN%%ICON_STEP%  Analyzing changes for commit message...%COLOR_RESET%

:: Get file statistics
set "py_files="
set "md_files="
set "txt_files="
set "other_files="
set "total_changes=0"

for /f "delims=" %%f in ('git diff --cached --name-only') do (
    set /a total_changes+=1
    echo %%f | findstr /i "\.py$" >nul && set "py_files=!py_files! %%f"
    echo %%f | findstr /i "\.md$" >nul && set "md_files=!md_files! %%f" 
    echo %%f | findstr /i "\.txt$" >nul && set "txt_files=!txt_files! %%f"
    if not defined py_files if not defined md_files if not defined txt_files set "other_files=!other_files! %%f"
)

:: Count each type
set /a py_count=0
set /a md_count=0  
set /a txt_count=0
set /a other_count=0

for /f "delims=" %%f in ('git diff --cached --name-only') do (
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
echo %COLOR_CYAN%Files changed:%COLOR_RESET%
echo   Python files: !py_count!
echo   Documentation: !md_count!  
echo   Text files: !txt_count!
echo   Other files: !other_count!
echo   Total changes: !total_changes!
echo.

echo %COLOR_GREEN%%ICON_OK%  Generated smart commit message.%COLOR_RESET%

:: Show generated message and confirm
echo.
echo %COLOR_YELLOW%Suggested commit message:%COLOR_RESET%
echo   !commit_msg!
echo.
set /p "choice=%COLOR_YELLOW%Use this message? (Y/n/custom): %COLOR_RESET%"

if /i "!choice!"=="n" (
    set /p "commit_msg=%COLOR_YELLOW%Enter custom commit message: %COLOR_RESET%"
    :: Clean the message
    set "commit_msg=!commit_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_msg!") do set "commit_msg=%%A"
    if "!commit_msg!"=="" set "commit_msg=Manual update"
) else if /i not "!choice!"=="Y" (
    :: User typed custom message directly
    set "commit_msg=!choice!"
    set "commit_msg=!commit_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_msg!") do set "commit_msg=%%A"
    if "!commit_msg!"=="" set "commit_msg=Manual update"
)

:: Commit
echo.
echo %COLOR_CYAN%%ICON_STEP%  Committing...%COLOR_RESET%
git commit -m "!commit_msg!"
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL%  Commit failed.%COLOR_RESET%
    pause
    endlocal & exit /b 1
)
echo %COLOR_GREEN%%ICON_OK%  Committed: !commit_msg!%COLOR_RESET%
echo.

:push_section

:: Get Current Branch
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%B"
if "!CURRENT_BRANCH!"=="" set "CURRENT_BRANCH=main"

echo.
echo %COLOR_CYAN%┌%SEP_LINE%┐%COLOR_RESET%
echo %COLOR_CYAN%│%COLOR_RESET%  %COLOR_GREEN%Current Git Branch: !CURRENT_BRANCH!%COLOR_RESET%       %COLOR_CYAN%│%COLOR_RESET%
echo %COLOR_CYAN%└%SEP_LINE%┘%COLOR_RESET%
echo.

:: Ask for Branch to Push
set /p "branch_input=%COLOR_YELLOW%%ICON_STEP% Branch to push [!CURRENT_BRANCH!]: %COLOR_RESET%"
if "!branch_input!"=="" set "branch_input=!CURRENT_BRANCH!"
set "branch_name=!branch_input!"

:: Check Remote
echo %COLOR_CYAN%%ICON_STEP%  Checking remote 'origin'...%COLOR_RESET%
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL% Remote 'origin' not configured.%COLOR_RESET%
    echo %COLOR_CYAN%Add with: git remote add origin [your-repo-url]%COLOR_RESET%
    pause
    endlocal & exit /b 1
)
echo %COLOR_GREEN%%ICON_OK%  Remote 'origin' detected.%COLOR_RESET%
echo.

:: Push
echo %COLOR_CYAN%%ICON_STEP% Pushing to origin/!branch_name!...%COLOR_RESET%
git push origin "!branch_name!"
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL% Push failed.%COLOR_RESET%
    echo %COLOR_YELLOW%You may need to pull first or check permissions%COLOR_RESET%
    pause
    endlocal & exit /b 1
)

echo %COLOR_GREEN%%ICON_OK%  Successfully pushed!%COLOR_RESET%
echo %COLOR_CYAN%┌%SEP_LINE%┐%COLOR_RESET%
echo %COLOR_CYAN%│%COLOR_RESET%  %COLOR_GREEN%√ Completed successfully%COLOR_RESET%                %COLOR_CYAN%│%COLOR_RESET%
echo %COLOR_CYAN%└%SEP_LINE%┘%COLOR_RESET%

pause
endlocal
exit /b 0