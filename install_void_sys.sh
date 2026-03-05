#!/usr/bin/env bash

# 1. System configuration
echo "VoidUSB" > /etc/hostname
echo "en_US.UTF-8 UTF-8" > /etc/default/libc-locales
xbps-reconfigure -f glibc-locales
xbps-install -Su
xbps-install -y void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
xbps-install -Su
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime # change if needed

# 2. New user
useradd user -G wheel
passwd -d user
groupadd -r autologin
groupadd -r nopasswdlogin
gpasswd -a user nopasswdlogin
gpasswd -a user autologin
mkdir -p /home/user
chown -R user /home/user

# 3. GRUB
xbps-install -y grub-x86_64-efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void" --removable
xbps-reconfigure -fa

# 4. Various services
# multiple network services are installed, not all are used but just in case you have more options.
xbps-install -y chrony elogind bluez xorg lightdm lightdm-slick-greeter dhcp NetworkManager wpa_supplicant connman
ln -s /etc/sv/chronyd /etc/runit/runsvdir/default/
ln -s /etc/sv/dbus /etc/runit/runsvdir/default/
ln -s /etc/sv/elogind /etc/runit/runsvdir/default/
ln -s /etc/sv/bluetoothd /etc/runit/runsvdir/default/
ln -s /etc/sv/lightdm /etc/runit/runsvdir/default/
ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/
resolvconf -u # hopefully this works

# 5. Some drivers (feel free to add to this if more are needed)
xbps-install -y linux-firmware-amd mesa-dri vulkan-loader mesa-vulkan-radeon mesa-vaapi

# 6. Flatpaks
xbps-install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# flatpak claims it wants a system restart but this works fine
flatpak install -y one.ablaze.floorp
flatpak install -y com.github.tchx84.Flatseal
flatpak install -y org.gnome.Calculator
flatpak install -y org.gnome.clocks
flatpak install -y io.github.flattool.Warehouse
flatpak install -y com.discordapp.Discord
flatpak install -y org.mozilla.Thunderbird
flatpak install -y com.obsproject.Studio
flatpak install -y com.github.flxzt.rnote
flatpak install -y org.blender.Blender
flatpak install -y org.audacityteam.Audacity
flatpak install -y com.mojang.Minecraft
flatpak install -y org.kde.kdenlive

# 7. Apps
xbps-install -y steam gamescope nautilus cmake gcc openjdk python rustup cargo neovim vim shotwell mpv curl \
gnome-tweaks git lazygit github-cli ffmpeg btop
# steam needs extra libraries, this is what it wants according to the README.voidlinux
xbps-install -y libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit mesa-vulkan-radeon-32bit
curl -f https://zed.dev/install.sh | sh # zed

# 8. Setup desktop
xbps-install -y noto-fonts-ttf noto-fonts-cjk noto-fonts-emoji nerd-fonts adwaita-fonts gnome-themes-standard gnome-themes-extra \
niri swaybg SwayNotificationCenter gtklock Waybar alacritty fuzzel xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
xwayland-satellite playerctl

# 9. Pipewire
xbps-install -y pipewire wiremix
mkdir -p /etc/pipewire/pipewire.conf.d
ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/

