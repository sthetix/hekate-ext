# Update Guide for hekate-ext

This guide explains how to update hekate-ext when new versions of the original hekate are released.

## Overview

hekate-ext is based on the original hekate by CTCaer with:
- **OFW instant boot functionality** - Bypasses all hekate processing for fastest stock firmware boot
- **Lockpick_RCM_Pro integration** - Uses Lockpick_RCM_Pro instead of Lockpick_RCM
- **hekate-ext branding** - Distinguishes it as an unofficial extended version
- **Dual 4GB/8GB RAM support** - Automated release builds for both Switch variants
- **Warmboot Extractor** - Extracts and saves warmboot binaries for Atmosphere on Mariko

---

## Recommended: Automated Update Script

Run the update script to automatically apply all patches:

```bash
python update_hekate.py <path-to-new-hekate>
```

This script:
1. Copies new hekate files (bootloader/, bdk/, nyx/, etc.)
2. Applies OFW patch to `bootloader/hos/hos_config.c` (single handler + table entry)
3. Patches hekate-ext branding (version, tagline, button label)
4. Patches Lockpick_RCM_Pro references
5. Adds `fuses` field to nyx pkg1_ids table

After running the script, build manually:
```bash
make release
```

---

## Manual Update (Alternative)

If the script fails or you prefer manual control, follow the steps below.

### Files Modified

| # | File | Purpose |
|---|------|---------|
| 1 | `bootloader/hos/hos_config.c` | OFW handler (1 function + 1 table entry) |
| 2 | `nyx/nyx_gui/frontend/gui.c` | Branding (version tag + tagline) |
| 3 | `nyx/nyx_gui/frontend/gui_info.c` | Lockpick_RCM_Pro |
| 4 | `nyx/nyx_gui/hos/pkg1.h` | Add `fuses` field to pkg1_id_t |
| 5 | `nyx/nyx_gui/hos/pkg1.c` | Add `fuses` values to pkg1_ids table |
| 6 | `nyx/Makefile` | Add warmboot_tools and gui_warmboot objects |
| 7 | `res/hekate_ipl_template.ini` | OFW boot entry |
| 8 | `res/patches_template.ini` | Lockpick_RCM_Pro entry |

**IMPORTANT: Credits are NOT a file modification - always use original hekate credits!**

---

### 1. `bootloader/hos/hos_config.c` - OFW Feature

Add the handler function before `_config_ucid`:

```c
static int _config_ofw(launch_ctxt_t *ctxt, const char *value)
{
	if (*value == '1')
	{
		power_set_state(REBOOT_BYPASS_FUSES);
		while (true)
			bpmp_halt();
	}
	return 0;
}
```

Register it in `_config_handlers[]` before `{ NULL, NULL }`:

```c
	{ "ofw",              _config_ofw },
	{ NULL, NULL },
```

No changes to `bootloader/main.c` are needed.

### 2. `nyx/nyx_gui/frontend/gui.c` - Branding

**Tagline** (change):
```c
// From:
"THE ALL IN ONE BOOTLOADER FOR ALL YOUR NEEDS"
// To:
"THE UNOFFICIAL ALL IN ONE BOOTLOADER FOR ALL YOUR NEEDS"
```

**Button label** (change):
```c
// From:
" hekate#"
// To:
" hekate-ext#"
```

**Version tag** (change):
```c
// From:
"hekate %s%d.%d.%d%c"
// To:
"hekate-ext %s%d.%d.%d%c"
```

### 3. `nyx/nyx_gui/frontend/gui_info.c` - Lockpick_RCM_Pro

Replace all occurrences:
```c
// From:
"Lockpick_RCM.bin"
"bootloader/payloads/Lockpick_RCM.bin"

// To:
"Lockpick_RCM_Pro.bin"
"bootloader/payloads/Lockpick_RCM_Pro.bin"
```

Also update the error message:
```
bootloader/payloads/Lockpick_RCM.bin is missing
-> bootloader/payloads/Lockpick_RCM_Pro.bin is missing
```

### 4. `nyx/nyx_gui/hos/pkg1.h` - Add fuses field

Add `fuses` field to `pkg1_id_t` struct (after `mkey`):
```c
typedef struct _pkg1_id_t
{
	const char *id;
	u16 mkey;
	u16 fuses;  // ADD THIS LINE
	u16 tsec_off;
	u32 pkg11_off;
	u32 secmon_base;
	u32 warmboot_base;
} pkg1_id_t;
```

### 5. `nyx/nyx_gui/hos/pkg1.c` - Add fuses values

