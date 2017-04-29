#!/bin/bash
set -e

mkdir -p bin sbin tmp dev proc var usr etc root

cp busybox bin/busybox
if [ ! -x ./bin/sh ]; then
	ln -s /bin/busybox bin/sh
fi

su -c 'chroot . /bin/busybox --install /bin/'
echo installation complete. this filesystem is usable.