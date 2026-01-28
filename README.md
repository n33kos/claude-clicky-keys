# Claude Clicky Keys

Audio feedback for Claude Code - hear keyboard typing sounds while Claude is working.

## How It Works

This plugin uses Claude Code's hooks system to:

1. Start a looping typing sound when Claude uses configured tools
2. Stop the sound when the tool completes
3. Auto-stops after 60 seconds as a safety measure

### Configurable Triggers

You can choose which tools trigger the typing sound via `CLICKY_TRIGGERS` in your config file. The default is `Edit,Write,Bash`.

To add more tools, edit `~/.claude/clicky-keys.env` and modify `CLICKY_TRIGGERS`. You may also need to add the tool to the matcher in `hooks/hooks.json` if it's not already included.

## Requirements

- **macOS** — uses `afplay` (built-in, no extra install needed)
- **Linux** — uses one of: `paplay` (PulseAudio/PipeWire), `aplay` (ALSA), `mpv`, or `ffplay` (FFmpeg)
- Claude Code with plugin support

## Installation

### From GitHub

```bash
# Add the marketplace
/plugin marketplace add n33kos/claude-plugins

# Add the plugin from this repository
/plugin install clicky-keys@n33kos
```

### For Development/Testing

```bash
# Clone the repository
git clone https://github.com/n33kos/claude-clicky-keys.git

# Test with Claude
claude --plugin-dir ./claude-clicky-keys
```

## Configuration

Run the setup command to configure volume, speed, and timeout:

```
/clicky-keys:setup
```

Or manually edit `~/.claude/clicky-keys.env`:

```bash
# Sound file (relative to plugin sounds/ or absolute path)
CLICKY_SOUND_FILE="clicking-keys.mp3"

# Audio player override (auto-detected if not set)
# macOS: afplay | Linux: mpv, ffplay, paplay, aplay
# CLICKY_PLAYER=""

# Volume (0.0 to 1.0)
CLICKY_VOLUME="0.5"

# Auto-stop timeout in seconds
CLICKY_MAX_DURATION="30"

# Playback speed (0.5 = half, 1.0 = normal, 2.0 = double)
CLICKY_SPEED="1.0"

# Delay before stopping sound in seconds (ensures fast operations are audible)
CLICKY_STOP_DELAY="0.4"

# Tools that trigger sound (comma-separated)
# Available: Edit, MultiEdit, Write, Bash, Task
CLICKY_TRIGGERS="Edit,MultiEdit,Write,Bash,Task"

# Mute sounds (true/false) - toggle with /clicky-keys:mute
CLICKY_MUTED="false"
```

### Custom Sounds

Add your own sound files to the `sounds/` folder and update `CLICKY_SOUND_FILE` in your config.

Supported formats depend on your audio player:
- **macOS (`afplay`):** MP3, AIFF, WAV, AAC, M4A
- **Linux (`paplay`):** WAV, OGG, FLAC (MP3 works on most PipeWire setups)
- **Linux (`mpv`/`ffplay`):** MP3, WAV, OGG, FLAC, and most other formats

Find mechanical keyboard sounds on [freesound.org](https://freesound.org) or similar sites.

## Commands

- `/clicky-keys:setup` - Interactive configuration wizard
- `/clicky-keys:mute` - Toggle sounds on/off mid-session
- `/clicky-keys:test` - Test the sound for a few seconds

## Testing

The easiest way to test is to run `/clicky-keys:test` which will run a simple bash command - the hooks trigger automatically.

### Manual Testing (outside Claude)

The scripts are split into hook wrappers and core audio scripts:

```bash
# Core scripts (pure audio control, need env vars):
SOUND_FILE=./sounds/clicking-keys.mp3 ./scripts/play.sh   # outputs PID
./scripts/kill.sh                                          # stops sound

# Hook wrappers (handle stdin parsing, counters, locks):
./scripts/start.sh   # called by hooks on tool start
./scripts/stop.sh    # called by hooks on tool end
```

## Troubleshooting

### Sound doesn't play

- **macOS:** Check that `afplay` works: `afplay /System/Library/Sounds/Tink.aiff`
- **Linux:** Check which player is available: `which paplay mpv ffplay aplay`
  - Install one if needed: `sudo apt install pulseaudio-utils` (Debian/Ubuntu) or `sudo dnf install mpv` (Fedora)
- Verify scripts are executable: `chmod +x scripts/*.sh`
- Run `/clicky-keys:setup` to configure settings

### Sound doesn't stop

- Run `./scripts/kill.sh` manually to force stop
- Check for orphaned processes: `ps aux | grep -E "afplay|paplay|aplay|mpv|ffplay"`
- Kill directly if needed: `pkill -f "clicking-keys"`
- The auto-timeout (default 60 seconds) will eventually stop it

### Cleanup temp files

All temporary files are stored in `/tmp/claude-clicky-keys/`. To clean up:

```bash
rm -rf /tmp/claude-clicky-keys
```

## Credits

Default keyboard sound effect by [matthewvakaliuk73627](https://pixabay.com/users/matthewvakaliuk73627-48347364/) via [Pixabay](https://pixabay.com/sound-effects/film-special-effects-computer-keyboard-typing-290582/).

## License

MIT
