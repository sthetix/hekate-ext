#!/usr/bin/env python3
"""
hekate-ext Update Script
========================
Updates hekate-ext to a new hekate version with minimal friction.

Usage:
    python update_hekate.py <path-to-new-hekate> [--build]

What it does:
1. Copies new hekate files (bootloader/, bdk/, nyx/, etc.)
2. Applies OFW patch to bootloader/hos/hos_config.c (single handler function + table entry)
3. Patches branding in nyx GUI
4. Patches Lockpick_RCM_Pro references
5. Adds warmboot tools (gui_warmboot, warmboot_tools) to Makefile and restores custom files
6. Adds OFW boot entry to hekate_ipl_template.ini

After running, build manually:
    make release
"""

import sys
import os
import shutil
import re
import argparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Folders to copy from upstream hekate
COPY_FOLDERS = [
    "bootloader",
    "bdk",
    "nyx",
    "loader",
    "modules",
    "tools",
]

# Files to copy individually
COPY_FILES = [
    "Versions.inc",
    "README.md",
    "README_BOOTLOGO.md",
    "LICENSE",
]

# ============================================================================
# CUSTOM FILES - preserved across updates
# These exist in hekate-ext but not upstream hekate.
# ============================================================================
HEKATE_EXT_CUSTOM_FILES = [
    # Warmboot extractor (hekate-ext custom feature)
    "nyx/nyx_gui/frontend/gui_warmboot.c",
    "nyx/nyx_gui/frontend/gui_warmboot.h",
    "nyx/nyx_gui/warmboot_tools.c",
    "nyx/nyx_gui/warmboot_tools.h",
]


# ============================================================================
# OFW PATCH - applied to bootloader/hos/hos_config.c
# Adds a single _config_ofw handler and registers it in _config_handlers[].
# ============================================================================

OFW_HANDLER = """\
static int _config_ofw(launch_ctxt_t *ctxt, const char *value)
{
\tif (*value == '1')
\t{
\t\tpower_set_state(REBOOT_BYPASS_FUSES);
\t\twhile (true)
\t\t\tbpmp_halt();
\t}
\treturn 0;
}

"""

def patch_hos_config(filepath):
    """Add _config_ofw handler to bootloader/hos/hos_config.c"""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    if "_config_ofw" in content:
        return 0  # Already patched

    if "static int _config_ucid" not in content:
        return -1  # Anchor not found

    # Insert handler function before _config_ucid
    content = content.replace(
        "static int _config_ucid",
        OFW_HANDLER + "static int _config_ucid"
    )

    # Register in handler table before { NULL, NULL }
    content = content.replace(
        '\t{ NULL, NULL },',
        '\t{ "ofw",              _config_ofw },\n\t{ NULL, NULL },'
    )

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    return 1


# ============================================================================
# BRANDING PATCHES
# ============================================================================

def apply_branding_patch(content):
    """Patch hekate-ext branding"""
    original = content
    changes = 0

    # Patch tagline
    if '"THE ALL IN ONE BOOTLOADER FOR ALL YOUR NEEDS"' in content:
        content = content.replace(
            '"THE ALL IN ONE BOOTLOADER FOR ALL YOUR NEEDS"',
            '"THE UNOFFICIAL ALL IN ONE BOOTLOADER FOR ALL YOUR NEEDS"'
        )
        changes += 1

    # Patch button label
    if '" hekate#"' in content:
        content = content.replace('" hekate#"', '" hekate-ext#"')
        changes += 1

    # Patch version string
    if re.search(r'"hekate-ext? %s%d\\.\\d\\.\\d', content):
        pass  # Already patched

    content = re.sub(
        r'(s_printf\(version,\s*")hekate( %s%d\\.\\d\\.\\d%c",)',
        r'\1hekate-ext\2',
        content
    )
    if '"hekate-ext %s%d.%d.%d%c"' in content:
        changes += 1

    return content, changes


def apply_lockpick_patch(content):
    """Patch Lockpick_RCM -> Lockpick_RCM_Pro"""
    original = content
    changes = 0

    if '"Lockpick_RCM.bin"' in content:
        content = content.replace('"Lockpick_RCM.bin"', '"Lockpick_RCM_Pro.bin"')
        changes += 1

    if '"bootloader/payloads/Lockpick_RCM.bin"' in content:
        content = content.replace(
            '"bootloader/payloads/Lockpick_RCM.bin"',
            '"bootloader/payloads/Lockpick_RCM_Pro.bin"'
        )
        changes += 1

    if 'bootloader/payloads/Lockpick_RCM.bin is missing' in content:
        content = content.replace(
            'bootloader/payloads/Lockpick_RCM.bin is missing',
            'bootloader/payloads/Lockpick_RCM_Pro.bin is missing'
        )
        changes += 1

    return content, changes


