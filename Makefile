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

# Read the build configuration if exists
-include .kconfig/config.mk
# We use Sming to control the build. Mostly
include $(SMING_HOME)/Makefile-rboot.mk

#$(if $(wildcard config.mk),, $(error No .config exists, config first!))

tags:
	ctags -R --c-kinds=+p --c++-kinds=+p . $(SMING_HOME)

distclean: clean
	$(info Cleaning local build artifacts)
	@rm -f tags
	@rm -f include/autoconf.h
	@rm -rf .kconfig

################################################################################
# Kconfig section
################################################################################
KCONF_TARGET ?= help

KCONF_ARGS += KCONFIG_AUTOCONFIG=".kconfig/dummy"
KCONF_ARGS += KCONFIG_AUTOHEADER="include/autoconf.h"
KCONF_ARGS += KCONFIG_CONFIG=".kconfig/.config"

kconfig:
	@mkdir -p .kconfig
	@mkdir -p include
	$(MAKE) -f kconfig/GNUmakefile $(KCONF_ARGS) TOPDIR=. SRCDIR=kconfig \
		$(KCONF_TARGET)
	$(if $(wildcard config.mk),, $(error No .config exists, config first!))
	@cp .config config.mk
# Do not expose CONFIG_ values used by C/C++ code
	@sed -i '/^CONFIG_/d' config.mk
# Sming doesn't want values in quotes
	@sed 's/\"//g' -i config.mk

menuconfig: KCONF_TARGET=menuconfig
menuconfig: kconfig

################################################################################
# The rest
################################################################################
SECONDARY:
.PHONY: kconfig menuconfig tags distclean


