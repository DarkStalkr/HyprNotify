#!/bin/bash
# Simple OSD testing utility

FIFO="/tmp/volume_bar.fifo"

# Ensure we are testing the NEW binary by killing any old instance
echo "Restarting volume-osd..."
pkill -x "volume-osd"
sleep 0.2
./volume-osd &
sleep 0.5

echo "Testing volume levels..."
for vol in 10 25 50 75 100 0; do
    echo "Sending $vol% to OSD..."
    echo $vol > "$FIFO"
    sleep 1.2
done

echo "Test complete."
