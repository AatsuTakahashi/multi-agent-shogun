# 会社/個人Mac設定分離廃止 調査レポート

## 背景

会社ClaudeのBypass規制強化により、将軍システムの稼働場所は個人Mac（AATSUs-MacBook-Air）のみに確定。
会社Macでは将軍システムを一切使わないことが決定したため、二系統保守の複雑性を廃止する。

## 影響範囲一覧

調査コマンド:
```bash
grep -r "会社Mac|個人Mac|AATSUs-MacBook-Air|company_mac|personal_mac|hostname" \
  --include="*.sh" --include="*.md" --include="*.yaml" --include="*.py" -l
```

### scripts/

| ファイル | 行番号 | 内容 | 判定 |
|---------|--------|------|------|
| `scripts/jarvis_memory.sh` | 14-19 | `hostname`でMacBook-Air/aatsuチェック。会社Mac以外での実行ガード | **要軍師判断** |
| `scripts/jarvis_memory.sh` | 16 | `HOSTNAME=$(hostname)` → `*MacBook-Air*` or `*aatsu*` のみ許可 | **要軍師判断** |

#### jarvis_memory.sh ガードの詳細

```bash
# Guard 1: only run on personal Mac (hostname check)
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" != *"MacBook-Air"* && "$HOSTNAME" != *"aatsu"* ]]; then
    echo "ERROR: This script only runs on personal Mac (detected: $HOSTNAME)" >&2
    exit 1
fi
```

**判定: 要軍師判断**
- このガードは殿の明示的な強い禁止ルール（CLAUDE.md § JARVIS Supabase Memory Write Rule）に基づく
- 会社Macが廃止されても、将来別のMacへの移行時に意図せず会社Macから実行するリスクを防ぐ安全弁としての価値がある
- ただし、個人Mac単一前提ならGuard 1は不要でGuard 2（tokenファイル存在確認）だけで十分とも言える
- → **家老・軍師の判断後に削除or保持を決定。本taskでは保留。**

### docs/

| ファイル | 行番号 | 内容 | 判定 |
|---------|--------|------|------|
| `CLAUDE.md` | 334-339 | `JARVIS Supabase Memory Write Rule` — 会社Mac禁止ルール | **要更新（コミット3）** |

#### CLAUDE.md の該当箇所

```
## JARVIS Supabase Memory Write Rule

**会社MacからJARVIS Supabaseへの記憶書き込みは完全禁止。将来含めて例外なし。**

- `scripts/jarvis_memory.sh` は個人Mac（AATSUs-MacBook-Air）でのみ実行可
- 会社Mac（ホスト名が異なる端末）では絶対に実行しない。curl直打ち等のバイパスも禁止
- JARVIS memories API（POST /api/memories）への直接リクエストも会社Macからは禁止
- この制約の緩和を提案すること自体が禁止
```

**判定: 要更新**
- 「会社Macからは禁止」→「このシステムは個人MacでのみJARVIS書き込みを行う」に言い換え
- 禁止の意図（意図しない環境からの書き込み防止）は維持しつつ、会社Mac二系統の記述を削除

### instructions/

| ファイル | 行番号 | 内容 | 判定 |
|---------|--------|------|------|
| `instructions/shogun.md` | 392-397 | `Pre-CMD Rule Injection` — `sqlite3 jarvis.db` への参照（`/path/to/jarvis.db`） | **要確認・更新** |

**注意**: `instructions/shogun.md` の `sqlite3 /path/to/jarvis.db` は古いドキュメントの名残（パスがプレースホルダー）。
現在のSession StartではCLAUDE.mdのStep 3でSupabase APIを使用するため、この記述はすでに陳腐化している。

### memory/ (MEMORY.md)

| ファイル | 内容 | 判定 |
|---------|------|------|
| `memory/MEMORY.md` | `[個人PCでjarvis.dbを使わない](feedback_no_jarvisdb_personal.md)` のエントリ | **要確認・更新** |

---

## 削除/保持/要軍師判断 分類まとめ

| ID | ファイル | 行番号 | 分類 |
|----|---------|--------|------|
| 1 | `scripts/jarvis_memory.sh` | 14-19 | **要軍師判断** (Guard 1の hostname チェック) |
| 2 | `CLAUDE.md` | 334-339 | **削除可（書き換え）** — 個人Mac単一前提に言い換え |
| 3 | `instructions/shogun.md` | 396 | **削除可** — `sqlite3 /path/to/jarvis.db` は陳腐化 |
| 4 | `memory/MEMORY.md` | feedback_no_jarvisdb_personal.md参照行 | **要確認・更新** |

---

## コミット計画

| コミット | 内容 | ステータス |
|---------|------|---------|
| Commit 1 (chore/investigate) | 本ドキュメント作成 | ✅ 完了 |
| Commit 2 (refactor/scripts) | jarvis_memory.sh Guard 1削除（軍師判断後）| ⏳ 保留 |
| Commit 3 (docs) | CLAUDE.md・MEMORY.md更新 | ⏳ 次フェーズ |
| Commit 4 (test) | syntax check・動作確認 | ⏳ 次フェーズ |

---

## 動作確認結果（Commit 4 用 — 後で追記）

```
# 実行日時: 
# bash -n syntax check結果:
```
