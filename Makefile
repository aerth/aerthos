SHELL := /bin/bash -euo pipefail

# most of this makefile is for copying keys and repos 
# to install the required packages during the build
# the ones in config/archives should probably be removed in favor of the new includes.X ones

## get buildmode

buildmode:=$(shell DEVELOP=1 source config/common && echo $${LB_IMAGE_TYPE})
image_ext=.iso
ifeq ($(buildmode),iso)
image_ext=.iso
else ifeq ($(buildmode),hdd)
image_ext=.img
else ifeq ($(buildmode),iso-hybrid)
image_ext=.hybrid.iso
else ifeq ($(buildmode),)
$(error No build mode specified. Edit config/common or set the environment variable LB_IMAGE_TYPE)
else
$(error Unknown build mode: $(buildmode))
endif

LB_BINARY_FILESYSTEM:=$(shell DEVELOP=1 source config/common && echo $${LB_BINARY_FILESYSTEM})
$(info Build mode: $(buildmode))
iso_filename=tmp/live-build/aerthOSLive-amd64$(image_ext)
$(info Target: $(iso_filename))
already_exists=$(wildcard $(iso_filename))
ifeq ($(already_exists),)
$(info OK: Target does not exist: $(iso_filename))
else
$(info OK: Target file exists: $(iso_filename))
$(info OK: We will not rebuild target (remove it, or use: make -B))
endif