# ============================================================================
# NYX MAKEFILE - Add warmboot tools to OBJS
# ============================================================================

def patch_nyx_makefile(filepath):
    """Add gui_warmboot and warmboot_tools to nyx Makefile OBJS"""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    # Check if already patched
    if "gui_warmboot" in content and "warmboot_tools" in content:
        return False

    # Add to the main OBJS line (after gui_tools_partition_manager, before fe_emummc_tools)
    old_objs = "gui gui_info gui_tools gui_options gui_emmc_tools gui_emummc_tools gui_tools_partition_manager \\\n\t\tfe_emummc_tools fe_emmc_tools"
    new_objs = "gui gui_info gui_tools gui_options gui_emmc_tools gui_emummc_tools gui_tools_partition_manager gui_warmboot \\\n\t\tfe_emummc_tools fe_emmc_tools \\\n\t\twarmboot_tools"

    if old_objs in content:
        content = content.replace(old_objs, new_objs)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        return True

    return False


# ============================================================================
# INI TEMPLATE - Add OFW boot entry
# ============================================================================

def patch_ini_template(filepath):
    """Add OFW entry to hekate_ipl_template.ini"""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    ofw_entry = """[100% Stock OFW]
ofw=1

# This is a true 100% stock firmware boot.
# It bypasses ALL hekate boot processing for the fastest possible stock boot.
# Perfect for online play or when you need completely clean stock firmware.
# Boot time: ~2-3 seconds.
# Note: This only works on units without AutoRCM enabled or Mariko units.
"""

    if "[100% Stock OFW]" in content:
        return False  # Already present

    # Find the [config] section and add OFW entry after it
    # Look for Stock entry or just append
    if "[Stock]" in content and "[100% Stock OFW]" not in content:
        # Insert after [Stock] section (before next [xxx] or at end)
        lines = content.split('\n')
        result = []
        inserted = False
        for line in lines:
            result.append(line)
            if line.strip() == "[Stock]":
                # Find the end of this section
                pass
        # Simpler: insert OFW entry after the [Stock] section ends
        # We detect end by looking for a line starting with [ or reaching the end
        result = []
        i = 0
        lines = content.split('\n')
        while i < len(lines):
            line = lines[i]
            result.append(line)
            if line.strip() == "[Stock]":
                # Find end of this section
                j = i + 1
                while j < len(lines):
                    if lines[j].startswith('['):
                        break
                    j += 1
                # Insert OFW entry before the next section
                result.append(ofw_entry.strip())
                i = j
                inserted = True
                continue
            i += 1

        if inserted:
            content = '\n'.join(result)
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(content)
            return True
        return False

    return False


# ============================================================================
# MAIN UPDATE LOGIC
# ============================================================================

