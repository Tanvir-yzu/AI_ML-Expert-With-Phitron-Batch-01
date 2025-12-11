@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: === Fix 1: Correct typo and enable Unicode ===
chcp 65001 >nul

:: === Fix 2: Use proper ESC character for ANSI colors (Windows Terminal compatible) ===
set "ESC="
set "COLOR_RED=!ESC![31m"
set "COLOR_GREEN=!ESC![32m"
set "COLOR_YELLOW=!ESC![33m"
set "COLOR_CYAN=!ESC![36m"
set "COLOR_RESET=!ESC![0m"

:: UI Icons
set "ICON_OK=✔"
set "ICON_FAIL=✖"
set "ICON_WARN=⚠"
set "ICON_STEP=»"
set "SEP_LINE=────────────────────────────────────"

:: === CONFIGURATION: Replace with your actual key ===
set "DEEPSEEK_API_KEY=sk-89562a5baec04f668588519e3a45b143"
set "DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions"

:: Banner
echo !COLOR_CYAN!┌!SEP_LINE!┐!COLOR_RESET!
echo !COLOR_CYAN!│!COLOR_RESET!  !COLOR_GREEN!AI/ML Git Automation Script!COLOR_RESET!        !COLOR_CYAN!│!COLOR_RESET!
echo !COLOR_CYAN!└!SEP_LINE!┘!COLOR_RESET!
echo.

:: === Check Git ===
echo !COLOR_CYAN!!ICON_STEP! Checking Git availability...!COLOR_RESET!
where git >nul 2>&1 || (
    echo !COLOR_RED!!ICON_FAIL! Git is not installed or not in PATH.!COLOR_RESET!
    endlocal & exit /b 1
)
echo !COLOR_GREEN!!ICON_OK!  Git is available.!COLOR_RESET!
echo.

:: === Check Git Repo ===
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

:: === Detect Changes ===
set "hasChanges="
for /f "delims=" %%s in ('git status --porcelain 2^>nul') do set "hasChanges=1"

if not defined hasChanges (
    echo !COLOR_YELLOW!!ICON_WARN!  No changes detected. Skipping add/commit.!COLOR_RESET!
    goto :push_section
)

:: === Stage Changes ===
echo !COLOR_CYAN!!ICON_STEP!  Staging changes...!COLOR_RESET!
git add -A
if errorlevel 1 (
    echo !COLOR_RED!!ICON_FAIL!  git add failed.!COLOR_RESET!
    endlocal & exit /b 1
)
echo !COLOR_GREEN!!ICON_OK!  Staged.!COLOR_RESET!
echo.

:: === Generate Commit Message via DeepSeek API ===
echo !COLOR_CYAN!!ICON_STEP!  Analyzing changes for auto-comment...!COLOR_RESET!

set "diff_file=%TEMP%\temp_git_diff.txt"
set "auto_comment_file=%TEMP%\auto_generated_comment.txt"

:: === Fix 3: Create diff summary WITHOUT git commands inside for loop ===
:: First, get the list of changed files
set "file_list=%TEMP%\changed_files.txt"
git diff --cached --name-only > "!file_list!"

:: Create header
echo Changed files in AI/ML repository: > "!diff_file!"
echo ===================================== >> "!diff_file!"

:: Process each file separately to avoid git command parsing issues
for /f "usebackq delims=" %%f in ("!file_list!") do (
    echo. >> "!diff_file!"
    echo File: %%f >> "!diff_file!"
    echo ------------------------------ >> "!diff_file!"
    
    :: Capture diff for this specific file
    git diff --cached -- "%%f" >> "!diff_file!" 2>nul
    
    echo ------------------------------ >> "!diff_file!"
)

:: Clean up file list
del "!file_list!" 2>nul

:: === Fix 4: Alternative approach for PowerShell (no ConvertTo-Json dependency) ===
:: Create a simple PowerShell script file to avoid command line escaping issues
set "ps_script=%TEMP%\generate_commit.ps1"

