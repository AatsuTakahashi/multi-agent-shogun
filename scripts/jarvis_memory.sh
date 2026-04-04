#!/bin/bash
# jarvis_memory.sh — Write memories to JARVIS Supabase via API
# Usage: bash scripts/jarvis_memory.sh <category> <content> [importance] [source]
#
# Categories: fact, preference, person, skill, event
# Importance: 1-10 (default: 5)
# Source: default "shogun"
#
# Example:
#   bash scripts/jarvis_memory.sh fact "課題: X。対応: Y。理由: Z" 7 shogun

set -euo pipefail

# Guard 1: only run on personal Mac (hostname check)
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" != *"MacBook-Air"* && "$HOSTNAME" != *"aatsu"* ]]; then
    echo "ERROR: This script only runs on personal Mac (detected: $HOSTNAME)" >&2
    exit 1
fi

# Guard 2: bearer token must exist on this machine
TOKEN_FILE="$HOME/.config/jarvis/external_api_token"
if [[ ! -f "$TOKEN_FILE" ]]; then
    echo "ERROR: Token file not found at $TOKEN_FILE" >&2
    echo "This script is only authorized on personal Mac." >&2
    exit 1
fi
API_TOKEN=$(cat "$TOKEN_FILE")

JARVIS_API="https://localhost:8000"
CATEGORY="${1:?Usage: jarvis_memory.sh <category> <content> [importance] [source]}"
CONTENT="${2:?Usage: jarvis_memory.sh <category> <content> [importance] [source]}"
IMPORTANCE="${3:-5}"
SOURCE="${4:-shogun}"

# Validate category
case "$CATEGORY" in
    fact|preference|person|skill|event) ;;
    *) echo "ERROR: Invalid category '$CATEGORY'. Use: fact, preference, person, skill, event" >&2; exit 1 ;;
esac

# Check if JARVIS backend is running
if ! curl -s --max-time 2 "$JARVIS_API/api/health" > /dev/null 2>&1; then
    echo "ERROR: JARVIS backend not running at $JARVIS_API" >&2
    echo "Start it with: cd ~/Development/jarvis && make dev" >&2
    exit 1
fi

# Escape content for JSON
JSON_CONTENT=$(printf '%s' "$CONTENT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$JARVIS_API/api/memories" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_TOKEN" \
    -d "{\"category\":\"$CATEGORY\",\"content\":$JSON_CONTENT,\"importance\":$IMPORTANCE,\"source\":\"$SOURCE\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "201" ]]; then
    echo "OK: Memory saved — $BODY"
else
    echo "ERROR: HTTP $HTTP_CODE — $BODY" >&2
    exit 1
fi
