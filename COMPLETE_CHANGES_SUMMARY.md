# Complete Changes Summary: hekate-ext vs upstream hekate

Comparing: **hekate-ext v6.4.1** vs **upstream hekate v6.4.1**

---

## 📊 Stats
- **8 files modified**
- **+87 insertions, -14 deletions** in bootloader/main.c
- **+11 insertions** in bootloader/hos/hos_config.c
- **+1 insertion** in bootloader/hos/hos.h
- **Total: ~100 lines of custom code**

---

## 🎯 Core OFW Feature (3 files)

### 1. bootloader/hos/hos.h
**What:** Add `bool ofw;` field to launch context structure

**Why:** Enables the launch context to track when OFW mode is requested

```c
typedef struct _launch_ctxt_t {
    bool ofw;  // ADD THIS LINE (after 'stock')
}
```

---

### 2. bootloader/hos/hos_config.c
**What:** Add config parser for `ofw=1` parameter

**Why:** Parses `ofw=1` from ini files and sets `ctxt->ofw = true`

**Two changes:**
1. Add `_config_ofw()` function (11 lines)
2. Register it in `_config_handlers[]` array (1 line)

---

### 3. bootloader/main.c (Functional Part)
**What:** Add OFW detection in 3 boot paths that bypasses `hos_launch()`

**Why:** When `ofw=1` is detected, skip ALL hekate boot processing and jump straight to `REBOOT_BYPASS_FUSES`

**3 locations where this code is added:**
- Boot path 1: ~line 446 (menu boot)
- Boot path 2: ~line 612 (payload boot)
- Boot path 3: ~line 1046 (autoboot)

**Pattern added at each location:**
```c
// Check for ofw=1 flag and reboot to OFW directly without hos_launch.
bool ofw_reboot = false;
if (cfg_sec)
{
    LIST_FOREACH_ENTRY(ini_kv_t, kv, &cfg_sec->kvs, link)
    {
        if (!strcmp("ofw", kv->key) && kv->val[0] == '1')
        {
            ofw_reboot = true;
            break;
        }
    }
}

if (ofw_reboot)
{
    power_set_state(REBOOT_BYPASS_FUSES);  // Direct reboot, no processing
}
else
{
    hos_launch(cfg_sec);  // Normal boot
}
```

**Result:** True instant OFW boot - no kernel loading, no patching, no kips, just pure reboot

---

## 🎨 Branding (2 files)

### 4. bootloader/main.c (Cosmetic Part)
**What:** Update menu title only

**Changes:**
- Menu title (~line 1523): Change to "hekate-ext v6.4.1"
- **Credits:** Kept identical to upstream (not modified to preserve formatting)

---

### 5. nyx/nyx_gui/frontend/gui.c
**What:** Change Nyx GUI branding from "hekate" to "hekate-ext"

**Changes:**
- Line ~1960: Brand label: `" hekate-ext#"`
- Line ~2343: Version tab: `"hekate-ext %s%d.%d.%d%c"`

---

## 📚 Documentation (2 files)

### 6. README.md
**What:** Add hekate-ext description and `ofw=1` parameter docs

**Changes:**
- Title: "hekate-ext - Nyx"
- Subtitle: "Extended version with instant OFW boot support"
- Boot entry keys table: Add `ofw=1` parameter documentation

---

### 7. res/hekate_ipl_template.ini
**What:** Add example `[100% Stock OFW]` boot entry

**Changes:**
- New section showing how to use `ofw=1`
- Explains: "bypasses ALL hekate boot processing"
- Notes: ~2-3s boot time, doesn't work with AutoRCM on Erista

---

## 🔧 Metadata (2 files)

### 8. .github/FUNDING.yml
**What:** GitHub Sponsors link

---

### 9. .gitignore
**What:** Ignore release markdown files

---

## 🔑 Key Differences: `ofw=1` vs `stock=1`

| Feature | `stock=1` | `ofw=1` |
|---------|-----------|---------|
| **Goes through hos_launch()** | ✅ Yes | ❌ No |
| **Loads kernel** | ✅ Yes | ❌ No |
| **Applies patches** | ✅ Minimal | ❌ None |
| **Loads kips** | ✅ Can load | ❌ None |
| **Boot time** | ~5-7s | ~2-3s |
| **100% stock** | ❌ No (hekate touches it) | ✅ Yes (pure reboot) |
| **Works with AutoRCM (Erista)** | ✅ Yes | ❌ No |
| **emuMMC compatible** | ❌ No | ❌ No |

**Bottom line:** `ofw=1` is for when you need the *fastest, cleanest possible stock boot* (e.g., going online). `stock=1` is for when you need stock but still want some hekate features.

---

## 🚀 Update Workflow

When new hekate version releases:

1. **Copy all files** from upstream
2. **Apply patches:**
   ```bash
   .\update_from_upstream.ps1  # Automated
   ```
3. **Update version string** in main.c
4. **Build & test**
5. **Commit**

See: [QUICK_UPDATE.md](QUICK_UPDATE.md)

---

## 📁 Files Reference

- **[CUSTOM_CHANGES.md](CUSTOM_CHANGES.md)** - Detailed code changes
- **[QUICK_UPDATE.md](QUICK_UPDATE.md)** - Quick update guide
- **[UPDATE_GUIDE.md](UPDATE_GUIDE.md)** - Comprehensive update guide
- **[patches/](patches/)** - All patch files
- **[update_from_upstream.ps1](update_from_upstream.ps1)** - Update automation script

---

Generated: 2025-12-03
