# hekate-ext Simple Update Script
# This script ONLY copies files and shows you what to do next
# Manual changes required - patches may fail due to line number changes

param(
    [string]$HekatePath = "D:\Coding\hekate"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "hekate-ext Simple Update Helper" -ForegroundColor Cyan
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
Write-Host "[Step 1/4] Updating local hekate repository..." -ForegroundColor Cyan
Push-Location $HekatePath
git fetch origin 2>&1 | Out-Null
$currentBranch = git rev-parse --abbrev-ref HEAD
git pull origin $currentBranch 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Local hekate updated to latest" -ForegroundColor Green
} else {
    Write-Host "  ! Could not update (continuing with current version)" -ForegroundColor Yellow
}

# Get version from upstream
$upstreamVersion = (git describe --tags 2>$null)
if (-not $upstreamVersion) {
    $upstreamVersion = "unknown"
}
Pop-Location

Write-Host "`n[Step 2/4] Version Information" -ForegroundColor Cyan
Write-Host "  Current hekate-ext: " -NoNewline -ForegroundColor Gray
Select-String -Path "bootloader\main.c" -Pattern 'menu_t menu_top.*"hekate-ext v' |
    ForEach-Object { $_ -match 'v([\d\.]+)'; Write-Host "v$($matches[1])" -ForegroundColor Yellow }

Write-Host "  Upstream hekate:    " -NoNewline -ForegroundColor Gray
Write-Host "$upstreamVersion`n" -ForegroundColor Yellow

$continue = Read-Host "Continue with update? (y/n)"
if ($continue -ne 'y') {
    Write-Host "`nUpdate cancelled." -ForegroundColor Yellow
    exit 0
}

# Create backup
Write-Host "`n[Step 3/4] Creating backup..." -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$branchName = "backup-$timestamp"

try {
    git branch $branchName 2>$null
    Write-Host "  ✓ Backup branch: $branchName" -ForegroundColor Green
} catch {
    Write-Host "  ! Could not create backup branch" -ForegroundColor Yellow
}

# Copy files
Write-Host "`n[Step 4/4] Copying files from upstream..." -ForegroundColor Cyan

$directories = @("bootloader", "nyx", "bdk")
foreach ($dir in $directories) {
    Write-Host "  Copying $dir..." -ForegroundColor Gray -NoNewline
    robocopy "$HekatePath\$dir" "$dir" /E /XD .git /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -le 7) {
        Write-Host " ✓" -ForegroundColor Green
    }
}

Write-Host "  Copying root files..." -ForegroundColor Gray -NoNewline
Copy-Item "$HekatePath\Makefile" "Makefile" -Force
Copy-Item "$HekatePath\Versions.inc" "Versions.inc" -Force
Write-Host " ✓`n" -ForegroundColor Green

# Summary and instructions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FILES COPIED - MANUAL CHANGES NEEDED" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Now you need to manually apply the OFW feature:`n" -ForegroundColor White

Write-Host "1. Add OFW field to launch context:" -ForegroundColor Cyan
Write-Host "   File: " -NoNewline -ForegroundColor Gray
Write-Host "bootloader/hos/hos.h" -ForegroundColor White
Write-Host "   Find: " -NoNewline -ForegroundColor Gray
Write-Host "bool stock;" -ForegroundColor White
Write-Host "   Add after it: " -NoNewline -ForegroundColor Gray
Write-Host "bool ofw;`n" -ForegroundColor White

Write-Host "2. Add OFW config handler:" -ForegroundColor Cyan
Write-Host "   File: " -NoNewline -ForegroundColor Gray
Write-Host "bootloader/hos/hos_config.c" -ForegroundColor White
Write-Host "   Copy the _config_ofw() function from CUSTOM_CHANGES.md" -ForegroundColor Gray
Write-Host "   Add to handlers array after 'stock'`n" -ForegroundColor Gray

Write-Host "3. Add OFW detection in main.c (3 locations):" -ForegroundColor Cyan
Write-Host "   File: " -NoNewline -ForegroundColor Gray
Write-Host "bootloader/main.c" -ForegroundColor White
Write-Host "   Search for: " -NoNewline -ForegroundColor Gray
Write-Host "hos_launch(cfg_sec);" -ForegroundColor White
Write-Host "   Replace each with OFW check (see CUSTOM_CHANGES.md)" -ForegroundColor Gray
Write-Host "   There are 3 locations to update`n" -ForegroundColor Yellow

