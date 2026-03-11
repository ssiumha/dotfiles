#!/usr/bin/env python3
"""Date-based Claude session browser with Logseq integration.

Usage:
    python3 recall-day.py list [DATE_EXPR]
    python3 recall-day.py expand <session_num> [DATE_EXPR]

DATE_EXPR: yesterday, today, last week, N days ago, YYYY-MM-DD, last monday, etc.
"""

import json
import os
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

CLAUDE_PROJECTS = Path.home() / ".claude" / "projects"
LOGSEQ_PAGES = Path.home() / "Documents" / "logseq" / "pages"
LOGSEQ_JOURNALS = Path.home() / "Documents" / "logseq" / "journals"

STRIP_PATTERNS = [
    r'<system-reminder>.*?</system-reminder>',
    r'<local-command-caveat>.*?</local-command-caveat>',
    r'<local-command-stdout>.*?</local-command-stdout>',
    r'<command-name>.*?</command-name>',
    r'<command-message>.*?</command-message>',
    r'<command-args>.*?</command-args>',
    r'<available-deferred-tools>.*?</available-deferred-tools>',
    r'<task-notification>.*?</task-notification>',
    r'<user-prompt-submit-hook>.*?</user-prompt-submit-hook>',
]

SKIP_MESSAGES = [
    r'^\[Request interrupted by user.*\]$',
    r'^This session is being continued from a previous conversation',
    r'^## Continue:',
    r'^\*\*IMPORTANT',
]


def is_skip_message(text):
    for pat in SKIP_MESSAGES:
        if re.match(pat, text, re.MULTILINE):
            return True
    return False


def clean_content(text):
    if not isinstance(text, str):
        return ""
    for pat in STRIP_PATTERNS:
        text = re.sub(pat, "", text, flags=re.DOTALL)
    return text.strip()


def extract_text(content):
    if isinstance(content, str):
        return clean_content(content)
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block["text"])
            elif isinstance(block, str):
                parts.append(block)
        return clean_content(" ".join(parts))
    return ""


def parse_date_expr(expr):
    """Parse date expression into (start_date, end_date) as date objects."""
    expr = expr.strip().lower()
    today = datetime.now().date()

    if expr in ("today", ""):
        return today, today
    if expr == "yesterday":
        d = today - timedelta(days=1)
        return d, d

    # N days ago
    m = re.match(r"(\d+)\s*days?\s*ago", expr)
    if m:
        d = today - timedelta(days=int(m.group(1)))
        return d, d

    # last N days
    m = re.match(r"last\s+(\d+)\s*days?", expr)
    if m:
        start = today - timedelta(days=int(m.group(1)))
        return start, today

    # this week (Monday-today)
    if expr == "this week":
        start = today - timedelta(days=today.weekday())
        return start, today

    # last week
    if expr == "last week":
        this_monday = today - timedelta(days=today.weekday())
        last_monday = this_monday - timedelta(days=7)
        last_sunday = this_monday - timedelta(days=1)
        return last_monday, last_sunday

    # last <weekday>
    weekdays = {
        "monday": 0, "tuesday": 1, "wednesday": 2, "thursday": 3,
        "friday": 4, "saturday": 5, "sunday": 6,
    }
    m = re.match(r"last\s+(\w+)", expr)
    if m and m.group(1) in weekdays:
        target = weekdays[m.group(1)]
        days_back = (today.weekday() - target) % 7
        if days_back == 0:
            days_back = 7
        d = today - timedelta(days=days_back)
        return d, d

    # YYYY-MM-DD
    try:
        d = datetime.strptime(expr, "%Y-%m-%d").date()
        return d, d
    except ValueError:
        pass

    print(f"Error: cannot parse date expression '{expr}'", file=sys.stderr)
    print("Supported: today, yesterday, N days ago, last N days, this week, last week, last monday, YYYY-MM-DD", file=sys.stderr)
    sys.exit(1)


