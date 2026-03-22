#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Improve Text with AI
# @raycast.mode silent
# @raycast.packageName AI Tools

# Optional parameters:
# @raycast.icon ✍️
# @raycast.shortcut cmd+shift+i

SCRIPT_DIR="/Users/davide/Library/Mobile Documents/com~apple~CloudDocs/Projects/improve-text-ai"

# Start Ollama if not already running
if ! curl -s http://localhost:11434 > /dev/null 2>&1; then
    /usr/local/bin/ollama serve > /tmp/ollama.log 2>&1 &
    sleep 3
fi

# Save current clipboard so we can restore it after
ORIGINAL_CLIPBOARD=$(pbpaste)

# Copy selected text
osascript -e 'tell application "System Events" to keystroke "c" using command down'
sleep 0.2

SELECTED=$(pbpaste)

if [ -z "$SELECTED" ]; then
    osascript -e 'display notification "No text selected." with title "Improve Text"'
    exit 0
fi

# Notify start
afplay /System/Library/Sounds/Morse.aiff &
osascript -e 'display notification "Improving your text..." with title "✍️ Improve Text"'

# Improve text
IMPROVED=$(echo "$SELECTED" | bash "$SCRIPT_DIR/improve_text.sh")

if [ -z "$IMPROVED" ]; then
    osascript -e 'display notification "Something went wrong." with title "Improve Text"'
    # Restore original clipboard
    printf '%s' "$ORIGINAL_CLIPBOARD" | pbcopy
    exit 1
fi

# Put improved text in clipboard and paste
printf '%s' "$IMPROVED" | pbcopy
osascript -e 'tell application "System Events" to keystroke "v" using command down'
sleep 0.1

# Restore original clipboard
printf '%s' "$ORIGINAL_CLIPBOARD" | pbcopy

afplay /System/Library/Sounds/Glass.aiff &
osascript -e 'display notification "Done! Text has been replaced." with title "✅ Improve Text"'