Update the `_pkg1_ids[]` table to include the `fuses` column:

```c
// Update header comment:
 // Timestamp  MK   FU  TSEC    PK11     SECMON     Warmboot

// Add fuses value (2nd number) to each entry:
{ "20161121",  0,  1, 0x1900, 0x3FE0, 0x40014020, 0x8000D000 }, // 1.0.0.
{ "20170210",  0,  2, 0x1900, 0x3FE0, 0x4002D000, 0x8000D000 }, // 2.0.0 - 2.3.0.
... (add fuses value for all entries)
{ "20260123", 21, 23, 0x0E00, 0x6FE0, 0x40030000, 0x4003E000 }, // 22.0.0+
```

### 6. `nyx/Makefile` - Add warmboot tools

Add to the OBJS line:
```makefile
# Main and graphics.
OBJS =  start exception_handlers nyx heap gfx \
		gui gui_info gui_tools gui_options gui_emmc_tools gui_emummc_tools gui_tools_partition_manager gui_warmboot \
		fe_emummc_tools fe_emmc_tools \
		warmboot_tools
```

### 7. `res/hekate_ipl_template.ini` - OFW Entry

Add after the [Stock] section:
```ini
[100% Stock OFW]
ofw=1

# This is a true 100% stock firmware boot.
# It bypasses ALL hekate boot processing for the fastest possible stock boot.
# Perfect for online play or when you need completely clean stock firmware.
# Boot time: ~2-3 seconds.
# Note: This only works on units without AutoRCM enabled or Mariko units.
```

### 8. `res/patches_template.ini` - Lockpick_RCM_Pro

Update the Lockpick entry:
```ini
[Lockpick_RCM_Pro]
payload=Lockpick_RCM_Pro.bin
```

---

## Build Commands

```bash
# Clean build
make clean

# Build 4GB variant (default)
make

# Build 8GB variant
make DRAM_8GB=1

# Build both variants
make all-both

# Create release packages (both 4GB and 8GB zips)
make release
```

---

## Key Differences from Original hekate

1. **OFW Boot** - `ofw=1` in ini entry triggers `REBOOT_BYPASS_FUSES` via `_config_ofw` handler in `hos_config.c`
2. **Branding** - "hekate-ext" instead of "hekate" in GUI
3. **Tagline** - "THE UNOFFICIAL ALL IN ONE BOOTLOADER FOR ALL YOUR NEEDS"
4. **Lockpick** - Uses "Lockpick_RCM_Pro.bin" instead of "Lockpick_RCM.bin"
5. **DRAM Support** - `CONFIG_DRAM_8GB` flag for 8GB RAM Switch models

---

## Troubleshooting

**Build fails with "memory_map.h: No such file or directory":**
- Verify `BDKINC := -I../$(BDKDIR)` in loader/Makefile
- Ensure bdk/memory_map.h exists

**Make release fails with zip error:**
- Verify the zip command changes to the correct directory
- Use `cd release/hekate-ext-$(VERSION)-XGB && zip -r ../hekate-ext-$(VERSION)-XGB.zip .`

**OFW not working:**
- Verify `_config_ofw` handler exists in `bootloader/hos/hos_config.c`
- Verify `{ "ofw", _config_ofw }` is in `_config_handlers[]`
- Check that `REBOOT_BYPASS_FUSES` is defined in bdk/power/max7762x.h or similar
- If upstream renamed `_config_ucid`, update the anchor in `update_hekate.py`

**Version shows "hekate" instead of "hekate-ext":**
- Check bootloader/main.c menu title
- Check nyx/nyx_gui/frontend/gui.c version string

---

## Example Update Session (Manual)

```bash
# 1. Backup current version
cp -r hekate-ext hekate-ext-backup

# 2. Copy files from upstream hekate
robocopy d:\Coding\hekate d:\Coding\hekate-ext /E /XD .git .github .vscode release /XF .gitignore

# 3. Apply modifications (see Files Modified section above)

# 4. Build and test
cd d:\Coding\hekate-ext
make clean
make release

# 5. Verify outputs
ls -lh release/
```

---

## Notes for Future Updates

1. **Always run `update_hekate.py`** first - it handles most patches automatically
2. **Manual patches** may still be needed if upstream code structure changes significantly
3. **Version format** - Nyx version (e.g., 1.9.0) is separate from hekate version (e.g., 6.5.0)
4. **DRAM configuration** - The 8GB flag only affects hekate payload, not nyx or modules
5. **Lockpick updates** - Check if Lockpick_RCM_Pro is still the correct filename on updates
