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

-include .config

all:
	$(if $(wildcard .config),, $(error No .config exists, config first!))
	$(MAKE) -f $(SMING_HOME)/Makefile-rboot.mk all

tags:
	ctags -R --c-kinds=+p --c++-kinds=+p . $(SMING_HOME)

clean:
	$(MAKE) -f $(SMING_HOME)/Makefile-rboot.mk clean
	rm -f tags
	rm -rf .autoconf
	rm -rf include/autoconf.h

distclean: clean
	rm -f .config

################################################################################
# Kconfig section
################################################################################
KCONF_TARGET ?= help

KCONF_ARGS += KCONFIG_AUTOCONFIG=".autoconf/dummy"
KCONF_ARGS += KCONFIG_AUTOHEADER="include/autoconf.h"
KCONF_ARGS += KCONFIG_CONFIG=".config"

kconfig:
	mkdir -p .autoconf
	mkdir -p include
	$(MAKE) -f kconfig/GNUmakefile $(KCONF_ARGS) TOPDIR=. SRCDIR=kconfig \
		$(KCONF_TARGET)

menuconfig: KCONF_TARGET=menuconfig
menuconfig: kconfig

################################################################################
# The rest
################################################################################
.SECONDARY:
.PHONY: all kconfig menuconfig tags clean distclean


