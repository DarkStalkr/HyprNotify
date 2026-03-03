#!/bin/bash
# OSD Styling Visualizer

BIN_DIR="./bin"
FIFO_VOL="/tmp/volume_bar.fifo"
FIFO_BRI="/tmp/brightness_bar.fifo"

echo -e "\e[1;36m--- OSD Styling Visualizer ---\e[0m"

# 1. Ask for style to test
echo "Select style to test:"
echo "1) macOS (Default)"
echo "2) Classic"
echo "3) Brightness"
read -p "Selection (1-3): " choice

case $choice in
    1) DAEMON="$BIN_DIR/volume-osd"; FIFO="$FIFO_VOL";;
    2) DAEMON="$BIN_DIR/volume-osd-classic"; FIFO="$FIFO_VOL";;
    3) DAEMON="$BIN_DIR/brightness-osd"; FIFO="$FIFO_BRI";;
    *) echo "Invalid choice"; exit 1;;
esac

# 2. Re-compile the specific one (verbose)
echo -e "\e[33m[1/3] Compiling current source...\e[0m"
gcc "src/$(basename $DAEMON | cut -d'-' -f1)/$(basename $DAEMON).c" -o "$DAEMON" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)

# 3. Restart daemon
echo -e "\e[33m[2/3] Restarting OSD daemon...\e[0m"
pkill -f "$(basename $DAEMON)"
sleep 0.5
"$DAEMON" &
DAEMON_PID=$!
sleep 1

# 4. Trigger visualization
echo -e "\e[33m[3/3] Sending test values...\e[0m"
for val in 15 45 75 100 0; do
    echo "  -> Sending $val% to $FIFO"
    echo "$val" > "$FIFO"
    sleep 0.8
done

echo -e "\e[1;32mVisualization complete.\e[0m"
kill $DAEMON_PID 2>/dev/null
