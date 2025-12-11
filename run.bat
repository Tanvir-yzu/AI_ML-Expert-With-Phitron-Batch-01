@echo off
setlocal EnableExtensionsensions EnableDelayedExpansion

:: Enable UTF-8 for box-drawing UI
chcp 65001 >nul

:: Color palette (works best in Windows Terminal)
set "COLOR_RED=[31m"
set "COLOR_GREEN=[32m"
set "COLOR_YELLOW=[33m"
set "COLOR_CYAN=[36m"
set "COLOR_RESET=[0m"

:: UI icons and separators
set "ICON_OK=✔"
set "ICON_FAIL=✖"
set "ICON_WARN=⚠"
set "ICON_STEP=»"
set "SEP_LINE=────────────────────────────────────"

:: DeepSeek API Configuration (REPLACE WITH YOUR CREDENTIALS)
set "DEEPSEEK_API_KEY=sk-89562a5baec04f668588519e3a45b143"
set "DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions"

:: Modern banner
echo %COLOR_CYAN%┌%SEP_LINE%┐%COLOR_RESET%
echo %COLOR_CYAN%│%COLOR_RESET%  %COLOR_GREEN%AI/ML Git Automation Script%COLOR_RESET%        %COLOR_CYAN%│%COLOR_RESET% 
echo %COLOR_CYAN%└%SEP_LINE%┘%COLOR_RESET%
echo.

:: Ensure Git is available
echo %COLOR_CYAN%%ICON_STEP% Checking Git availability...%COLOR_RESET%
where git >nul 2>&1
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL% Git is not installed or not available in PATH.%COLOR_RESET%
    endlocal & exit /b 1
)
echo %COLOR_GREEN%%ICON_OK%  Git is available.%COLOR_RESET%
echo.

:: Ensure we are inside a Git repository (initialize if missing)
echo %COLOR_CYAN%%ICON_STEP%  Checking repository...%COLOR_RESET%
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo %COLOR_YELLOW%%ICON_WARN%  No Git repository detected. Initializing...%COLOR_RESET%
    git init
    if errorlevel 1 (
        echo %COLOR_RED%%ICON_FAIL%  Failed to initialize git repository.%COLOR_RESET%
        endlocal & exit /b 1
    )
    echo %COLOR_GREEN%%ICON_OK%  Repository initialized.%COLOR_RESET%
) else (
    echo %COLOR_GREEN%%ICON_OK%  Repository OK.%COLOR_RESET%
)
echo.

:: Check for changes
set "hasChanges="
for /f "delims=" %%s in ('git status --porcelain') do set hasChanges=1

if not defined hasChanges (
    echo %COLOR_YELLOW%%ICON_WARN%  No changes detected. Skipping add/commit.%COLOR_RESET%
    goto push_section
)

echo %COLOR_CYAN%%ICON_STEP%  Staging changes...%COLOR_RESET%
:: Stage all changes
git add -A
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL%  git add failed.%COLOR_RESET%
    endlocal & exit /b 1
)
echo %COLOR_GREEN%%ICON_OK%  Staged.%COLOR_RESET%
echo.

:: Generate auto-comment using DeepSeek API
echo %COLOR_CYAN%%ICON_STEP%  Analyzing changes for auto-comment...%COLOR_RESET%

:: Capture changed files and their diffs
set "diff_file=temp_git_diff.txt"
echo. > "%diff_file%"
echo Changed files in AI/ML repository: >> "%diff_file%"
echo ===================================== >> "%diff_file%"
for /f "delims=" %%f in ('git diff --cached --name-only') do (
    echo. >> "%diff_file%"
    echo File: %%f >> "%diff_file%"
    echo ------------------------------ >> "%diff_file%"
    git diff --cached "%%f" >> "%diff_file%"
    echo ------------------------------ >> "%diff_file%"
)

:: Fixed PowerShell command with proper escaping
set "auto_comment_file=auto_generated_comment.txt"
powershell -Command "$ErrorActionPreference = 'Stop'; $diffContent = Get-Content '%diff_file%' -Raw; $body = @{ model = 'deepseek-chat'; messages = @(@{'role' = 'user'; 'content' = 'Generate a concise Git commit message (50 chars or less) for these changes in an AI/ML repository. Focus on code changes, text modifications, or documentation updates. Examples: ''Updated NLP sample text'', ''Fixed ML architecture docs'', ''Added Python for ML exercises'' ' + $diffContent}) } | ConvertTo-Json; $response = Invoke-RestMethod -Uri '%DEEPSEEK_API_URL%' -Method Post -Headers @{ 'Authorization' = 'Bearer %DEEPSEEK_API_KEY%'; 'Content-Type' = 'application/json' } -Body $body; $response.choices[0].message.content | Out-File '%auto_comment_file%' -Encoding utf8"

