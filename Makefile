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

MODULES = app
EXTRA_INCDIR = include
USER_CFLAGS = -DVERSION=\"$(GIT_VERSION)\"

KCONFIG_OUT_DIR=.kconfig

# Read the build configuration if exists
-include $(KCONFIG_OUT_DIR)/config.mk
# We use Sming to control the build, but configuration
include $(SMING_HOME)/Makefile-rboot.mk

#$(if $(wildcard config.mk),, $(error No .config exists, config first!))

tags:
	ctags -R --c-kinds=+p --c++-kinds=+p . $(SMING_HOME) $(ESP_HOME)

distclean: clean
	$(info Cleaning local build artifacts)
	@rm -f tags
	@rm -f include/autoconf.h
	@rm -rf $(KCONFIG_OUT_DIR)

################################################################################
# Kconfig section
################################################################################
KCONF_TARGET ?= help

KCONF_ARGS += KCONFIG_AUTOCONFIG="$(KCONFIG_OUT_DIR)/dummy"
KCONF_ARGS += KCONFIG_AUTOHEADER="include/autoconf.h"
KCONF_ARGS += KCONFIG_CONFIG="$(KCONFIG_OUT_DIR)/.config"

kconfig:
	@mkdir -p $(KCONFIG_OUT_DIR)
	@mkdir -p include
	$(MAKE) -f kconfig/GNUmakefile $(KCONF_ARGS) TOPDIR=. SRCDIR=kconfig \
		$(KCONF_TARGET)
	@cp $(KCONFIG_OUT_DIR)/.config $(KCONFIG_OUT_DIR)/config.mk
# Only expose CONFIG_SMING_ values
	@sed -i '/^CONFIG_SMING/!d' $(KCONFIG_OUT_DIR)/config.mk
# Remove CONFIG_SMING_ prefix
	@sed -i 's/^CONFIG_SMING_//g' $(KCONFIG_OUT_DIR)/config.mk
# Sming doesn't want values in quotes
	@sed 's/\"//g' -i $(KCONFIG_OUT_DIR)/config.mk

menuconfig: KCONF_TARGET=menuconfig
menuconfig: kconfig

################################################################################
# The rest
################################################################################
SECONDARY:
.PHONY: kconfig menuconfig tags distclean
