GIT_VERSION = $(shell git describe --long --dirty --always --tags)

all:

KCONF_TARGET?=help
kconfig:
	$(MAKE) -f kconfig/GNUmakefile TOPDIR=. SRCDIR=kconfig $(KCONF_TARGET)

menuconfig: KCONF_TARGET=menuconfig
menuconfig: kconfig

tags:
	ctags -R --c-kinds=+p --c++-kinds=+p .

clean:
	rm -f tags
	rm -f config

.SECONDARY:
.PHONY: all kconfig menuconfig tags clean
