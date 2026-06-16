#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title improveTextAI
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.description Improve selected text with Claude directly from the right-click menu (or a keyboard shortcut) in any macOS app.
# @raycast.author Davide Evangelisti

resolve_script_dir() {
    local source dir
    source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

SCRIPT_DIR="$(resolve_script_dir)"
IMPROVE_TEXT_SCRIPT="$SCRIPT_DIR/improve_text.sh"
LOG_FILE="$HOME/Library/Logs/improveTextAI.log"
if ! { mkdir -p "$(dirname "$LOG_FILE")" && : >> "$LOG_FILE"; } 2>/dev/null; then
    LOG_FILE="${TMPDIR:-/tmp}/improveTextAI.log"
    : >> "$LOG_FILE" 2>/dev/null || true
fi

log() {
    { printf '%s RaycastScript: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; } 2>/dev/null >> "$LOG_FILE" || true
}

notify() {
    /usr/bin/osascript \
        -e 'on run argv' \
        -e 'display notification (item 1 of argv) with title (item 2 of argv)' \
        -e 'end run' \
        "$1" "$2" >/dev/null 2>> "$LOG_FILE" || true
}

play_sound() {
    /usr/bin/afplay "$1" >/dev/null 2>> "$LOG_FILE" &
}

log "launched from $SCRIPT_DIR"

if [ ! -f "$IMPROVE_TEXT_SCRIPT" ]; then
    log "missing helper script at $IMPROVE_TEXT_SCRIPT"
    notify "Cannot find improve_text.sh. Re-add the moved folder in Raycast." "Improve Text"
    exit 1
fi

# Save current clipboard so we can restore it after
ORIGINAL_CLIPBOARD=$(pbpaste)

# Copy selected text
osascript -e 'tell application "System Events" to keystroke "c" using command down'
sleep 0.2

SELECTED=$(pbpaste)

if [ -z "$SELECTED" ]; then
    log "exiting because no text was selected"
    notify "No text selected." "Improve Text"
    exit 0
fi

# Notify start
play_sound /System/Library/Sounds/Morse.aiff
notify "Improving your text..." "Improve Text"

# Improve text
ERROR_FILE=$(mktemp)
IMPROVED=$(printf '%s' "$SELECTED" | bash "$IMPROVE_TEXT_SCRIPT" 2> "$ERROR_FILE")
EXIT_CODE=$?
ERROR_MESSAGE=$(tail -1 "$ERROR_FILE" 2>/dev/null || true)
rm -f "$ERROR_FILE"

if [ $EXIT_CODE -ne 0 ] || [ -z "$IMPROVED" ]; then
    [ $EXIT_CODE -ne 0 ] || EXIT_CODE=1
    [ -n "$ERROR_MESSAGE" ] || ERROR_MESSAGE="no improved text was returned"
    log "failed with exit $EXIT_CODE: $ERROR_MESSAGE"
    notify "Something went wrong. See ~/Library/Logs/improveTextAI.log" "Improve Text"
    printf '%s' "$ORIGINAL_CLIPBOARD" | pbcopy
    exit $EXIT_CODE
fi

# Put improved text in clipboard and paste
printf '%s' "$IMPROVED" | pbcopy
osascript -e 'tell application "System Events" to keystroke "v" using command down'
sleep 0.1

# Restore original clipboard
printf '%s' "$ORIGINAL_CLIPBOARD" | pbcopy

play_sound /System/Library/Sounds/Glass.aiff
notify "Done! Text has been replaced." "Improve Text"
log "completed successfully"
