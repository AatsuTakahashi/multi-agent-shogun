#!/bin/bash
# inbox_watcher_shogun.sh - 将軍ペインのctx limit検出 → /compact 自動送出
# Usage: bash scripts/inbox_watcher_shogun.sh <tmux_target>
# Example: bash scripts/inbox_watcher_shogun.sh multiagent:agents.0

set -euo pipefail

TMUX_TARGET="${1:-multiagent:agents.0}"
CHECK_INTERVAL=30  # 30秒ごとにペイン内容をチェック
STATE_FILE="$(dirname "$0")/../queue/shogun_state.yaml"

# shogun_state.yaml から outing_mode を取得して閾値切替
OUTING_MODE=$(grep 'outing_mode:' "$STATE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "false")
if [ "$OUTING_MODE" = "true" ]; then
  CTX_THRESHOLD=70
else
  CTX_THRESHOLD=85
fi

# ctx limit検出パターン（閾値に応じて動的生成）
if [ "$CTX_THRESHOLD" -le 70 ]; then
  CTX_LIMIT_PATTERNS=(
    "Context limit reached"
    "Approaching context limit"
    "context window is"
    "ctx:7[0-9]%"
    "ctx:8[0-9]%"
    "ctx:9[0-9]%"
  )
else
  CTX_LIMIT_PATTERNS=(
    "Context limit reached"
    "Approaching context limit"
    "context window is"
    "ctx:8[5-9]%"
    "ctx:9[0-9]%"
  )
fi

while true; do
  # ペイン内容取得（最後30行）
  PANE_CONTENT=$(tmux capture-pane -t "$TMUX_TARGET" -p | tail -30 2>/dev/null || true)

  for pattern in "${CTX_LIMIT_PATTERNS[@]}"; do
    if echo "$PANE_CONTENT" | grep -q "$pattern" 2>/dev/null; then
      echo "[$(date -Iseconds)] ctx limit detected: $pattern"
      # /compact をshogunペインに送出
      tmux send-keys -t "$TMUX_TARGET" "/compact" Enter
      sleep 10  # 連続送出防止
      break
    fi
  done

  sleep "$CHECK_INTERVAL"
done
