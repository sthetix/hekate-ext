ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

include $(DEVKITARM)/base_rules

################################################################################

IPL_LOAD_ADDR := 0x40008000
IPL_MAGIC := 0x43544349 #"ICTC"
include ./Versions.inc

################################################################################

TARGET := hekate
BUILDDIR := build
OUTPUTDIR := output
SOURCEDIR = bootloader
BDKDIR := bdk
BDKINC := -I./$(BDKDIR)
VPATH = $(dir ./$(SOURCEDIR)/) $(dir $(wildcard ./$(SOURCEDIR)/*/)) $(dir $(wildcard ./$(SOURCEDIR)/*/*/))
VPATH += $(dir $(wildcard ./$(BDKDIR)/)) $(dir $(wildcard ./$(BDKDIR)/*/)) $(dir $(wildcard ./$(BDKDIR)/*/*/))

# Main and graphics.
OBJS = $(addprefix $(BUILDDIR)/$(TARGET)/, \
	start.o exception_handlers.o \
	main.o heap.o \
	gfx.o logos.o tui.o \
	l4t.o fe_info.o fe_tools.o \
)

# Hardware.
OBJS += $(addprefix $(BUILDDIR)/$(TARGET)/, \
	bpmp.o ccplex.o clock.o di.o i2c.o irq.o timer.o \
	mc.o sdram.o minerva.o \
	gpio.o pinmux.o pmc.o se.o smmu.o tsec.o uart.o \
	fuse.o kfuse.o \
	sdmmc.o sdmmc_driver.o emmc.o sd.o emummc.o \
	bq24193.o max17050.o max7762x.o max77620-rtc.o \
	hw_init.o \
)

# Utilities.
OBJS += $(addprefix $(BUILDDIR)/$(TARGET)/, \
	btn.o dirlist.o ianos.o util.o \
	config.o ini.o \
)

# Horizon.
OBJS += $(addprefix $(BUILDDIR)/$(TARGET)/, \
	hos.o hos_config.o pkg1.o pkg2.o pkg3.o pkg2_ini_kippatch.o secmon_exo.o \
)

# Libraries.
OBJS += $(addprefix $(BUILDDIR)/$(TARGET)/, \
	lz.o lz4.o blz.o \
	diskio.o ff.o ffunicode.o ffsystem.o \
	elfload.o elfreloc_arm.o \
)

GFX_INC   := '"../$(SOURCEDIR)/gfx/gfx.h"'
FFCFG_INC := '"../$(SOURCEDIR)/libs/fatfs/ffconf.h"'

################################################################################

CUSTOMDEFINES := -DIPL_LOAD_ADDR=$(IPL_LOAD_ADDR) -DBL_MAGIC=$(IPL_MAGIC)
CUSTOMDEFINES += -DBL_VER_MJ=$(BLVERSION_MAJOR) -DBL_VER_MN=$(BLVERSION_MINOR) -DBL_VER_HF=$(BLVERSION_HOTFX) -DBL_VER_RL=$(BLVERSION_REL)
CUSTOMDEFINES += -DNYX_VER_MJ=$(NYXVERSION_MAJOR) -DNYX_VER_MN=$(NYXVERSION_MINOR) -DNYX_VER_HF=$(NYXVERSION_HOTFX) -DNYX_VER_RL=$(NYXVERSION_REL)

# BDK defines.
CUSTOMDEFINES += -DBDK_MALLOC_NO_DEFRAG -DBDK_MC_ENABLE_AHB_REDIRECT -DBDK_EMUMMC_ENABLE
CUSTOMDEFINES += -DBDK_WATCHDOG_FIQ_ENABLE -DBDK_RESTART_BL_ON_WDT
CUSTOMDEFINES += -DGFX_INC=$(GFX_INC) -DFFCFG_INC=$(FFCFG_INC)

# DRAM 8GB mode support.
ifeq ($(DRAM_8GB),1)
CUSTOMDEFINES += -DCONFIG_DRAM_8GB=1
else
CUSTOMDEFINES += -DCONFIG_DRAM_8GB=0
endif

#CUSTOMDEFINES += -DDEBUG

# UART Logging: Max baudrate 12.5M.
# DEBUG_UART_PORT - 0: UART_A, 1: UART_B, 2: UART_C.
#CUSTOMDEFINES += -DDEBUG_UART_BAUDRATE=115200 -DDEBUG_UART_INVERT=0 -DDEBUG_UART_PORT=1

#TODO: Considering reinstating some of these when pointer warnings have been fixed.
WARNINGS := -Wall -Wsign-compare -Wtype-limits -Wno-array-bounds -Wno-stringop-overread -Wno-stringop-overflow
#-fno-delete-null-pointer-checks
#-Wstack-usage=byte-size -fstack-usage

ARCH := -march=armv4t -mtune=arm7tdmi -mthumb -mthumb-interwork $(WARNINGS)
CFLAGS = $(ARCH) -O2 -g -gdwarf-4 -nostdlib -ffunction-sections -fdata-sections -fomit-frame-pointer -fno-inline -std=gnu11 $(CUSTOMDEFINES)
LDFLAGS = $(ARCH) -nostartfiles -lgcc -Wl,--nmagic,--gc-sections -Xlinker --defsym=IPL_LOAD_ADDR=$(IPL_LOAD_ADDR)

