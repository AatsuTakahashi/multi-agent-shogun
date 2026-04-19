"""
yes/no返信に基づき振り返り候補のステータスを更新する。
系統B: queue/reflection/shogun_candidates.yaml の status を accepted/rejected に更新。
系統A: POST /api/reflection_candidates/{id}/status で更新（Supabase）。

使用例:
  python3 scripts/reflection/apply_yes_no.py yes all
  python3 scripts/reflection/apply_yes_no.py yes 1,2,4
  python3 scripts/reflection/apply_yes_no.py no abc12345
"""
import fcntl
import os
import sys
import tempfile
from pathlib import Path

import yaml

CANDIDATES_PATH = Path(
    "/Users/aatsutakahashi/Development/multi-agent-shogun/queue/reflection/shogun_candidates.yaml"
)
JARVIS_API_BASE = os.environ.get("JARVIS_API_BASE", "http://localhost:8000")


def _load_candidates() -> dict:
    if not CANDIDATES_PATH.exists():
        return {}
    with open(CANDIDATES_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def _save_candidates(data: dict) -> None:
    tmp_fd, tmp_path = tempfile.mkstemp(
        dir=CANDIDATES_PATH.parent, suffix=".tmp"
    )
    try:
        with os.fdopen(tmp_fd, "w", encoding="utf-8") as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            yaml.dump(data, f, allow_unicode=True, default_flow_style=False)
            fcntl.flock(f, fcntl.LOCK_UN)
        os.replace(tmp_path, CANDIDATES_PATH)
    except Exception:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass
        raise


def _update_system_a(candidate_id: str, status: str) -> None:
    """系統A: JARVIS API で status 更新。失敗してもサイレントスキップ。"""
    import urllib.request
    import json

    try:
        payload = json.dumps({"status": status}).encode()
        req = urllib.request.Request(
            f"{JARVIS_API_BASE}/api/reflection_candidates/{candidate_id}/status",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="PATCH",
        )
        urllib.request.urlopen(req, timeout=5)
    except Exception as e:
        print(f"[apply_yes_no] 系統A更新スキップ ({candidate_id}): {e}", file=sys.stderr)


def apply_decision(action: str, targets: str) -> None:
    """
    action: "yes" or "no"
    targets: "all" / "1,2,4"（番号、1始まり）/ "abc12345"（短縮ID前方一致）
    複合指定: カンマ区切りで番号と短縮IDを混在可
    """
    data = _load_candidates()
    candidates = data.get("candidates", [])
    pending = [c for c in candidates if c.get("status") == "pending"]

    if not pending:
        print("pending候補なし。スキップ。")
        return

    if targets.strip().lower() == "all":
        selected = list(pending)
    else:
        selected_ids: set[str] = set()
        for t in targets.split(","):
            t = t.strip()
            if not t:
                continue
            if t.isdigit():
                idx = int(t) - 1
                if 0 <= idx < len(pending):
                    selected_ids.add(pending[idx]["id"])
            else:
                # 短縮IDの前方一致マッチ
                for c in pending:
                    if c["id"].startswith(t):
                        selected_ids.add(c["id"])
        selected = [c for c in pending if c["id"] in selected_ids]

    new_status = "accepted" if action == "yes" else "rejected"
    for c in selected:
        c["status"] = new_status
        _update_system_a(c.get("system_a_id", c["id"]), new_status)

    _save_candidates(data)
    print(f"{len(selected)}件を {new_status} に更新しました。")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: apply_yes_no.py <yes|no> <all|番号|短縮ID>", file=sys.stderr)
        sys.exit(1)
    apply_decision(sys.argv[1], sys.argv[2])