# 10. Configs
# wayland session config so niri starts correctly
mkdir -p /usr/share/wayland-sessions/
echo "[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=/usr/bin/dbus-run-session /usr/bin/niri --session
Type=Application
DesktopNames=niri" > /usr/share/wayland-sessions/niri.desktop
# cursor/icon theme force
mkdir -p /home/user/.local/share/icons/default
echo "[Icon Theme]
Inherits=Adwaita" > /home/user/.local/share/icons/default/index.theme
# waybar configs
mkdir -p /home/user/.config/waybar
echo '// -*- mode: jsonc -*-
{
    "layer": "top", // Waybar at top layer
    "position": "bottom", // Waybar position (top|bottom|left|right)
    "height": 26, // Waybar height (to be removed for auto height)
    // "width": 1280, // Waybar width
    "spacing": 0, // Gaps between modules (4px)
    // Choose the order of the modules
    "modules-left": [
        "niri/workspaces"
        // "custom/waybar-media"
    ],
    "modules-center": [
        "niri/window"
    ],
    "modules-right": [
        "pulseaudio",
        "network",
        "tray",
	"custom/notifications",
	"clock"
    ],
    "keyboard-state": {
        "numlock": true,
        "capslock": true,
        "format": "{name} {icon}",
        "format-icons": {
            "locked": "",
            "unlocked": ""
        }
    },
    "tray": {
        "icon-size": 21,
        "spacing": 10
    },
    "clock": {
        // "timezone": "America/New_York",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%Y-%m-%d}"
    },
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    "memory": {
        "format": "{}% "
    },
    "network": {
        // "interface": "wlp2*", // (Optional) To force the use of this interface
        "format-wifi": "({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    "pulseaudio": {
        // "scroll-step": 1, // %, can be a float
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": "{volume}% ",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "alacritty -e wiremix"
    },
    "custom/waybar-media": {
        // "return-type": "json",
        "exec": "playerctl metadata",
        "on-click": "playerctl play-pause",
        "escape": true
    },
    "custom/power": {
        "format" : "⏻",
		"tooltip": false,
		"menu": "on-click",
		"menu-file": "$HOME/.config/waybar/power_menu.xml", // Menu file in resources folder
		"menu-actions": {
			"shutdown": "shutdown",
			"reboot": "reboot",
			"suspend": "systemctl suspend",
			"hibernate": "systemctl hibernate"
		}
    },
    "custom/notifications": {
        "tooltip": false,
	"format": "{icon}",
	"format-icons": {
            "notification": "<span foreground='red'><sup></sup></span>",
            "none": "",
            "dnd-notification": "<span foreground='red'><sup></sup></span>",
            "dnd-none": "",
            "inhibited-notification": "<span foreground='red'><sup></sup></span>",
            "inhibited-none": "",
            "dnd-inhibited-notification": "<span foreground='red'><sup></sup></span>",
            "dnd-inhibited-none": ""
        },
        "return-type": "json",
        "exec-if": "which swaync-client",
        "exec": "swaync-client -swb",
        "on-click": "swaync-client -t -sw",
        "on-click-right": "swaync-client -d -sw",
        "escape": true
    }
}' > /home/user/.config/waybar/config.jsonc
# niri
mkdir -p /home/user/.config/niri
echo '// This config is in the KDL format: https://kdl.dev
// "/-" comments out the following node.
// Check the wiki for a full description of the configuration:
// https://github.com/YaLTeR/niri/wiki/Configuration:-Overview

// Input device configuration.
// Find the full list of options on the wiki:
// https://github.com/YaLTeR/niri/wiki/Configuration:-Input

spawn-at-startup "xwayland-satellite"
spawn-at-startup "waybar"
// spawn-at-startup "swaybg" "-i" "/home/drew/Pictures/Wallpapers/tower.png"
spawn-at-startup "swaync"
spawn-at-startup "pipewire"

environment {
    DISPLAY ":0"
    XDG_CURRENT_DESKTOP "niri"
    QT_QPA_PLATFORM "wayland"
}

cursor {
    xcursor-size 24
}

hotkey-overlay {
    skip-at-startup
}

input {
    keyboard {
        xkb {
        }
    }

    touchpad {
        // off
        tap
        // dwt
        // dwtp
        // drag-lock
        natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "two-finger"
        // disabled-on-external-mouse
    }

    mouse {
        // off
        // natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "no-scroll"
    }

    trackpoint {
        // off
        // natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "on-button-down"
        // scroll-button 273
        // middle-emulation
    }

    focus-follows-mouse max-scroll-amount="0%"
    disable-power-key-handling
}

layout {
    gaps 16
    center-focused-column "never"

    preset-column-widths {
        proportion 0.5
        proportion 0.33333
        proportion 0.66667
        // Fixed sets the width in logical pixels exactly.
        // fixed 1920
    }

    default-column-width { proportion 0.5; }
    focus-ring {
        off
    }

    border {
        width 2
        active-color "#0081f9"
        inactive-color "#f90045"
    }

    shadow {
        on

        softness 15
        spread 10
        offset x=0 y=5
        color "#0007"
    }
}

prefer-no-csd

screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

animations {
}

window-rule {
    match app-id=r#"firefox$"# title="^Picture-in-Picture$"
    open-floating true
}