MODULEDIRS := $(wildcard modules/*)
NYXDIR := $(wildcard nyx)
LDRDIR := $(wildcard loader)
TOOLSLZ := $(wildcard tools/lz)
TOOLSB2C := $(wildcard tools/bin2c)
TOOLS := $(TOOLSLZ) $(TOOLSB2C)

################################################################################

.PHONY: all all-both release clean $(MODULEDIRS) $(NYXDIR) $(LDRDIR) $(TOOLS)

all: $(TARGET).bin $(LDRDIR)
	@printf ICTC49 >> $(OUTPUTDIR)/$(TARGET).bin
	@echo "--------------------------------------"
	@echo "$(TARGET) size:"
	@echo -n "Uncompr:  "
	$(eval BIN_SIZE = $(shell wc -c < $(OUTPUTDIR)/$(TARGET)_unc.bin))
	@echo $(BIN_SIZE)" Bytes"
	@if [ ${BIN_SIZE} -gt 140288 ]; then echo "\e[1;33mUncompr size exceeds limit!\e[0m"; fi
	@echo -n "Payload:  "
	$(eval BIN_SIZE = $(shell wc -c < $(OUTPUTDIR)/$(TARGET).bin))
	@echo $(BIN_SIZE)" Bytes"
	@if [ ${BIN_SIZE} -gt 126296 ]; then echo "\e[1;33mPayload size exceeds limit!\e[0m"; fi
	@echo "--------------------------------------"

clean: $(TOOLS)
	@rm -rf $(OBJS)
	@rm -rf $(BUILDDIR)
	@-rm -rf $(OUTPUTDIR) 2>/dev/null || true
	@rm -f $(OUTPUTDIR)/*.bin $(OUTPUTDIR)/*.bso 2>/dev/null || true

all-both:
	@$(MAKE) --no-print-directory
	@mv $(OUTPUTDIR)/$(TARGET).bin $(OUTPUTDIR)/$(TARGET)_4gb.bin
	@mv $(OUTPUTDIR)/$(TARGET)_4gb.bin ../$(TARGET)_4gb.bin
	@rm -rf $(BUILDDIR)
	@$(MAKE) --no-print-directory DRAM_8GB=1
	@mv ../$(TARGET)_4gb.bin $(OUTPUTDIR)/$(TARGET)_4gb.bin
	@mv $(OUTPUTDIR)/$(TARGET).bin $(OUTPUTDIR)/$(TARGET)_8gb.bin
	@echo "--------------------------------------"
	@echo "Built 4GB and 8GB versions:"
	@echo "  $(OUTPUTDIR)/$(TARGET)_4gb.bin"
	@echo "  $(OUTPUTDIR)/$(TARGET)_8gb.bin"
	@echo "--------------------------------------"

release:
	@echo "Building release packages..."
	@$(MAKE) --no-print-directory all-both
	@-rm -rf release 2>/dev/null || true
	@rm -f release/*.zip 2>/dev/null || true
	@mkdir -p release
	$(eval VERSION := $(BLVERSION_MAJOR).$(BLVERSION_MINOR).$(BLVERSION_HOTFX))
	@echo "Creating 4GB release..."
	@mkdir -p release/hekate-ext-$(VERSION)-4GB/bootloader/ini
	@mkdir -p release/hekate-ext-$(VERSION)-4GB/bootloader/payloads
	@mkdir -p release/hekate-ext-$(VERSION)-4GB/bootloader/res
	@mkdir -p release/hekate-ext-$(VERSION)-4GB/bootloader/sys/l4t
	@cp $(OUTPUTDIR)/$(TARGET)_4gb.bin release/hekate-ext-$(VERSION)-4GB/payload.bin
	@touch release/hekate-ext-$(VERSION)-4GB/bootloader/update.bin
	@cp $(OUTPUTDIR)/nyx.bin release/hekate-ext-$(VERSION)-4GB/bootloader/sys/
	@cp $(OUTPUTDIR)/libsys_lp0.bso release/hekate-ext-$(VERSION)-4GB/bootloader/sys/
	@cp $(OUTPUTDIR)/libsys_minerva.bso release/hekate-ext-$(VERSION)-4GB/bootloader/sys/
	@cp res/hekate_ipl_template.ini release/hekate-ext-$(VERSION)-4GB/bootloader/ini/hekate_ipl.ini
	@cp extras/res/*.bmp release/hekate-ext-$(VERSION)-4GB/bootloader/res/
	@cp extras/sys/emummc.kipm release/hekate-ext-$(VERSION)-4GB/bootloader/sys/
	@cp extras/sys/res.pak release/hekate-ext-$(VERSION)-4GB/bootloader/sys/
	@cp extras/sys/thk.bin release/hekate-ext-$(VERSION)-4GB/bootloader/sys/
	@cp extras/sys/l4t/*.bin release/hekate-ext-$(VERSION)-4GB/bootloader/sys/l4t/
	@powershell -Command "Compress-Archive -Path 'release/hekate-ext-$(VERSION)-4GB/*' -DestinationPath 'release/hekate-ext-$(VERSION)-4GB.zip' -Force"
	@echo "Creating 8GB release..."
	@mkdir -p release/hekate-ext-$(VERSION)-8GB/bootloader/ini
	@mkdir -p release/hekate-ext-$(VERSION)-8GB/bootloader/payloads
	@mkdir -p release/hekate-ext-$(VERSION)-8GB/bootloader/res
	@mkdir -p release/hekate-ext-$(VERSION)-8GB/bootloader/sys/l4t
	@cp $(OUTPUTDIR)/$(TARGET)_8gb.bin release/hekate-ext-$(VERSION)-8GB/payload.bin
	@touch release/hekate-ext-$(VERSION)-8GB/bootloader/update.bin
	@cp $(OUTPUTDIR)/nyx.bin release/hekate-ext-$(VERSION)-8GB/bootloader/sys/
	@cp $(OUTPUTDIR)/libsys_lp0.bso release/hekate-ext-$(VERSION)-8GB/bootloader/sys/
	@cp $(OUTPUTDIR)/libsys_minerva.bso release/hekate-ext-$(VERSION)-8GB/bootloader/sys/
	@cp res/hekate_ipl_template.ini release/hekate-ext-$(VERSION)-8GB/bootloader/ini/hekate_ipl.ini
	@cp extras/res/*.bmp release/hekate-ext-$(VERSION)-8GB/bootloader/res/
	@cp extras/sys/emummc.kipm release/hekate-ext-$(VERSION)-8GB/bootloader/sys/
	@cp extras/sys/res.pak release/hekate-ext-$(VERSION)-8GB/bootloader/sys/
	@cp extras/sys/thk.bin release/hekate-ext-$(VERSION)-8GB/bootloader/sys/
	@cp extras/sys/l4t/*.bin release/hekate-ext-$(VERSION)-8GB/bootloader/sys/l4t/
	@powershell -Command "Compress-Archive -Path 'release/hekate-ext-$(VERSION)-8GB/*' -DestinationPath 'release/hekate-ext-$(VERSION)-8GB.zip' -Force"
	@echo "--------------------------------------"
	@echo "Release packages created:"
	@echo "  release/hekate-ext-$(VERSION)-4GB.zip"
	@echo "  release/hekate-ext-$(VERSION)-8GB.zip"
	@echo "--------------------------------------"

$(MODULEDIRS):
	@$(MAKE) --no-print-directory -C $@ $(MAKECMDGOALS) -$(MAKEFLAGS)

$(NYXDIR):
	@$(MAKE) --no-print-directory -C $@ $(MAKECMDGOALS) -$(MAKEFLAGS)

$(LDRDIR): $(TARGET).bin
	@$(TOOLSLZ)/lz77 $(OUTPUTDIR)/$(TARGET).bin
	@mv $(OUTPUTDIR)/$(TARGET).bin $(OUTPUTDIR)/$(TARGET)_unc.bin
	@mv $(OUTPUTDIR)/$(TARGET).bin.00.lz payload_00
	@mv $(OUTPUTDIR)/$(TARGET).bin.01.lz payload_01
	@$(TOOLSB2C)/bin2c payload_00 > $(LDRDIR)/payload_00.h
	@$(TOOLSB2C)/bin2c payload_01 > $(LDRDIR)/payload_01.h
	@rm payload_00
	@rm payload_01
	@$(MAKE) --no-print-directory -C $@ $(MAKECMDGOALS) -$(MAKEFLAGS) PAYLOAD_NAME=$(TARGET)

$(TOOLS):
	@$(MAKE) --no-print-directory -C $@ $(MAKECMDGOALS) -$(MAKEFLAGS)

$(TARGET).bin: $(BUILDDIR)/$(TARGET)/$(TARGET).elf $(MODULEDIRS) $(NYXDIR) $(TOOLS)
	@$(OBJCOPY) -S -O binary $< $(OUTPUTDIR)/$@

$(BUILDDIR)/$(TARGET)/$(TARGET).elf: $(OBJS)
	@$(CC) $(LDFLAGS) -T $(SOURCEDIR)/link.ld $^ -o $@
	@printf "$(TARGET) was built with the following flags:\nCFLAGS:  $(CFLAGS)\nLDFLAGS: $(LDFLAGS)\n"

$(BUILDDIR)/$(TARGET)/%.o: %.c
	@echo Building $@
	@$(CC) $(CFLAGS) $(BDKINC) -c $< -o $@

$(BUILDDIR)/$(TARGET)/%.o: %.S
	@echo Building $@
	@$(CC) $(CFLAGS) -c $< -o $@

$(OBJS): $(BUILDDIR)/$(TARGET)

$(BUILDDIR)/$(TARGET):
	@mkdir -p "$(BUILDDIR)"
	@mkdir -p "$(BUILDDIR)/$(TARGET)"
	@mkdir -p "$(OUTPUTDIR)"
