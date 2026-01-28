#!/bin/bash
# Core script: Start looping typing sound in background
# Pure audio control - no counter/lock logic
# Expects environment: SOUND_FILE, CLICKY_VOLUME, CLICKY_SPEED, CLICKY_MAX_DURATION

# Detect audio player (allow override via env/config)
if [ -n "$CLICKY_PLAYER" ] && command -v "$CLICKY_PLAYER" &>/dev/null; then
    : # Use configured player
elif [[ "$(uname)" == "Darwin" ]]; then
    # macOS: afplay is built-in
    CLICKY_PLAYER="afplay"
else
    # Linux: prefer players that handle MP3 with volume/speed control
    if command -v mpv &>/dev/null; then
        CLICKY_PLAYER="mpv"
    elif command -v ffplay &>/dev/null; then
        CLICKY_PLAYER="ffplay"
    elif command -v paplay &>/dev/null; then
        CLICKY_PLAYER="paplay"
    elif command -v aplay &>/dev/null; then
        CLICKY_PLAYER="aplay"
    else
        echo "Error: No supported audio player found. Install one of: mpv, ffplay, paplay, aplay" >&2
        exit 1
    fi
fi

# Validate required inputs
if [ -z "$SOUND_FILE" ] || [ ! -f "$SOUND_FILE" ]; then
    echo "Error: SOUND_FILE not set or file not found" >&2
    exit 1
fi

# Defaults
CLICKY_VOLUME="${CLICKY_VOLUME:-0.5}"
CLICKY_MAX_DURATION="${CLICKY_MAX_DURATION:-30}"

# Build player command based on detected player
build_play_cmd() {
    case "$CLICKY_PLAYER" in
        afplay)
            PLAY_CMD=(afplay -v "$CLICKY_VOLUME")
            if [ -n "$CLICKY_SPEED" ]; then
                PLAY_CMD+=(-r "$CLICKY_SPEED")
            fi
            PLAY_CMD+=("$SOUND_FILE")
            ;;
        paplay)
            # paplay supports --volume (0-65536, linear). Convert 0.0-1.0 to that range.
            PA_VOL=$(awk "BEGIN {printf \"%d\", $CLICKY_VOLUME * 65536}")
            PLAY_CMD=(paplay --volume="$PA_VOL" "$SOUND_FILE")
            ;;
        aplay)
            # aplay plays raw/wav natively; mp3 requires conversion.
            # For mp3 files, fall through to ffplay/mpv if available.
            PLAY_CMD=(aplay "$SOUND_FILE")
            ;;
        mpv)
            # mpv volume is 0-100
            MPV_VOL=$(awk "BEGIN {printf \"%d\", $CLICKY_VOLUME * 100}")
            PLAY_CMD=(mpv --no-video --really-quiet --volume="$MPV_VOL")
            if [ -n "$CLICKY_SPEED" ]; then
                PLAY_CMD+=(--speed="$CLICKY_SPEED")
            fi
            PLAY_CMD+=("$SOUND_FILE")
            ;;
        ffplay)
            # ffplay volume is 0-100
            FF_VOL=$(awk "BEGIN {printf \"%d\", $CLICKY_VOLUME * 100}")
            PLAY_CMD=(ffplay -nodisp -autoexit -loglevel quiet -volume "$FF_VOL" "$SOUND_FILE")
            ;;
    esac
}

build_play_cmd

# Start looping sound in background with auto-timeout
(
    START_TIME=$(date +%s)
    while true; do
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        if [ "$ELAPSED" -ge "$CLICKY_MAX_DURATION" ]; then
            exit 0
        fi
        "${PLAY_CMD[@]}" 2>/dev/null
    done
) > /dev/null 2>&1 &

# Output PID for caller to track
echo $!
disown
