# hekate-ext Patches

These patch files contain all custom modifications for hekate-ext.

## Patch Files

**Core OFW Feature:**
- `003-ofw-hos-h.patch` - Add `bool ofw;` field to launch context
- `004-ofw-hos-config.patch` - Add `ofw=1` config handler
- `005-ofw-and-branding-main.patch` - OFW detection logic + branding

**Branding:**
- `006-branding-gui.patch` - Nyx GUI branding changes

**Documentation:**
- `007-ofw-template.patch` - Template.ini OFW example
- `008-readme-docs.patch` - README documentation

**Legacy (old approach):**
- `001-ofw-main.patch` - Old main.c removals only
- `002-ofw-hos.patch` - Old hos.c removals only

## How to Use

After copying new files from upstream hekate:

```bash
# Apply all patches
git apply patches/003-ofw-hos-h.patch
git apply patches/004-ofw-hos-config.patch
git apply patches/005-ofw-and-branding-main.patch
git apply patches/006-branding-gui.patch
git apply patches/007-ofw-template.patch
git apply patches/008-readme-docs.patch

# Or apply in one command:
for patch in patches/00{3..8}*.patch; do git apply "$patch"; done
```

If patches fail, apply manually using the reference in `../CUSTOM_CHANGES.md`

## Updating Patches

To regenerate patches after modifying the changes:

```bash
# Compare against upstream tag (e.g., v6.4.1)
git diff v6.4.1 HEAD -- bootloader/hos/hos.h > patches/003-ofw-hos-h.patch
git diff v6.4.1 HEAD -- bootloader/hos/hos_config.c > patches/004-ofw-hos-config.patch
git diff v6.4.1 HEAD -- bootloader/main.c > patches/005-ofw-and-branding-main.patch
git diff v6.4.1 HEAD -- nyx/nyx_gui/frontend/gui.c > patches/006-branding-gui.patch
git diff v6.4.1 HEAD -- res/hekate_ipl_template.ini > patches/007-ofw-template.patch
git diff v6.4.1 HEAD -- README.md > patches/008-readme-docs.patch
```
