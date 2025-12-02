# hekate-ext Philosophy

## What is hekate-ext?

**hekate-ext = 100% original hekate + ONE feature**

That's it. Nothing more, nothing less.

---

## The One Feature

**OFW Launch from Boot Menu**

Add `ofw=1` to any boot entry to bypass ALL hekate processing and reboot directly to stock firmware.

**Why?**
- Fastest possible stock boot (~2-3s vs ~5-7s with `stock=1`)
- True 100% stock (no hekate kernel/kip loading)
- Perfect for going online or when you need completely clean stock

**How it works:**
- Detects `ofw=1` in boot config
- Calls `power_set_state(REBOOT_BYPASS_FUSES)`
- Skips `hos_launch()` entirely

---

## Minor Cosmetic Changes

**Menu/GUI Labels:**
- "hekate" → "hekate-ext" (so users know which version they're using)

**Credits:**
- **NOT MODIFIED** - kept 100% identical to upstream
- Preserves original formatting and attribution

---

## What We Don't Do

❌ Add extra features
❌ Modify hekate's core functionality
❌ Change credits or claim original work
❌ Fork and diverge from upstream

We stay as close to upstream as possible.

---

## Files Modified (Total: 8)

### Core Feature (3 files)
1. `bootloader/hos/hos.h` - Add `bool ofw;` field
2. `bootloader/hos/hos_config.c` - Parse `ofw=1` parameter
3. `bootloader/main.c` - OFW detection logic in 3 boot paths

### Branding (2 files)
4. `bootloader/main.c` - Menu title: "hekate-ext vX.X.X"
5. `nyx/nyx_gui/frontend/gui.c` - GUI labels

### Documentation (2 files)
6. `README.md` - OFW feature description
7. `res/hekate_ipl_template.ini` - OFW usage example

### Metadata (2 files)
8. `.github/FUNDING.yml`, `.gitignore`

**Total code added:** ~100 lines
**Complexity:** Low
**Maintenance:** Easy - applies cleanly to new hekate versions

---

## Update Strategy

When new hekate version releases:

1. Copy all files from upstream
2. Apply patches (automated)
3. Update version string
4. Done!

See: [QUICK_UPDATE.md](QUICK_UPDATE.md)

---

## Design Principles

1. **Minimal changes** - Only add what's necessary
2. **Preserve upstream** - Keep 100% compatibility
3. **Easy updates** - Should merge cleanly with new versions
4. **Respect attribution** - Don't modify original credits
5. **Single purpose** - One feature, done well

---

hekate-ext exists for ONE reason: instant OFW boot from the menu.

Everything else is just hekate.
