# HyprNotify Suite

A collection of high-performance, minimalist C utilities for Hyprland/Wayland, designed for seamless system feedback and power management.

<div align="center">
  <img src="https://raw.githubusercontent.com/DarkStalkr/HyprNotify/main/assets/volume_demo.gif" width="45%" alt="Volume OSD Demo">
  <img src="https://raw.githubusercontent.com/DarkStalkr/HyprNotify/main/assets/brightness_demo.gif" width="45%" alt="Brightness OSD Demo">
</div>

---

## Features
- **Zero-Latency**: Daemons use persistent FIFOs to eliminate the overhead of spawning new processes on every keypress.
- **Low Resource Usage**: Idle at 0% CPU; optimized read loops ensure smooth performance even under extreme input stress.
- **Pure C + GTK3**: Built with `gtk-layer-shell` for native Wayland overlays (it stays above full-screen apps!).
- **Hardware Agnostic Power-Mod**: Automatically detects monitor specs to toggle refresh rates (65Hz/165Hz+) dynamically.

---

## 🎨 Theming & Customization

The HyprNotify suite is designed to be easily "riceable." You can customize the look by modifying the CSS string in the `src/*.c` files before compiling.

### 1. Default: Catppuccin Segmented (Mac-style)
The current default features 12px blocks with 4px gaps for a modern, geometric look.
```css
/* Mauve: #cba6f7 | Background: #181825 */
window { background-color: rgba(24, 24, 37, 0.95); border-radius: 20px; border: 2px solid #cba6f7; }
trough { background-image: linear-gradient(to right, rgba(69, 71, 90, 0.3) 12px, transparent 12px); background-size: 16px 100%; }
progress { background-image: linear-gradient(to right, #cba6f7 12px, transparent 12px); background-size: 16px 100%; }
```

### 2. Solid Minimal (Nord Theme)
A thinner, solid bar without segments for a cleaner aesthetic.
```css
/* Change trough/progress in the .c file */
window { background-color: rgba(46, 52, 64, 0.9); border-radius: 8px; border: 1px solid #88c0d0; }
trough { background-color: rgba(76, 86, 106, 0.5); min-height: 8px; border-radius: 4px; }
progress { background-color: #88c0d0; min-height: 8px; border-radius: 4px; }
```

### 3. Chunky Gruvbox
A thicker, bold bar with retro colors.
```css
/* Gruvbox Gold: #fabd2f */
window { background-color: #282828; border-radius: 0px; border: 3px solid #fabd2f; }
trough { background-color: #3c3836; min-height: 32px; }
progress { background-color: #fabd2f; min-height: 32px; }
```

---

## Installation

```bash
# Clone and compile
git clone https://github.com/DarkStalkr/HyprNotify.git
cd HyprNotify

# Compile Volume (example)
gcc src/volume/volume-osd.c -o bin/volume-osd $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)
```

## Keybindings (Hyprland)
```bash
# Volume control with FIFO feedback
binde = , XF86AudioRaiseVolume, exec, pamixer -ui 3 && pamixer --get-volume > /tmp/volume_bar.fifo
binde = , XF86AudioLowerVolume, exec, pamixer -ud 3 && pamixer --get-volume > /tmp/volume_bar.fifo
```

---

## Performance Benchmark
| Utility | Idle CPU | Active CPU (Stress) | RAM Usage |
| :--- | :--- | :--- | :--- |
| **Volume OSD** | 0.0% | 4-5% | ~40MB |
| **Brightness OSD** | 0.0% | 3-4% | ~35MB |
| **Power Mod** | N/A | < 5ms exec | Negligible |

*Tested on Arch Linux / Zen Kernel.*
