#!/bin/bash
# inbox_watcher_gunshi.sh - 軍師ペイン(multiagent:0.8) ctx自動管理
# Usage: bash scripts/inbox_watcher_gunshi.sh
# NOTE: 起動は殿が手動で実行すること（D006制約: kill/自動起動禁止）

set -euo pipefail

GUNSHI_PANE="multiagent:0.8"
CHECK_INTERVAL=30  # 30秒ごとにペイン内容をチェック
LOG_FILE="/tmp/inbox_watcher_gunshi.log"

WARN_THRESHOLD=80
COMPACT_THRESHOLD=85
CLEAR_THRESHOLD=90

log() {
  echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"
}

log "inbox_watcher_gunshi started — pane: $GUNSHI_PANE"
log "Thresholds: warn=${WARN_THRESHOLD}% compact=${COMPACT_THRESHOLD}% clear=${CLEAR_THRESHOLD}%"

# 直近の送出時刻（連続送出防止）
LAST_COMPACT_AT=0
LAST_CLEAR_AT=0

while true; do
  PANE_CONTENT=$(tmux capture-pane -t "$GUNSHI_PANE" -p | tail -30 2>/dev/null || true)

  NOW=$(date +%s)

  # ctx:90%+ → /clear
  if echo "$PANE_CONTENT" | grep -qE "ctx:9[0-9]%" 2>/dev/null; then
    if [ $((NOW - LAST_CLEAR_AT)) -gt 120 ]; then
      log "ctx CLEAR threshold (${CLEAR_THRESHOLD}%) detected — sending /clear to $GUNSHI_PANE"
      tmux send-keys -t "$GUNSHI_PANE" "/clear" Enter
      LAST_CLEAR_AT=$NOW
      sleep 10
    fi
  # ctx:85-89% → /compact
  elif echo "$PANE_CONTENT" | grep -qE "ctx:8[5-9]%" 2>/dev/null; then
    if [ $((NOW - LAST_COMPACT_AT)) -gt 60 ]; then
      log "ctx COMPACT threshold (${COMPACT_THRESHOLD}%) detected — sending /compact to $GUNSHI_PANE"
      tmux send-keys -t "$GUNSHI_PANE" "/compact" Enter
      LAST_COMPACT_AT=$NOW
      sleep 10
    fi
  # ctx:80-84% → 警告ログのみ
  elif echo "$PANE_CONTENT" | grep -qE "ctx:8[0-4]%" 2>/dev/null; then
    log "ctx WARN threshold (${WARN_THRESHOLD}%) detected — gunshi should finish current task"
  fi

  # "Context limit reached" パターン
  if echo "$PANE_CONTENT" | grep -q "Context limit reached" 2>/dev/null; then
    if [ $((NOW - LAST_COMPACT_AT)) -gt 60 ]; then
      log "Context limit reached detected — sending /compact to $GUNSHI_PANE"
      tmux send-keys -t "$GUNSHI_PANE" "/compact" Enter
      LAST_COMPACT_AT=$NOW
      sleep 10
    fi
  fi

  sleep "$CHECK_INTERVAL"
done
