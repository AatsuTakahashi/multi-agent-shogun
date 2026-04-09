#!/bin/bash
# jarvis_memory_backup.sh — Backup JARVIS memories to local directory (personal Mac only)
# Usage: bash scripts/jarvis_memory_backup.sh
#
# Environment variables:
#   JARVIS_BACKUP_REPO: Path to local backup directory (default: $HOME/Development/jarvis/backups)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Guard 1: only run on personal Mac (hostname check)
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" != *"MacBook-Air"* && "$HOSTNAME" != *"aatsu"* ]]; then
    echo "ERROR: This script only runs on personal Mac (detected: $HOSTNAME)" >&2
    exit 1
fi

# Guard 2: bearer token must exist
TOKEN_FILE="$HOME/.config/jarvis/external_api_token"
if [[ ! -f "$TOKEN_FILE" ]]; then
    echo "ERROR: Token file not found at $TOKEN_FILE" >&2
    exit 1
fi
TOKEN=$(cat "$TOKEN_FILE")

# Setup backup directory
BACKUP_DIR="${JARVIS_BACKUP_REPO:-$HOME/Development/jarvis/backups}"
mkdir -p "$BACKUP_DIR"

DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$BACKUP_DIR/memories_${DATE}.json"

# Fetch memories from JARVIS API
RESPONSE=$(curl -sk --max-time 10 -w "\n%{http_code}" \
    -H "Authorization: Bearer $TOKEN" \
    "https://localhost:8000/api/memories" 2>/dev/null) || {
    echo "ERROR: JARVISサーバーに接続できません" >&2
    bash "$SCRIPT_DIR/ntfy.sh" "【JARVIS記憶バックアップ失敗】${DATE}: JARVISサーバーに接続できません" 2>/dev/null || true
    exit 1
}

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "ERROR: JARVIS API returned HTTP $HTTP_CODE" >&2
    bash "$SCRIPT_DIR/ntfy.sh" "【JARVIS記憶バックアップ失敗】${DATE}: API HTTP ${HTTP_CODE}" 2>/dev/null || true
    exit 1
fi

# Save as pretty-printed JSON
if command -v jq &>/dev/null; then
    echo "$BODY" | jq '.' > "$OUTPUT_FILE"
else
    echo "$BODY" | python3 -m json.tool > "$OUTPUT_FILE"
fi

echo "Saved to $OUTPUT_FILE"

# 7-day rotation: delete backups older than 7 days
find "$BACKUP_DIR" -name 'memories_*.json' -mtime +7 -delete 2>/dev/null || true

echo "バックアップ完了: ${DATE}"
