#!/bin/bash
# OSD Performance Benchmark Utility

# Daemons to test
DAEMONS=("volume-osd" "brightness-osd")
FIFO_VOL="/tmp/volume_bar.fifo"
FIFO_BRI="/tmp/brightness_bar.fifo"

echo "--- HyprNotify Performance Benchmark ---"

# 1. Baseline Test (Idle)
echo -e "
[1/3] Baseline: Measuring idle usage (10 seconds)..."
for name in "${DAEMONS[@]}"; do
    PID=$(pgrep -x "$name")
    if [ -n "$PID" ]; then
        STATS=$(ps -p "$PID" -o %cpu,%mem,rss --no-headers)
        echo "$name (PID $PID): $STATS (CPU% MEM% RSS)"
    else
        echo "$name: NOT RUNNING"
    fi
done

# 2. Stress Test (Active Load)
echo -e "
[2/3] Stress Test: Sending 50 updates per daemon in 2 seconds..."
(for i in {1..50}; do echo $i > "$FIFO_VOL"; sleep 0.02; done) &
(for i in {1..50}; do echo $i > "$FIFO_BRI"; sleep 0.02; done) &
wait

echo "Peak usage during updates:"
for name in "${DAEMONS[@]}"; do
    PID=$(pgrep -x "$name")
    if [ -n "$PID" ]; then
        STATS=$(ps -p "$PID" -o %cpu,%mem,rss --no-headers)
        echo "$name (PID $PID): $STATS"
    fi
done

# 3. Power-Mod Execution Test
echo -e "
[3/3] Power-Mod: Measuring execution time..."
TIME_START=$(date +%s%3N)
./bin/power-mod > /dev/null 2>&1
TIME_END=$(date +%s%3N)
ELAPSED=$((TIME_END - TIME_START))
echo "power-mod execution time: ${ELAPSED}ms (includes 1500ms OSD timeout)"

echo -e "
Benchmark complete."