(
echo $ErrorActionPreference = 'Stop'
echo try {
echo     # Read the diff content
echo     $diffContent = Get-Content -Path '%diff_file%' -Raw -Encoding UTF8
echo     
echo     # Simple prompt for commit message
echo     $prompt = "Generate a concise Git commit message (50 chars or less) for these changes in an AI/ML repository. Focus on code changes, text modifications, or documentation updates. Examples: Updated NLP sample text, Fixed ML architecture docs, Added Python for ML exercises."
echo     
echo     # Combine prompt and diff
echo     $fullPrompt = $prompt + "`n`nChanges:`n" + $diffContent
echo     
echo     # Prepare request body as string (avoid ConvertTo-Json)
echo     $bodyString = '{"model": "deepseek-chat", "messages": [{"role": "user", "content": "' + $fullPrompt.Replace('\', '\\').Replace('"', '\"').Replace("`n", '\n') + '"}]}'
echo     
echo     # Set headers
echo     $headers = @{
echo         'Authorization' = 'Bearer %DEEPSEEK_API_KEY%'
echo         'Content-Type' = 'application/json'
echo     }
echo     
echo     # Make API call
echo     $response = Invoke-RestMethod -Uri '%DEEPSEEK_API_URL%' -Method Post -Headers $headers -Body $bodyString
echo     
echo     # Extract message content
echo     $msg = $response.choices[0].message.content.Trim()
echo     [System.IO.File]::WriteAllText('%auto_comment_file%', $msg, [System.Text.UTF8Encoding]::new($false))
echo     Write-Host "SUCCESS: Commit message generated"
echo     exit 0
echo } catch {
echo     Write-Host "ERROR: "$_.Exception.Message
echo     # Write fallback message
echo     [System.IO.File]::WriteAllText('%auto_comment_file%', 'Auto-update in AI/ML repository', [System.Text.UTF8Encoding]::new($false))
echo     exit 1
echo }
) > "!ps_script!"

:: Execute PowerShell script
powershell -ExecutionPolicy Bypass -File "!ps_script!"

:: === Handle Result ===
set "commit_msg="
if exist "!auto_comment_file!" (
    set /p commit_msg=<"!auto_comment_file!"
    :: Clean message: remove quotes and trim
    set "commit_msg=!commit_msg:"=!"
    for /f "tokens=* delims= " %%A in ("!commit_msg!") do set "commit_msg=%%A"
)

:: Fallback if still empty
if "!commit_msg!"=="" (
    echo !COLOR_YELLOW!!ICON_WARN!  API call failed. Using default message.!COLOR_RESET!
    set "commit_msg=Auto-update in AI/ML repository"
) else (
    echo !COLOR_GREEN!!ICON_OK!  Auto-comment generated.!COLOR_RESET!
)

:: Cleanup
del "!diff_file!" 2>nul
del "!auto_comment_file!" 2>nul
del "!ps_script!" 2>nul

:: Confirm Message
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

:: === Commit ===
echo.
echo !COLOR_CYAN!!ICON_STEP!  Committing...!COLOR_RESET!
git commit -m "!commit_msg!" || (
    echo !COLOR_RED!!ICON_FAIL!  Commit failed.!COLOR_RESET!
    endlocal & exit /b 1
)
echo !COLOR_GREEN!!ICON_OK!  Committed with message: !commit_msg!!COLOR_RESET!
echo.

:push_section

:: === Get Current Branch ===
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%B"
if "!CURRENT_BRANCH!"=="" set "CURRENT_BRANCH=(unknown)"

echo.
echo !COLOR_CYAN!┌!SEP_LINE!┐!COLOR_RESET!
echo !COLOR_CYAN!│!COLOR_RESET!  !COLOR_GREEN!Current Git Branch:!COLOR_RESET!             !COLOR_CYAN!│!COLOR_RESET!
echo !COLOR_CYAN!│!COLOR_RESET!      !COLOR_YELLOW![ !CURRENT_BRANCH! ]!COLOR_RESET!              !COLOR_CYAN!│!COLOR_RESET!
echo !COLOR_CYAN!└!SEP_LINE!┘!COLOR_RESET!
echo.

:: === Ask for Branch to Push ===
set /p "branch_input=!COLOR_YELLOW!!ICON_STEP! Enter branch to push [default: !CURRENT_BRANCH!]: !COLOR_RESET!"
set "branch_name=!branch_input!"
if "!branch_name!"=="" set "branch_name=!CURRENT_BRANCH!"

:: === Check Remote ===
echo !COLOR_CYAN!!ICON_STEP!  Checking remote 'origin'...!COLOR_RESET!
git remote get-url origin >nul 2>&1 || (
    echo !COLOR_RED!!ICON_FAIL! Remote 'origin' not configured.!COLOR_RESET!
    echo !COLOR_CYAN!Run: git remote add origin https://github.com/Tanvir-yzu/AI_ML-Expert-With-Phitron-Batch-01.git!COLOR_RESET!
    endlocal & exit /b 1
)
echo !COLOR_GREEN!!ICON_OK!  Remote 'origin' detected.!COLOR_RESET!
echo.

:: === Push ===
echo !COLOR_CYAN!!ICON_STEP! Pushing to origin/!branch_name!...!COLOR_RESET!
git push origin "!branch_name!" || (
    echo !COLOR_RED!!ICON_FAIL! Push failed.!COLOR_RESET!
    endlocal & exit /b 1
)

echo !COLOR_GREEN!!ICON_OK!  Done.!COLOR_RESET!
echo !COLOR_CYAN!┌!SEP_LINE!┐!COLOR_RESET!
echo !COLOR_CYAN!│!COLOR_RESET!  !COLOR_GREEN!✔ Completed!COLOR_RESET!                   !COLOR_CYAN!│!COLOR_RESET!
echo !COLOR_CYAN!└!SEP_LINE!┘!COLOR_RESET!

:: === Optional Success Sound (safe) ===
if exist "%~dp0sounds\success.wav" (
    powershell -NoProfile -Command "(New-Object Media.SoundPlayer '%~dp0sounds\success.wav').PlaySync()" >nul 2>&1
)

endlocal
exit /b 0