#!/bin/bash
# Core script: Stop the looping typing sound
# Pure audio control - no counter/lock logic
# Expects: PID as argument or CLICKY_SOUND_FILE env for pkill fallback

PID="$1"
CLICKY_SOUND_FILE="${CLICKY_SOUND_FILE:-clicking-keys.mp3}"

# Kill by PID if provided
if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null || true
fi

# Always pkill as fallback/cleanup — match any supported player
for PLAYER in afplay paplay aplay mpv ffplay; do
    pkill -f "${PLAYER}.*${CLICKY_SOUND_FILE}" 2>/dev/null || true
done
