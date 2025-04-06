#!/bin/bash
set -u
set -x
set -o pipefail
shopt -s nullglob


# password: live
# user: builder
grep ${LIVE_USER-builder} /etc/passwd || (echo "no live user yet")
grep ${LIVE_USER-builder} /etc/passwd && (echo "${LIVE_USER-builder}:live" | chpasswd && echo "password set for ${LIVE_USER-builder}")

SKELDIR=/etc/skel
type _log 2>/dev/null || {
    _log() {
        echo "$@" 1>&2
    }
}

install_theme_xfwm_root() {
    update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper
    if [ -f /usr/bin/aerthos-browser ]; then
        update-alternatives --set x-www-browser /usr/bin/aerthos-browser
    else
        _log "Warning: no aerthos-browser detected while 0020 hook is running, proceeding.."
    fi
    type wget unzip || apt install -y wget unzip
    if [ ! -d /usr/share/themes/McOS-XFCE-Edition-II ]; then
        url=https://github.com/brudolp/McOS-XFCE-Edition/archive/d5ff59ff18429e175d77a5c34fd0349cf8909fb2.zip
        tmpdir=$(mktemp -d)
        wget -t 20 --retry-on-host-error $url -O ${tmpdir}/McOS-XFCE-Edition.zip
        if [ $? -ne 0 ]; then
            _log "Failed to download theme"
            return 1
        fi
        unzip ${tmpdir}/McOS-XFCE-Edition.zip -d $tmpdir
        if [ $? -ne 0 ]; then
            _log "Failed to unzip theme"
            return 1
        fi
        cp -r $tmpdir/McOS-XFCE-Edition-d5ff59ff18429e175d77a5c34fd0349cf8909fb2/McOS-XFCE-Edition-II /usr/share/themes/
        rm -rf $tmpdir
    fi
}


# /usr/share/images/desktop-base/default
# from /aerthos/images/background.svg
set_background_image_root() {
    # update-alternatives --set desktop-background /usr/share/images/desktop-base/default
    echo hi
}

doall() {
    install_theme_xfwm_root
    set_background_image_root
}

doall |& tee -a /var/log/aerthos-settings.log
echo "Done running 0002-aerthos-settings.bash"
