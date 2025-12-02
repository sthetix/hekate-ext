# hekate-ext Update Script
# Updates hekate-ext by copying files from upstream and applying OFW patches

param(
    [string]$HekatePath = "D:\Coding\hekate"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "hekate-ext Update Helper" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if source exists, clone if not
if (-not (Test-Path $HekatePath)) {
    Write-Host "Hekate directory not found at: $HekatePath" -ForegroundColor Yellow
    Write-Host "Cloning from GitHub...`n" -ForegroundColor Cyan

    $parentDir = Split-Path $HekatePath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    git clone https://github.com/CTCaer/hekate.git $HekatePath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to clone hekate repository" -ForegroundColor Red
        exit 1
    }
    Write-Host "Clone complete!`n" -ForegroundColor Green
}

# Update local hekate clone
Write-Host "Source: $HekatePath" -ForegroundColor Gray
Write-Host "Target: $PWD`n" -ForegroundColor Gray

Write-Host "Updating local hekate repository..." -ForegroundColor Cyan
Push-Location $HekatePath
git fetch origin 2>&1 | Out-Null
$currentBranch = git rev-parse --abbrev-ref HEAD
git pull origin $currentBranch 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Local hekate updated to latest version" -ForegroundColor Green
} else {
    Write-Host "  Warning: Could not update local hekate (continuing with current version)" -ForegroundColor Yellow
}
Pop-Location

Write-Host ""

# Show versions
Write-Host "Current versions:" -ForegroundColor Yellow
Write-Host "`nhekate-ext version:" -ForegroundColor Gray
Select-String -Path "bootloader\main.c" -Pattern "hekate-ext v" | Select-Object -First 1 | ForEach-Object { Write-Host $_.Line.Trim() }

Write-Host "`nUpstream hekate version:" -ForegroundColor Gray
Select-String -Path "$HekatePath\bootloader\main.c" -Pattern "hekate v" | Select-Object -First 1 | ForEach-Object { Write-Host $_.Line.Trim() }

Write-Host ""
$continue = Read-Host "Continue with update? (y/n)"
if ($continue -ne 'y') {
    Write-Host "Update cancelled." -ForegroundColor Yellow
    exit 0
}

# Step 1: Backup
Write-Host "`n[1/5] Creating backup..." -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$branchName = "backup-$timestamp"

try {
    git branch $branchName 2>$null
    Write-Host "Backup branch created: $branchName" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not create backup branch" -ForegroundColor Yellow
}

# Step 2: Stash changes
Write-Host "`n[2/5] Stashing current changes..." -ForegroundColor Cyan
git stash push -m "Before upstream update $timestamp" 2>$null

# Step 3: Copy files
Write-Host "`n[3/5] Copying files from upstream hekate..." -ForegroundColor Cyan

$directories = @("bootloader", "nyx", "bdk")
foreach ($dir in $directories) {
    Write-Host "  Copying $dir..." -ForegroundColor Gray
    robocopy "$HekatePath\$dir" "$dir" /E /XD .git /NFL /NDL /NJH /NJS /NP | Out-Null
}

Write-Host "  Copying root files..." -ForegroundColor Gray
Copy-Item "$HekatePath\Makefile" "Makefile" -Force
Copy-Item "$HekatePath\Versions.inc" "Versions.inc" -Force

Write-Host "Files copied successfully." -ForegroundColor Green

# Step 4: Apply patches
Write-Host "`n[4/5] Applying OFW patches...`n" -ForegroundColor Cyan

$patches = @(
    "003-ofw-hos-h.patch",
    "004-ofw-hos-config.patch",
    "005-ofw-and-branding-main.patch",
    "006-branding-gui.patch",
    "007-ofw-template.patch",
    "008-readme-docs.patch"
)

$allSuccess = $true
$failedPatches = @()

foreach ($patch in $patches) {
    try {
        git apply "patches\$patch" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Applied $patch" -ForegroundColor Green
        } else {
            throw "Patch failed"
        }
    } catch {
        Write-Host "  [FAIL] Could not apply $patch" -ForegroundColor Red
        $allSuccess = $false
        $failedPatches += $patch
    }
}

# Step 5: Summary
Write-Host "`n[5/5] Update Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Files updated from: $HekatePath`n" -ForegroundColor Green

Write-Host "NEXT STEPS:`n" -ForegroundColor Yellow

Write-Host "1. Review changes:" -ForegroundColor White
Write-Host "   git status" -ForegroundColor Gray
Write-Host "   git diff`n" -ForegroundColor Gray

if (-not $allSuccess) {
    Write-Host "2. MANUAL FIXES NEEDED:" -ForegroundColor Red
    Write-Host "   - See CUSTOM_CHANGES.md for reference" -ForegroundColor Gray
    Write-Host "   - Failed patches:" -ForegroundColor Gray
    foreach ($patch in $failedPatches) {
        Write-Host "     * $patch" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "3. Update version strings:" -ForegroundColor White
Write-Host "   - Edit bootloader/main.c line ~1523" -ForegroundColor Gray
Write-Host "   - Update to: 'hekate-ext vX.X.X'`n" -ForegroundColor Gray

Write-Host "4. Build and test:" -ForegroundColor White
Write-Host "   make clean && make`n" -ForegroundColor Gray

Write-Host "5. Commit when ready:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Update to hekate vX.X.X with OFW feature'" -ForegroundColor Gray
Write-Host "   git push origin main`n" -ForegroundColor Gray

Write-Host "6. If something went wrong:" -ForegroundColor White
Write-Host "   git reset --hard HEAD" -ForegroundColor Gray
Write-Host "   git stash pop" -ForegroundColor Gray
Write-Host "   # Or: git reset --hard $branchName`n" -ForegroundColor Gray

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  - QUICK_UPDATE.md" -ForegroundColor Gray
Write-Host "  - CUSTOM_CHANGES.md" -ForegroundColor Gray
Write-Host "  - UPDATE_GUIDE.md (detailed)" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan
