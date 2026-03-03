#!/bin/bash
# Advanced Debugging Script for Brightness OSD

FIFO="/tmp/brightness_bar.fifo"
BINARY="$HOME/.local/bin/brightness-osd"
LOG_FILE="/tmp/brightness_osd_debug.log"

echo "--- Brightness OSD Debugging Session ---" | tee "$LOG_FILE"
date | tee -a "$LOG_FILE"

# 1. Check Binary
echo "[1/5] Checking binary..." | tee -a "$LOG_FILE"
if [ -f "$BINARY" ]; then
    ls -l "$BINARY" | tee -a "$LOG_FILE"
    file "$BINARY" | tee -a "$LOG_FILE"
else
    echo "ERROR: Binary not found at $BINARY" | tee -a "$LOG_FILE"
    exit 1
fi

# 2. Check Dependencies (shared libs)
echo "[2/5] Checking shared library dependencies..." | tee -a "$LOG_FILE"
ldd "$BINARY" | grep -E "gtk|layer|wayland" | tee -a "$LOG_FILE"

# 3. Check FIFO
echo "[3/5] Checking FIFO state..." | tee -a "$LOG_FILE"
if [ -p "$FIFO" ]; then
    echo "FIFO exists: $FIFO" | tee -a "$LOG_FILE"
    ls -l "$FIFO" | tee -a "$LOG_FILE"
else
    echo "FIFO does not exist. Creating it..." | tee -a "$LOG_FILE"
    mkfifo "$FIFO"
    chmod 666 "$FIFO"
fi

# 4. Start Daemon with output capture
echo "[4/5] Restarting brightness-osd in background with logging..." | tee -a "$LOG_FILE"
pkill -x "brightness-osd"
sleep 0.5

# Start the daemon and redirect ALL output to the log file
"$BINARY" > "$LOG_FILE.out" 2>&1 &
DAEMON_PID=$!
sleep 1

if ps -p $DAEMON_PID > /dev/null; then
    echo "Daemon started successfully (PID: $DAEMON_PID)" | tee -a "$LOG_FILE"
else
    echo "ERROR: Daemon failed to start or crashed immediately." | tee -a "$LOG_FILE"
    cat "$LOG_FILE.out" | tee -a "$LOG_FILE"
    exit 1
fi

# 5. Injection Test
echo "[5/5] Injecting test value (50)..." | tee -a "$LOG_FILE"
echo 50 > "$FIFO"
sleep 1

echo "--- Output from Daemon ---" | tee -a "$LOG_FILE"
cat "$LOG_FILE.out" | tee -a "$LOG_FILE"

echo "--- End of Debug ---" | tee -a "$LOG_FILE"
echo "Full log available at: $LOG_FILE"