# all the config/archives/*.key files
pubkeys_raw=$(subst config/archives/,,$(wildcard config/archives/*.key))
# changes '.key' to '.asc'
pubkeys_raw_2=$(subst .key,.asc,${pubkeys_raw})
# adds prefix config/archives/ to each key
pubkeys=$(addprefix config/archives/, ${pubkeys_raw})
# for the copies: binary and chroot
copies1=$(addprefix config/includes.chroot/usr/share/keyrings/, ${pubkeys_raw_2})
copies2=$(addprefix config/includes.chroot/usr/share/keyrings/, ${pubkeys_raw_2})
# for preferences
copies3=config/includes.chroot/etc/apt/preferences.d/aerthos-mozilla-archive config/includes.binary/etc/apt/preferences.d/aerthos-mozilla-archive
# when adding a key here, add a .list file beside it
supported_keys=\
	config/archives/aerthos-brave-browser-archive-keyring.key \
	config/archives/aerthos-chrome-archive-keyring.key \
	config/archives/aerthos-docker-archive-keyring.key \
	config/archives/aerthos-microsoft-archive-keyring.key \
	config/archives/aerthos-mozilla-archive-keyring.key
source_repos=$(wildcard config/archives/*.list)
# copy_repos1 = $(subst config/archives,config/includes.binary/etc/apt/sources.list.d,${source_repos})
copy_repos2 = $(subst config/archives,config/includes.chroot/etc/apt/sources.list.d,${source_repos})
copy_repos = ${copy_repos1} ${copy_repos2}
# for copykeys target
all_copies=${supported_keys} ${pubkeys} ${copies1} ${copies2} ${copies3} ${copy_repos}
default: checkprogs all
checkprogs:
	test ! -f "${iso_filename}" || echo "Warning: ${iso_filename} already exists, will not be rebuilt unless you use -B or clean"
all: ${iso_filename}  # copy the keys and build the iso
	@echo iso=${iso_filename}
	sha256sum $^
	@echo complete: $^
walkaway:
	ifeq (${ADEVICE},)
	$(error "Please set ADEVICE to the USB device to use")
	endif
	@test -n "${ADEVICE}" || exit 2
	@test $(shell id -u) = 0 || (echo "Error: Please run as root"; exit 1)
	@dialog --yesno "Are you sure you want to flash ${ADEVICE}?" 7 60
	@dialog --yesno "Are you sure you want to flash ${ADEVICE}? There will be no more confirmation dialogs! The device will be WIPED!" 7 60
	test -e ${iso_filename} || ${MAKE} ${iso_filename}
	AUTO=1 ./flash.bash flash ${ADEVICE}
	./boot.bash -3 sda

${iso_filename}: config/common ${all_copies} # build the iso 
	@echo building: $@
	bash build.bash
	@echo done building: $@
	chown ${SUDO_USER}:kvm $@
copyrepos: ${copy_repos}
	echo "Apt Sources:"
	@ls -l $^
refresh_keys: ${supported_keys}
echo:
	@echo pubkeys="(${pubkeys})"
	@echo iso="(${iso_filename})"
	@echo copies1="(${copies1})"
	@echo copies2="(${copies2})"
	@echo copies3="(${copies3})"
	@echo all_copies=${all_copies}
help: # show this help
	@echo "make ${iso_filename}"
clean:
	rm -fv ${copies1} ${copies2} ${copies3} *.log
	bash build.bash -r 
copykeys : ${all_copies}
	ls -l $^
# copy small things
config/includes.chroot/usr/share/keyrings/%.asc: config/archives/%.key
	mkdir -p config/includes.chroot/usr/share/keyrings/
	cp -v $< $@
config/includes.chroot/etc/apt/sources.list.d/%.list: config/archives/%.list
	mkdir -p config/includes.chroot/etc/apt/sources.list.d/
	cp -v $< $@
# config/includes.binary/usr/share/keyrings/%.asc: config/archives/%.key
# 	mkdir -p config/includes.binary/usr/share/keyrings/
# 	cp -v $< $@
# config/includes.binary/etc/apt/sources.list.d/%.list: config/archives/%.list 
# 	mkdir -p config/includes.binary/etc/apt/sources.list.d/
# 	cp -v $< $@
config/includes.binary/etc/apt/preferences.d/aerthos-mozilla-archive: # preferences (binary)
	mkdir -p config/includes.binary/etc/apt/preferences.d/
	cp -v config/archives/aerthos-mozilla.pref $@
config/includes.chroot/etc/apt/preferences.d/aerthos-mozilla-archive: # preferences
	mkdir -p config/includes.chroot/etc/apt/preferences.d/
	cp -v config/archives/aerthos-mozilla.pref $@
config/archives/aerthos-chrome-archive-keyring.key: # chrome key
	mkdir -p $(dir $@)
	curl -o $@ https://dl.google.com/linux/linux_signing_key.pub
	chmod 644 $@
config/archives/aerthos-brave-browser-archive-keyring.key: # brave key
	mkdir -p $(dir $@)
	curl -o $@ https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.asc
	chmod 644 $@
config/archives/aerthos-docker-archive-keyring.key: # docker key
	mkdir -p $(dir $@)
	curl -o $@ https://download.docker.com/linux/debian/gpg 
	chmod 644 $@
config/archives/aerthos-microsoft-archive-keyring.key: # microsoft key for vscode
	mkdir -p $(dir $@)
	curl -o $@ https://packages.microsoft.com/keys/microsoft.asc
	chmod 644 $@
config/archives/aerthos-mozilla-archive-keyring.key: # mozilla key
	mkdir -p $(dir $@)
	curl -o $@ https://packages.mozilla.org/apt/repo-signing-key.gpg
	chmod 644 $@

# LIBVIRT_STORAGE_PATH := /var/lib/libvirt/images
# OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.ms.fd
# OVMF_VARS_ORIG=/usr/share/OVMF/OVMF_VARS_4M.ms.fd
# # a local copy
# OVMF_VARS=tmp/$(shell basename ${OVMF_VARS_ORIG})
# LIBVIRT_DUMMY=${LIBVIRT_STORAGE_PATH}/aerthos-test-disk0.qcow2
# LIBVIRT_IMAGE=${LIBVIRT_STORAGE_PATH}/aerthOSLive-amd64$(image_ext)
# .PHONY: test_kvm_uefi # test resulting live image in libvirt VM with UEFI
# PWD := $(shell pwd)
# # @test ! -e "${iso_filename}" || mv -v ${iso_filename} "${LIBVIRT_IMAGE}"
# # @test -e "${LIBVIRT_IMAGE}" || { echo "No image found at ${LIBVIRT_IMAGE}, please build the iso first" && exit 1; }
# # @test -e "${LIBVIRT_IMAGE}"
# check_virt_efi: 
# 	@test -e "${OVMF_CODE}" || echo "No OVMF_CODE found, please install ovmf package"
# 	@test -e "${OVMF_VARS_ORIG}" || echo "No OVMF_VARS found, please install ovmf package"
# 	@test -e "${OVMF_VARS_ORIG}" || exit 1
# 	@echo 'ready for virt'
# qemu_usb: # wow one line
# 	test -b /dev/${ADEVICE} || die "ADEVICE is not a block device"
# 	test -n "${ADEVICE}" || echo "ADEVICE not set"
# 	test -n "${ADEVICE}" || exit 2
# 	bash -c 'test "$(shell free -b | tail -n -2 | head -n 1 | awk '{print $$4}')" -gt 6442450944 || (echo "Not enough memory" && exit 1)'
# 	kvm -m 6G -drive file=/dev/${ADEVICE},format=raw
# qemu_hdd:
# 	@test -n "${iso_filename}" || echo "IMAGE not set"
# 	@test -n "${iso_filename}" || exit 2
# 	@test -e "${iso_filename}" || { echo "image ${iso_filename} not found" && exit 1; }
# 	kvm -no-reboot -hda ${iso_filename} -m 4096 -vga virtio
# qemu_binary: # tmp/live-build/binary/live
# 	qemu-system-x86_64 \
# 		-enable-kvm \
# 		-m 4096 \
# 		-vga virtio \
# 		-hda ${LIBVIRT_DUMMY} \
# 		-drive file=tmp/live-build/binary/live/filesystem.ext4,format=raw,if=virtio,readonly=on 
# 		-kernel tmp/live-build/binary/live/vmlinuz \
# 		-initrd tmp/live-build/binary/live/initrd.img \
# 		-append "boot=live components ${APPENDS}"
# qemu_binary_installer: # tmp/live-build/binary/live
# 	@echo creating mini-cdrom
# # tmp/live-build/binary/boot/extlinux/
# 	cd tmp/live-build/binary && \
# 		mkisofs -o ../../mini-cdrom.iso \
# 			-m live .
			
# 	@echo done creating mini-cdrom: tmp/mini-cdrom.iso
# 	@ls -l tmp/mini-cdrom.iso
# 	qemu-system-x86_64 \
# 		-enable-kvm \
# 		-m 4096 \
# 		-vga virtio \
# 		-hda ${LIBVIRT_DUMMY} \
# 		-cdrom tmp/mini-cdrom.iso \
# 		-kernel tmp/live-build/binary/install/vmlinuz \
# 		-initrd tmp/live-build/binary/install/initrd.gz \
# 		-append "theme=dark file=/hd-media/install/preseed.cfg file=/hd-media/install/preseed.cfg ${APPENDS}"
# qemu_fs: ${OVMF_VARS}
# 	qemu-system-x86_64 \
# 		-enable-kvm \
# 		-m 4096 \
# 		-vga virtio \
# 		-machine q35,smm=on \
# 		-global driver=cfi.pflash01,property=secure,value=on \
# 		-drive if=pflash,format=raw,unit=0,file=${OVMF_CODE},readonly=on \
# 		-drive if=pflash,format=raw,unit=1,file=${OVMF_VARS} \
# 		-hda ${LIBVIRT_DUMMY} \
# 		-drive file=tmp/live-build/binary/live/filesystem.${LB_BINARY_FILESYSTEM},format=raw,if=virtio,readonly=on \
# 		-device usb-storage,bus=xhci.0,drive=stick,removable=on \
# # -usb -device usb-host,hostdevice=/dev/bus/usb/001/005 

# ${OVMF_VARS}: ${OVMF_VARS_ORIG}
# 	@test -f ${OVMF_VARS} || mkdir -p tmp; cp -v ${OVMF_VARS_ORIG} ${OVMF_VARS}
# test_kvm_uefi: check_virt_efi
# 	# @test ! -f ${iso_filename} || echo "iso exists, moving it"
# 	# @test ! -f ${iso_filename} || mv -v ${iso_filename} "${LIBVIRT_IMAGE}"
# 	@test -f ${LIBVIRT_DUMMY} || echo "qemu disk does not exist, creating it"
# 	@test -f ${LIBVIRT_DUMMY} || qemu-img create -f qcow2 "${LIBVIRT_DUMMY}" 20G
# 	@test "tmp/live-build/aerthOSLive-amd64.img" != "${iso_filename}" || echo cant boot efi hdd mode
# 	@test "tmp/live-build/aerthOSLive-amd64.img" != "${iso_filename}"
# 	@echo
# 	@echo "Starting VM with UEFI qemu"
# 	@echo "To confirm EFI boot, run in the container:"
# 	@echo "    test -d /sys/firmware/efi && echo UEFI || echo BIOS"
# 	@echo "    sudo mokutil --sb-state"

# # -device usb-host,hostdevice=/dev/bus/usb/001/005
# # -device qemu-xhci \
# # -usb -device u2f-passthru,hidraw=/dev/hidraw2
# 	qemu-system-x86_64 \
# 		-enable-kvm \
# 		-m 4096 \
# 		-vga virtio \
#         -machine q35,smm=on \
#         -global driver=cfi.pflash01,property=secure,value=on \
# 		-drive media=cdrom,file=${iso_filename},format=raw,if=virtio,readonly=on \
# 		-drive if=pflash,format=raw,unit=0,file=${OVMF_CODE},readonly=on \
#         -drive if=pflash,format=raw,unit=1,file=${OVMF_VARS} \
# 		-hda ${LIBVIRT_DUMMY}

# -usb -device u2f-passthru 
.PHONY: help
.PHONY: copykeys
.PHONY: all
.PHONY: clean
.PHONY: echo
.PHONY: refresh_keys
.PHONY: copyrepos
