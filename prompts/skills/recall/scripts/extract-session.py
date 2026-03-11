#!/usr/bin/env python3
"""JSONL session transcript → Logseq namespace page converter (idempotent).

Usage:
    python3 extract-session.py <jsonl_path> [--dry-run] [--min-msgs N] [--outdir DIR] [--status STATUS]

Output:
    ~/Documents/logseq/pages/session___YYYY-MM-DD {slug}.md
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

LOGSEQ_PAGES = Path.home() / "Documents" / "logseq" / "pages"
MAX_USER_PREVIEW = 150
MAX_ASSISTANT_PREVIEW = 100
MAX_TURNS = 50
MAX_SUMMARY = 200

# Characters not allowed in Logseq page filenames
STRIP_CHARS = re.compile(r'[<>:"/\\|?*#^{}\[\]]')

# System tags to strip from user messages (from ArtemXTech/recall)
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

# Messages that are system-generated, not real user input
SKIP_MESSAGES = [
    r'^\[Request interrupted by user.*\]$',
    r'^This session is being continued from a previous conversation',
    r'^## Continue:',
    r'^\*\*IMPORTANT',
]

# System-managed properties (may be updated on each sync)
SYSTEM_PROPERTIES = {"project", "date", "status", "session-id", "messages", "exclude-from-graph-view"}

# System-managed sections (regenerated on each sync)
SYSTEM_SECTIONS = {"Summary", "Conversation", "Files"}


def parse_args():
    p = argparse.ArgumentParser(description="Extract Claude session to Logseq page")
    p.add_argument("jsonl_path", help="Path to .jsonl transcript file")
    p.add_argument("--dry-run", action="store_true", help="Print to stdout instead of writing file")
    p.add_argument("--min-msgs", type=int, default=3, help="Minimum user messages (default: 3)")
    p.add_argument("--outdir", type=str, default=None, help="Override output directory")
    p.add_argument("--status", default="archived", help="Page status (active/archived)")
    return p.parse_args()


def clean_content(text):
    """Strip system tags, keep only human-written content."""
    if not isinstance(text, str):
        return ""
    for pat in STRIP_PATTERNS:
        text = re.sub(pat, "", text, flags=re.DOTALL)
    return text.strip()


def is_skip_message(text):
    """Check if a message is system-generated noise."""
    for pat in SKIP_MESSAGES:
        if re.match(pat, text, re.MULTILINE):
            return True
    return False


def extract_text(content):
    """Extract plain text from message content (str or list of blocks)."""
    if isinstance(content, str):
        return clean_content(content)
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict):
                if block.get("type") == "text":
                    parts.append(block["text"])
                elif block.get("type") == "tool_result":
                    pass
                elif block.get("type") == "thinking":
                    pass
            elif isinstance(block, str):
                parts.append(block)
        return clean_content(" ".join(parts))
    return ""


def extract_tool_names(content):
    """Extract tool_use names from assistant message content."""
    if not isinstance(content, list):
        return []
    names = []
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_use":
            name = block.get("name", "unknown")
            if name not in names:
                names.append(name)
    return names


def derive_slug(text):
    """Derive a filename-safe slug from the first user message."""
    text = text.strip()
    # Take first line only
    text = text.split("\n")[0]
    # Truncate
    if len(text) > 60:
        text = text[:60].rsplit(" ", 1)[0]
    # Remove special chars for filename safety
    text = STRIP_CHARS.sub("", text)
    # Collapse whitespace
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        text = "untitled"
    return text


def derive_project(cwd):
    """Derive project name from cwd path.

    /pj/foo/wt/feat-xxx → foo
    /pj/foo/main        → foo
    /pj/myapp               → myapp
    ~/dots                  → dots
    """
    if not cwd:
        return None
    # Expand home
    cwd = cwd.replace("~", str(Path.home()))
    parts = cwd.split("/")

    # Look for /pj/<name> pattern
    for i, part in enumerate(parts):
        if part == "pj" and i + 1 < len(parts):
            return parts[i + 1]

    # Fallback: last meaningful directory
    for part in reversed(parts):
        if part and part not in (".", ""):
            return part
    return None


def collect_files(messages):
    """Collect unique file paths from tool_use blocks (Read, Edit, Write)."""
    seen = set()
    files = []
    home = str(Path.home())
    for msg in messages:
        content = msg.get("message", {}).get("content", [])
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict):
                continue
            if block.get("type") != "tool_use":
                continue
            inp = block.get("input", {})
            path = inp.get("file_path") or inp.get("path") or ""
            if not path:
                continue
            if path.startswith(home):
                path = "~" + path[len(home):]
            if path not in seen:
                seen.add(path)
                files.append(path)
    return files


def parse_jsonl(jsonl_path):
    """Parse JSONL and return structured session data."""
    messages = []
    with open(jsonl_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            msg_type = obj.get("type")
            if msg_type in ("user", "assistant"):
                messages.append(obj)

    if not messages:
        return None

    # Session metadata
    first = messages[0]
    session_id = first.get("sessionId", "")
    cwd = first.get("cwd", "")

    # Separate user and assistant messages
    assistant_msgs = [m for m in messages if m.get("type") == "assistant"]

    # Filter out pure tool_result user messages, slash commands, and system noise
    real_user_msgs = []
    for m in messages:
        if m.get("type") != "user":
            continue
        if m.get("toolUseResult"):
            continue
        content = m.get("message", {}).get("content", "")
        text = extract_text(content)
        if not text or len(text) < 5:
            continue
        if re.match(r"^/\w+\s*$", text):
            continue
        if is_skip_message(text):
            continue
        real_user_msgs.append(m)

    # Timestamps
    timestamps = [m.get("timestamp", "") for m in messages if m.get("timestamp")]
    if timestamps:
        first_ts = timestamps[0]
        last_ts = timestamps[-1]
    else:
        first_ts = last_ts = ""

    return {
        "session_id": session_id,
        "cwd": cwd,
        "all_messages": messages,
        "real_user_msgs": real_user_msgs,
        "user_count": len(real_user_msgs),
        "assistant_count": len(assistant_msgs),
        "first_ts": first_ts,
        "last_ts": last_ts,
    }


def format_time(ts_str):
    """Format ISO timestamp to HH:MM."""
    if not ts_str:
        return "??:??"
    try:
        dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        # Convert to local time
        local_dt = dt.astimezone()
        return local_dt.strftime("%H:%M")
    except (ValueError, TypeError):
        return "??:??"


def format_date(ts_str):
    """Format ISO timestamp to YYYY-MM-DD."""
    if not ts_str:
        return datetime.now().strftime("%Y-%m-%d")
    try:
        dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        local_dt = dt.astimezone()
        return local_dt.strftime("%Y-%m-%d")
    except (ValueError, TypeError):
        return datetime.now().strftime("%Y-%m-%d")


def duration_minutes(first_ts, last_ts):
    """Calculate duration in minutes between two ISO timestamps."""
    try:
        t1 = datetime.fromisoformat(first_ts.replace("Z", "+00:00"))
        t2 = datetime.fromisoformat(last_ts.replace("Z", "+00:00"))
        return int((t2 - t1).total_seconds() / 60)
    except (ValueError, TypeError, AttributeError):
        return 0


def build_conversation(messages):
    """Build conversation turns: list of (time, user_preview, assistant_preview, tools)."""
    turns = []
    i = 0
    while i < len(messages) and len(turns) < MAX_TURNS:
        msg = messages[i]
        if msg.get("type") == "user" and not msg.get("toolUseResult"):
            text = extract_text(msg.get("message", {}).get("content", ""))
            if text:
                time_str = format_time(msg.get("timestamp", ""))
                user_preview = text[:MAX_USER_PREVIEW]
                if len(text) > MAX_USER_PREVIEW:
                    user_preview += "..."

                # Collect subsequent assistant responses
                asst_text = ""
                asst_tools = []
                j = i + 1
                while j < len(messages) and messages[j].get("type") == "assistant":
                    a_content = messages[j].get("message", {}).get("content", [])
                    a_text = extract_text(a_content)
                    if a_text and not asst_text:
                        asst_text = a_text
                    tools = extract_tool_names(a_content)
                    asst_tools.extend(t for t in tools if t not in asst_tools)
                    j += 1

                asst_preview = asst_text[:MAX_ASSISTANT_PREVIEW]
                if len(asst_text) > MAX_ASSISTANT_PREVIEW:
                    asst_preview += "..."

                turns.append({
                    "time": time_str,
                    "user": user_preview,
                    "assistant": asst_preview,
                    "tools": asst_tools,
                })
                i = j
                continue
        i += 1
    return turns


def parse_existing_page(path):
    """Parse existing Logseq page, separating system vs user content.

    Returns:
        (properties, user_properties, user_sections)
        - properties: dict of all properties {key: value}
        - user_properties: dict of non-system properties {key: raw_line}
        - user_sections: list of raw line groups for non-system top-level blocks
    """
    content = path.read_text(encoding="utf-8")
    lines = content.split("\n")

    properties = {}
    user_properties = {}
    body_start = 0

    # Parse properties (lines before first empty line or first "- " line)
    for idx, line in enumerate(lines):
        if not line.strip():
            body_start = idx + 1
            break
        match = re.match(r'^(\S+?)::\s*(.*)', line)
        if match:
            key, val = match.group(1), match.group(2).strip()
            properties[key] = val
            if key not in SYSTEM_PROPERTIES:
                user_properties[key] = line
            body_start = idx + 1
        else:
            # Not a property line, body starts here
            body_start = idx
            break

    # Parse sections from body
    # Top-level blocks start with "- " (no indent)
    user_sections = []
    current_block = []
    current_is_system = False

    for line in lines[body_start:]:
        if line.startswith("- "):
            # Flush previous block
            if current_block and not current_is_system:
                user_sections.append(current_block)

            current_block = [line]
            # Check if this is a system section header
            section_match = re.match(r'^- # (.+)$', line)
            if section_match and section_match.group(1) in SYSTEM_SECTIONS:
                current_is_system = True
            else:
                current_is_system = False
        elif current_block:
            # Continuation of current block (indented lines)
            current_block.append(line)

    # Flush last block
    if current_block and not current_is_system:
        user_sections.append(current_block)

    return properties, user_properties, user_sections


def find_existing_page(session_id_short, outdir):
    """Find existing page file for this session-id. Returns Path or None."""
    for f in outdir.glob("session___*.md"):
        try:
            with open(f) as fh:
                for line in fh:
                    if line.startswith("session-id::"):
                        existing_id = line.split("::", 1)[1].strip()
                        if existing_id == session_id_short:
                            return f
                    if line.startswith("- "):
                        break  # past properties
        except (OSError, UnicodeDecodeError):
            continue
    return None


def generate_page(session, status, existing_path=None):
    """Generate Logseq page content. Preserves user content from existing page."""
    date_str = format_date(session["first_ts"])
    project = derive_project(session["cwd"])
    sid_short = session["session_id"][:8] if session["session_id"] else "unknown"

    # Parse existing page if present
    user_properties = {}
    user_sections = []
    existing_status = None
    if existing_path:
        props, user_properties, user_sections = parse_existing_page(existing_path)
        existing_status = props.get("status")

    # Don't downgrade archived → active (prevent re-open)
    if existing_status == "archived":
        status = "archived"

    # First user message for summary
    first_user_text = ""
    if session["real_user_msgs"]:
        first_user_text = extract_text(
            session["real_user_msgs"][0].get("message", {}).get("content", "")
        )

    summary = first_user_text[:MAX_SUMMARY]
    if len(first_user_text) > MAX_SUMMARY:
        summary += "..."

    # Duration
    start_time = format_time(session["first_ts"])
    end_time = format_time(session["last_ts"])
    dur = duration_minutes(session["first_ts"], session["last_ts"])

    # Build conversation
    turns = build_conversation(session["all_messages"])

    # Collect files
    files = collect_files(session["all_messages"])

    # Build page
    lines = []

    # System properties
    if project:
        lines.append(f"project:: [[session-{project}]]")
    lines.append(f"date:: {date_str}")
    lines.append(f"status:: {status}")
    lines.append(f"session-id:: {sid_short}")
    lines.append(f"messages:: {session['user_count']}")
    lines.append("exclude-from-graph-view:: true")

    # Append user-added properties
    for key, raw_line in user_properties.items():
        lines.append(raw_line)

    lines.append("")

    # Summary
    lines.append("- # Summary")
    lines.append(f"\t- {summary}")
    lines.append(f"\t- Duration: {start_time} - {end_time} ({dur}min)")
    lines.append(f"\t- Messages: {session['user_count']} user, {session['assistant_count']} assistant")

    # Conversation
    if turns:
        lines.append("- # Conversation")
        for turn in turns:
            user_line = f"\t- {turn['time']} {turn['user']}"
            lines.append(user_line)
            if turn["assistant"]:
                lines.append(f"\t\t- {turn['assistant']}")
            if turn["tools"]:
                tool_str = ", ".join(turn["tools"][:5])
                lines.append(f"\t\t- -> {tool_str}")

    # Files
    if files:
        lines.append("- # Files")
        for fp in files[:30]:
            lines.append(f"\t- `{fp}`")

    # Append user sections (preserved from existing page)
    for section_lines in user_sections:
        for line in section_lines:
            lines.append(line)

    return "\n".join(lines) + "\n"


def output_filename(session):
    """Generate output filename: session___YYYY-MM-DD {slug} {sid}.md"""
    date_str = format_date(session["first_ts"])
    sid_short = session["session_id"][:8] if session["session_id"] else "unknown"
    first_text = ""
    if session["real_user_msgs"]:
        first_text = extract_text(
            session["real_user_msgs"][0].get("message", {}).get("content", "")
        )
    slug = derive_slug(first_text)
    return f"session___{date_str} {slug} {sid_short}.md"


def main():
    args = parse_args()
    jsonl_path = Path(args.jsonl_path).expanduser().resolve()

    if not jsonl_path.exists():
        print(f"Error: {jsonl_path} not found", file=sys.stderr)
        sys.exit(1)

    session = parse_jsonl(str(jsonl_path))
    if not session:
        print("Error: no messages found in JSONL", file=sys.stderr)
        sys.exit(1)

    # Skip condition: too few user messages
    if session["user_count"] < args.min_msgs:
        print(f"Skip: only {session['user_count']} user messages (min: {args.min_msgs})", file=sys.stderr)
        sys.exit(0)

    outdir = Path(args.outdir) if args.outdir else LOGSEQ_PAGES
    sid_short = session["session_id"][:8] if session["session_id"] else "unknown"

    # Find existing page for idempotent update
    existing_path = None
    if not args.dry_run:
        existing_path = find_existing_page(sid_short, outdir)

    page_content = generate_page(session, args.status, existing_path)

    if args.dry_run:
        print(page_content)
        out_name = output_filename(session)
        if existing_path:
            print(f"\n--- Would update: {existing_path} ---", file=sys.stderr)
        else:
            print(f"\n--- Would write to: {outdir / out_name} ---", file=sys.stderr)
    else:
        outdir.mkdir(parents=True, exist_ok=True)
        if existing_path:
            existing_path.write_text(page_content, encoding="utf-8")
            print(f"Updated: {existing_path}")
        else:
            out_path = outdir / output_filename(session)
            out_path.write_text(page_content, encoding="utf-8")
            print(f"Created: {out_path}")


if __name__ == "__main__":
    main()