:: Handle API response
set "commit_msg="
if exist "%auto_comment_file%" (
    set /p commit_msg=<%auto_comment_file%
    :: Clean up comment
    set "commit_msg=!commit_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_msg!") do set "commit_msg=%%A"
)

:: Fallback if API failed
if "!commit_msg!"=="" (
    echo %COLOR_YELLOW%%ICON_WARN%  API call failed. Using default message.%COLOR_RESET%
    set "commit_msg=Auto-update in AI/ML repository"
) else (
    echo %COLOR_GREEN%%ICON_OK%  Auto-comment generated.%COLOR_RESET%
)

:: Cleanup temp files
del "%diff_file%" 2>nul
del "%auto_comment_file%" 2>nul

:: Show generated message and confirm
echo.
echo %COLOR_YELLOW%Generated commit message: !commit_msg!%COLOR_RESET%
set /p "confirm=%COLOR_YELLOW%Use this message? (Y/n) %COLOR_RESET%"
if /i "!confirm!" neq "Y" (
    set /p commit_text=%COLOR_YELLOW%%ICON_STEP% Enter custom commit message: %COLOR_RESET%
    set "commit_text=!commit_text:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_text!") do set "commit_text=%%A"
    if "!commit_text!"=="" set "commit_text=Manual update"
    set "commit_msg=!commit_text!"
)

:: Commit changes
echo.
echo %COLOR_CYAN%%ICON_STEP%  Committing...%COLOR_RESET%
git commit -m "!commit_msg!"
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL%  Commit failed.%COLOR_RESET%
    endlocal & exit /b 1
)
echo %COLOR_GREEN%%ICON_OK%  Committed with message: !commit_msg!%COLOR_RESET%
echo.

:push_section

:: Get the current branch name
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%B

:: Display the current branch name with design
echo.
echo %COLOR_CYAN%┌%SEP_LINE%┐%COLOR_RESET%
echo %COLOR_CYAN%│%COLOR_RESET%  %COLOR_GREEN%Current Git Branch:%COLOR_RESET%             %COLOR_CYAN%│%COLOR_RESET%
echo %COLOR_CYAN%│%COLOR_RESET%      %COLOR_YELLOW%[ !CURRENT_BRANCH! ]%COLOR_RESET%              %COLOR_CYAN%│%COLOR_RESET%
echo %COLOR_CYAN%└%SEP_LINE%┘%COLOR_RESET%
echo.

:: Determine branch to push
set /p branch_input=%COLOR_YELLOW%%ICON_STEP% Enter the branch to push (Current Branch -  !CURRENT_BRANCH!): %COLOR_RESET%
set "branch_name=!branch_input!"
if "!branch_name!"=="" (
    for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "branch_name=%%b"
    if "!branch_name!"=="" set "branch_name=!CURRENT_BRANCH!"
)

:: Ensure remote 'origin' exists
echo %COLOR_CYAN%%ICON_STEP%  Checking remote 'origin'...%COLOR_RESET%
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL% Remote 'origin' is not configured.%COLOR_RESET%
    echo %COLOR_CYAN%Add it with: git remote add origin https://github.com/Tanvir-yzu/AI_ML-Expert-With-Phitron-Batch-01.git%COLOR_RESET%
    endlocal & exit /b 1
)
echo %COLOR_GREEN%%ICON_OK%  Remote 'origin' detected.%COLOR_RESET%
echo.

:: Push to origin
echo %COLOR_CYAN%%ICON_STEP% Pushing to origin/!branch_name!...%COLOR_RESET%
git push origin "!branch_name!"
if errorlevel 1 (
    echo %COLOR_RED%%ICON_FAIL% Push failed.%COLOR_RESET%
    endlocal & exit /b 1
)

echo %COLOR_GREEN%%ICON_OK%  Done.%COLOR_RESET%
echo %COLOR_CYAN%┌%SEP_LINE%┐%COLOR_RESET%
echo %COLOR_CYAN%│%COLOR_RESET%  %COLOR_GREEN%✔     Completed%COLOR_RESET%                   %COLOR_CYAN%│%COLOR_RESET%
echo %COLOR_CYAN%└%SEP_LINE%┘%COLOR_RESET%

:: Optional success sound (create sounds folder and add success.wav if needed)
powershell -NoProfile -Command "(New-Object Media.SoundPlayer '%~dp0sounds\success.wav').PlaySync()" >nul 2>&1

endlocal
exit /b