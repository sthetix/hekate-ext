@echo off
REM Script to update hekate-ext from upstream hekate
REM This script helps merge new hekate versions while preserving OFW feature

echo ========================================
echo Updating hekate-ext from upstream
echo ========================================
echo.

REM Fetch latest upstream changes
echo [1/5] Fetching latest upstream changes...
git fetch upstream
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to fetch upstream
    pause
    exit /b 1
)

REM Show available tags/versions
echo.
echo Available upstream versions:
git tag --list --sort=-v:refname | findstr /R "^v[0-9]" | head -10
echo.

REM Ask which version to merge
set /p VERSION="Enter version to merge (e.g., v6.4.2): "

echo.
echo [2/5] Creating backup branch...
git branch backup-before-%VERSION% 2>nul
echo Backup created: backup-before-%VERSION%

echo.
echo [3/5] Attempting to merge %VERSION%...
git merge %VERSION% -m "Merge upstream %VERSION%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Merge completed without conflicts!
    echo.
    echo [4/5] Updating version strings...
    REM Update menu version in main.c
    REM You'll need to manually check this

    echo.
    echo [5/5] Next steps:
    echo 1. Review changes: git diff HEAD~1
    echo 2. Test build: make clean ^&^& make
    echo 3. Update version in bootloader/main.c if needed
    echo 4. Commit: git add . ^&^& git commit --amend
    echo.
) else (
    echo.
    echo [CONFLICTS DETECTED]
    echo.
    echo The merge has conflicts that need manual resolution.
    echo Common conflict files:
    echo   - bootloader/main.c (OFW reboot logic)
    echo   - bootloader/hos/hos.c (OFW check removal)
    echo   - Versions.inc (version numbers)
    echo.
    echo To resolve:
    echo 1. git status  (see conflicted files)
    echo 2. Edit each file to resolve conflicts
    echo 3. git add ^<file^>  (mark as resolved)
    echo 4. git merge --continue
    echo.
    echo To abort merge:
    echo   git merge --abort
    echo   git checkout main
    echo.
)

pause
