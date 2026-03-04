#!/bin/bash
# Robust OSD Performance & Stress Tester

DAEMON="volume-osd"
FIFO="/tmp/volume_bar.fifo"
LOG_FILE="/tmp/osd_stress_test.log"

echo "--- HyprNotify Robust Stress Test ---"
echo "Target: $DAEMON"

# Ensure daemon is running
PID=$(pgrep -x "$DAEMON" | head -n 1)
if [ -z "$PID" ]; then
    echo "Error: $DAEMON is not running. Starting it..."
    ./bin/volume-osd &
    sleep 1
    PID=$(pgrep -x "$DAEMON" | head -n 1)
fi

echo "PID: $PID"
echo "Monitoring CPU for 5 seconds while flooding FIFO..."

# Background monitoring
(
    while ps -p $PID > /dev/null; do
        ps -p $PID -o %cpu,rss --no-headers >> "$LOG_FILE"
        sleep 0.1
    done
) &
MONITOR_PID=$!

# Stress: Send 200 updates with 5ms interval (1 second of sustained input)
for i in {1..200}; do
    val=$((i % 100))
    echo $val > "$FIFO"
    sleep 0.005
done

sleep 2 # Let it settle
kill $MONITOR_PID 2>/dev/null

echo "Stress test complete."
echo "Average CPU during stress:"
awk '{ sum += $1; n++ } END { if (n > 0) print sum / n "%"; }' "$LOG_FILE"
echo "Peak RSS: $(sort -nk2 "$LOG_FILE" | tail -n1 | awk '{print $2/1024 " MB"}')"

rm "$LOG_FILE"