def scan_session_metadata(filepath, start_date, end_date):
    """Fast scan of JSONL first ~30 lines for session metadata."""
    session_id = None
    first_ts = None
    first_user_msg = None
    user_count = 0
    file_size = os.path.getsize(filepath)

    try:
        with open(filepath) as f:
            for i, line in enumerate(f):
                if i > 50 and first_ts:
                    break
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if not session_id and obj.get("sessionId"):
                    session_id = obj["sessionId"]

                ts = obj.get("timestamp", "")
                if ts and not first_ts:
                    try:
                        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                        local_date = dt.astimezone().date()
                        if local_date < start_date or local_date > end_date:
                            return None
                        first_ts = ts
                    except (ValueError, TypeError):
                        pass

                if obj.get("type") == "user" and not obj.get("toolUseResult"):
                    content = obj.get("message", {}).get("content", "")
                    text = extract_text(content)
                    if text and len(text) >= 5 and not re.match(r"^/\w+\s*$", text) and not is_skip_message(text):
                        user_count += 1
                        if not first_user_msg:
                            first_user_msg = text

            # Count remaining user messages (fast scan)
            if first_ts:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    if obj.get("type") == "user" and not obj.get("toolUseResult"):
                        content = obj.get("message", {}).get("content", "")
                        text = extract_text(content)
                        if text and len(text) >= 5 and not re.match(r"^/\w+\s*$", text) and not is_skip_message(text):
                            user_count += 1

    except (OSError, UnicodeDecodeError):
        return None

    if not first_ts:
        return None

    return {
        "session_id": session_id or Path(filepath).stem,
        "first_ts": first_ts,
        "first_msg": first_user_msg or "(no message)",
        "user_count": user_count,
        "file_size": file_size,
        "filepath": str(filepath),
    }


def format_time(ts_str):
    if not ts_str:
        return "??:??"
    try:
        dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        return dt.astimezone().strftime("%H:%M")
    except (ValueError, TypeError):
        return "??:??"


def format_size(size_bytes):
    if size_bytes < 1024:
        return f"{size_bytes}B"
    if size_bytes < 1024 * 1024:
        return f"{size_bytes // 1024}KB"
    return f"{size_bytes // (1024 * 1024)}MB"


def has_logseq_page(session_id_short):
    """Check if a Logseq session page exists for this session."""
    for f in LOGSEQ_PAGES.glob("session___*.md"):
        try:
            with open(f) as fh:
                for line in fh:
                    if line.startswith("session-id::"):
                        sid = line.split("::", 1)[1].strip()
                        if sid == session_id_short:
                            return True
                    if line.startswith("- "):
                        break
        except (OSError, UnicodeDecodeError):
            continue
    return False


def find_all_jsonl():
    """Find all JSONL session files."""
    files = []
    if not CLAUDE_PROJECTS.exists():
        return files
    for project_dir in CLAUDE_PROJECTS.iterdir():
        if not project_dir.is_dir():
            continue
        for jsonl in project_dir.glob("*.jsonl"):
            files.append(jsonl)
    return files


def get_logseq_journal(date_obj):
    """Read Logseq journal for a given date."""
    filename = date_obj.strftime("%Y_%m_%d") + ".md"
    journal_path = LOGSEQ_JOURNALS / filename
    if journal_path.exists():
        try:
            return journal_path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            return None
    return None


def dedup_sessions(sessions):
    """Deduplicate sessions by session_id, keeping largest file."""
    seen = {}
    for s in sessions:
        sid = s["session_id"][:8]
        if sid not in seen or s["file_size"] > seen[sid]["file_size"]:
            seen[sid] = s
    return sorted(seen.values(), key=lambda s: s["first_ts"])


