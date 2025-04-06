#!/bin/bash
if [ $(id -u) -ne 0 ]; then
    echo "This script must be run as root"
    exec sudo "$0" "$@"
fi
dpkg -L code google-chrome-stable && echo "packages already installed" && exit 0
# if persistence is enabled, this will run once. otherwise, it will run every live-boot
apt update  | logger -s || true
apt install -y ccache autoconf autoconf-archive automake cmake clang-tidy qtcreator-doc \
        qtcreator libgtk-4-dev libgtk-3-dev libgtk2.0-dev xfce4-dev-tools cmake qt6-base-dev \
        qt6-tools-dev-tools qt6-wayland | logger -s || true
# these are >1GB each and too big for the ISO
apt install -y code google-chrome-stable | logger -s || true
echo All done with 9999-aerthos-bootpackages.bash | logger -s