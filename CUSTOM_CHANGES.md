# hekate-ext Custom Changes

This document tracks the custom changes made to hekate for the OFW (Original Firmware) instant boot feature.

## Summary
The OFW feature allows instant reboot to stock firmware by adding `ofw=1` parameter to boot entries, which triggers `REBOOT_BYPASS_FUSES` to bypass fuse checks.

**TL;DR: 8 files modified total:**

**Core OFW Feature (3 files):**
1. `bootloader/hos/hos.h` - Add `bool ofw;` field
2. `bootloader/hos/hos_config.c` - Add config handler for `ofw=1` parameter
3. `bootloader/main.c` - Add OFW detection in 3 boot paths

**Branding (2 files):**
4. `bootloader/main.c` - Update menu title only (credits unchanged)
5. `nyx/nyx_gui/frontend/gui.c` - Change "hekate" to "hekate-ext"

**Documentation (2 files):**
6. `README.md` - Add OFW feature docs
7. `res/hekate_ipl_template.ini` - Add OFW example

**Metadata:**
8. `.github/FUNDING.yml`, `.gitignore`

## Modified Files

### 1. `bootloader/hos/hos.h`
**Changes:**
- Add `bool ofw;` field to `launch_ctxt_t` structure (line ~114)

```c
typedef struct _launch_ctxt_t
{
    bool svcperm;
    bool debugmode;
    bool stock;
    bool ofw;           // ADD THIS
    bool emummc_forced;
    // ...
}
```

### 2. `bootloader/hos/hos_config.c`
**Changes:**
- Add `_config_ofw()` function to parse `ofw=1` parameter
- Register handler in `_config_handlers` array

```c
// Add this function after _config_stock()
static int _config_ofw(launch_ctxt_t *ctxt, const char *value)
{
    if (*value == '1')
    {
        DPRINTF("Direct OFW reboot enabled\n");
        ctxt->ofw = true;
    }
    return 1;
}

// Add to _config_handlers array
static const cfg_handler_t _config_handlers[] = {
    { "stock",            _config_stock },
    { "ofw",              _config_ofw },    // ADD THIS
    { "warmboot",         _config_warmboot },
    // ...
}
```

### 3. `bootloader/main.c`
**Changes (Functional - OFW Feature):**
- Add OFW detection and direct reboot in 3 boot paths (before calling `hos_launch`)
- Bypasses all hekate boot processing when `ofw=1` is detected

**Changes (Cosmetic - Branding):**
- Updated menu title to "hekate-ext vX.X.X"
- **Note:** Credits are kept identical to upstream (not modified)

**Lines affected:**
- Line ~465-471: Removed gfx messages after first ofw_reboot check
- Line ~631-637: Removed gfx messages after second ofw_reboot check
- Line ~1065-1071: Removed gfx messages after third ofw_reboot check
- Line ~1523: Updated menu title to "hekate-ext vX.X.X"

**Keep these patterns:**
```c
if (ofw_reboot)
{
    power_set_state(REBOOT_BYPASS_FUSES);
}
```

**Remove these patterns:**
```c
gfx_con.mute = false;
gfx_clear_grey(0x1B);
gfx_con_setpos(0, 0);
gfx_printf("\nRebooting to 100%% Stock OFW...\n");
msleep(1000);
```

### 2. `bootloader/hos/hos.c`
**Changes:**
- Removed the early OFW check that was moved to main.c (lines ~715-730)
- This was the check that scanned cfg->kvs for "ofw" key

**What was removed:**
```c
// Check for ofw=1 flag early, before any file loading or hardware init.
if (cfg)
{
    LIST_FOREACH_ENTRY(ini_kv_t, kv, &cfg->kvs, link)
    {
        if (!strcmp("ofw", kv->key) && kv->val[0] == '1')
        {
            gfx_con.mute = false;
            gfx_clear_grey(0x1B);
            gfx_con_setpos(0, 0);
            gfx_printf("\nRebooting to 100%% Stock OFW...\n");
            msleep(1000);
            power_set_state(REBOOT_BYPASS_FUSES);
        }
    }
}
```

### 3. Other Files (Version Updates Only)

The following files are updated when merging new hekate versions, but are **NOT part of the OFW feature**:

- **`bootloader/hos/pkg2_patches.inl`** - FS patches refinement (byte-level patching improvement)
- **`nyx/nyx_gui/frontend/gui_info.c`** - Fuse version detection for new firmware
- **`Versions.inc`** - Version numbers matching upstream
- **`.gitignore`** - Build artifacts to ignore

These are just regular upstream updates and don't need special handling.

## Merge Strategy

When merging new upstream versions:

1. **Expect conflicts in:**
   - `bootloader/main.c` - version string and ofw_reboot logic areas
   - `Versions.inc` - version numbers
   - `nyx/nyx_gui/frontend/gui_info.c` - if upstream adds fuse versions

2. **Usually no conflicts:**
   - `bootloader/hos/hos.c` - our removal is stable
   - `bootloader/hos/pkg2_patches.inl` - patches are version-specific, watch for new FS versions

3. **Resolution strategy:**
   - Keep the `ofw_reboot` detection and `power_set_state(REBOOT_BYPASS_FUSES)` calls
   - Remove any gfx notification messages around OFW reboots
   - Update version strings to "hekate-ext vX.X.X"
   - For pkg2_patches, ensure new FS versions follow the single-byte patch pattern

## Testing Checklist

After merging:
- [ ] Build successfully completes
- [ ] Version displays correctly in menu
- [ ] OFW boot works with `ofw=1` parameter
- [ ] Normal CFW boot still works
- [ ] emuMMC boot still works
