#!/bin/bash
pkgs=()
test ! -f /var/lib/aerthos/package-list.txt || for pkg in $(cat /var/lib/aerthos/package-list.txt); do
    if [ -z "${pkg/# }" ] || [[ $pkg == \#* ]]; then
        continue
    fi
    if ! dpkg -L $pkg 1>/dev/null 2>&1; then
        pkgs+=("$pkg")
    fi
done
test ! -f /var/lib/aerthos/package-list-huge.txt || for pkg in $(cat /var/lib/aerthos/package-list-huge.txt); do
    if [ -z "${pkg/# }" ] || [[ $pkg == \#* ]]; then
        continue
    fi
    if ! dpkg -L $pkg 1>/dev/null 2>&1; then
        pkgs+=("$pkg")
    fi
done
if [ ${#pkgs[@]} -eq 0 ]; then
    echo "No packages to install"
    exit 0
fi
menupkgs=()
for pkg in "${pkgs[@]}"; do
    if [ -z "${pkg/# }" ] || [[ $pkg == \#* ]]; then
        continue
    fi
    # menupkgs+=("$pkg" "$(apt show ${pkg} | grep Installed-Size | awk '{print $2 " " $3}')" "on")
    # filesize=$(dpkg-query -W -f="${Installed-Size;8} ${pkg}" "${pkg}" 2>/dev/null)
    pkginfo=$(apt show "${pkg}" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Package $pkg not found"
        continue
    fi
    # Extract the human-readable installed size and synopsis from the package info
    filesize=$(echo "$pkginfo" | grep -i "Installed-Size:" | awk '{print $2 $3}')
    synopsis=$(echo "$pkginfo" | grep -i "Synopsis:" | cut -d' ' -f2-)
    if [ $? -ne 0 ]; then
        echo "Package $pkg not found"
        continue
    fi
    menupkgs+=("$pkg" "${filesize} ${synopsis}" "on")
done
echo All packages: "${menupkgs[@]}"
if [ ${#menupkgs[@]} -eq 0 ]; then
    echo "No packages to install"
    exit 0
fi
message="Free space: $(df -h / | grep / | awk '{print $4}')\nPersistence: $(test -d /run/live/persistence/* && echo "enabled" || echo "disabled")\n\n"
option=$(dialog --no-clear --checklist "Choose packages to install:\n$message" 0 0 0 "${menupkgs[@]}" 2>&1 1>/dev/tty)
exitstatus=$?
if [ $exitstatus -ne 0 ]; then
    echo "Cancel"
    exit 0
fi
if [ -z "$option" ]; then
    echo "No packages selected for installation"
    exit 0
fi
pkgs=${option//\"/}
if [ ${#pkgs[@]} -eq 0 ]; then
    echo "No packages selected for installation"
    exit 0
fi

if [ ${#pkgs[@]} -gt 0 ]; then
    echo "Installing packages: ${pkgs[@]}"
    sudo apt install -y "${pkgs[@]}" | logger -s || true
else
    echo "No new packages to install"
fi
