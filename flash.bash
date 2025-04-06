#!/bin/bash
# flash.bash - flash the iso to a usb drive
# dd is OK but persistence is needed
# Usage: sudo ./flash.bash [optional-flags]


# for dialog theme
export DIALOGRC=$PWD/config/includes.chroot/etc/dialogrc

# for post-flash git clone into persistence dir
export this_wd=$PWD
fatal() {
    echo "fatal: $@" 1>&2
    exit 1
}
DEVELOP=1 source config/common || {
    echo "Error: config/common not found"
    exit 1
}
set -o pipefail || fatal "shell option 'set -o pipefail' not supported"
set -u || fatal "shell option 'set -u' not supported"
shopt -s nullglob || fatal "shopt -s nullglob not supported"
cmddialog=$(command -v dialog)
dialog_wr() (
    trap "echo 'Caught signal, cleaning up'; return 1" SIGINT SIGTERM
    ${cmddialog} --backtitle "aerthOS" "$@" 1>/dev/tty 2>&1 3>&1
    dialogexit=$?
    echo "dialogexit=$dialogexit"
    return $dialogexit
)
dialog() {
    dialog_wr "$@"
    dialogexit=$?
    echo "dialogexit_wr=$dialogexit"
    return $dialogexit
}

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
export aerthos_image_filename=./tmp/live-build/aerthOSLive-amd64.${image_ext#.}

# image_ext=.iso
# else ifeq ($(LB_IMAGE_TYPE),hdd)
# image_ext=.hdd
# else ifeq ($(LB_IMAGE_TYPE),iso-hybrid)
# image_ext=.hybrid.iso
# else ifeq ($(LB_IMAGE_TYPE),)
# $(error "No build mode specified. Edit config/common or set the environment variable LB_IMAGE_TYPE")
# else
# $(error "Unknown build mode: $(LB_IMAGE_TYPE)")
# endif

print_help() {
    echo input file: ${aerthos_image_filename}
    echo "Usage: sudo $0 [optional-flags]"
    echo "Flags:"
    echo "  -h, --help       show this help message"
    echo "  flash sdx        flash the iso to a usb drive"
    exit 1
}
[ ${#@} -ne 0 ] || {
    echo "No arguments provided"
    print_help
    exit 1
}
# [ $(id -u) -eq 0 ] || fatal "This script must be run as root"

# usage: do_flash_usb sdx
do_flash_usb() {
    echo do_flash_usb
    set -e
    if [ ${#@} -eq 0 ] || [ -z "$1" ]; then
        echo "usage: do_flash_usb sdx"
        exit 1
    fi
    ADEVICE=$1
    echo "Flashing ${aerthos_image_filename} to /dev/${ADEVICE}"
    test_flash $1
    do_real_flash $1
    echo "Done flashing to /dev/${ADEVICE}"
}

test_flash() {
    if [ ${#@} -eq 0 ] || [ -z "$1" ]; then
        echo "usage: test_flash sdx"
        exit 1
    fi
    ADEVICE=$1
    deviceinfo=$(lsblk -n -o NAME,SIZE,TYPE,MODEL,VENDOR /dev/${ADEVICE} 2>/dev/null | head -n 1 | awk '{print "Device: "$1"\\nSize: "$2"\\nType: "$3"\\nModel: "$4"\\nVendor: "$5}')
    device_size=$(lsblk -bnao SIZE /dev/${ADEVICE} | head -n 1) # minus the partitions if any
    lsblk -nao NAME,SIZE,TYPE,MODEL,LABEL /dev/${ADEVICE}
    if [ -b /dev/${ADEVICE}1 ]; then
        label=$(lsblk -nao LABEL /dev/${ADEVICE} | head -n 1)
        case $label in
        aerthOS_*)
            echo "Device /dev/${ADEVICE}1 has label aerthOSLive"
            [ "${AUTO-0}" == 1 ] || dialog --yesno "Device /dev/${ADEVICE}1 has label aerthOSLive, do you want to remove it?\nAll persistence data will be DELETED. OK?" 0 0 
            if [ $? -ne 0 ]; then
                echo "User cancelled"
                exit 1
            fi
            wipefs -a /dev/${ADEVICE}
            ;;
        *)
            echo "Error: Device /dev/${ADEVICE}1 exists already, please remove it with wipefs -a /dev/${ADEVICE}"
            exit 1
            ;;
        esac
    fi
    num_partitions=$(($(lsblk -n -o NAME /dev/${ADEVICE} | wc -l) - 1)) # minus the device itself
    [ $num_partitions -eq 0 ] || {
        echo "Error: Device /dev/${ADEVICE} has $num_partitions partitions. Remove them or use a different device." 2>&1
        echo "Partitions found:" 2>&1
        lsblk -n -o NAME,SIZE,TYPE,MODEL,VENDOR,FSTYPE /dev/${ADEVICE} | sed 's/^/    /' 2>&1
        echo -e "You can remove them all with..(THIS WILL DELETE ALL ABOVE PARTITIONS)\n\t'sudo wipefs -a /dev/${ADEVICE}'" 2>&1
        fatal "Device has partitions"
    }
    echo "Device size: ${device_size}"
    echo "Device info: ${deviceinfo}"
    isofilesize=$(stat -c %s ${aerthos_image_filename})

    test -e "${aerthos_image_filename}" || fatal "File ${aerthos_image_filename} does not exist. Please run 'make iso' first"
    test -b "/dev/${ADEVICE}" || fatal "Device /dev/${ADEVICE} does not exist"
    echo "Checking if we can flash ${aerthos_image_filename} to /dev/${ADEVICE}"
    lsblk -nao NAME,SIZE,TYPE,MODEL,LABEL /dev/${ADEVICE}
    test -n "${device_size}" || fatal "Device size not found"
    test "${device_size}" -lt 1000753467904 || fatal "Error: Device /dev/${ADEVICE} is too large (${device_size} bytes). Please use a smaller device."
    test "${device_size}" -lt 1000753467904
    test -n "${ADEVICE}" || fatal "missing ADEVICE env var. To flash to usb device /dev/sdx, use 'make flash ADEVICE=sdx'"
    test -b "/dev/${ADEVICE}" || fatal "Missing ADEVICE env var. To flash to usb device /dev/sdx, use 'make flash ADEVICE=sdx'"
    test -b "/dev/${ADEVICE}" || fatal "Device /dev/${ADEVICE} does not exist"
    test -n "${deviceinfo}" || fatal "Device info not found"
    test -n "${isofilesize}" || fatal "File size not found"
}

read_file_pv(){
    pv -n -s ${isofilesize} ${aerthos_image_filename}
}

write_stdin_dd(){
    dd "of=/dev/${ADEVICE}"
}

do_real_flash() {
    test -f ${aerthos_image_filename} || (
        echo "Error: File ${aerthos_image_filename} does not exist. Please run 'make iso' first"
        exit 1
    )
    test -b /dev/${ADEVICE} || (
        echo "Error: Device /dev/${ADEVICE} does not exist"
        exit 1
    )
    echo Flashing ${aerthos_image_filename} to /dev/${ADEVICE}
    file ${aerthos_image_filename} || true
    ls -lh "${aerthos_image_filename}"

    test ! -b /dev/${ADEVICE}1 || (
        exit 1
    )
    test ! -b /dev/${ADEVICE}1

    if [ "${AUTO-0}" != "1" ]; then
        dialog --defaultno --yesno "Are you sure you want to flash to /dev/${ADEVICE}?\n${deviceinfo}\n$(lsblk -nf /dev/${ADEVICE})" 0 0 || (
            echo "User cancelled"
            exit 1
        )
        dialog --defaultno --yesno "Are you REALLY sure you want to flash to /dev/${ADEVICE}?\n${deviceinfo}" 0 0 || (
            echo "User cancelled"
            exit 1
        )
    fi
    echo "Flashing to /dev/${ADEVICE} in 3 seconds..."
    sleep 1
    echo "Flashing to /dev/${ADEVICE} in 2 seconds..."
    sleep 1
    #type pv || {
    #    echo "pv not found, please install pv (apt install pv) to use this feature"
    #    exit 1
    #}
    bs=$(lsblk -b -n -o PHY-SEC /dev/${ADEVICE} 2>/dev/null | awk '{print $1}' | head -n 1)
    echo bs=${bs}
    test -n "${bs}" || fatal "Something went wrong. To flash to usb device /dev/sdx, use 'make flash ADEVICE=sdx'"
    if [ -z "$bs" ]; then
        bs=512
        echo "error: block size not found. 512?" 1>&2
        exit 3
    fi
    echo "Flashing to /dev/${ADEVICE} with block size ${bs}, this might take a while!"
    sleep 1
    echo "Flashing to /dev/${ADEVICE} with block size ${bs}, this might take a while!.. LAST CHANCE TO CANCEL"
    sleep 1
    date
    trap "echo 'Caught signal, cleaning up'; sync; exit 1" SIGINT SIGTERM
    humansize=$(numfmt --to=iec --suffix=B $isofilesize)
    echo "Flashing ${aerthos_image_filename} to /dev/${ADEVICE} (${humansize})"
    set -x
    # (pv -n -s ${isofilesize} ${aerthos_image_filename} | dd "of=/dev/${ADEVICE}"; echo $? > /tmp/dd.exitcode) 2>&1 | dialog --title aerthOS --gauge "Flashing ${aerthos_image_filename} to /dev/${ADEVICE}\nISO Size: ${humansize}" 10 70 0
    dd if=${aerthos_image_filename} of=/dev/${ADEVICE} bs=${bs} status=progress conv=fsync
    exitcode=$?
    echo "Flashing to /dev/${ADEVICE} finished.. now adding persistence"
    sleep 1
    echo "Syncing /dev/${ADEVICE}..."
    sync
    if [ $exitcode -ne 0 ]; then
        echo "Error: dd failed with exit code $exitcode"
        exit 1
    fi
    echo "Done flashing to /dev/${ADEVICE}"
    echo "Creating UNFORMATTED persistence partition"
    persistence_num=$(lsblk -n /dev/${ADEVICE} | wc -l)
    fdisk "/dev/${ADEVICE}" <<<$(printf "n\np\n\n\n\nw\nq\n") || {
        echo "Error: fdisk failed"
        exit 1
    }
    exitcode=$?
    if [ $exitcode -ne 0 ]; then
        echo "Error: fdisk failed"
        exit 1
    fi
    set +x
    echo "Creating ext4 filesystem on /dev/${ADEVICE}${persistence_num}"
    [ -b "/dev/${ADEVICE}${persistence_num}" ] || {
        echo "Error: /dev/${ADEVICE}${persistence_num} does not exist"
        exit 1
    }
    mkfs.ext4 -L persistence /dev/${ADEVICE}${persistence_num} || {
        echo "Error: mkfs.ext4 failed"
        exit 1
    }
    mkdir -p /mnt/persistence || {
        echo "Error: mkdir failed"
        exit 1
    }
    mount /dev/${ADEVICE}${persistence_num} /mnt/persistence || {
        echo "Error: mount failed"
        exit 1
    }
    chown 1000:1000 /mnt/persistence || {
        echo "Error: chown failed"
        exit 1
    }
    test -f /mnt/persistence/persistence.conf 1>/dev/null || (echo "/ union" | tee /mnt/persistence/persistence.conf) || {
        echo "Error: echo failed"
        exit 1
    }
    git clone ${this_wd} /mnt/persistence/src/aerthos
    echo "Saved aerthos source to persistence drive"
    umount /dev/${ADEVICE}${persistence_num} || {
        echo "Error: umount failed"
        exit 1
    }
    rmdir /mnt/persistence
    sync
    echo "Done creating persistence partition"
    echo "Done flashing to /dev/${ADEVICE}"
    date
}

case $1 in
-h | --help | help)
    print_help
    exit 1
    ;;
flash)
    if [ ${#@} -ne 2 ] || [ -z "$2" ]; then
        echo "usage: $0 flash sdx"
        echo "Available devices (DANGER!!! This will erase the device!!! Choose carefully)"
        lsblk -d -o NAME,SIZE,TYPE,MODEL,VENDOR | sed 's/^/    /'
        echo "Example: $0 flash sdx"
        exit 1
    fi
    test -b /dev/$2 || fatal "Device /dev/$2 does not exist"
    test_flash $2 || fatal "Test failed"
    echo OK
    do_flash_usb $2 |& tee /tmp/flash.log
    exitcode=$?
    if [ $exitcode -ne 0 ]; then
        echo "Error: do_flash_usb failed with exit code $exitcode"
        exit 1
    fi
    echo "Done flashing to /dev/$2"
    echo "You can now boot from /dev/$2"
    exit 0
    ;;
*)
    echo "Unknown option: $1" 1>&2
    print_help
    exit 1
    ;;
esac
exit $?
# foo() {
#     # echo trying false
#     false && fatal "false failed"
#     echo false=$?
#     # echo trying true
#     true || fatal "true failed"
#     echo true=$?
# }
