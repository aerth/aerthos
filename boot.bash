#!/bin/bash
# boot.bash - boot from qemu, kvm etc
set -euo pipefail
shopt -s nullglob

export DIALOGRC=$PWD/config/includes.chroot/etc/dialogrc
fatal() {
    echo "fatal: $@" 1>&2
    exit 1
}
DEVELOP=1 source config/common || {
    echo "Error: config/common not found"
    exit 1
}
set -o pipefail || fatal "shell option 'set -o pipefail' not supported"
set -e || fatal "shell option 'set -e' not supported"
set -u || fatal "shell option 'set -u' not supported"
shopt -s nullglob || fatal "shopt -s nullglob not supported"

dialog_wr() {
    command dialog --backtitle "aerthOS" "$@" 1>/dev/tty 2>&1 3>&1
    return $?
}
dialog() {
    dialog_wr "$@"
    return $?
}

this_command=$0
all_args="${@}"
M_QEMU_SYSLINUX=1
M_QEMU_EFI=2
M_USBTEST=3

image_ext=.iso
case $LB_IMAGE_TYPE in
iso)
    image_ext=.iso
    ;;
hdd)
    image_ext=.img
    ;;
iso-hybrid)
    image_ext=.hybrid.iso
    ;;
*)
    echo "Unknown build mode: ${LB_IMAGE_TYPE}"
    exit 1
    ;;
esac
[ -n "${LB_IMAGE_TYPE}" ] || {
    echo "No build mode specified. Edit config/common or set the environment variable LB_IMAGE_TYPE"
    exit 1
}
default_imagefile=./tmp/live-build/aerthOSLive-amd64.${image_ext#.}

show_help() {
    echo "Usage: $0 [-options] [imagefile]"
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -${M_QEMU_SYSLINUX}                Boot ISO with QEMU (BIOS  syslinux boot tmp/live-build/aerthOSLive-amd64.img)"
    echo "  -${M_QEMU_EFI}                Boot ISO with QEMU (EFI boot tmp/live-build/aerthOSLive-amd64.hybrid.iso)"
    echo "  -${M_USBTEST}                Boot ISO with KVM (actual) USB stick (EFI boot \$ADEVICE)"

}

bootmode=0
imagefile=${default_imagefile}
while getopts ":h${M_QEMU_SYSLINUX}${M_QEMU_EFI}${M_USBTEST}" opt; do
    case $opt in
    h)
        show_help
        exit 0
        ;;
    ${M_QEMU_SYSLINUX})
        bootmode=$M_QEMU_SYSLINUX
        ;;
    ${M_QEMU_EFI})
        bootmode=$M_QEMU_EFI
        ;;
    ${M_USBTEST})
        bootmode=$M_USBTEST
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        echo Want: ${M_QEMU_SYSLINUX} ${M_QEMU_EFI} ${M_USBTEST}
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))
if [ $# -gt 0 ]; then
    imagefile=$1
fi
if [ $bootmode -eq 0 ]; then
    echo "No boot mode selected, use -1 for KVM or -2 for QEMU"
    exit 1
fi

# -drive file="$imagefile",format=raw,if=virtio,readonly=on \

# -1
boot_qemu_syslinux() {
    echo "Booting aerthos hdd as fake usb drive (BIOS boot)..."
    exec qemu-system-x86_64 -no-reboot -enable-kvm -m 6096 -smp 4 -vga qxl \
        -chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on \
        -device virtio-serial-pci \
        -device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0 \
        -hda ${imagefile}

}

# -3
boot_usbtest() {
    if [ $# -eq 0 ]; then
        echo "No USB device specified, try ${this_command} ${all_args} sda"
        return 1
    fi
    echo "Booting with KVM USB (EFI boot)..."
    exec kvm -m 6G -no-reboot -drive file=/dev/${1},format=raw,if=virtio,readonly=on
}

copy_to_writable() {
    local src=$1
    local dest=tmp/$(basename "$src")

}

# -2
boot_qemu_efi() {
    echo "Booting with QEMU (EFI boot)..."
    qemu-system-x86_64 -enable-kvm -no-reboot -m 6096 -smp 2 \
        -drive file="$imagefile",format=raw,if=virtio,readonly=on \
        -vga virtio \
        -net nic,model=virtio \
        -bios /usr/share/OVMF/OVMF_CODE.fd
}
set -x
case $bootmode in
${M_QEMU_SYSLINUX})
    # Boot with QEMU (BIOS boot)
    echo "Booting with QEMU (BIOS boot)..."
    boot_qemu_syslinux
    ;;
${M_QEMU_EFI})
    # Boot with QEMU (EFI boot)
    echo "Booting with QEMU (EFI boot)..."
    boot_qemu_efi
    ;;
${M_USBTEST})
    # Boot with KVM USB (EFI boot)
    echo "Booting with KVM USB (EFI boot)..."
    if [ $# -eq 0 ]; then
        echo "No USB device specified, try ${this_command} ${all_args} sda"
        exit 1
    fi
    boot_usbtest "$@"
    ;;
*)
    echo "Invalid boot mode"
    exit 1
    ;;
esac
