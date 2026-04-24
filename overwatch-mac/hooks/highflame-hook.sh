#!/bin/sh
# Highflame Overwatch — IDE hook script
# Sends IDE hook events to Cerberus for real-time security evaluation.
#
# Usage: highflame-hook.sh <source> <event>
#   source: cursor | claudecode | github_copilot
#   event:  IDE-specific event name (e.g., PreToolUse, beforeSubmitPrompt)
#
# Environment:
#   HIGHFLAME_API_KEY  (required) Your Highflame API key.
#   HIGHFLAME_URL      (optional) Cerberus endpoint. Default: https://cerberus.highflame.ai

HIGHFLAME_API_KEY="${HIGHFLAME_API_KEY:-}"
HIGHFLAME_URL="${HIGHFLAME_URL:-https://cerberus.highflame.ai}"

# Fail-open: no API key → allow
if [ -z "$HIGHFLAME_API_KEY" ]; then
    exit 0
fi

SOURCE="${1:-unknown}"
EVENT="${2:-unknown}"

# Read IDE payload from stdin
payload=$(cat)
[ -z "$payload" ] && payload="{}"

# Cross-IDE dedup: skip if Cursor fires a non-cursor hook
if [ "$SOURCE" != "cursor" ] && printf '%s' "$payload" | grep -q '"cursor_version"'; then
    exit 0
fi

# Wrap payload for Cerberus: {"source":"...","event":"...","payload":...}
body=$(printf '{"source":"%s","event":"%s","payload":%s}' "$SOURCE" "$EVENT" "$payload")

# POST to Cerberus with ?format=ide — response is IDE-native format
response=$(printf '%s' "$body" | curl -s -f -m 3 \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HIGHFLAME_API_KEY" \
    -d @- \
    "$HIGHFLAME_URL/v1/hooks/evaluate?format=ide" 2>/dev/null) || true

# Fail-open: curl failure or empty response → allow
if [ -z "$response" ]; then
    exit 0
fi

echo "$response"
exit 0
