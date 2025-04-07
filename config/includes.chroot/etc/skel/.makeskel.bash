#!/bin/bash
# makeskel.bash - (needs DISPLAY) apply xfce settings/theme
# Copyright (c) 2025 aerth <aerth@localhost>
# This file is part of the aerthOS project (https://aerth.github.io/aerthOS)

test ! -e ~/.config/aerthos/setup.txt || {
    echo "Error: ~/.config/aerthos/setup.txt already exists. If you want to reconfigure, remove it." >&2
    sleep 3
    exit 0
}
_log() {
    echo "aerthos-makeskel: $@" | tee -a /tmp/aerthos-makeskel.log 1>&2
}

if [ -z "${DISPLAY}" ]; then
    echo "Error: DISPLAY environment variable is not set. Please run this script in an X11 session." >&2
    exit 0
fi
export DISPLAY=${DISPLAY-:0}

# xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
# list with xfconf-query -c xfce4-keyboard-shortcuts -lv
set_keyboard_shortcuts() {
    xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/default/Print' -s 'xfce4-screenshooter -r'
    xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Super>d' -s '/usr/local/bin/start_ephemeral_shell xfce4-terminal' --create -t string
    xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Super>t' -s 'exo-open --launch TerminalEmulator' --create -t string
    xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Super>r' -s 'rofi -show combi -combi-modi "window,drun,ssh" -modi combi' --create -t string
}

set_default_applications() {
    # browser
    xdg-settings set default-web-browser my-chromium-browser.desktop
}

gtk_theme_Dark() {
    xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark" --create -t string
    xfconf-query -c xsettings -p /Net/IconThemeName -s "bloom-classic" --create -t string # part of deepin-icon-theme
    xfconf-query -c xsettings -p /general/theme -s "McOS-XFCE-Edition-II" --create -t string
}

do_xfce4_dark() {
    # set black color bg , no pic
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor/workspace0/image-style -s 0 --create -t int
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor/workspace0/image-style -s 0 --create -t int
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor/workspace0/imagestyle -s 0 --create -t int
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor/workspace0/imagestyle -s 0 --create -t int

    monitors=$(xfconf-query -c xfce4-desktop -l | sed 's@/backdrop/screen0/@@g' | grep ^monitor | sed 's/\// /g' | awk '{print $1}' | sort -u)
    for mon in $monitors; do
        echo "Setting $mon"
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/$mon/image-style -s 0 --create -t int
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/$mon/imagestyle -s 0 --create -t int
    done
}

# https://wiki.debian.org/Design/Theming
# https://wiki.xfce.org/howto/gtk_theme
# Theme files are located in usr/share/themes/
# /gtk-2/gtkrc
# /gtk-3/gtk.css
# /gtk-3/gtk-widgets.css
# /gtk-3/settings.ini
# /xfwm4/themerc

do_mousepad_terminal() {
    xfconf-query -c mousepad -p /preferences/file/session-restore -s 'unsaved-documents' --create -t string
    xfconf-query -c mousepad -p /preferences/view/auto-indent -s true --create -t bool
    xfconf-query -c mousepad -p /preferences/view/color-scheme -s 'cobalt' --create -t string
    xfconf-query -c mousepad -p /preferences/view/font-name -s 'Spleen 32x64 Medium 20' --create -t string
    xfconf-query -c mousepad -p /preferences/view/match-braces -s true --create -t bool
    xfconf-query -c mousepad -p /preferences/view/show-line-numbers -s true --create -t bool
    xfconf-query -c mousepad -p /preferences/view/use-default-monospace-font -s false --create -t bool
    xfconf-query -c mousepad -p /preferences/window/always-show-tabs -s true --create -t bool
    xfconf-query -c mousepad -p /preferences/window/client-side-decorations -s true --create -t bool
    xfconf-query -c mousepad -p /preferences/window/cycle-tabs -s true --create -t bool
    xfconf-query -c mousepad -p /preferences/window/opening-mode -s 'window' --create -t string
    xfconf-query -c mousepad -p /preferences/window/toolbar-icon-size -s 'dialog' --create -t string
    xfconf-query -c mousepad -p /preferences/window/toolbar-style -s 'both' --create -t string
    xfconf-query -c mousepad -p /preferences/window/toolbar-visible -s true --create -t bool
    xfconf-query -c mousepad -p /state/application/enabled-plugins -s "['mousepad-plugin-shortcuts', 'mousepad-plugin-gspell']" --create -t string
    xfconf-query -c mousepad -p /state/search/search-history -s "['60000']" --create -t string

    xfconf-query -c xfce4-terminal -p /default-show-menubar -s false --create -t bool
    xfconf-query -c xfce4-terminal -p /font-name -s 'Spleen 32x64 Medium 14' --create -t string
    xfconf-query -c xfce4-terminal -p /misc-background-mode -s 'TERMINAL_BACKGROUND_SOLID' --create -t string
    xfconf-query -c xfce4-terminal -p /misc-background-shade -s 100 --create -t int
    xfconf-query -c xfce4-terminal -p /misc-use-theme-colors -s false --create -t bool
    xfconf-query -c xfce4-terminal -p /scrollbar-position -s 'hidden' --create -t string
    xfconf-query -c xfce4-terminal -p /scrollbar-visible -s false --create -t bool
    xfconf-query -c xfce4-terminal -p /font-name --create -t string -s "Spleen 32x64 Medium 12"
    xfconf-query -c xfce4-terminal -p /misc-menubar-default -s false --create -t bool
    xfconf-query -c xfce4-terminal -p /misc-borders-default -s false --create -t bool

    # background vary a bit (helps distinguish between cascading terminal windows)
    xfconf-query -c xfce4-terminal -p /background-mode -s "TERMINAL_BACKGROUND_SOLID" --create -t string
    xfconf-query -c xfce4-terminal -p /background-darkness -s 1.0 --create -t double
    xfconf-query -c xfce4-terminal -p /color-background-vary -s true --create -t bool
    xfconf-query -c xfce4-terminal -p /color-background -s "#202020202020" --create -t string
    # TODO: but for now, tango theme
    xfconf-query -c xfce4-terminal -p /color-palette --create -t string -s "#000000;#cc0000;#4e9a06;#c4a000;#3465a4;#75507b;#06989a;#d3d7cf;#555753;#ef2929;#8ae234;#fce94f;#739fcf;#ad7fa8;#34e2e2;#eeeeec"

}

