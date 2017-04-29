#!/bin/bash
AUTHOR='aerth@riseup.net'
VERSION=v0.0.1
LATEST=
RWD=$(pwd)
needed=( make gcc bash rm echo chmod chroot git chown )
PACKAGES=( busybox linux gcc glibc )
VENDORDIR=${RWD}/vendor/


# urls to do shallow clone
# these are selected for speed, they are mirrors.
URL_LINUX=https://kernel.googlesource.com/pub/scm/linux/kernel/git/torvalds/linux.git
URL_GCC=https://github.com/gcc-mirror/gcc
URL_GLIBC=git://sourceware.org/git/glibc.git
URL_BUSYBOX=git://git.busybox.net/busybox

set -e

# make sure we are bash
if [[ x"$SHELL" == "x" ]]; then
	echo cant find $SHELL
	exit 111;
elif [[ ! -x /bin/bash ]]; then
	echo no /bin/bash, try 'ln -s /usr/bin/bash /bin/bash'
	exit 111;
fi

check_dependencies(){
	# dependencies check
	echo [check dependencies]
	set +e
	for need in "${needed[@]}"; do
		printf "checking for $need... "
		EXEC=$(which $need)
		if [ -z "$EXEC" ]; then
			echo "fatal: need $need in "'$PATH'
			exit 111
		else
			echo "found $need: $EXEC"
		fi
	done
	set -e
}


set -e

printf "\naerthos $0 $VERSION\n"
echo ""
helpmode(){
	lines=()
	lines+=("aerthos iso build script")
	lines+=("	$0 fetch")
	lines+=("	$0 update")
	lines+=("	$0 config")	
	lines+=("	$0 build")
	lines+=("	$0 install")
	lines+=("	$0 all")



	for line in "${lines[@]}"; do
		printf "$line\n"
	done

}

dothings(){
	cmd="$1"
	FAIL=0
	if [ -z "$cmd" ]; then
		echo '$cmd is empty'
		return 111;

	fi
	if [ -f "$cmd" ] && [ ! -x "$(which $cmd)" ]; then
		echo $cmd not exe
		return 111;
	fi
	shift
	if [ 0 == $((${#@})) ]; then
		echo "single:"
		$cmd;
		return 0;
	fi
	printf "running $((${#@})) tasks \n"
	for i in "$@"; do
		printf "\ntask $cmd: $i\n"
		$cmd $i && echo ""
	done
	return 0;
}

do_update(){
	for i in $@; do
	echo updatin: $i
	cd ${VENDORDIR}$i && git pull origin master
	echo ""
	done
}

gen_iso(){
	mkisofs -o aerthos64-current.iso \
	    -R -J -V "aerthos64-current DVD" \
	    -hide-rr-moved -hide-joliet-trans-tbl \
	    -v -d -N -no-emul-boot -boot-load-size 4 -boot-info-table \
	    -sort isolinux/iso.sort \
	    -b isolinux/isolinux.bin \
	    -c isolinux/isolinux.boot \
	    -preparer "aerth <aerth@riseup.net>" \
	    -publisher "aerth" \
	    -A "AERTHOS64 DVD - build $(date)" \
	    -x ./iso-ignore \
	    -joliet-long \
	    -eltorito-alt-boot -no-emul-boot -eltorito-boot isolinux/efiboot.img \
	    .
		
}

config_linux(){
	echo ASSUMING KERNEL ALREADY CONFIGURED
}

build_linux_debpkg(){
	cd ${VENDORDIR}linux
	time make -j1 | tee ../build-linux.log
}

case "$1" in 
	"fetch")
		check_dependencies $needed
		printf "fetching\n\n"
		dothings 'git -C vendor clone --depth 1 -v' $URL_LINUX $URL_GCC $URL_GLIBC $URL_BUSYBOX
		printf "\nfetch complete!\n\n"
		;;
	"update")
		check_dependencies $needed
		do_update ${PACKAGES[@]}
		;;
	"config")
		dothings "make -C ${VENDORDIR}linux localmodconfig"
		dothings "make -C ${VENDORDIR}linux menuconfig"
		dothings "make -C ${VENDORDIR}busybox defconfig"
		dothings "make -C ${VENDORDIR}busybox menuconfig"
		;;
	"linux")
		config_linux
		build_linux_debpkg
		;;
	"build")
		check_dependencies $needed
		printf "building\n\n"
		if [ ! -f ${VENDORDIR}linux/.config ]; then
			echo "no config found, try:"
			echo "	$0 config"
			exit 111
		fi
		set -e	
		dothings "make -C ${VENDORDIR}linux -j2 V=1 deb-pkg"
		dothings "make -C ${VENDORDIR}busybox"
		dothings "make -C ${VENDORDIR}gcc -j2 V=1"
		dothings "make -C ${VENDORDIR}glibc -j2 V=1"
		echo "DONE"
		;;
	"install")
		printf "installing\n\n"
		;;
	"iso")
		gen_iso
		
		;;
	*)
		helpmode
		;;
esac
