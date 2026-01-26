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
            "command": "/path/to/claude-clicky-keys/start-typing.sh"
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
            "command": "/path/to/claude-clicky-keys/stop-typing.sh"
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
            "command": "/path/to/claude-clicky-keys/stop-typing.sh"
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

## Custom Sound

The plugin uses a fallback "Tink" sound by default. To use a custom typing sound:

1. Add an audio file to the `sounds/` folder named `keyboard-typing.aiff`
2. Supported formats: AIFF, WAV, MP3 (anything `afplay` supports)

Recommended: Look for mechanical keyboard typing sounds on [freesound.org](https://freesound.org) or similar sites.

## Testing

Test the scripts manually:

```bash
# Start the typing sound
./start-typing.sh

# Listen for a few seconds...

# Stop the typing sound
./stop-typing.sh
```

## How It Works Technically

- `start-typing.sh`: Starts a background process that loops the sound file. Stores PID in `/tmp/claude-clicky-keys.pid`. Auto-stops after 60 seconds.
- `stop-typing.sh`: Reads the PID file and kills the background process.
- Hooks trigger on `Edit`, `Write`, and `Bash` tools by default.

## Configuration

### Adjusting the timeout

Edit `start-typing.sh` and change the `MAX_DURATION` variable (default: 60 seconds).

### Changing which tools trigger sounds

Modify the `matcher` pattern in the hooks:
- `"Edit|Write"` - Only file editing
- `"Bash"` - Only shell commands
- `"Edit|Write|Bash|Read"` - Include file reading
- `".*"` - All tools

## Troubleshooting

### Sound doesn't play
- Check that `afplay` works: `afplay /System/Library/Sounds/Tink.aiff`
- Verify scripts are executable: `chmod +x *.sh`
- Check the sound file exists in `sounds/`

### Sound doesn't stop
- Run `./stop-typing.sh` manually
- Check for orphaned processes: `ps aux | grep afplay`
- The 60-second timeout will eventually stop it

### Hooks not working
- Restart Claude Code (hooks load at session start)
- Verify hooks are in settings: `cat ~/.claude/settings.json | jq .hooks`

## License

MIT
