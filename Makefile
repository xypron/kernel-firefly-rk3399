TAG=4.16
TAGPREFIX=v
REVISION=002

MK_ARCH="${shell uname -m}"
ifneq ("aarch64", $(MK_ARCH))
	export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
endif
undefine MK_ARCH

export LOCALVERSION:=-D$(REVISION)-arm64

all:
	make prepare
	make build
	make copy

oldconfig:
	cd linux && make oldconfig

menuconfig:
	cd linux && make menuconfig

Image:
	cd linux && make -j6 Image

modules:
	cd linux && make -j6 modules

dtbs:
	cd linux && DTC_FLAGS='-@' make dtbs

prepare:
	test -d linux || git clone -v \
	https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git \
	linux
	cd linux && git fetch
	gpg --list-keys 79BE3E4300411886 || \
	gpg --keyserver keys.gnupg.net --recv-key 79BE3E4300411886
	gpg --list-keys 38DBBDC86092693E || \
	gpg --keyserver keys.gnupg.net --recv-key 38DBBDC86092693E
	gpg --list-keys 89F91C0A41D5C07A || \
	gpg --keyserver keys.gnupg.net --recv-key 89F91C0A41D5C07A
	gpg --list-keys C481DBBC2C051AC4 || \
	gpg --keyserver keys.gnupg.net --recv-key C481DBBC2C051AC4

build:
	cd linux && git verify-tag $(TAGPREFIX)$(TAG) 2>&1 | \
	grep '647F 2865 4894 E3BD 4571  99BE 38DB BDC8 6092 693E' || \
	git verify-tag $(TAGPREFIX)$(TAG) 2>&1 | \
	grep 'ABAF 11C6 5A29 70B1 30AB  E3C4 79BE 3E43 0041 1886' || \
	git verify-tag $(TAGPREFIX)$(TAG) 2>&1 | \
	grep '985B 681F A459 1969 9753  A264 89F9 1C0A 41D5 C07A' || \
	git verify-tag $(TAGPREFIX)$(TAG) 2>&1 | \
	grep '6DC4 F9C7 1F29 A6FA 06B7  6D33 C481 DBBC 2C05 1AC4'
	cd linux && git checkout $(TAGPREFIX)$(TAG)
	cd linux && ( git branch -D build || true )
	cd linux && git checkout -b build
	test ! -f patch/patch-$(TAG) || ( cd linux && ../patch/patch-$(TAG) )
	cd linux && make distclean
	cp config/config-$(TAG) linux/.config
	cd linux && make scripts
	cd linux && make oldconfig
	cd linux && DTC_FLAGS='-@' make -j6 Image firmware modules dtbs

copy:
	rm linux/deploy -rf
	mkdir -p linux/deploy
	echo "#!/bin/sh" > linux/deploy/version
	echo "echo \\" >> linux/deploy/version
	cd linux && make -s kernelrelease >> deploy/version
	chmod 755 linux/deploy/version
	VERSION=$$(linux/deploy/version) && \
	cp linux/.config linux/deploy/config-$$VERSION
	VERSION=$$(linux/deploy/version) && \
	cd linux && \
	cp arch/arm64/boot/Image deploy/vmlinuz-$$VERSION
	cd linux && make modules_install INSTALL_MOD_PATH=deploy
	VERSION=$$(linux/deploy/version) && \
	cd linux && make headers_install \
	INSTALL_HDR_PATH=deploy/usr/src/linux-headers-$$VERSION
	VERSION=$$(linux/deploy/version) && \
	cd linux && make dtbs_install \
	INSTALL_DTBS_PATH=deploy/dtbs-$$VERSION
	VERSION=$$(linux/deploy/version) && \
	mkdir -p -m 755 linux/deploy/lib/firmware/$$VERSION; true
	VERSION=$$(linux/deploy/version) && \
	mv linux/deploy/lib/firmware/* \
	linux/deploy/lib/firmware/$$VERSION; true
	VERSION=$$(linux/deploy/version) && \
	cd linux/deploy && tar -czf $$VERSION-modules-firmware.tar.gz lib
	VERSION=$$(linux/deploy/version) && \
	cd linux/deploy && tar -czf $$VERSION-headers.tar.gz usr

install:
	mkdir -p -m 755 $(DESTDIR)/boot;true
	VERSION=$$(linux/deploy/version) && \
	cp linux/deploy/vmlinuz-$$VERSION $(DESTDIR)/boot;true
	VERSION=$$(linux/deploy/version) && \
	cp linux/deploy/config-$$VERSION $(DESTDIR)/boot;true
	VERSION=$$(linux/deploy/version) && \
	tar -xzf linux/deploy/$$VERSION-modules-firmware.tar.gz -C $(DESTDIR)/
	VERSION=$$(linux/deploy/version) && \
	tar -xzf linux/deploy/$$VERSION-headers.tar.gz -C $(DESTDIR)/
	VERSION=$$(linux/deploy/version) && \
	mkdir -p -m 755 $(DESTDIR)/usr/lib/linux-image-$$VERSION/amlogic
	VERSION=$$(linux/deploy/version) && \
	cp -R linux/deploy/dtbs-$$VERSION/* \
	$(DESTDIR)/usr/lib/linux-image-$$VERSION/;true

uninstall:
	VERSION=$$(linux/deploy/version) && \
	rm $(DESTDIR)/lib/modules/$$VERSION -rf
	VERSION=$$(linux/deploy/version) && \
	rm $(DESTDIR)/lib/firmware/$$VERSION -rf
	VERSION=$$(linux/deploy/version) && \
	rm $(DESTDIR)/usr/src/linux-headers-$$VERSION -rf
	VERSION=$$(linux/deploy/version) && \
	rm $(DESTDIR)/usr/src/linux-image-$$VERSION -rf

clean:
	test -d linux && cd linux && rm -f .config || true
	test -d linux && cd linux && git clean -df || true