Write-Host "4. Update menu title:" -ForegroundColor Cyan
Write-Host "   File: " -NoNewline -ForegroundColor Gray
Write-Host "bootloader/main.c" -ForegroundColor White
Write-Host "   Find: " -NoNewline -ForegroundColor Gray
Write-Host 'menu_t menu_top = { ment_top, "hekate v' -ForegroundColor White
Write-Host "   Change to: " -NoNewline -ForegroundColor Gray
Write-Host '"hekate-ext v' -NoNewline -ForegroundColor White
Write-Host $upstreamVersion.TrimStart('v') -NoNewline -ForegroundColor Yellow
Write-Host '"' -ForegroundColor White
Write-Host ""

Write-Host "5. Update GUI branding:" -ForegroundColor Cyan
Write-Host "   File: " -NoNewline -ForegroundColor Gray
Write-Host "nyx/nyx_gui/frontend/gui.c" -ForegroundColor White
Write-Host "   Search/replace: " -NoNewline -ForegroundColor Gray
Write-Host '"hekate"' -NoNewline -ForegroundColor White
Write-Host " → " -NoNewline -ForegroundColor Gray
Write-Host '"hekate-ext"' -ForegroundColor White
Write-Host "   (2 locations)`n" -ForegroundColor Gray

Write-Host "6. Update documentation:" -ForegroundColor Cyan
Write-Host "   File: " -NoNewline -ForegroundColor Gray
Write-Host "README.md" -ForegroundColor White
Write-Host "   Add OFW parameter docs (see CUSTOM_CHANGES.md)" -ForegroundColor Gray
Write-Host ""
Write-Host "   File: " -NoNewline -ForegroundColor Gray
Write-Host "res/hekate_ipl_template.ini" -ForegroundColor White
Write-Host "   Add [100% Stock OFW] section (see CUSTOM_CHANGES.md)`n" -ForegroundColor Gray

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REFERENCE DOCUMENTATION" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "  CUSTOM_CHANGES.md  - " -NoNewline -ForegroundColor Gray
Write-Host "Detailed code examples for all changes" -ForegroundColor White
Write-Host "  PHILOSOPHY.md      - " -NoNewline -ForegroundColor Gray
Write-Host "Why hekate-ext exists" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AFTER MAKING CHANGES" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "1. Review what changed:" -ForegroundColor White
Write-Host "   git status" -ForegroundColor Gray
Write-Host "   git diff`n" -ForegroundColor Gray

Write-Host "2. Test build:" -ForegroundColor White
Write-Host "   make clean && make`n" -ForegroundColor Gray

Write-Host "3. Regenerate patches for next time:" -ForegroundColor White
Write-Host "   git diff $upstreamVersion HEAD -- bootloader/hos/hos.h > patches/003-ofw-hos-h.patch" -ForegroundColor Gray
Write-Host "   git diff $upstreamVersion HEAD -- bootloader/hos/hos_config.c > patches/004-ofw-hos-config.patch" -ForegroundColor Gray
Write-Host "   git diff $upstreamVersion HEAD -- bootloader/main.c > patches/005-ofw-and-branding-main.patch" -ForegroundColor Gray
Write-Host "   git diff $upstreamVersion HEAD -- nyx/nyx_gui/frontend/gui.c > patches/006-branding-gui.patch" -ForegroundColor Gray
Write-Host "   git diff $upstreamVersion HEAD -- res/hekate_ipl_template.ini > patches/007-ofw-template.patch" -ForegroundColor Gray
Write-Host "   git diff $upstreamVersion HEAD -- README.md > patches/008-readme-docs.patch`n" -ForegroundColor Gray

Write-Host "4. Commit:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Update to hekate $upstreamVersion with OFW feature'" -ForegroundColor Gray
Write-Host "   git push origin main`n" -ForegroundColor Gray

Write-Host "5. If something went wrong:" -ForegroundColor White
Write-Host "   git reset --hard $branchName`n" -ForegroundColor Gray

Write-Host "========================================`n" -ForegroundColor Cyan
