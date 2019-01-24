GIT_VERSION = $(shell git describe --long --dirty --always --tags)

################################################################################
# Sming required environment
################################################################################
ifndef SMING_HOME
$(error SMING_HOME is not set. Please configure it)
endif
ifndef ESP_HOME
$(error ESP_HOME is not set. Please configure it)
endif

# Read the build configuration if exists
-include config.mk

MODULES += app
EXTRA_INCDIR += include include/generated
USER_CFLAGS += -DVERSION=\"$(GIT_VERSION)\"

KCONFIG_OUT_DIR=.kconfig

# If you want to use, for example, two 512k roms in the first 1mb block of flash
# (old style) then follow these instructions to produce two separately linked
# roms. If you are flashing a single rom to multiple 1mb flash blocks (using big
# flash) you only need one linked rom that can be used on each.

ifeq ($(SPI_SIZE),1M)
RBOOT_LD_0	:= $(addprefix ld/1mib/,$(RBOOT_LD_0))
RBOOT_LD_1	:= $(addprefix ld/1mib/,$(RBOOT_LD_1))
else
RBOOT_LD_0	:= $(addprefix ld/,$(RBOOT_LD_0))
RBOOT_LD_1	:=
endif

# We use Sming to control the build, but configuration
include $(SMING_HOME)/Makefile-rboot.mk

checkdirs: config_mk

tags:
	ctags -R --c-kinds=+p --c++-kinds=+p . $(SMING_HOME) $(ESP_HOME)

distclean: clean
	$(info Cleaning local build artifacts)
	@rm -f tags
	@rm -f config.mk
	@rm -rf include/generated
	@rm -rf $(KCONFIG_OUT_DIR)
	@rm -rf out

################################################################################
# Kconfig section
################################################################################
KCONF_TARGET ?= help

KCONF_ARGS += KCONFIG_AUTOCONFIG="$(KCONFIG_OUT_DIR)/dummy"
KCONF_ARGS += KCONFIG_CONFIG="$(KCONFIG_OUT_DIR)/.config"
ifneq ($(KBUILD_DEFCONFIG),)
KCONF_ARGS += KBUILD_DEFCONFIG="$(KBUILD_DEFCONFIG)"
endif
KCONF_ARGS += KBUILD_CONFIG_DIR="$(CURDIR)"

kconfig:
	@mkdir -p $(KCONFIG_OUT_DIR)
	$(MAKE) -f kconfig/GNUmakefile $(KCONF_ARGS) TOPDIR=. SRCDIR=kconfig \
		$(KCONF_TARGET)

menuconfig: KCONF_TARGET=menuconfig
menuconfig: kconfig | config_mk

defconfig: KCONF_TARGET=defconfig
defconfig: kconfig | config_mk

oldconfig: KCONF_TARGET=oldconfig
oldconfig: kconfig | config_mk

# This target is used for compilation and generates autoconf.h
silentoldconfig: KCONF_TARGET=silentoldconfig
silentoldconfig: kconfig

$(TOPDIR)/config_mk: config_mk
$(TOPDIR)/include/generated/autoconf.h: include/generated/autoconf.h

config_mk: include/generated/autoconf.h
	$(info Generating config.mk)
	$(if $(wildcard $(KCONFIG_OUT_DIR)/.config),, $(error Cannot create config_mk, run menuconfig first?))
	@cp $(KCONFIG_OUT_DIR)/.config $(KCONFIG_OUT_DIR)/.config_mk
# Only expose CONFIG_SMING_ values
	@sed -i '/^CONFIG_SMING/!d' $(KCONFIG_OUT_DIR)/.config_mk
# Remove CONFIG_SMING_ prefix
	@sed -i 's/^CONFIG_SMING_//g' $(KCONFIG_OUT_DIR)/.config_mk
# Sming doesn't want values in quotes
	@sed 's/\"//g' -i $(KCONFIG_OUT_DIR)/.config_mk
	@mv -f $(KCONFIG_OUT_DIR)/.config_mk config.mk

include/generated/autoconf.h: silentoldconfig

################################################################################
# The rest
################################################################################
SECONDARY:
.PHONY: kconfig menuconfig defconfig oldconfig silentoldconfig tags distclean