themer() {
    set_keyboard_shortcuts
    if [ $? -ne 0 ]; then
        _log "Failed to set keyboard shortcuts"
    fi
    set_default_applications
    if [ $? -ne 0 ]; then
        _log "Failed to set default applications"
    fi
    set_background_image
    if [ $? -ne 0 ]; then
        _log "Failed to set background image"
    fi
    gtk_theme_Dark
    if [ $? -ne 0 ]; then
        _log "Failed to set gtk theme"
    fi
    do_mousepad_terminal
    if [ $? -ne 0 ]; then
        _log "Failed to set gconf"
    fi
    do_xfce4_dark
    if [ $? -ne 0 ]; then
        _log "Failed to set xfce4 dark"
    fi
}

save_home_for_skel(){
    if command -v tree >/dev/null 2>&1; then
        tree -a ${HOME}/.config ${HOME}/Desktop -L 1 >/tmp/aerthos-home-config.txt || true
        _log "Created directory listing: /tmp/aerthos-home-config.txt"
    else
        _log "Warning: 'tree' command not found. Skipping directory listing."
    fi
    num_dl=$(ls ${HOME}/Downloads/* 2>/dev/null || true | wc -l)
    if [ $num_dl -gt 0 ]; then
        _log "Warning: Downloads directory is not empty. Please check."
        return 0
    fi
    if [ -f /tmp/aerthos-home-config.zip ]; then
        _log "Warning: /tmp/aerthos-home-config.zip already exists. Please check."
        return 0
    fi

    command -v zip >/dev/null 2>&1 || {
        _log "Warning: 'zip' command not found. Skipping zip creation."
        return 0
    }
    zip -r /tmp/aerthos-home-config.zip ${HOME}/.config ${HOME}/Desktop || true
    if [ $? -ne 0 ]; then
        _log "Failed to create zip file"
        return 1
    fi
    _log "Created zip file: /tmp/aerthos-home-config.zip"
    _log "Please check the files for any errors."
    return 0
}

do_themer() {
    if [ ${#} -ne 0 ]; then
        sleep $1
    fi
    themer || {
        _log "Failed to set theme"
        exit 1
    }
}

grep 'color-background-vary' ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml || do_themer
xfce4-terminal --show-borders --title "aerthos Package Installation" -x sudo bash -c -x '/usr/local/sbin/9999-aerthos-bootpackages.bash || (echo package installation failed, you can close this window; sleep 60)'
cat /proc/cmdline | grep nodot || (git clone https://gitlab.com/aerth/dot ~/.local/dot)
mkdir -p ~/.config/aerthos
touch ~/.config/aerthos/setup.txt
echo all done
# for example, nuke home dir and run this for creating /etc/skel config
if "$1" == "save_home" ]; then
    save_home_for_skel
    if [ $? -ne 0 ]; then
        _log "Failed to save home directory"
        exit 1
    fi
fi
