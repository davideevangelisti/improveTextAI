#!/bin/bash
# improve_text.sh — calls Claude API to improve selected text.

set -euo pipefail

TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

cat > "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
    exit 0
fi

# Load API key
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -f "$HOME/.config/anthropic/api_key" ]; then
    export ANTHROPIC_API_KEY=$(cat "$HOME/.config/anthropic/api_key" | tr -d '[:space:]')
fi

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "ANTHROPIC_API_KEY not set" >&2
    exit 1
fi

PAYLOAD=$(python3 - "$TMPFILE" <<'EOF'
import json, sys

system = "You are a writing assistant. Fix grammar, spelling, and punctuation, and lightly improve the phrasing where it sounds unnatural or unclear — but stay close to the original. Keep the author's tone, voice, and structure. Do not rewrite or restructure sentences unless truly necessary. Preserve all formatting. Output ONLY the corrected text — no explanations, no preamble, no quotes. Never truncate or omit any part of the text."

with open(sys.argv[1], 'r') as f:
    user = f.read()

payload = {
    "model": "claude-sonnet-4-6",
    "max_tokens": 8192,
    "system": system,
    "messages": [
        {"role": "user", "content": user}
    ]
}
print(json.dumps(payload))
EOF
)

RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$PAYLOAD")

python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
if 'content' in data:
    print(data['content'][0]['text'], end='')
else:
    print(json.dumps(data), file=sys.stderr)
    sys.exit(1)
" <<< "$RESPONSE"