binds {
    Mod+Shift+Slash { show-hotkey-overlay; }

    Mod+T { spawn "alacritty"; }
    Mod+E { spawn "fuzzel"; }
    Mod+L { spawn "gtklock"; }

    XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02+"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02-"; }
    XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
    XF86AudioMicMute     allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
    XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
    XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
    XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }

    Alt+F4 { close-window; }

    Mod+A  { focus-column-left; }
    Mod+S  { focus-window-down; }
    Mod+W    { focus-window-up; }
    Mod+D { focus-column-right; }
    Mod+Left  { focus-column-left; }
    Mod+Down  { focus-window-down; }
    Mod+Up    { focus-window-up; }
    Mod+Right { focus-column-right; }

    Mod+Ctrl+A  { move-column-left; }
    Mod+Ctrl+S  { move-window-down; }
    Mod+Ctrl+W    { move-window-up; }
    Mod+Ctrl+D { move-column-right; }
    Mod+Ctrl+Left  { move-column-left; }
    Mod+Ctrl+Down  { move-window-down; }
    Mod+Ctrl+Up    { move-window-up; }
    Mod+Ctrl+Right { move-column-right; }

    Mod+Home { focus-column-first; }
    Mod+End  { focus-column-last; }
    Mod+Ctrl+Home { move-column-to-first; }
    Mod+Ctrl+End  { move-column-to-last; }

    Mod+Shift+A  { focus-monitor-left; }
    Mod+Shift+S  { focus-monitor-down; }
    Mod+Shift+W    { focus-monitor-up; }
    Mod+Shift+D { focus-monitor-right; }
    Mod+Shift+Left  { focus-monitor-left; }
    Mod+Shift+Down  { focus-monitor-down; }
    Mod+Shift+Up    { focus-monitor-up; }
    Mod+Shift+Right { focus-monitor-right; }

    Mod+Shift+Ctrl+A  { move-column-to-monitor-left; }
    Mod+Shift+Ctrl+S  { move-column-to-monitor-down; }
    Mod+Shift+Ctrl+W  { move-column-to-monitor-up; }
    Mod+Shift+Ctrl+D { move-column-to-monitor-right; }
    Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
    Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
    Mod+Shift+Ctrl+Up  { move-column-to-monitor-up; }
    Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

    Mod+Page_Down      { focus-workspace-down; }
    Mod+Page_Up        { focus-workspace-up; }
    Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
    Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }

    Mod+Shift+Page_Down { move-workspace-down; }
    Mod+Shift+Page_Up   { move-workspace-up; }
    Mod+Shift+U         { move-workspace-down; }
    Mod+Shift+I         { move-workspace-up; }

    Mod+WheelScrollDown      cooldown-ms=50  { focus-workspace-down; }
    Mod+WheelScrollUp        cooldown-ms=50  { focus-workspace-up; }
    Mod+Ctrl+WheelScrollDown cooldown-ms=50  { move-column-to-workspace-down; }
    Mod+Ctrl+WheelScrollUp   cooldown-ms=50  { move-column-to-workspace-up; }

    Mod+WheelScrollRight      { focus-column-right; }
    Mod+WheelScrollLeft       { focus-column-left; }
    Mod+Ctrl+WheelScrollRight { move-column-right; }
    Mod+Ctrl+WheelScrollLeft  { move-column-left; }

    Mod+Shift+WheelScrollDown      { focus-column-left; }
    Mod+Shift+WheelScrollUp        { focus-column-right; }
    Mod+Ctrl+Shift+WheelScrollDown { move-column-left; }
    Mod+Ctrl+Shift+WheelScrollUp   { move-column-right; }

    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }
    Mod+Ctrl+1 { move-column-to-workspace 1; }
    Mod+Ctrl+2 { move-column-to-workspace 2; }
    Mod+Ctrl+3 { move-column-to-workspace 3; }
    Mod+Ctrl+4 { move-column-to-workspace 4; }
    Mod+Ctrl+5 { move-column-to-workspace 5; }
    Mod+Ctrl+6 { move-column-to-workspace 6; }
    Mod+Ctrl+7 { move-column-to-workspace 7; }
    Mod+Ctrl+8 { move-column-to-workspace 8; }
    Mod+Ctrl+9 { move-column-to-workspace 9; }
    Mod+BracketLeft  { consume-or-expel-window-left; }
    Mod+BracketRight { consume-or-expel-window-right; }

    Mod+Comma  { consume-window-into-column; }
    Mod+Period { expel-window-from-column; }

    Mod+R { switch-preset-column-width; }
    Mod+Shift+R { switch-preset-window-height; }
    Mod+Ctrl+R { reset-window-height; }
    Mod+F { maximize-column; }
    Mod+Shift+F { fullscreen-window; }

    Mod+Ctrl+F { toggle-windowed-fullscreen; }

    Mod+C { center-column; }

    Mod+Minus { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }

    Mod+Shift+Minus { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }

    Mod+V       { toggle-window-floating; }
    Mod+Shift+V { switch-focus-between-floating-and-tiling; }

    Print { screenshot; }
    Ctrl+Shift+S { screenshot; }
    Ctrl+Shift+Alt+S { screenshot-screen; }
    Alt+Print { screenshot-window; }

    Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

    Mod+Shift+E { quit; }
    Ctrl+Alt+Delete { quit; }

    Mod+Shift+P { power-off-monitors; }

    MouseBack { open-overview; }
}' > /home/user/.config/niri/config.kdl
# lightdm confs
mkdir -p /etc/lightdm
echo '#
# General configuration
#
# start-default-seat = True to always start one seat if none are defined in the configuration
# greeter-user = User to run greeter as
# minimum-display-number = Minimum display number to use for X servers
# minimum-vt = First VT to run displays on
# lock-memory = True to prevent memory from being paged to disk
# user-authority-in-system-dir = True if session authority should be in the system location
# guest-account-script = Script to be run to setup guest account
# logind-check-graphical = True to on start seats that are marked as graphical by logind
# log-directory = Directory to log information to
# run-directory = Directory to put running state in
# cache-directory = Directory to cache to
# sessions-directory = Directory to find sessions
# remote-sessions-directory = Directory to find remote sessions
# greeters-directory = Directory to find greeters
# backup-logs = True to move add a .old suffix to old log files when opening new ones
# dbus-service = True if LightDM provides a D-Bus service to control it
#
[LightDM]
#start-default-seat=true
#greeter-user=lightdm
#minimum-display-number=0
#minimum-vt=7
#lock-memory=true
#user-authority-in-system-dir=false
#guest-account-script=guest-account
#logind-check-graphical=true
#log-directory=/var/log/lightdm
#run-directory=/var/run/lightdm
#cache-directory=/var/cache/lightdm
#sessions-directory=/usr/share/lightdm/sessions:/usr/share/xsessions:/usr/share/wayland-sessions
#remote-sessions-directory=/usr/share/lightdm/remote-sessions
#greeters-directory=$XDG_DATA_DIRS/lightdm/greeters:$XDG_DATA_DIRS/xgreeters
#backup-logs=true
#dbus-service=true

