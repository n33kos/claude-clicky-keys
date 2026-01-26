#!/bin/bash
# Stop the looping typing sound

PID_FILE="/tmp/claude-clicky-keys.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        # Kill the background loop and all its children
        pkill -P "$PID" 2>/dev/null
        kill "$PID" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi
