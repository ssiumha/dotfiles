#!/usr/bin/env python3
"""Build Logseq knowledge graph and generate vis-network HTML report.

Parses [[wikilinks]] and #tags from Logseq pages to visualize
page interconnections. Uses only the Python standard library (3.10+).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

from vis_graph_common import find_template, inject_template


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

NAMESPACE_COLORS: dict[str, str] = {
    "decision":     "#4CAF50",
    "troubleshoot": "#F44336",
    "spec":         "#2196F3",
    "qa":           "#FF9800",
    "debrief":      "#009688",
    "session":      "#9E9E9E",
    "incident":     "#D32F2F",
    "_root":        "#607D8B",
}

PROJECT_PALETTE = [
    "#9C27B0", "#7B1FA2", "#6A1B9A",
    "#AB47BC", "#CE93D8", "#E040FB",
    "#8E24AA", "#AA00FF", "#D500F9",
]

FALLBACK_PALETTE = [
    "#4FC3F7", "#81C784", "#FFB74D", "#E57373",
    "#BA68C8", "#4DD0E1", "#FFD54F", "#A1887F",
    "#90A4AE", "#F06292", "#AED581", "#7986CB",
]

DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}")
WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
HASHTAG_RE = re.compile(
    r"(?<!\w)#([a-zA-Z\u3131-\u318E\uAC00-\uD7A3]"
    r"[a-zA-Z0-9\u3131-\u318E\uAC00-\uD7A3_-]*)"
)
PROPERTY_RE = re.compile(r"^(\w[\w-]*):: (.+)$")
MAX_LABEL_LEN = 25


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Build Logseq knowledge graph -> vis-network HTML",
    )
    p.add_argument(
        "--pages", type=Path, default=Path("pages"),
        help="Pages directory (default: ./pages)",
    )
    p.add_argument("--template", type=Path, help="Path to logseq.html template")
    p.add_argument(
        "--output", type=Path, default=Path("knowledge-graph.html"),
        help="Output HTML file",
    )
    p.add_argument("--include-session", action="store_true", help="Include session/ pages")
    p.add_argument("--include-date", action="store_true", help="Include date pages")
    p.add_argument("--no-orphans", action="store_true", help="Exclude orphan pages")
    p.add_argument("--namespace", help="Focus on specific namespace + direct connections")
    p.add_argument("--min-links", type=int, default=0, help="Min total connections to include")
    p.add_argument("--ns-depth", type=int, default=1,
                   help="Namespace depth for grouping (1=pj-xxx, 2=pj-xxx/task)")
    p.add_argument("--json", action="store_true", dest="json_output", help="Print JSON stats")
    return p.parse_args(argv)


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def filename_to_page(filename: str) -> str:
    """Convert Logseq filename to page name: ___ -> /"""
    stem = filename
    if stem.endswith(".md"):
        stem = stem[:-3]
    return stem.replace("___", "/")


def get_namespace(page_name: str, depth: int = 1) -> str:
    """Extract namespace up to given depth.

    depth=1: pj-xxx/task/foo -> pj-xxx
    depth=2: pj-xxx/task/foo -> pj-xxx/task
    """
    parts = page_name.split("/")
    if len(parts) <= 1:
        return "_root"
    return "/".join(parts[:depth])


def make_label(page_name: str) -> str:
    """Create display label: strip namespace prefix, truncate if long."""
    if "/" in page_name:
        name = page_name.split("/", 1)[1]
    else:
        name = page_name
    if len(name) > MAX_LABEL_LEN:
        return name[: MAX_LABEL_LEN - 1] + "\u2026"
    return name


def _parse_alias_value(value: str) -> list[str]:
    """Parse alias:: value handling mixed [[wrapped]] and plain text.

    Example: 'SC, [[스테이블 코인]], Stablecoin'
    Returns: ['SC', '스테이블 코인', 'Stablecoin']
    """
    aliases: list[str] = []
    # Extract [[wrapped]] aliases and track their positions
    wikilink_spans: list[tuple[int, int]] = []
    for m in WIKILINK_RE.finditer(value):
        aliases.append(m.group(1))
        wikilink_spans.append((m.start(), m.end()))

    # Remove wikilink spans to get remaining plain text
    remaining = value
    for start, end in reversed(wikilink_spans):
        remaining = remaining[:start] + remaining[end:]

    # Split remaining by comma and collect non-empty parts
    for part in remaining.split(","):
        part = part.strip()
        if part:
            aliases.append(part)

    return aliases


def _has_rg() -> bool:
    """Check if rg (ripgrep) is available."""
    import shutil
    return shutil.which("rg") is not None


def _rg_json(pattern: str, pages_dir: Path) -> list[dict]:
    """Run rg --json and return parsed match lines."""
    import subprocess
    result = subprocess.run(
        ["rg", "--json", "--no-heading", pattern, str(pages_dir)],
        capture_output=True, text=True, timeout=30,
    )
    matches = []
    for line in result.stdout.splitlines():
        obj = json.loads(line)
        if obj["type"] == "match":
            matches.append(obj["data"])
    return matches


def scan_pages_rg(pages_dir: Path) -> dict[str, dict]:
    """Scan pages using rg for fast bulk extraction.

    Returns dict of page_name -> {page_name, namespace, wikilinks, hashtags, aliases, properties}
    """
    pages: dict[str, dict] = {}

    # Initialize pages from filenames (no file I/O)
    for md_file in sorted(pages_dir.glob("*.md")):
        page_name = filename_to_page(md_file.name)
        pages[page_name] = {
            "page_name": page_name,
            "namespace": get_namespace(page_name),
            "wikilinks": set(),
            "hashtags": set(),
            "aliases": [],
            "properties": {},
        }

    # 1. Extract wikilinks via rg
    for m in _rg_json(r"\[\[([^\]]+)\]\]", pages_dir):
        filepath = m["path"]["text"]
        page_name = filename_to_page(Path(filepath).name)
        if page_name not in pages:
            continue
        for sub in m.get("submatches", []):
            target = sub["match"]["text"]
            # rg returns full match including [[ ]], strip them
            if target.startswith("[[") and target.endswith("]]"):
                target = target[2:-2]
            if target and target != page_name:
                pages[page_name]["wikilinks"].add(target)

    # 2. Extract hashtags via rg (include Korean Jamo+Hangul to match HASHTAG_RE)
    for m in _rg_json(r"(?:^|\s)#([a-zA-Z\u3131-\u318E\uAC00-\uD7A3][a-zA-Z0-9\u3131-\u318E\uAC00-\uD7A3_-]*)", pages_dir):
        filepath = m["path"]["text"]
        page_name = filename_to_page(Path(filepath).name)
        if page_name not in pages:
            continue
        for sub in m.get("submatches", []):
            tag = sub["match"]["text"]
            # rg returns full match; extract the tag part after #
            if "#" in tag:
                tag = tag.split("#", 1)[1]
            tag = tag.strip()
            if tag and tag != page_name:
                pages[page_name]["hashtags"].add(tag)

    # 3. Extract alias:: properties via rg
    for m in _rg_json(r"alias:: (.+)$", pages_dir):
        filepath = m["path"]["text"]
        page_name = filename_to_page(Path(filepath).name)
        if page_name not in pages:
            continue
        line_text = m["lines"]["text"].strip()
        if line_text.startswith("- "):
            line_text = line_text[2:]
        prop_match = PROPERTY_RE.match(line_text)
        if prop_match:
            value = prop_match.group(2)
            pages[page_name]["properties"]["alias"] = value
            pages[page_name]["aliases"].extend(_parse_alias_value(value))

    return pages


def parse_page(filepath: Path) -> dict | None:
    """Parse a single .md file (fallback when rg is unavailable)."""
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"warn: {filepath}: {e}", file=sys.stderr)
        return None

    page_name = filename_to_page(filepath.name)
    namespace = get_namespace(page_name)

    wikilinks: set[str] = set()
    hashtags: set[str] = set()
    aliases: list[str] = []
    properties: dict[str, str] = {}

    for line in content.splitlines():
        stripped = line.strip()
        if stripped.startswith("- "):
            stripped = stripped[2:]

        # Properties (key:: value)
        prop_match = PROPERTY_RE.match(stripped)
        if prop_match:
            key, value = prop_match.group(1), prop_match.group(2)
            properties[key] = value
            if key == "alias":
                aliases.extend(_parse_alias_value(value))

        # Wikilinks
        for m in WIKILINK_RE.finditer(stripped):
            target = m.group(1)
            if target != page_name:
                wikilinks.add(target)

        # Hashtags
        for m in HASHTAG_RE.finditer(stripped):
            tag = m.group(1)
            if tag != page_name:
                hashtags.add(tag)

    return {
        "page_name": page_name,
        "namespace": namespace,
        "wikilinks": wikilinks,
        "hashtags": hashtags,
        "aliases": aliases,
        "properties": properties,
    }


# ---------------------------------------------------------------------------
# Graph building
# ---------------------------------------------------------------------------

def assign_namespace_color(ns: str, pj_counter: list[int]) -> str:
    """Get color for a namespace.

    For multi-level namespaces (e.g. pj-xxx/decision), checks the last
    segment against known type colors first, then falls back to project
    or general palette.
    """
    if ns in NAMESPACE_COLORS:
        return NAMESPACE_COLORS[ns]
    # Multi-level: check last segment for known type (decision, troubleshoot, etc.)
    if "/" in ns:
        last = ns.rsplit("/", 1)[1]
        if last in NAMESPACE_COLORS:
            return NAMESPACE_COLORS[last]
    if ns.startswith("pj-"):
        idx = pj_counter[0] % len(PROJECT_PALETTE)
        pj_counter[0] += 1
        return PROJECT_PALETTE[idx]
    # Unknown namespace: use fallback palette
    idx = hash(ns) % len(FALLBACK_PALETTE)
    return FALLBACK_PALETTE[idx]


def _normalize(name: str) -> str:
    """Normalize for fuzzy alias matching: strip spaces, lowercase."""
    return name.replace(" ", "").lower()


def build_graph(pages_dir: Path, args: argparse.Namespace) -> dict:
    """Scan pages and build graph data."""
    if not pages_dir.exists():
        print(f"error: pages directory not found: {pages_dir}", file=sys.stderr)
        sys.exit(1)

    # Parse all pages — rg for speed, Python fallback
    if _has_rg():
        all_pages = scan_pages_rg(pages_dir)
    else:
        all_pages = {}
        for md_file in sorted(pages_dir.glob("*.md")):
            parsed = parse_page(md_file)
            if parsed is not None:
                all_pages[parsed["page_name"]] = parsed

    # Apply filters
    pages: dict[str, dict] = {}
    alias_map: dict[str, str] = {}       # exact alias -> canonical
    norm_map: dict[str, str] = {}         # normalized -> canonical (fuzzy)

    for page_name, parsed in all_pages.items():
        ns = parsed["namespace"]

        # Filter: session
        if not args.include_session and ns == "session":
            continue

        # Filter: date pages
        if not args.include_date and DATE_RE.match(page_name):
            continue

        pages[page_name] = parsed

        # Register page name in normalized map
        norm_map[_normalize(page_name)] = page_name

        # Register aliases (exact + normalized)
        for alias in parsed["aliases"]:
            alias_map[alias] = page_name
            norm_map[_normalize(alias)] = page_name

    # Merge duplicate pages: if page B's name matches page A's alias,
    # absorb B into A (redirect B -> A, merge links and aliases)
    merged: dict[str, str] = {}  # page_name -> canonical_name
    for page_name in list(pages.keys()):
        if page_name in alias_map and alias_map[page_name] != page_name:
            canonical = alias_map[page_name]
            # Prevent circular merge (A->B and B->A)
            if canonical in merged:
                continue
            if canonical in pages:
                merged[page_name] = canonical
                pages[canonical]["aliases"] = list(
                    set(pages[canonical]["aliases"])
                    | set(pages[page_name].get("aliases", []))
                    | {page_name}
                )
                pages[canonical]["wikilinks"] |= pages[page_name].get("wikilinks", set())
                pages[canonical]["hashtags"] |= pages[page_name].get("hashtags", set())
                pages[canonical]["wikilinks"].discard(canonical)
                pages[canonical]["hashtags"].discard(canonical)
                print(f"merge: '{page_name}' -> '{canonical}' (exact alias)", file=sys.stderr)

    # Remove merged pages
    for page_name in merged:
        del pages[page_name]

    # Update maps with merges
    for page_name, canonical in merged.items():
        alias_map[page_name] = canonical
        norm_map[_normalize(page_name)] = canonical

    # Resolve: exact match first, then fuzzy (normalized)
    def resolve(name: str) -> str:
        def _follow_merged(start: str) -> str:
            seen: set[str] = set()
            cur = start
            while cur in merged and cur not in seen:
                seen.add(cur)
                cur = merged[cur]
            return cur

        # Exact alias
        if name in alias_map:
            return _follow_merged(alias_map[name])
        # Fuzzy: strip spaces + lowercase
        norm = _normalize(name)
        if norm in norm_map:
            return _follow_merged(norm_map[norm])
        return name

    # Build edges
    edges: list[dict] = []
    edge_set: set[tuple[str, str]] = set()
    in_degree: dict[str, int] = defaultdict(int)
    out_degree: dict[str, int] = defaultdict(int)

    for page_name, parsed in pages.items():
        all_targets = parsed["wikilinks"] | parsed["hashtags"]
        for raw_target in all_targets:
            target = resolve(raw_target)

            # Skip date targets
            if not args.include_date and DATE_RE.match(target):
                continue

            # Skip session targets
            if not args.include_session and get_namespace(target) == "session":
                continue

            key = (page_name, target)
            if key not in edge_set and page_name != target:
                edge_set.add(key)
                edges.append({"from": page_name, "to": target, "arrows": "to"})
                out_degree[page_name] += 1
                in_degree[target] += 1

    # Collect all referenced pages (including phantoms)
    all_page_ids: set[str] = set(pages.keys())
    phantom_ids: set[str] = set()
    for e in edges:
        if e["to"] not in all_page_ids:
            phantom_ids.add(e["to"])
    all_page_ids |= phantom_ids

    # Namespace focus filter
    if args.namespace:
        focus_ns = args.namespace
        focused: set[str] = set()
        for pid in all_page_ids:
            if get_namespace(pid, args.ns_depth) == focus_ns:
                focused.add(pid)
        # Add direct connections
        connected: set[str] = set()
        for e in edges:
            if e["from"] in focused:
                connected.add(e["to"])
            if e["to"] in focused:
                connected.add(e["from"])
        keep = focused | connected
        edges = [e for e in edges if e["from"] in keep and e["to"] in keep]
        all_page_ids = keep
        # Recalculate degrees
        in_degree = defaultdict(int)
        out_degree = defaultdict(int)
        for e in edges:
            out_degree[e["from"]] += 1
            in_degree[e["to"]] += 1

    # Min-links filter
    if args.min_links > 0:
        keep = set()
        for pid in all_page_ids:
            total = in_degree.get(pid, 0) + out_degree.get(pid, 0)
            if total >= args.min_links:
                keep.add(pid)
        edges = [e for e in edges if e["from"] in keep and e["to"] in keep]
        all_page_ids = keep

    # Orphan filter
    connected_ids: set[str] = set()
    for e in edges:
        connected_ids.add(e["from"])
        connected_ids.add(e["to"])

    if args.no_orphans:
        all_page_ids = all_page_ids & connected_ids

    # Build namespace info
    pj_counter = [0]
    ns_counts: dict[str, int] = defaultdict(int)
    ns_depth = args.ns_depth
    for pid in all_page_ids:
        ns = get_namespace(pid, ns_depth)
        ns_counts[ns] += 1

    namespaces: dict[str, dict] = {}
    for ns, count in sorted(ns_counts.items()):
        namespaces[ns] = {
            "color": assign_namespace_color(ns, pj_counter),
            "count": count,
        }

    # Build nodes
    nodes: list[dict] = []
    orphan_count = 0
    for pid in sorted(all_page_ids):
        ns = get_namespace(pid, ns_depth)
        is_phantom = pid in phantom_ids
        is_orphan = pid not in connected_ids
        if is_orphan:
            orphan_count += 1

        fi = in_degree.get(pid, 0)
        fo = out_degree.get(pid, 0)

        parsed_data = pages.get(pid)
        aliases = parsed_data["aliases"] if parsed_data else []
        tooltip_parts = [pid]
        if aliases:
            tooltip_parts.append(f"Aliases: {', '.join(aliases)}")
        tooltip_parts.append(f"Links: {fo} | Linked by: {fi}")
        if is_phantom:
            tooltip_parts.append("(phantom - no page file)")

        node = {
            "id": pid,
            "label": make_label(pid),
            "group": ns,
            "title": "\n".join(tooltip_parts),
            "size": fi,
            "phantom": is_phantom,
        }
        if aliases:
            node["aliases"] = aliases
        nodes.append(node)

    # Stats
    total_pages = len([n for n in nodes if not n["phantom"]])
    total_links = len(edges)
    avg_links = round(total_links / total_pages, 1) if total_pages else 0

    most_linked_page = max(in_degree, key=in_degree.get) if in_degree else ""
    most_linking_page = max(out_degree, key=out_degree.get) if out_degree else ""

    stats = {
        "totalPages": total_pages,
        "totalLinks": total_links,
        "avgLinks": avg_links,
        "orphanPages": orphan_count,
        "phantomPages": len(phantom_ids & all_page_ids),
        "mostLinked": {
            "page": most_linked_page,
            "count": in_degree.get(most_linked_page, 0),
        },
        "mostLinking": {
            "page": most_linking_page,
            "count": out_degree.get(most_linking_page, 0),
        },
    }

    return {
        "nodes": nodes,
        "edges": edges,
        "namespaces": namespaces,
        "stats": stats,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    pages_dir = args.pages.resolve()
    tpl_path = find_template("logseq.html", args.template)
    out_path = args.output

    graph_data = build_graph(pages_dir, args)

    # --json: output full GRAPH_DATA to stdout (no HTML rendering)
    if args.json_output:
        json.dump(graph_data, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return

    inject_template(graph_data, tpl_path, out_path)

    # Report
    s = graph_data["stats"]
    print(f"Pages: {s['totalPages']}")
    print(f"Links: {s['totalLinks']}")
    print(f"Avg links: {s['avgLinks']}")
    print(f"Orphans: {s['orphanPages']}")
    print(f"Phantoms: {s['phantomPages']}")
    ml = s["mostLinked"]
    mk = s["mostLinking"]
    print(f"Most linked: {ml['page']} ({ml['count']})")
    print(f"Most linking: {mk['page']} ({mk['count']})")
    print(f"Namespaces: {list(graph_data['namespaces'].keys())}")
    print(f"Output: {out_path}")


if __name__ == "__main__":
    main()