#
# Seat configuration
#
# Seat configuration is matched against the seat name glob in the section, for example:
# [Seat:*] matches all seats and is applied first.
# [Seat:seat0] matches the seat named "seat0".
# [Seat:seat-thin-client*] matches all seats that have names that start with "seat-thin-client".
#
# type = Seat type (local, xremote)
# pam-service = PAM service to use for login
# pam-autologin-service = PAM service to use for autologin
# pam-greeter-service = PAM service to use for greeters
# xserver-command = X server command to run (can also contain arguments e.g. X -special-option)
# xmir-command = Xmir server command to run (can also contain arguments e.g. Xmir -special-option)
# xserver-config = Config file to pass to X server
# xserver-layout = Layout to pass to X server
# xserver-allow-tcp = True if TCP/IP connections are allowed to this X server
# xserver-share = True if the X server is shared for both greeter and session
# xserver-hostname = Hostname of X server (only for type=xremote)
# xserver-display-number = Display number of X server (only for type=xremote)
# xdmcp-manager = XDMCP manager to connect to (implies xserver-allow-tcp=true)
# xdmcp-port = XDMCP UDP/IP port to communicate on
# xdmcp-key = Authentication key to use for XDM-AUTHENTICATION-1 (stored in keys.conf)
# greeter-session = Session to load for greeter
# greeter-hide-users = True to hide the user list
# greeter-allow-guest = True if the greeter should show a guest login option
# greeter-show-manual-login = True if the greeter should offer a manual login option
# greeter-show-remote-login = True if the greeter should offer a remote login option
# user-session = Session to load for users
# allow-user-switching = True if allowed to switch users
# allow-guest = True if guest login is allowed
# guest-session = Session to load for guests (overrides user-session)
# session-wrapper = Wrapper script to run session with
# greeter-wrapper = Wrapper script to run greeter with
# guest-wrapper = Wrapper script to run guest sessions with
# display-setup-script = Script to run when starting a greeter session (runs as root)
# display-stopped-script = Script to run after stopping the display server (runs as root)
# greeter-setup-script = Script to run when starting a greeter (runs as root)
# session-setup-script = Script to run when starting a user session (runs as root)
# session-cleanup-script = Script to run when quitting a user session (runs as root)
# autologin-guest = True to log in as guest by default
# autologin-user = User to log in with by default (overrides autologin-guest)
# autologin-user-timeout = Number of seconds to wait before loading default user
# autologin-session = Session to load for automatic login (overrides user-session)
# autologin-in-background = True if autologin session should not be immediately activated
# exit-on-failure = True if the daemon should exit if this seat fails
#
[Seat:*]
#type=local
#pam-service=lightdm
#pam-autologin-service=lightdm-autologin
#pam-greeter-service=lightdm-greeter
#xserver-command=X
#xmir-command=Xmir
#xserver-config=
#xserver-layout=
#xserver-allow-tcp=false
#xserver-share=true
#xserver-hostname=
#xserver-display-number=
#xdmcp-manager=
#xdmcp-port=177
#xdmcp-key=
greeter-session=slick-greeter
#greeter-hide-users=false
#greeter-allow-guest=true
#greeter-show-manual-login=false
#greeter-show-remote-login=true
user-session=niri
#allow-user-switching=true
#allow-guest=true
#guest-session=
session-wrapper=/etc/lightdm/Xsession
#greeter-wrapper=
#guest-wrapper=
#display-setup-script=
#display-stopped-script=
#greeter-setup-script=
#session-setup-script=
#session-cleanup-script=
autologin-guest=false
autologin-user=user
autologin-user-timeout=0
#autologin-in-background=false
autologin-session=niri
#exit-on-failure=false

