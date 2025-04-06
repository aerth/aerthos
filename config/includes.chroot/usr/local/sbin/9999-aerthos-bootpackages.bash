#!/bin/bash
if [ $(id -u) -ne 0 ]; then
    echo "This script must be run as root"
    exec sudo "$0" "$@"
fi
pkgs=()
for pkg in $(cat /var/lib/aerthos/package-list.txt); do
    if [ -z "$pkg" ] || [[ $pkg == \#* ]]; then
        continue
    fi
    if dpkg -L $pkg 1>/dev/null 2>&1; then
        echo "Package $pkg already installed"
    else
        echo "We will install $pkg"
        pkgs+=("$pkg")
    fi
done
for pkg in $(cat /var/lib/aerthos/package-list-huge.txt); do
    if [ -z "$pkg" ] || [[ $pkg == \#* ]]; then
        continue
    fi
    if dpkg -L $pkg 1>/dev/null 2>&1; then
        echo "Package $pkg already installed"
    else
        echo "We will install $pkg"
        pkgs+=("$pkg")
    fi
done

if [ ${#pkgs[@]} -gt 0 ]; then
    echo "Installing packages: ${pkgs[@]}"
    apt install -y "${pkgs[@]}" | logger -s || true
else
    echo "No new packages to install"
fi
