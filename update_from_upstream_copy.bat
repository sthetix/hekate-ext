@echo off
REM Script to update hekate-ext by copying files from upstream hekate
REM This script helps copy new files and reapply OFW patches

echo ========================================
echo hekate-ext Update Helper (File Copy)
echo ========================================
echo.

REM Check if upstream hekate path is provided
set HEKATE_PATH=D:\Coding\hekate
if not "%1"=="" set HEKATE_PATH=%1

if not exist "%HEKATE_PATH%" (
    echo ERROR: Hekate directory not found: %HEKATE_PATH%
    echo.
    echo Usage: update_from_upstream_copy.bat [path-to-hekate]
    pause
    exit /b 1
)

echo Source: %HEKATE_PATH%
echo Target: %CD%
echo.

REM Show current versions
echo Current versions:
echo.
echo hekate-ext version:
findstr "hekate-ext v" bootloader\main.c
echo.
echo Upstream hekate version:
findstr "hekate v" "%HEKATE_PATH%\bootloader\main.c"
echo.

set /p CONTINUE="Continue with update? (y/n): "
if /i not "%CONTINUE%"=="y" (
    echo Update cancelled.
    pause
    exit /b 0
)

echo.
echo [1/5] Creating backup...
git branch backup-%DATE:/=-%_%TIME::=-% 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Backup branch created successfully
) else (
    echo Warning: Could not create backup branch
)

echo.
echo [2/5] Stashing current changes...
git stash push -m "Before upstream update %DATE% %TIME%"

echo.
echo [3/5] Copying files from upstream hekate...

REM Copy main directories (preserving structure)
echo Copying bootloader...
robocopy "%HEKATE_PATH%\bootloader" "bootloader" /E /XD .git /NFL /NDL /NJH /NJS
echo Copying nyx...
robocopy "%HEKATE_PATH%\nyx" "nyx" /E /XD .git /NFL /NDL /NJH /NJS
echo Copying bdk...
robocopy "%HEKATE_PATH%\bdk" "bdk" /E /XD .git /NFL /NDL /NJH /NJS

REM Copy root files
copy /Y "%HEKATE_PATH%\Makefile" "Makefile" >nul 2>&1
copy /Y "%HEKATE_PATH%\Versions.inc" "Versions.inc" >nul 2>&1

echo Files copied successfully.

echo.
echo [4/5] Applying OFW patches...
echo.

REM Try to apply patches
git apply patches\001-ofw-main.patch 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Applied 001-ofw-main.patch
) else (
    echo [FAIL] Could not apply 001-ofw-main.patch - manual fix needed
)

git apply patches\002-ofw-hos.patch 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Applied 002-ofw-hos.patch
) else (
    echo [FAIL] Could not apply 002-ofw-hos.patch - manual fix needed
)

echo.
echo [5/5] Update Summary
echo ========================================
echo.
echo Files updated from: %HEKATE_PATH%
echo.
echo NEXT STEPS:
echo.
echo 1. Review changes:
echo    git status
echo    git diff
echo.
echo 2. Manual fixes needed:
echo    - See CUSTOM_CHANGES.md for reference
echo    - Update version in bootloader/main.c menu_top
echo    - Update Versions.inc if needed
echo    - Fix any failed patches manually
echo.
echo 3. Build and test:
echo    make clean ^&^& make
echo.
echo 4. Commit when ready:
echo    git add .
echo    git commit -m "Update to hekate vX.X.X with OFW feature"
echo.
echo 5. If something went wrong:
echo    git reset --hard HEAD
echo    git stash pop
echo.

pause
