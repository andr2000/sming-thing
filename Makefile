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
-include config.mk

all:
	$(if $(wildcard config.mk),, $(error No .config exists, config first!))
	MODULES=$(MODULES) EXTRA_INCDIR=$(EXTRA_INCDIR) \
		USER_CFLAGS=$(USER_CFLAGS) \
		$(MAKE) -f $(SMING_HOME)/Makefile-rboot.mk all

tags:
	ctags -R --c-kinds=+p --c++-kinds=+p . $(SMING_HOME)

clean:
	$(MAKE) -f $(SMING_HOME)/Makefile-rboot.mk clean
	@rm -f tags
	@rm -rf .kconfig

distclean: clean
	@rm -rf include/autoconf.h
	@rm -f .config
	@rm -f config.mk

################################################################################
# Kconfig section
################################################################################
KCONF_TARGET ?= help

KCONF_ARGS += KCONFIG_AUTOCONFIG=".kconfig/dummy"
KCONF_ARGS += KCONFIG_AUTOHEADER="include/autoconf.h"
KCONF_ARGS += KCONFIG_CONFIG=".config"

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
.SECONDARY:
.PHONY: all kconfig menuconfig tags clean distclean


