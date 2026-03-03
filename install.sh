#!/bin/bash
# HyprNotify Suite Installer (Robust Paths)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
DEST="$HOME/.local/bin"
CONF="$HOME/.config/hypr/hyprland.conf"
BIN_DIR="$ROOT_DIR/bin"

echo -e "\e[1;34m--- HyprNotify Installer ---\e[0m"

# 1. Check Dependencies
echo -e "\e[33m[1/4] Checking dependencies...\e[0m"
for dep in gtk+-3.0 gtk-layer-shell-0; do
    if ! pkg-config --exists "$dep"; then
        echo -e "\e[31mError: $dep not found. Please install it.\e[0m"
        exit 1
    fi
done
mkdir -p "$BIN_DIR" "$DEST"

# 2. Compile All Stylings
echo -e "\e[33m[2/4] Compiling utilities...\e[0m"
gcc "$ROOT_DIR/src/volume/volume-osd.c" -o "$BIN_DIR/volume-osd" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0) && echo "  - volume-osd compiled."
gcc "$ROOT_DIR/src/volume/volume-osd-classic.c" -o "$BIN_DIR/volume-osd-classic" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0) && echo "  - volume-osd-classic compiled."
gcc "$ROOT_DIR/src/brightness/brightness-osd.c" -o "$BIN_DIR/brightness-osd" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0) && echo "  - brightness-osd compiled."
gcc "$ROOT_DIR/src/power/power-mod.c" -o "$BIN_DIR/power-mod" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0) && echo "  - power-mod compiled."

# 3. Installation
echo -e "\e[33m[3/4] Installing binaries to $DEST...\e[0m"
pkill volume-osd
pkill brightness-osd
cp "$BIN_DIR"/* "$DEST/"
chmod +x "$DEST"/*-osd "$DEST/power-mod"

# 4. Hyprland Integration
echo -e "\e[33m[4/4] Configuring Hyprland...\e[0m"
if [ -f "$CONF" ]; then
    for daemon in volume-osd brightness-osd; do
        if ! grep -q "exec-once = $daemon" "$CONF"; then
            echo "exec-once = $daemon" >> "$CONF"
            echo "  - Added 'exec-once = $daemon' to hyprland.conf"
        fi
    done
fi

echo -e "\e[1;32mInstallation Complete!\e[0m"
