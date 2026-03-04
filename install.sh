#!/bin/bash
# HyprNotify Suite Installer (Verbose Version)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.local/bin"
CONF="$HOME/.config/hypr/hyprland.conf"
BIN_DIR="$ROOT_DIR/bin"

echo -e "\e[1;34m--- HyprNotify Suite: Professional Installer ---\e[0m"

# 1. Dependency Check
echo -e "\e[33m[1/4] Step: Verifying system prerequisites...\e[0m"
for dep in gtk+-3.0 gtk-layer-shell-0; do
    if pkg-config --exists "$dep"; then
        echo -e "  \e[32m✔\e[0m Found dependency: $dep"
    else
        echo -e "  \e[31m✘\e[0m Error: $dep missing."
        echo "      Please install prerequisites:"
        echo "      Arch:   sudo pacman -S gtk3 gtk-layer-shell pkg-config pamixer brightnessctl"
        echo "      Debian: sudo apt install libgtk-3-dev libgtk-layer-shell-dev pkg-config pamixer brightnessctl"
        exit 1 
    fi
done

echo "  -> Ensuring directory exists: $DEST"
mkdir -p "$DEST"
echo "  -> Ensuring directory exists: $BIN_DIR"
mkdir -p "$BIN_DIR"

# 2. Selection
echo -e "\n\e[36m[2/4] Step: Theme Selection\e[0m"
echo "  0) macOS (Segmented / Default)"
echo "  1) Mocha (Solid)"
echo "  2) Macchiato"
echo "  3) Frappé"
echo "  4) Latte"
echo "  5) Dracula"
echo "  6) Tokyo Night"
read -p "  Selection (0-6): " t
case $t in
    0) THEME="macos"; V="src/volume/volume-osd-macos.c"; B="src/brightness/brightness-osd-macos.c";;
    1) THEME="mocha"; V="src/volume/volume-osd-classic.c"; B="src/brightness/brightness-osd.c";;
    2) THEME="macchiato"; V="src/volume/volume-osd-macchiato.c"; B="src/brightness/brightness-osd-macchiato.c";;
    3) THEME="frappe"; V="src/volume/volume-osd-frappe.c"; B="src/brightness/brightness-osd-frappe.c";;
    4) THEME="latte"; V="src/volume/volume-osd-latte.c"; B="src/brightness/brightness-osd-latte.c";;
    5) THEME="dracula"; V="src/volume/volume-osd-dracula.c"; B="src/brightness/brightness-osd-dracula.c";;
    6) THEME="tokyonight"; V="src/volume/volume-osd-tokyonight.c"; B="src/brightness/brightness-osd-tokyonight.c";;
    *) THEME="macos"; V="src/volume/volume-osd-macos.c"; B="src/brightness/brightness-osd-macos.c";;
esac
echo -e "  \e[32m✔\e[0m Selected Theme Style: \e[1m$THEME\e[0m"

echo -e "\n\e[36m[2.5/4] Optional: Power-Mod Utility\e[0m"
read -p "  Install Power-Mod (Refresh Rate Toggler)? (y/N): " install_power
[[ "$install_power" =~ ^[Yy]$ ]] && INSTALL_POWER=true || INSTALL_POWER=false

# 3. Cleanup & Compilation
echo -e "\n\e[33m[3/4] Step: Compilation & Binary Deployment\e[0m"

echo "  -> Stopping any running OSD instances..."
pkill -x volume-osd 2>/dev/null
pkill -x brightness-osd 2>/dev/null
pkill -f "osd-" 2>/dev/null

echo "  -> Compiling Volume OSD ($THEME)..."
gcc "$ROOT_DIR/$V" -o "$DEST/volume-osd" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)
if [ $? -eq 0 ]; then echo -e "     \e[32m✔\e[0m Binary installed to $DEST/volume-osd"; else exit 1; fi

echo "  -> Compiling Brightness OSD ($THEME)..."
gcc "$ROOT_DIR/$B" -o "$DEST/brightness-osd" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)
if [ $? -eq 0 ]; then echo -e "     \e[32m✔\e[0m Binary installed to $DEST/brightness-osd"; else exit 1; fi

# 4. Config & Activation
echo -e "\n\e[33m[4/5] Step: System Integration\e[0m"

if [ -f "$CONF" ]; then
    echo "  -> Checking Hyprland configuration at $CONF..."
    if grep -q "volume-osd" "$CONF"; then
        echo -e "     \e[32m✔\e[0m volume-osd autostart already present."
    else
        echo -e "     + Adding 'exec-once = volume-osd' to config."
        echo "exec-once = volume-osd" >> "$CONF"
    fi
    if grep -q "brightness-osd" "$CONF"; then
        echo -e "     \e[32m✔\e[0m brightness-osd autostart already present."
    else
        echo -e "     + Adding 'exec-once = brightness-osd' to config."
        echo "exec-once = brightness-osd" >> "$CONF"
    fi
else
    echo -e "  \e[31m!\e[0m Warning: Hyprland config not found at $CONF. Please add autostart manually."
fi

echo "  -> Launching new OSD daemons in background..."
"$DEST/volume-osd" &
"$DEST/brightness-osd" &

if [ "$INSTALL_POWER" = true ]; then
    echo -e "\n\e[33m[5/5] Final Step: Power-Mod Utility\e[0m"
    echo "  -> Compiling Power-Mod Utility..."
    gcc "$ROOT_DIR/src/power/power-mod.c" -o "$DEST/power-mod" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)
    if [ $? -eq 0 ]; then 
        echo -e "     \e[32m✔\e[0m Binary installed to $DEST/power-mod"
    else 
        echo -e "     \e[31m✘\e[0m Compilation failed for Power-Mod."
    fi
fi

echo -e "\n\e[1;32mInstallation Successful!\e[0m"
echo "The $THEME theme is now active. You can now use your volume and brightness keys."
echo "If icons don't appear, ensure you have a Nerd Font installed."
