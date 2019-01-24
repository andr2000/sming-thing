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

KCONFIG_OUT_DIR=.kconfig

# Read the build configuration if exists
-include $(KCONFIG_OUT_DIR)/config.mk

MODULES += app
EXTRA_INCDIR += include
USER_CFLAGS += -DVERSION=\"$(GIT_VERSION)\"

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

tags:
	ctags -R --c-kinds=+p --c++-kinds=+p . $(SMING_HOME) $(ESP_HOME)

distclean: clean
	$(info Cleaning local build artifacts)
	@rm -f tags
	@rm -f include/autoconf.h
	@rm -rf $(KCONFIG_OUT_DIR)
	@rm -rf out

################################################################################
# Kconfig section
################################################################################
KCONF_TARGET ?= help

KCONF_ARGS += KCONFIG_AUTOCONFIG="$(KCONFIG_OUT_DIR)/dummy"
KCONF_ARGS += KCONFIG_AUTOHEADER="include/autoconf.h"
KCONF_ARGS += KCONFIG_CONFIG="$(KCONFIG_OUT_DIR)/.config"

mk_config:
	$(info Generating config.mk)
	$(if $(wildcard $(KCONFIG_OUT_DIR)/.config),, $(error Cannot create config.mk, something went wrong!))
	@cp $(KCONFIG_OUT_DIR)/.config $(KCONFIG_OUT_DIR)/config.mk
# Only expose CONFIG_SMING_ values
	@sed -i '/^CONFIG_SMING/!d' $(KCONFIG_OUT_DIR)/config.mk
# Remove CONFIG_SMING_ prefix
	@sed -i 's/^CONFIG_SMING_//g' $(KCONFIG_OUT_DIR)/config.mk
# Sming doesn't want values in quotes
	@sed 's/\"//g' -i $(KCONFIG_OUT_DIR)/config.mk

kconfig:
	@mkdir -p $(KCONFIG_OUT_DIR)
	@mkdir -p include
	$(MAKE) -f kconfig/GNUmakefile $(KCONF_ARGS) TOPDIR=. SRCDIR=kconfig \
		$(KCONF_TARGET)

menuconfig: KCONF_TARGET=menuconfig
menuconfig: kconfig | mk_config

oldconfig: KCONF_TARGET=oldconfig
oldconfig: kconfig | mk_config

################################################################################
# The rest
################################################################################
SECONDARY:
.PHONY: kconfig menuconfig oldconfig tags distclean mk_config
