#!/bin/bash
set -x
set -e
if [ $(id -u) != 0 ]; then
echo switching to root
su -c "$0 $@"
fi

echo running as $USER $(id -u)
cd target
if [ -f make.bash ]; then
	echo not in target dir
	exit 111;
fi

debooter(){
	/usr/sbin/debootstrap --verbose jessie .
}

aptgetter(){
# otherwise commented out in default locale.gen
	echo "en_US.UTF-8 UTF-8" >> etc/locale.gen

# could be liter, but we want X11 and LVM2 and a solid dev env
	DEPS='ca-certificates apt-transport-https lvm2 grub2 gcc build-essential wmaker xinit wpasupplicant tmux tree ncdu w3m irssi iceweasel bsdmainutils man-db'

# update for latest ca-certificates and https transport using default mirror
	chroot . apt-get update

# need dialog and utf8 for sure and https for docker
	chroot . apt-get -y install dialog locales apt-transport-https ca-certificates
	chroot . locale-gen

# use host sources.list
	cp /etc/apt/sources.list etc/apt/
	chroot . apt-get -y update
	chroot . apt-get -y upgrade

# install packages	
	chroot . apt-get -y install $DEPS
	echo "AERTHOS apt-get COMPLETE"

}

debloat(){
# remove bloat (not really too bloaty)
	chroot . apt-get  remove --purge python3 python3.*
}

busyboxxer(){
	echo busyboxxing
	cp -avx ../busybox bin/busybox
	chroot . /bin/busybox --install /bin/
	echo installation complete. this filesystem is jam packed with goodness
}
debloat
exit 0;

#aptgetter && \
#busyboxxer
