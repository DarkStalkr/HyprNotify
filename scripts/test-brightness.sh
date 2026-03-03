#!/bin/bash
# Brightness OSD testing utility

FIFO="/tmp/brightness_bar.fifo"

# Ensure OSD is running
echo "Restarting brightness-osd..."
pkill -x "brightness-osd"
sleep 0.2
./brightness-osd &
sleep 0.5

echo "Testing brightness levels..."
for val in 10 30 50 80 100 20; do
    echo "Sending $val% to OSD..."
    echo $val > "$FIFO"
    sleep 1.2
done

echo "Test complete."