def cmd_list(date_expr):
    start_date, end_date = parse_date_expr(date_expr)

    all_jsonl = find_all_jsonl()
    sessions = []

    for jsonl_path in all_jsonl:
        meta = scan_session_metadata(jsonl_path, start_date, end_date)
        if meta:
            sessions.append(meta)

    sessions = dedup_sessions(sessions)

    # Header
    if start_date == end_date:
        day_name = start_date.strftime("%A")
        print(f"\n=== Sessions: {start_date} ({day_name}) ===\n")
    else:
        print(f"\n=== Sessions: {start_date} ~ {end_date} ===\n")

    if not sessions:
        print("  No sessions found.\n")
    else:
        print(f" {'#':>2}  {'Time':5}  {'Msgs':>4}  {'Size':>6}  First Message")
        print(f" {'--':>2}  {'-----':5}  {'----':>4}  {'------':>6}  -------------")

        for i, s in enumerate(sessions, 1):
            time_str = format_time(s["first_ts"])
            msg_preview = s["first_msg"][:60]
            if len(s["first_msg"]) > 60:
                msg_preview += "..."
            sid_short = s["session_id"][:8]
            logseq_marker = " [Logseq]" if has_logseq_page(sid_short) else ""
            print(f" {i:>2}  {time_str:5}  {s['user_count']:>4}  {format_size(s['file_size']):>6}  {msg_preview}{logseq_marker}")

        print(f"\nSession IDs:")
        for i, s in enumerate(sessions, 1):
            print(f"  {i}. {s['session_id'][:8]}")

    # Show Logseq journals
    current = start_date
    while current <= end_date:
        journal = get_logseq_journal(current)
        if journal:
            print(f"\n=== Logseq Journal {current} ===")
            # Truncate if too long
            lines = journal.split("\n")
            if len(lines) > 50:
                print("\n".join(lines[:50]))
                print(f"  ... ({len(lines) - 50} more lines)")
            else:
                print(journal)
        current += timedelta(days=1)

    print()


def cmd_expand(session_num, date_expr):
    start_date, end_date = parse_date_expr(date_expr)
    all_jsonl = find_all_jsonl()
    sessions = []

    for jsonl_path in all_jsonl:
        meta = scan_session_metadata(jsonl_path, start_date, end_date)
        if meta:
            sessions.append(meta)

    sessions = dedup_sessions(sessions)

    if session_num < 1 or session_num > len(sessions):
        print(f"Error: session #{session_num} not found (have {len(sessions)} sessions)", file=sys.stderr)
        sys.exit(1)

    target = sessions[session_num - 1]
    print(f"\n=== Session #{session_num}: {target['session_id'][:8]} ===\n")

    max_msgs = 30
    count = 0
    with open(target["filepath"]) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg_type = obj.get("type")
            if msg_type not in ("user", "assistant"):
                continue

            ts = format_time(obj.get("timestamp", ""))
            content = obj.get("message", {}).get("content", "")

            if msg_type == "user" and not obj.get("toolUseResult"):
                text = extract_text(content)
                if text and len(text) >= 5:
                    print(f"[{ts}] USER: {text[:200]}")
                    count += 1
            elif msg_type == "assistant":
                text = extract_text(content)
                if text:
                    print(f"[{ts}] ASST: {text[:150]}")
                # Show tool names
                if isinstance(content, list):
                    tools = [b.get("name") for b in content
                             if isinstance(b, dict) and b.get("type") == "tool_use"]
                    if tools:
                        print(f"       TOOL: {', '.join(tools[:5])}")
                count += 1

            if count >= max_msgs:
                print(f"\n  ... truncated at {max_msgs} messages")
                break

    print()


def main():
    if len(sys.argv) < 2:
        print("Usage: recall-day.py list [DATE_EXPR]")
        print("       recall-day.py expand <N> [DATE_EXPR]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "list":
        date_expr = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else "today"
        cmd_list(date_expr)
    elif cmd == "expand":
        if len(sys.argv) < 3:
            print("Usage: recall-day.py expand <session_num> [DATE_EXPR]", file=sys.stderr)
            sys.exit(1)
        session_num = int(sys.argv[2])
        date_expr = " ".join(sys.argv[3:]) if len(sys.argv) > 3 else "today"
        cmd_expand(session_num, date_expr)
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
