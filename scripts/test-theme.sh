#!/bin/bash
# Quick non-destructive OSD theme tester

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_BIN="$ROOT_DIR/bin/test-osd"
FIFO_VOL="/tmp/volume_bar.fifo"
FIFO_BRI="/tmp/brightness_bar.fifo"

echo -e "\e[1;36m--- HyprNotify Theme Tester ---\e[0m"

echo "Select style to test:"
echo "1) macOS (Default)"
echo "2) Classic (Mocha)"
echo "3) Dracula"
echo "4) Macchiato"
echo "5) Latte (Light)"
echo "6) Brightness (Mocha)"
echo "7) Brightness (Latte)"
read -p "Selection (1-7): " choice

case $choice in
    1) SRC="src/volume/volume-osd-macos.c"; FIFO="$FIFO_VOL";;
    2) SRC="src/volume/volume-osd-classic.c"; FIFO="$FIFO_VOL";;
    3) SRC="src/volume/volume-osd-dracula.c"; FIFO="$FIFO_VOL";;
    4) SRC="src/volume/volume-osd-macchiato.c"; FIFO="$FIFO_VOL";;
    5) SRC="src/volume/volume-osd-latte.c"; FIFO="$FIFO_VOL";;
    6) SRC="src/brightness/brightness-osd.c"; FIFO="$FIFO_BRI";;
    7) SRC="src/brightness/brightness-osd-latte.c"; FIFO="$FIFO_BRI";;
    *) echo "Invalid choice"; exit 1;;
esac

# Kill ALL OSDs to clear the FIFO
echo -e "\e[33m[1/3] Clearing all OSD processes...\e[0m"
pkill -x volume-osd
pkill -x brightness-osd
pkill -f "osd-"
sleep 0.5

# Compile
echo -e "\e[33m[2/3] Compiling standalone test...\e[0m"
gcc "$ROOT_DIR/$SRC" -o "$TEST_BIN" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)

# Run
"$TEST_BIN" &
TEST_PID=$!
sleep 1

# Feed values
echo -e "\e[33m[3/3] Visualizing...\e[0m"
for val in 20 50 80 100 0; do
    echo "  -> $val%"
    echo "$val" > "$FIFO"
    sleep 0.7
done

echo -e "\e[1;32mTest complete. Cleaning up...\e[0m"
kill $TEST_PID
