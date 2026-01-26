# Claude Clicky Keys

Audio feedback for Claude Code - hear keyboard typing sounds while Claude is working!

## How It Works

This plugin uses Claude Code's hooks system to:
1. Start a looping typing sound when Claude begins editing files (Edit, Write, Bash tools)
2. Stop the sound when the tool completes
3. Auto-stops after 60 seconds as a safety measure

## Requirements

- macOS (uses `afplay` for audio playback)
- `jq` for JSON manipulation: `brew install jq`
- Claude Code

## Installation

### Quick Install

```bash
# Clone or download this repository
cd ~/claude-clicky-keys

# Run the installer
./install.sh
```

The installer will:
- Ask if you want user-level (all projects) or project-level hooks
- Automatically detect the plugin location
- Add the necessary hooks to your Claude settings
- Check for existing installations

### Manual Install

Add the following to your Claude Code settings (`~/.claude/settings.json` or `.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-clicky-keys/scripts/claude-clicky-keys-start.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-clicky-keys/scripts/claude-clicky-keys-stop.sh"
          }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-clicky-keys/scripts/claude-clicky-keys-stop.sh"
          }
        ]
      }
    ]
  }
}
```

## Uninstallation

```bash
./uninstall.sh
```

The uninstaller will:
- Detect where hooks are installed
- Remove only the Claude Clicky Keys hooks
- Preserve your other hooks and settings

## Configuration

Configuration is managed via the `.env` file in the project root:

```bash
# Sound file to use (relative to sounds/ or absolute path)
CLICKY_SOUND_FILE="clicking-keys.mp3"

# Volume (0.0 to 1.0)
CLICKY_VOLUME="0.5"

# Auto-stop timeout in seconds
CLICKY_MAX_DURATION="60"

# Playback speed (optional)
CLICKY_SPEED=""
```

### Custom Sounds

Add your own sound files to the `sounds/` folder and update `CLICKY_SOUND_FILE` in `.env`.
Supported formats: MP3, AIFF, WAV (anything `afplay` supports).

Find mechanical keyboard sounds on [freesound.org](https://freesound.org) or similar sites.

### Changing Which Tools Trigger Sounds

Modify the `matcher` pattern in the hooks:
- `"Edit|Write"` - Only file editing
- `"Bash"` - Only shell commands
- `"Edit|Write|Bash|Read"` - Include file reading
- `".*"` - All tools

## Testing

Test the scripts manually:

```bash
# Start the typing sound
./scripts/claude-clicky-keys-start.sh

# Listen for a few seconds...

# Stop the typing sound
./scripts/claude-clicky-keys-stop.sh
```

## How It Works Technically

- `scripts/claude-clicky-keys-start.sh`: Starts a background process that loops the sound file. Kills any existing instances to prevent stacking. Reads config from `.env`.
- `scripts/claude-clicky-keys-stop.sh`: Kills all typing sound processes using process name matching.
- `.env`: Configuration for sound file, volume, timeout, and speed.
- Hooks trigger on `Edit`, `Write`, and `Bash` tools by default.

## Troubleshooting

### Sound doesn't play
- Check that `afplay` works: `afplay /System/Library/Sounds/Tink.aiff`
- Verify scripts are executable: `chmod +x scripts/*.sh`
- Check the sound file exists in `sounds/`

### Sound doesn't stop
- Run `./scripts/claude-clicky-keys-stop.sh` manually
- Check for orphaned processes: `ps aux | grep afplay`
- The 60-second timeout will eventually stop it

### Hooks not working
- Restart Claude Code (hooks load at session start)
- Verify hooks are in settings: `cat ~/.claude/settings.json | jq .hooks`

## Credits

Default keyboard sound effect by [matthewvakaliuk73627](https://pixabay.com/users/matthewvakaliuk73627-48347364/) via [Pixabay](https://pixabay.com/sound-effects/film-special-effects-computer-keyboard-typing-290582/).

## License

MIT
