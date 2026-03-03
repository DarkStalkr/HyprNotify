# HyprNotify Suite

A collection of high-performance, minimalist C utilities for Hyprland/Wayland, designed for seamless system feedback and power management.

## Project Structure
- `src/volume/`: Source files for volume OSD variants (Classic, macOS style).
- `src/brightness/`: Source for the brightness OSD.
- `src/power/`: Hardware-agnostic Power-Mod utility for refresh rate toggling.
- `scripts/`: Testing and debugging utilities for all OSDs.
- `bin/`: Target directory for compiled binaries (ignored by Git).

---

## Included Utilities

### 1. Volume & Brightness OSDs
Modern notification bars that provide instant visual feedback via GTK3 and Layer-Shell.
- **Segmented Design**: macOS-inspired "cube" style bar with dynamic coloring.
- **Asynchronous Updates**: Uses named pipes (FIFOs) for zero-latency feedback without spawning new processes.
- **Intelligent Feedback**: Volume OSD automatically detects mute status via `pamixer`.

### 2. Power-Mod Utility
A tool to toggle between performance and battery-saving modes based on monitor hardware.
- **Auto-Detection**: Dynamically identifies the focused monitor, resolution, and maximum refresh rate.
- **Seamless Toggling**: Switches refresh rates (e.g., 165Hz to 60Hz) with a built-in visual OSD.
- **Single Binary**: Logic and UI combined into one unified tool.

---

## Prerequisites
- **Toolkit**: `gtk3`, `gtk-layer-shell`
- **Utilities**: `hyprland`, `hyprctl`, `pamixer` (volume), `brightnessctl` (brightness).
- **Fonts**: A NerdFont (e.g., JetBrainsMono Nerd Font) for icons.

## Installation & Compilation

Compile the utilities into the `bin/` directory:
```bash
# Volume OSD
gcc src/volume/volume-osd.c -o bin/volume-osd $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)

# Brightness OSD
gcc src/brightness/brightness-osd.c -o bin/brightness-osd $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)

# Power Mod
gcc src/power/power-mod.c -o bin/power-mod $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)
```

## Setup & Keybindings

### 1. Autostart
Add the OSD daemons to your `hyprland.conf`:
```bash
exec-once = ~/.local/bin/volume-osd
exec-once = ~/.local/bin/brightness-osd
```

### 2. Keybinds
```bash
# Volume
binde = , XF86AudioRaiseVolume, exec, pamixer -ui 3 && pamixer --get-volume > /tmp/volume_bar.fifo
binde = , XF86AudioLowerVolume, exec, pamixer -ud 3 && pamixer --get-volume > /tmp/volume_bar.fifo
bind  = , XF86AudioMute, exec, pamixer -t && pamixer --get-volume > /tmp/volume_bar.fifo

# Brightness
binde = , XF86MonBrightnessUp, exec, brightnessctl s +5% && brightnessctl g | awk '{print int($1/255*100)}' > /tmp/brightness_bar.fifo
binde = , XF86MonBrightnessDown, exec, brightnessctl s 5%- && brightnessctl g | awk '{print int($1/255*100)}' > /tmp/brightness_bar.fifo

# Power Toggle
bind = , XF86Assistant, exec, power-mod
```
