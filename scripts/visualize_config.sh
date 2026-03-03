#!/bin/bash
# OSD Styling Visualizer (Themed)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$ROOT_DIR/bin"
FIFO_VOL="/tmp/volume_bar.fifo"
FIFO_BRI="/tmp/brightness_bar.fifo"

echo -e "\e[1;36m--- OSD Styling Visualizer (Themed) ---\e[0m"
mkdir -p "$BIN_DIR"

echo "Select style to test:"
echo "1) macOS (Default)"
echo "2) Classic (Mocha)"
echo "3) Dracula"
echo "4) Macchiato"
echo "5) Latte"
echo "6) Brightness"
read -p "Selection (1-6): " choice

case $choice in
    1) SRC_PATH="src/volume/volume-osd.c"; BIN_NAME="volume-osd"; FIFO="$FIFO_VOL";;
    2) SRC_PATH="src/volume/volume-osd-classic.c"; BIN_NAME="volume-osd-classic"; FIFO="$FIFO_VOL";;
    3) SRC_PATH="src/volume/volume-osd-dracula.c"; BIN_NAME="volume-osd-dracula"; FIFO="$FIFO_VOL";;
    4) SRC_PATH="src/volume/volume-osd-macchiato.c"; BIN_NAME="volume-osd-macchiato"; FIFO="$FIFO_VOL";;
    5) SRC_PATH="src/volume/volume-osd-latte.c"; BIN_NAME="volume-osd-latte"; FIFO="$FIFO_VOL";;
    6) SRC_PATH="src/brightness/brightness-osd.c"; BIN_NAME="brightness-osd"; FIFO="$FIFO_BRI";;
    *) echo "Invalid choice"; exit 1;;
esac

echo -e "\e[33m[1/3] Compiling $SRC_PATH...\e[0m"
gcc "$ROOT_DIR/$SRC_PATH" -o "$BIN_DIR/$BIN_NAME" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)

if [ $? -ne 0 ]; then
    echo -e "\e[31mCompilation failed!\e[0m"
    exit 1
fi

echo -e "\e[33m[2/3] Restarting $BIN_NAME...\e[0m"
pkill -f "$BIN_NAME"
sleep 0.5
"$BIN_DIR/$BIN_NAME" &
DAEMON_PID=$!
sleep 1

echo -e "\e[33m[3/3] Sending test values...\e[0m"
for val in 15 45 75 100 0; do
    echo "  -> Sending $val% to $FIFO"
    echo "$val" > "$FIFO"
    sleep 0.8
done

echo -e "\e[1;32mVisualization complete.\e[0m"
kill $DAEMON_PID 2>/dev/null
