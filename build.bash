#!/bin/bash
export DIALOGRC=$PWD/config/includes.chroot/etc/dialogrc
# set -u, pipefail, nullglob
set -uo pipefail || {
    echo "set -u, pipefail, nullglob not supported"
    exit 1
}
shopt -s nullglob || {
    echo "shopt -s nullglob not supported"
    exit 1
}
set -e

type lb eatmydata apt-cacher-ng || apt install -y live-build eatmydata apt-cacher-ng

type dialog || apt install -y dialog 
dialog_wr(){
    trap 'echo "aborting build"; exit 1' INT TERM HUP QUIT
    command dialog --backtitle "aerthOS" "$@" 1>/dev/tty 2>&1 3>&1
    return $?
}
dialog(){
    dialog_wr "$@"
    return $?
}
echo "Building ISO"
isobuilderpid=$$

print_help(){
    echo "Usage: sudo $0 [optional-flags]"
    echo "Flags:"
    echo "  -c, --continue   continue a PREVIOUS build (unstable)"
    echo "  -r, --remove     remove the build directory (used by make clean)"
    echo "  -h, --help       show this help message"
    exit 1
}
[ $(id -u) -eq 0 ] || {
    echo "This build script must be run as root"
    print_help
    exit 1
}
cleanup() (
    set +e
    if [ ! -d tmp/live-build ]; then
        echo "cant cleanup without a build directory"
        return 0
    fi
    # TODO: re-enable this 
    trap 'echo "aborting cleanup"; return 101' INT TERM HUP QUIT
    dialog --pause "Do you want to remove the build directory?" 0 0 5 1>/dev/tty
    if [ $? -ne 0 ]; then
        echo "aborting cleanup"
        return 1
    fi
    cd tmp/live-build || return 1
    lb clean --all
    cd -
    rm -rf tmp/live-build
)
continue_build() {
    if [ ! -d tmp/live-build ]; then
        echo "cant continue build without a build directory"
        exit 1
    fi
    set -e
    cd tmp/live-build
    echo "Continuing build at $(date)" | tee -a build.log
    lb build --debug |& tee -a build.log
    cd -
}


while getopts ":crh" opt; do
    case $opt in
    c)
        continue_build
        exit $?
        ;;
    r)
        cleanup
        exit $?
        ;;
    h)
        print_help
        exit 1
        ;;
    \?)
        echo "invalid option: -$OPTARG" >&2
        print_help
        exit 1
        ;;
    :)
        echo "option -$OPTARG requires an argument." >&2
        print_help
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

[ "${#@}" -eq 0 ] || case $1 in
-h | --help)
    print_help
    exit 1
    ;;
--continue)
    continue_build
    exit 0
    ;;
--remove)
    cleanup
    exit 0
    ;;
"")
    ;;
*)
    print_help
    exit 1
    ;;
esac



test ! -f "tmp/live-build/*.iso" || {
    dialog --defaultno --yesno "An ISO already exists. Do you want to remove it?" 7 60 1>/dev/tty
    if [ $? -ne 0 ]; then
        echo "aborting build, output already exists"
        exit 0
    fi
    rm -f tmp/live-build/*.iso
}

DIALOG_TIMEOUT=0 dialog --title aerthOS --pause "Building ISO\nThis will take a minute!" 10 0 5 1>/dev/tty
if [ $? -ne 0 ]; then
    echo "aborting build, user cancelled"
    exit 1
fi
test ! -d tmp/live-build || (cleanup || exit $?)
mkdir -p tmp/live-build
rsync -av config/ tmp/live-build/config/ |& tee rsync.log
rm -vf tmp/live-build/config/archives/*
cd tmp/live-build
lb config --debug |& tee config.log
lb build --debug |& tee build.log
if [ $? -ne 0 ]; then
    echo "build failed"
    exit 1
fi
echo "build finished"
