# ⚡ Quick Update Guide

**hekate-ext = 100% hekate + OFW launch feature**

When hekate releases a new version:

## 🚀 Recommended Method (File Copy + Manual Apply)

```powershell
# Run this script:
.\update_from_upstream_simple.ps1
```

The script will:
1. ✓ Auto-update local hekate clone (`D:\Coding\hekate`)
2. ✓ Copy all files to hekate-ext
3. ✓ Create backup branch
4. ✓ Show you exactly what to change (step-by-step)

**Why manual?** Line numbers change between versions, so patches often fail. Manual is faster and more reliable.

## 📋 Manual Steps After Script

1. **Update version strings:**
   ```c
   // bootloader/main.c line ~1523
   menu_t menu_top = { ment_top, "hekate-ext v6.4.2", 0, 0 };
   ```

2. **Verify patches applied** (check these files):
   - [bootloader/main.c](bootloader/main.c) - OFW reboot logic (no gfx messages)
   - [bootloader/hos/hos.c](bootloader/hos/hos.c) - Early OFW check removed

3. **Build & test:**
   ```bash
   make clean && make
   ```

4. **Commit:**
   ```bash
   git add .
   git commit -m "Update to hekate v6.4.2 with OFW feature"
   git push origin main
   ```

## 🆘 Undo If Needed

```bash
# See backups
git branch | findstr backup

# Restore
git reset --hard backup-YYYY-MM-DD
```

## 📚 Detailed Info

- **Full guide:** [UPDATE_GUIDE.md](UPDATE_GUIDE.md)
- **What we changed:** [CUSTOM_CHANGES.md](CUSTOM_CHANGES.md)
- **Patch files:** [patches/](patches/)