#
# XDMCP Server configuration
#
# enabled = True if XDMCP connections should be allowed
# port = UDP/IP port to listen for connections on
# listen-address = Host/address to listen for XDMCP connections (use all addresses if not present)
# key = Authentication key to use for XDM-AUTHENTICATION-1 or blank to not use authentication (stored in keys.conf)
# hostname = Hostname to report to XDMCP clients (defaults to system hostname if unset)
#
# The authentication key is a 56 bit DES key specified in hex as 0xnnnnnnnnnnnnnn.  Alternatively
# it can be a word and the first 7 characters are used as the key.
#
[XDMCPServer]
#enabled=false
#port=177
#listen-address=
#key=
#hostname=

#
# VNC Server configuration
#
# enabled = True if VNC connections should be allowed
# command = Command to run Xvnc server with
# port = TCP/IP port to listen for connections on
# listen-address = Host/address to listen for VNC connections (use all addresses if not present)
# width = Width of display to use
# height = Height of display to use
# depth = Color depth of display to use
#
[VNCServer]
#enabled=false
#command=Xvnc
#port=5900
#listen-address=
#width=1024
#height=768
#depth=8' > /etc/lightdm/lightdm.conf
# PAM for lightdm
mkdir -p /etc/pam.d/
echo '#%PAM-1.0
auth      sufficient  pam_succeed_if.so user ingroup nopasswdlogin

# Block login if they are globally disabled
auth      required pam_nologin.so

# Load environment from /etc/environment and ~/.pam_environment
auth      required pam_env.so

# Use /etc/passwd and /etc/shadow for passwords
auth      required pam_unix.so

# Check account is active, change password if required
account   required pam_unix.so

# Allow password to be changed
password  required pam_unix.so

# Setup session
session   required pam_unix.so
-session   optional pam_turnstile.so
-session   optional pam_elogind.so
-session   optional pam_elogind.so
-session optional pam_ck_connector.so nox11' > /etc/pam.d/lightdm


# Additionally makes a few folders for the user
mkdir -p /home/user/Downloads
mkdir -p /home/user/Pictures/Screenshots

# just in case, there seemed to be some issues.
chown -R user /home/user

echo "Installation complete. You can boot into the new system now."