def update_hekate_ext(hekate_src=None):
    hekate_ext = SCRIPT_DIR

    # Default source path
    if hekate_src is None:
        hekate_src = r"D:\Coding\hekate"

    print(f"\n{'='*60}")
    print(f"hekate-ext Update Script")
    print(f"{'='*60}")
    print(f"Source: {os.path.abspath(hekate_src)}")
    print(f"Target: {os.path.abspath(hekate_ext)}")
    print()

    if not os.path.isdir(hekate_src):
        print(f"[ERROR] Source directory not found: {hekate_src}")
        return False

    # Step 1: Copy folders (with custom file preservation)
    print("[1/6] Copying upstream hekate files...")

    backup_dir = os.path.join(hekate_ext, ".update_backup")
    custom_files = []
    skip_dirs = {".git", ".update_backup", ".claude", "build", "output", "release", ".vscode", ".planning"}

    # Find custom files that exist in hekate-ext but not in upstream
    for rel_path in HEKATE_EXT_CUSTOM_FILES:
        src_check = os.path.join(hekate_src, rel_path)
        ext_file = os.path.join(hekate_ext, rel_path)
        if not os.path.exists(src_check) and os.path.exists(ext_file):
            custom_files.append(rel_path)

    # Remove old backup if exists
    if os.path.exists(backup_dir):
        shutil.rmtree(backup_dir)

    # Backup custom files
    if custom_files:
        os.makedirs(backup_dir)
        for cf in custom_files:
            src_file = os.path.join(hekate_ext, cf)
            dst_file = os.path.join(backup_dir, cf)
            os.makedirs(os.path.dirname(dst_file), exist_ok=True)
            shutil.copy2(src_file, dst_file)
        print(f"  [BACKUP] {len(custom_files)} custom file(s) preserved")

    # Copy all folders (overwrites everything except custom files we restore below)
    for folder in COPY_FOLDERS:
        src = os.path.join(hekate_src, folder)
        dst = os.path.join(hekate_ext, folder)
        if os.path.isdir(src):
            if os.path.isdir(dst):
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
            print(f"  [COPY] {folder}/")
        else:
            print(f"  [SKIP] {folder}/ (not found)")

    # Restore custom files
    for cf in custom_files:
        src_file = os.path.join(backup_dir, cf)
        dst_file = os.path.join(hekate_ext, cf)
        if os.path.exists(src_file):
            os.makedirs(os.path.dirname(dst_file), exist_ok=True)
            shutil.copy2(src_file, dst_file)
            print(f"  [RESTORE] {cf}")

    # Cleanup backup
    if os.path.exists(backup_dir):
        shutil.rmtree(backup_dir)

    for fname in COPY_FILES:
        src = os.path.join(hekate_src, fname)
        dst = os.path.join(hekate_ext, fname)
        if os.path.isfile(src):
            shutil.copy2(src, dst)
            print(f"  [COPY] {fname}")
        else:
            print(f"  [SKIP] {fname} (not found)")

    # Step 2: Apply OFW patch to hos_config.c
    print("\n[2/6] Applying OFW patch to bootloader/hos/hos_config.c...")
    hos_config_c = os.path.join(hekate_ext, "bootloader", "hos", "hos_config.c")
    if os.path.exists(hos_config_c):
        result = patch_hos_config(hos_config_c)
        if result == 1:
            print("  [PATCH] Added _config_ofw handler and registered in _config_handlers[]")
        elif result == 0:
            print("  [SKIP] OFW handler already present")
        else:
            print("  [ERROR] Anchor '_config_ucid' not found — hos_config.c structure may have changed")
    else:
        print("  [ERROR] bootloader/hos/hos_config.c not found!")

    # Step 3: Branding patches
    print("\n[3/6] Applying hekate-ext branding...")
    gui_c = os.path.join(hekate_ext, "nyx", "nyx_gui", "frontend", "gui.c")
    if os.path.exists(gui_c):
        with open(gui_c, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        new_content, count = apply_branding_patch(content)
        if count > 0:
            with open(gui_c, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"  [PATCH] Branding updated ({count} change(s))")
        else:
            print("  [SKIP] Branding already applied or pattern not found")
    else:
        print("  [ERROR] gui.c not found!")

    # Step 4: Lockpick_RCM_Pro patches
    print("\n[4/6] Applying Lockpick_RCM_Pro patches...")
    gui_info_c = os.path.join(hekate_ext, "nyx", "nyx_gui", "frontend", "gui_info.c")
    if os.path.exists(gui_info_c):
        with open(gui_info_c, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        new_content, count = apply_lockpick_patch(content)
        if count > 0:
            with open(gui_info_c, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"  [PATCH] Lockpick_RCM_Pro updated ({count} change(s))")
        else:
            print("  [SKIP] Lockpick_RCM_Pro already applied")
    else:
        print("  [ERROR] gui_info.c not found!")

    # Step 5: Nyx Makefile - add warmboot tools
    print("\n[5/6] Patching nyx Makefile (warmboot tools)...")
    nyx_makefile = os.path.join(hekate_ext, "nyx", "Makefile")
    if os.path.exists(nyx_makefile):
        patched = patch_nyx_makefile(nyx_makefile)
        if patched:
            print(f"  [PATCH] Added gui_warmboot and warmboot_tools to OBJS")
        else:
            print(f"  [SKIP] Warmboot tools already in Makefile")
    else:
        print(f"  [ERROR] nyx/Makefile not found!")

    # Step 6: INI template - add OFW entry
    print("\n[6/6] Patching hekate_ipl_template.ini (OFW entry)...")
    ini_template = os.path.join(hekate_ext, "res", "hekate_ipl_template.ini")
    if os.path.exists(ini_template):
        patched = patch_ini_template(ini_template)
        if patched:
            print(f"  [PATCH] Added [100% Stock OFW] entry")
        else:
            print(f"  [SKIP] OFW entry already present")
    else:
        print(f"  [ERROR] hekate_ipl_template.ini not found!")

    print(f"\n{'='*60}")
    print("Update complete!")
    print(f"{'='*60}")
    print()
    print("Next steps:")
    print("  1. Review changes: git diff")
    print("  2. Build:           make release")
    print("  3. Test on hardware")
    print()
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Update hekate-ext to new hekate version")
    parser.add_argument("source", nargs="?", default=r"D:\Coding\hekate", help="Path to new hekate source (default: D:\\Coding\\hekate)")
    parser.add_argument("--build", action="store_true", help="Also run make release")
    args = parser.parse_args()

    success = update_hekate_ext(args.source)

    if args.build and success:
        print("\n[BUILD] Running make release...")
        import subprocess
        result = subprocess.run(["make", "release"], cwd=SCRIPT_DIR)
        sys.exit(result.returncode)

    sys.exit(0 if success else 1)
