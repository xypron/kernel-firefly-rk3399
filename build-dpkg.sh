#!/bin/sh
git clean -df
make prepare
make clean
dpkg-buildpackage -aarm64 --no-check-builddeps
