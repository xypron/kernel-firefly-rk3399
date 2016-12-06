TAG=4.9-rc8
TAGPREFIX=v

MK_ARCH="${shell uname -m}"
ifneq ("aarch64", $(MK_ARCH))
	export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
endif
undefine MK_ARCH

all: prepare build copy

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

build:
	cd linux && git verify-tag $(TAGPREFIX)$(TAG) 2>&1 | \
	grep '647F 2865 4894 E3BD 4571  99BE 38DB BDC8 6092 693E' || \
	git verify-tag $(TAGPREFIX)$(TAG) 2>&1 | \
	grep 'ABAF 11C6 5A29 70B1 30AB  E3C4 79BE 3E43 0041 1886' || \
	git verify-tag $(TAGPREFIX)$(TAG) 2>&1 | \
	grep '985B 681F A459 1969 9753  A264 89F9 1C0A 41D5 C07A'
	cd linux && git checkout $(TAGPREFIX)$(TAG)
	cd linux && ( git branch -D build || true )
	cd linux && git checkout -b build
	test ! -f patch/patch-$(TAG) || ( cd linux && ../patch/patch-$(TAG) )
	cd linux && make distclean
	cp config/config-$(TAG) linux/.config
	cd linux && make oldconfig
	cd linux && make -j6 Image firmware modules dtbs

copy:
	rm linux/deploy -rf
	mkdir -p linux/deploy
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cp linux/.config linux/deploy/config-$$VERSION
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cd linux && \
	cp arch/arm64/boot/Image deploy/vmlinuz-$$VERSION
	cd linux && make modules_install INSTALL_MOD_PATH=deploy
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cd linux && make headers_install \
	INSTALL_HDR_PATH=deploy/usr/src/linux-headers-$$VERSION
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cd linux && make dtbs_install \
	INSTALL_DTBS_PATH=deploy/dtbs-$$VERSION
	VERSION=$$(cd linux && make -s kernelrelease) && \
	mkdir -p -m 755 linux/deploy/lib/firmware/$$VERSION; true
	VERSION=$$(cd linux && make -s kernelrelease) && \
	mv linux/deploy/lib/firmware/* \
	linux/deploy/lib/firmware/$$VERSION; true
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cd linux/deploy && tar -czf $$VERSION-modules-firmware.tar.gz lib
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cd linux/deploy && tar -czf $$VERSION-headers.tar.gz usr

install:
	echo "$(ARCH) $(CROSS_COMPILE)"
	mkdir -p -m 755 $(DESTDIR)/boot;true
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cp linux/deploy/vmlinuz-$$VERSION $(DESTDIR)/boot;true
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cp linux/deploy/config-$$VERSION $(DESTDIR)/boot;true
	VERSION=$$(cd linux && make -s kernelrelease) && \
	tar -xzf linux/deploy/$$VERSION-modules-firmware.tar.gz -C $(DESTDIR)/
	VERSION=$$(cd linux && make -s kernelrelease) && \
	tar -xzf linux/deploy/$$VERSION-headers.tar.gz -C $(DESTDIR)/
	VERSION=$$(cd linux && make -s kernelrelease) && \
	mkdir -p -m 755 $(DESTDIR)/usr/lib/linux-image-$(VERSION)
	VERSION=$$(cd linux && make -s kernelrelease) && \
	cp linux/deploy/dtbs-$$VERSION/amlogic/meson-gxbb-odroidc2.dtb \
	$(DESTDIR)/usr/lib/linux-image-$(VERSION)/;true

uninstall:
	VERSION=$$(cd linux && make -s kernelrelease) && \
	rm $(DESTDIR)/lib/modules/$$VERSION -rf
	VERSION=$$(cd linux && make -s kernelrelease) && \
	rm $(DESTDIR)/lib/firmware/$$VERSION -rf
	VERSION=$$(cd linux && make -s kernelrelease) && \
	rm $(DESTDIR)/usr/src/linux-headers-$$VERSION -rf

clean:
	test -d linux && cd linux && rm -f .config || true
	test -d linux && cd linux && git clean -df || true

