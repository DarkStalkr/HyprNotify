# HyprNotify Suite


<div align="right">
  <img src="assets/showcase_gifs/classic_volume.gif" width="45%" alt="Volume OSD Demo">
  <img src="assets/showcase_gifs/classic_birghtness.gif" width="45%" alt="Brightness OSD Demo">
</div>

A collection of high-performance, minimalist C utilities for Hyprland/Wayland, designed for seamless system feedback and power management.



---

## 🚀 Features
- **Zero-Latency**: Daemons use persistent FIFOs to eliminate the overhead of spawning new processes on every keypress.
- **Ultra-Smooth Animations**: Optimized logic with 0.05s CSS transitions and throttled UI updates for a "clean" and responsive feel, even under high-frequency input (e.g., holding a key).
- **Low Resource Usage**: Idle at 0.0% CPU; optimized read loops and redundant call avoidance ensure minimal impact during use.
- **Pure C + GTK3**: Built with `gtk-layer-shell` for native Wayland overlays (it stays above full-screen apps!).
- **Hardware Agnostic Power-Mod**: Automatically detects monitor specs to toggle refresh rates (65Hz/165Hz+) dynamically.

---

## 🎨 Theming & Customization

The HyprNotify suite is designed to be easily "riceable." It includes pre-configured variants for:
- **macOS (Default)**: Segmented "dotted" bar design.
- **Catppuccin**: Mocha, Macchiato, Frappé, Latte.
- **Dracula**: Classic dark palette with purple accents.
- **Tokyo Night**: Deep blue and gold aesthetics.

### 1. Style: macOS Segmented
The current default features 12px blocks with 4px gaps for a modern, geometric look.
```css
/* Mauve: #cba6f7 | Background: #181825 */
window { background-color: rgba(24, 24, 37, 0.95); border-radius: 20px; border: 2px solid #cba6f7; }
trough { background-image: linear-gradient(to right, rgba(69, 71, 90, 0.3) 12px, transparent 12px); background-size: 16px 100%; }
progress { background-image: linear-gradient(to right, #cba6f7 12px, transparent 12px); background-size: 16px 100%; }
```

---

## 🛠️ Installation

### 1. Install Prerequisites

**Arch Linux:**
```bash
sudo pacman -S gtk3 gtk-layer-shell pkg-config pamixer brightnessctl
```

**Debian / Ubuntu:**
```bash
sudo apt install libgtk-3-dev libgtk-layer-shell-dev pkg-config pamixer brightnessctl
```

### 2. Run Installer
```bash
git clone https://github.com/DarkStalkr/HyprNotify.git
cd HyprNotify
chmod +x install.sh
./install.sh
```

## ⌨️ Keybindings (Hyprland)
Add these to your `hyprland.conf`:
```bash
# Volume control with FIFO feedback
binde = , XF86AudioRaiseVolume, exec, pamixer -ui 3 && pamixer --get-volume > /tmp/volume_bar.fifo
binde = , XF86AudioLowerVolume, exec, pamixer -ud 3 && pamixer --get-volume > /tmp/volume_bar.fifo
bind  = , XF86AudioMute, exec, pamixer -t && pamixer --get-volume > /tmp/volume_bar.fifo

# Brightness control
binde = , XF86MonBrightnessUp, exec, brightnessctl s +5% && brightnessctl g | awk '{print int($1/255*100)}' > /tmp/brightness_bar.fifo
binde = , XF86MonBrightnessDown, exec, brightnessctl s 5%- && brightnessctl g | awk '{print int($1/255*100)}' > /tmp/brightness_bar.fifo
```

---

## 📊 Performance Benchmark
| Utility | Idle CPU | Active CPU (Stress) | RAM Usage |
| :--- | :--- | :--- | :--- |
| **Volume OSD** | 0.0% | ~4.9% | ~39MB |
| **Brightness OSD** | 0.0% | ~3.4% | ~35MB |
| **Power Mod** | N/A | < 5ms exec | Negligible |

*Tested on Arch Linux / Zen Kernel using `scripts/robust_benchmark.sh`.*
