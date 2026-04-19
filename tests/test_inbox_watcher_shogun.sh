#!/bin/bash
# tests/test_inbox_watcher_shogun.sh — inbox_watcher_shogun.sh 単体テスト

PASS=0
FAIL=0

# テスト1: ctx limit文字列(85%)の検出
test_ctx_detection_85() {
  local test_output="ctx:88%  some other text"
  if echo "$test_output" | grep -q "ctx:8[5-9]%"; then
    echo "PASS: ctx 88% 検出"
    ((PASS++))
  else
    echo "FAIL: ctx 88% 未検出"
    ((FAIL++))
  fi
}

# テスト2: ctx limit文字列(90%)の検出
test_ctx_detection_90() {
  local test_output="ctx:92% remaining"
  if echo "$test_output" | grep -q "ctx:9[0-9]%"; then
    echo "PASS: ctx 92% 検出"
    ((PASS++))
  else
    echo "FAIL: ctx 92% 未検出"
    ((FAIL++))
  fi
}

# テスト3: "Context limit reached" 文字列検出
test_ctx_limit_reached() {
  local test_output="Context limit reached. Please start a new conversation."
  if echo "$test_output" | grep -q "Context limit reached"; then
    echo "PASS: Context limit reached 検出"
    ((PASS++))
  else
    echo "FAIL: Context limit reached 未検出"
    ((FAIL++))
  fi
}

# テスト4: 正常なctx%では誤検出しない
test_no_false_positive() {
  local test_output="ctx:70% all good"
  if echo "$test_output" | grep -q "ctx:8[5-9]%\|ctx:9[0-9]%"; then
    echo "FAIL: ctx 70% で誤検出"
    ((FAIL++))
  else
    echo "PASS: ctx 70% 誤検出なし"
    ((PASS++))
  fi
}

# テスト5: スクリプトのsyntax確認
test_syntax() {
  if bash -n scripts/inbox_watcher_shogun.sh 2>/dev/null; then
    echo "PASS: syntax OK"
    ((PASS++))
  else
    echo "FAIL: syntax error"
    ((FAIL++))
  fi
}

test_ctx_detection_85
test_ctx_detection_90
test_ctx_limit_reached
test_no_false_positive
test_syntax

echo ""
echo "Result: PASS=$PASS FAIL=$FAIL"
[ $FAIL -eq 0 ] && exit 0 || exit 1
