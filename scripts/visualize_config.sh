#!/bin/bash
# Visualize customization changes quickly

DAEMON_BIN="./bin/volume-osd"
FIFO="/tmp/volume_bar.fifo"
SRC="src/volume/volume-osd.c"

echo "--- HyprNotify Config Visualizer ---"

# 1. Compile with current source
echo "[1/3] Compiling current source..."
gcc "$SRC" -o "$DAEMON_BIN" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)

# 2. Restart daemon
echo "[2/3] Restarting daemon..."
pkill volume-osd
"$DAEMON_BIN" &
sleep 1

# 3. Trigger OSD
echo "[3/3] Triggering OSD with test values..."
for val in 25 50 75 100 0; do
    echo "Sending $val% to OSD..."
    echo "$val" > "$FIFO"
    sleep 1
done

echo "Visualizer complete. Edit $SRC to change CSS/Icons and re-run."
