#!/bin/bash
# Stop the looping typing sound
# Uses marker files to handle parallel commands

MARKER_DIR="/tmp/claude-clicky-keys-markers"

# Clean up stale markers (processes that no longer exist)
if [ -d "$MARKER_DIR" ]; then
    for marker in "$MARKER_DIR"/*; do
        if [ -f "$marker" ]; then
            PID=$(basename "$marker")
            # Check if process still exists
            if ! kill -0 "$PID" 2>/dev/null; then
                rm -f "$marker"
            fi
        fi
    done
fi

# Check if any markers remain (active commands)
if [ -d "$MARKER_DIR" ]; then
    REMAINING=$(find "$MARKER_DIR" -type f 2>/dev/null | wc -l)
else
    REMAINING=0
fi

# Only stop sound if no other commands are running
if [ "$REMAINING" -eq 0 ]; then
    # Kill all instances of claude-clicky-keys-start.sh
    pkill -f "claude-clicky-keys-start.sh" 2>/dev/null || true

    # Kill all afplay processes playing clicking-keys.mp3
    pkill -f "afplay.*clicking-keys.mp3" 2>/dev/null || true

    # Clean up marker directory
    rm -rf "$MARKER_DIR"
fi
