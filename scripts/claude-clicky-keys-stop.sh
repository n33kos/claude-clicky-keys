#!/bin/bash
# Stop the looping typing sound
# Uses counter to handle parallel commands

COUNTER_FILE="/tmp/claude-clicky-keys.counter"
LOCK_DIR="/tmp/claude-clicky-keys.lock"

# Atomic decrement using mkdir lock
while ! mkdir "$LOCK_DIR" 2>/dev/null; do sleep 0.01; done

# Read and decrement counter
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE")
COUNT=$((COUNT - 1))
[ "$COUNT" -lt 0 ] && COUNT=0
echo "$COUNT" > "$COUNTER_FILE"

# Release lock
rmdir "$LOCK_DIR"

# Only stop sound if counter reached zero
if [ "$COUNT" -eq 0 ]; then
    # Kill all instances of claude-clicky-keys-start.sh
    pkill -f "claude-clicky-keys-start.sh" 2>/dev/null || true

    # Kill all afplay processes playing clicking-keys.mp3
    pkill -f "afplay.*clicking-keys.mp3" 2>/dev/null || true

    # Clean up counter file
    rm -f "$COUNTER_FILE"
fi
