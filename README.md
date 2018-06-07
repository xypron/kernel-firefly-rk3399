<h1>kernel-odroid-c2</h1>

This package provides scripts to build the Linux kernel for the
Odroid C2.

<h2>Debian package</h2>

Call ./build-dpkg.sh to build a Debian package.

The package can be installed with

```
sudo dpkg -i odroid-c2-kernel-image_<version>_arm64.deb
```

It can be uninstalled with

```
sudo apt-get remove odroid-c2-kernel-image
```

The Debian package installation routine shows a list of available
kernels and asks which of them shall be copied to /boot/uboot/vmlinux.

This assumes that the partion from which u-boot reads the kernel is
mounted as /boot/uboot.

<h2>Manual build and installation</h2>

To build the kernel without debian packageing run

```
make
sudo make install
```

The install step copies the kernel as file &lt;version&gt;.vmlinux
to directory /boot. It has to be copied manually to the partion used by
u-boot.

