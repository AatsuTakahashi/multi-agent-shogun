#!/bin/bash
# jarvis_memory_backup.sh — Backup JARVIS memories to external GitHub private repo (personal Mac only)
# Usage: bash scripts/jarvis_memory_backup.sh
#
# Environment variables:
#   JARVIS_BACKUP_REPO: Path to local clone of backup repo (default: $HOME/Development/jarvis-memory-backup)

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

# Guard 3: backup repo must exist
JARVIS_BACKUP_REPO="${JARVIS_BACKUP_REPO:-$HOME/Development/jarvis-memory-backup}"
if [[ ! -d "$JARVIS_BACKUP_REPO" ]]; then
    echo "ERROR: Backup repo not found at $JARVIS_BACKUP_REPO" >&2
    bash "$SCRIPT_DIR/ntfy.sh" "【JARVIS記憶バックアップ失敗】$(date +%Y-%m-%d): バックアップリポジトリが見つかりません: $JARVIS_BACKUP_REPO" 2>/dev/null || true
    exit 1
fi

DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$JARVIS_BACKUP_REPO/memories_${DATE}.json"

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

# Git operations
cd "$JARVIS_BACKUP_REPO"
git add "memories_${DATE}.json"

if git diff --cached --quiet; then
    echo "変更なし: 同日のバックアップが既に最新です"
    exit 0
fi

git commit -m "📦 backup: memories snapshot ${DATE}"
git push origin main

echo "バックアップ完了: ${DATE}"
