#!/bin/bash
# Hook wrapper: Parse stdin, manage counter/locks, start sound
# All complexity lives here - play.sh is pure audio control

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Plugin root from env or derive from script location
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
    PLUGIN_DIR="$CLAUDE_PLUGIN_ROOT"
else
    PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

CONFIG_FILE="${HOME}/.claude/clicky-keys.env"
SOUNDS_DIR="${PLUGIN_DIR}/sounds"
TMP_DIR="/tmp/claude-clicky-keys"
COUNTER_FILE="${TMP_DIR}/counter"
PID_FILE="${TMP_DIR}/pid"
LOCK_DIR="${TMP_DIR}/lock"

mkdir -p "$TMP_DIR"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Check if muted
if [ "$CLICKY_MUTED" = "true" ]; then
    exit 0
fi

# Read hook input from stdin (with timeout to prevent blocking when called manually)
HOOK_INPUT=$(timeout 0.1 cat 2>/dev/null || true)

# Extract tool name from JSON input
TOOL_NAME=""
if [ -n "$HOOK_INPUT" ]; then
    TOOL_NAME=$(echo "$HOOK_INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Check if this tool should trigger sound
CLICKY_TRIGGERS="${CLICKY_TRIGGERS:-Edit,MultiEdit,Write,Bash,Task}"
if [ -n "$TOOL_NAME" ]; then
    if [[ ! ",$CLICKY_TRIGGERS," == *",$TOOL_NAME,"* ]]; then
        exit 0
    fi
fi

# Set defaults
CLICKY_SOUND_MODE="${CLICKY_SOUND_MODE:-clicking}"
CLICKY_SOUND_FILE="${CLICKY_SOUND_FILE:-clicking-keys.mp3}"
CLICKY_VOLUME="${CLICKY_VOLUME:-0.5}"
if [ "$CLICKY_SOUND_MODE" = "animalese" ]; then
    CLICKY_MAX_DURATION="${CLICKY_MAX_DURATION:-15}"
else
    CLICKY_MAX_DURATION="${CLICKY_MAX_DURATION:-30}"
fi

# Resolve CLICKY_SOUND_FILE early (needed for stale counter detection via pgrep)
if [ "$CLICKY_SOUND_MODE" = "animalese" ]; then
    CLICKY_SOUND_FILE="animalese-generated.wav"
fi

# === Counter/Lock Management ===

# Atomic increment using mkdir lock
while ! mkdir "$LOCK_DIR" 2>/dev/null; do sleep 0.01; done

COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE")

# Check for stale counter (counter > 0 but no sound playing)
if [ "$COUNT" -gt 0 ]; then
    STALE=true
    for PLAYER in afplay paplay aplay mpv ffplay; do
        if pgrep -f "${PLAYER}.*${CLICKY_SOUND_FILE}" > /dev/null 2>&1; then
            STALE=false
            break
        fi
    done
    if [ "$STALE" = true ]; then
        COUNT=0
    fi
fi

COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Release lock
rmdir "$LOCK_DIR"

# Only first caller starts sound
if [ "$COUNT" -gt 1 ]; then
    exit 0
fi

# Clean up any orphaned processes
for PLAYER in afplay paplay aplay mpv ffplay; do
    pkill -f "${PLAYER}.*${CLICKY_SOUND_FILE}" 2>/dev/null || true
done

# === Resolve Sound File ===

if [ "$CLICKY_SOUND_MODE" = "animalese" ]; then
    # Generate fresh animalese babble via Python (only runs for first caller)
    GENERATED_WAV="${TMP_DIR}/animalese-generated.wav"
    export CLICKY_ANIMALESE_PITCH="${CLICKY_ANIMALESE_PITCH:-1.0}"
    export CLICKY_ANIMALESE_LENGTH="${CLICKY_ANIMALESE_LENGTH:-20}"
    export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"
    if python3 "${SCRIPT_DIR}/animalese.py" "$GENERATED_WAV" > /dev/null 2>&1; then
        SOUND_FILE="$GENERATED_WAV"
    else
        # Fallback to clicking mode if python3 unavailable or synthesis fails
        SOUND_FILE="${SOUNDS_DIR}/clicking-keys.mp3"
        CLICKY_SOUND_FILE="clicking-keys.mp3"
    fi
else
    # Standard mode: use configured sound file
    if [[ "$CLICKY_SOUND_FILE" = /* ]]; then
        SOUND_FILE="$CLICKY_SOUND_FILE"
    else
        SOUND_FILE="${SOUNDS_DIR}/${CLICKY_SOUND_FILE}"
    fi
fi

# Check if sound file exists
if [ ! -f "$SOUND_FILE" ]; then
    exit 1
fi

# === Start Sound ===

# Export config for play.sh
export SOUND_FILE
export CLICKY_PLAYER
export CLICKY_VOLUME
export CLICKY_SPEED
export CLICKY_MAX_DURATION

# Call play.sh and save PID
PID=$("${SCRIPT_DIR}/play.sh")
echo "$PID" > "$PID_FILE"
