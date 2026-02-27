# Volume OSD for Hyprland

A modern, high-performance volume notification bar (OSD) written in C, specifically designed for Wayland compositors using GTK3 and Layer-Shell. It features a crisp, segmented "cube" design inspired by macOS, smooth transitions, and dynamic Nerd Font icons.

## Features
- **macOS-Style Segmented Bar**: Crisp 12px blocks with 4px gaps for clear visibility.
- **Minimalist Aesthetic**: Floating overlay anchored to the bottom center of the screen.
- **Real-time Feedback**: Updates instantly via a named pipe (FIFO) at `/tmp/volume_bar.fifo`.
- **Intelligent Mute Detection**: Automatically checks system mute status via `pamixer`.
- **Hardware Efficient**: Uses an asynchronous event loop; only visible when needed.

## Prerequisites
- **Toolkit**: `gtk3`, `gtk-layer-shell`
- **Audio Utility**: `pamixer` (required for volume and mute status detection).
- **Fonts**: A NerdFont (e.g., JetBrainsMono Nerd Font) to render icons correctly.

## Installation & Compilation

1. **Compile the binary**:
   ```bash
   gcc volume-osd.c -o volume-osd $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)
   ```
2. **Move to your PATH**:
   ```bash
   mkdir -p ~/.local/bin
   cp volume-osd ~/.local/bin/
   ```

## Usage

### 1. Autostart
Add this to your `hyprland.conf` or `autostart.conf`:
```bash
exec-once = ~/.local/bin/volume-osd
```

### 2. Keybindings
Update your volume keys in `hyprland.conf` (using **`binde`** to enable repeat when held):
```bash
binde = , XF86AudioRaiseVolume, exec, pamixer -ui 3 && pamixer --get-volume > /tmp/volume_bar.fifo
binde = , XF86AudioLowerVolume, exec, pamixer -ud 3 && pamixer --get-volume > /tmp/volume_bar.fifo
bind  = , XF86AudioMute, exec, pamixer -t && pamixer --get-volume > /tmp/volume_bar.fifo
```

## Testing
Use the included testing script to verify the UI without changing your system volume:
```bash
./test-osd.sh
```

## UI Customization
You can personalize the OSD by editing the source code in `volume-osd.c`:

- **Segment Size**: In the CSS section, change `12px` (block size) and `16px` (total block + gap) to adjust the "cube" look.
- **Colors**: Modify `#cba6f7` (Mauve) for the accent and `#f38ba8` (Red) for the muted state.
- **Timing**: Change the value in `g_timeout_add(1500, ...)` to adjust the display duration in milliseconds.
