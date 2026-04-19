#!/bin/bash
# tests/test_outing_mode_gunshi_watcher.sh — outing_mode + gunshi watcher 単体テスト

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# テスト1: shogun_state.yaml に outing_mode フィールドが存在するか
test_outing_mode_field() {
  if grep -q "outing_mode:" "$REPO_ROOT/queue/shogun_state.yaml" 2>/dev/null; then
    echo "PASS: queue/shogun_state.yaml に outing_mode フィールドが存在する"
    ((PASS++))
  else
    echo "FAIL: queue/shogun_state.yaml に outing_mode フィールドが存在しない"
    ((FAIL++))
  fi
}

# テスト2: inbox_watcher_gunshi.sh の syntax チェック
test_gunshi_watcher_syntax() {
  if bash -n "$REPO_ROOT/scripts/inbox_watcher_gunshi.sh" 2>/dev/null; then
    echo "PASS: scripts/inbox_watcher_gunshi.sh syntax OK"
    ((PASS++))
  else
    echo "FAIL: scripts/inbox_watcher_gunshi.sh syntax error"
    ((FAIL++))
  fi
}

# テスト3: ntfy_listener.sh に外出モードハンドラが存在するか
test_ntfy_outing_handler() {
  if grep -q "外出モード on" "$REPO_ROOT/scripts/ntfy_listener.sh" 2>/dev/null; then
    echo "PASS: ntfy_listener.sh に外出モードハンドラが存在する"
    ((PASS++))
  else
    echo "FAIL: ntfy_listener.sh に外出モードハンドラが存在しない"
    ((FAIL++))
  fi
}

# テスト4: inbox_watcher_shogun.sh に outing_mode 閾値切替ロジックが存在するか
test_shogun_watcher_outing_logic() {
  if grep -q "OUTING_MODE" "$REPO_ROOT/scripts/inbox_watcher_shogun.sh" 2>/dev/null && \
     grep -q "CTX_THRESHOLD=70" "$REPO_ROOT/scripts/inbox_watcher_shogun.sh" 2>/dev/null; then
    echo "PASS: inbox_watcher_shogun.sh に outing_mode 閾値切替ロジックが存在する"
    ((PASS++))
  else
    echo "FAIL: inbox_watcher_shogun.sh に outing_mode 閾値切替ロジックが存在しない"
    ((FAIL++))
  fi
}

test_outing_mode_field
test_gunshi_watcher_syntax
test_ntfy_outing_handler
test_shogun_watcher_outing_logic

echo ""
echo "Result: PASS=$PASS FAIL=$FAIL"
[ $FAIL -eq 0 ] && exit 0 || exit 1
