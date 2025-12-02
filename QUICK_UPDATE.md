# ⚡ Quick Update Guide

**hekate-ext = 100% hekate + OFW launch feature**

When hekate releases a new version:

## 🚀 Fastest Method (File Copy + Auto Patch)

```bash
# Just run this:
update_from_upstream_copy.bat
```

That's it! The script will:
1. ✓ Backup your work
2. ✓ Copy files from `D:\Coding\hekate`
3. ✓ Auto-apply OFW patches
4. ✓ Tell you what needs manual fixing

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
