GIT_VERSION = $(shell git describe --long --dirty --always --tags)

all:

KCONF_TARGET ?= help

KCONF_ARGS += KCONFIG_AUTOCONFIG=".autoconf/dummy"
KCONF_ARGS += KCONFIG_AUTOHEADER="include/autoconf.h"
KCONF_ARGS += KCONFIG_CONFIG=".config"

kconfig:
	mkdir -p .autoconf
	mkdir -p include
	$(MAKE) -f kconfig/GNUmakefile $(KCONF_ARGS) TOPDIR=. SRCDIR=kconfig $(KCONF_TARGET)

menuconfig: KCONF_TARGET=menuconfig
menuconfig: kconfig

tags:
	ctags -R --c-kinds=+p --c++-kinds=+p .

clean:
	rm -f tags
	rm -f config
	rm -rf .autoconf
	rm -rf include/autoconf.h

.SECONDARY:
.PHONY: all kconfig menuconfig tags clean
