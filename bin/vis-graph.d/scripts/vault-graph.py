#!/usr/bin/env python3
"""Build an Obsidian vault knowledge graph and generate a vis-network HTML report.

Recursively scans an Obsidian vault: parses [[wikilinks]] (with #heading / |alias
/ path forms), #tags, and YAML frontmatter aliases to visualize note
interconnections. Namespaces derive from the containing folder. Uses only the
Python standard library (3.10+).
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
    "issue":        "#FF5722",
    "incident":     "#D32F2F",
    "know":         "#3F51B5",
    "journals":     "#9E9E9E",
    "session":      "#9E9E9E",
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
    r"(?<!\w)#([a-zA-Zㄱ-ㆎ가-힣]"
    r"[a-zA-Z0-9ㄱ-ㆎ가-힣_/-]*)"
)
MAX_LABEL_LEN = 25

# .session은 --include-session 으로 별도 제어. 그 외 dot-dir + 아래 폴더는 스캔 제외.
EXCLUDE_DIRS = {"templates", "node_modules"}

DEFAULT_VAULT = Path.home() / "Documents" / "obsidian"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Build Obsidian vault knowledge graph -> vis-network HTML",
    )
    p.add_argument(
        "--vault", type=Path, default=DEFAULT_VAULT,
        help=f"Obsidian vault root (default: {DEFAULT_VAULT})",
    )
    p.add_argument("--template", type=Path, help="Path to vault.html template")
    p.add_argument(
        "--output", type=Path, default=Path("knowledge-graph.html"),
        help="Output HTML file",
    )
    p.add_argument("--include-session", action="store_true", help="Include .session/ pages")
    p.add_argument("--include-date", action="store_true", help="Include date (journal) pages")
    p.add_argument("--no-orphans", action="store_true", help="Exclude orphan pages")
    p.add_argument("--namespace", help="Focus on specific namespace + direct connections")
    p.add_argument("--min-links", type=int, default=0, help="Min total connections to include")
    p.add_argument("--json", action="store_true", dest="json_output", help="Print JSON stats")
    return p.parse_args(argv)


# ---------------------------------------------------------------------------
# Obsidian parsing
# ---------------------------------------------------------------------------

def note_namespace(rel: Path) -> str:
    """폴더 기반 네임스페이스 = 바로 위 디렉토리명. vault 루트 파일은 _root."""
    parts = rel.parts
    return parts[-2] if len(parts) >= 2 else "_root"


def clean_target(raw: str) -> str:
    """[[folder/Note#Heading|Display]] → Note (Obsidian는 basename으로 링크 해소)."""
    t = raw.strip()
    if "|" in t:
        t = t.split("|", 1)[0]
    t = re.split(r"[#^]", t, 1)[0].strip()
    if "/" in t:
        t = t.rsplit("/", 1)[1]
    return t


def parse_frontmatter_aliases(text: str) -> list[str]:
    """YAML frontmatter의 aliases/alias 파싱 (inline [a,b] / 블록 - a / 스칼라)."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return []
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() in ("---", "..."):
            end = i
            break
    if end is None:
        return []

    fm = lines[1:end]
    aliases: list[str] = []
    i = 0
    while i < len(fm):
        m = re.match(r"^\s*(aliases|alias)\s*:\s*(.*)$", fm[i])
        if m:
            val = m.group(2).strip()
            if val.startswith("[") and val.endswith("]"):
                inner = val[1:-1]
                aliases += [a.strip().strip("\"'") for a in inner.split(",") if a.strip()]
            elif val:
                aliases.append(val.strip("\"'"))
            else:
                j = i + 1
                while j < len(fm) and re.match(r"^\s*-\s+", fm[j]):
                    item = re.sub(r"^\s*-\s+", "", fm[j]).strip().strip("\"'")
                    if item:
                        aliases.append(item)
                    j += 1
                i = j - 1
        i += 1
    return aliases


def _excluded(parts: tuple[str, ...], include_session: bool) -> bool:
    """디렉토리 세그먼트 기준 제외. .session은 옵션으로 제어, 그 외 dot-dir/제외폴더 skip."""
    for p in parts[:-1]:
        if p == ".session":
            if include_session:
                continue
            return True
        if p.startswith(".") or p in EXCLUDE_DIRS:
            return True
    return False


def scan_vault(vault: Path, include_session: bool) -> dict[str, dict]:
    """vault를 재귀 스캔. page_name = 파일 basename(확장자 제외) — Obsidian 링크 해소 단위."""
    pages: dict[str, dict] = {}
    for md in sorted(vault.rglob("*.md")):
        rel = md.relative_to(vault)
        if _excluded(rel.parts, include_session):
            continue
        name = md.stem
        if name in pages:
            print(f"warn: 중복 basename '{name}' — 첫 항목 유지 ({rel})", file=sys.stderr)
            continue
        try:
            text = md.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as e:
            print(f"warn: {rel}: {e}", file=sys.stderr)
            continue

        wikilinks = {clean_target(t) for t in WIKILINK_RE.findall(text)}
        hashtags = {t.rsplit("/", 1)[-1] for t in HASHTAG_RE.findall(text)}
        wikilinks.discard(name)
        wikilinks.discard("")
        hashtags.discard(name)
        pages[name] = {
            "page_name": name,
            "namespace": note_namespace(rel),
            "wikilinks": wikilinks,
            "hashtags": hashtags,
            "aliases": parse_frontmatter_aliases(text),
            "properties": {},
        }
    return pages


# ---------------------------------------------------------------------------
# Graph building
# ---------------------------------------------------------------------------

def make_label(page_name: str) -> str:
    if len(page_name) > MAX_LABEL_LEN:
        return page_name[: MAX_LABEL_LEN - 1] + "…"
    return page_name


def assign_namespace_color(ns: str, pj_counter: list[int]) -> str:
    if ns in NAMESPACE_COLORS:
        return NAMESPACE_COLORS[ns]
    if ns.startswith("pj-") or ns.startswith("pj_"):
        idx = pj_counter[0] % len(PROJECT_PALETTE)
        pj_counter[0] += 1
        return PROJECT_PALETTE[idx]
    return FALLBACK_PALETTE[hash(ns) % len(FALLBACK_PALETTE)]


def _normalize(name: str) -> str:
    return name.replace(" ", "").lower()


def build_graph(pages: dict[str, dict], args: argparse.Namespace) -> dict:
    """스캔된 pages dict로 그래프 데이터를 만든다."""
    def ns_of(pid: str) -> str:
        p = pages.get(pid)
        return p["namespace"] if p else "_root"

    # Filters (date/journal pages)
    filtered: dict[str, dict] = {}
    alias_map: dict[str, str] = {}
    norm_map: dict[str, str] = {}
    for page_name, parsed in pages.items():
        if not args.include_date and DATE_RE.match(page_name):
            continue
        filtered[page_name] = parsed
        norm_map[_normalize(page_name)] = page_name
        for alias in parsed["aliases"]:
            alias_map[alias] = page_name
            norm_map[_normalize(alias)] = page_name
    pages = filtered

    # Merge duplicate pages via exact-alias match
    merged: dict[str, str] = {}
    for page_name in list(pages.keys()):
        if page_name in alias_map and alias_map[page_name] != page_name:
            canonical = alias_map[page_name]
            if canonical in merged or canonical not in pages:
                continue
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
    for page_name in merged:
        del pages[page_name]
    for page_name, canonical in merged.items():
        alias_map[page_name] = canonical
        norm_map[_normalize(page_name)] = canonical

    def resolve(name: str) -> str:
        def _follow(start: str) -> str:
            seen: set[str] = set()
            cur = start
            while cur in merged and cur not in seen:
                seen.add(cur)
                cur = merged[cur]
            return cur
        if name in alias_map:
            return _follow(alias_map[name])
        norm = _normalize(name)
        if norm in norm_map:
            return _follow(norm_map[norm])
        return name

    # Build edges
    edges: list[dict] = []
    edge_set: set[tuple[str, str]] = set()
    in_degree: dict[str, int] = defaultdict(int)
    out_degree: dict[str, int] = defaultdict(int)
    for page_name, parsed in pages.items():
        for raw_target in parsed["wikilinks"] | parsed["hashtags"]:
            target = resolve(raw_target)
            if not args.include_date and DATE_RE.match(target):
                continue
            key = (page_name, target)
            if key not in edge_set and page_name != target:
                edge_set.add(key)
                edges.append({"from": page_name, "to": target, "arrows": "to"})
                out_degree[page_name] += 1
                in_degree[target] += 1

    # Collect referenced pages (incl. phantoms)
    all_page_ids: set[str] = set(pages.keys())
    phantom_ids: set[str] = {e["to"] for e in edges if e["to"] not in all_page_ids}
    all_page_ids |= phantom_ids

    # Namespace focus
    if args.namespace:
        focused = {pid for pid in all_page_ids if ns_of(pid) == args.namespace}
        connected: set[str] = set()
        for e in edges:
            if e["from"] in focused:
                connected.add(e["to"])
            if e["to"] in focused:
                connected.add(e["from"])
        keep = focused | connected
        edges = [e for e in edges if e["from"] in keep and e["to"] in keep]
        all_page_ids = keep
        in_degree = defaultdict(int)
        out_degree = defaultdict(int)
        for e in edges:
            out_degree[e["from"]] += 1
            in_degree[e["to"]] += 1

    # Min-links
    if args.min_links > 0:
        keep = {pid for pid in all_page_ids
                if in_degree.get(pid, 0) + out_degree.get(pid, 0) >= args.min_links}
        edges = [e for e in edges if e["from"] in keep and e["to"] in keep]
        all_page_ids = keep

    # Orphans
    connected_ids: set[str] = set()
    for e in edges:
        connected_ids.add(e["from"])
        connected_ids.add(e["to"])
    if args.no_orphans:
        all_page_ids &= connected_ids

    # Namespaces
    pj_counter = [0]
    ns_counts: dict[str, int] = defaultdict(int)
    for pid in all_page_ids:
        ns_counts[ns_of(pid)] += 1
    namespaces: dict[str, dict] = {}
    for ns, count in sorted(ns_counts.items()):
        namespaces[ns] = {"color": assign_namespace_color(ns, pj_counter), "count": count}

    # Nodes
    nodes: list[dict] = []
    orphan_count = 0
    for pid in sorted(all_page_ids):
        ns = ns_of(pid)
        is_phantom = pid in phantom_ids
        is_orphan = pid not in connected_ids
        if is_orphan:
            orphan_count += 1
        fi = in_degree.get(pid, 0)
        fo = out_degree.get(pid, 0)
        parsed_data = pages.get(pid)
        aliases = parsed_data["aliases"] if parsed_data else []
        tooltip = [pid]
        if aliases:
            tooltip.append(f"Aliases: {', '.join(aliases)}")
        tooltip.append(f"Links: {fo} | Linked by: {fi}")
        if is_phantom:
            tooltip.append("(phantom - no page file)")
        node = {
            "id": pid,
            "label": make_label(pid),
            "group": ns,
            "title": "\n".join(tooltip),
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
    most_linked = max(in_degree, key=in_degree.get) if in_degree else ""
    most_linking = max(out_degree, key=out_degree.get) if out_degree else ""
    stats = {
        "totalPages": total_pages,
        "totalLinks": total_links,
        "avgLinks": avg_links,
        "orphanPages": orphan_count,
        "phantomPages": len(phantom_ids & all_page_ids),
        "mostLinked": {"page": most_linked, "count": in_degree.get(most_linked, 0)},
        "mostLinking": {"page": most_linking, "count": out_degree.get(most_linking, 0)},
    }
    return {"nodes": nodes, "edges": edges, "namespaces": namespaces, "stats": stats}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    vault = args.vault.resolve()
    if not vault.exists():
        print(f"error: vault not found: {vault}", file=sys.stderr)
        sys.exit(1)

    pages = scan_vault(vault, args.include_session)
    graph_data = build_graph(pages, args)

    if args.json_output:
        json.dump(graph_data, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return

    tpl_path = find_template("vault.html", args.template)
    inject_template(graph_data, tpl_path, args.output)

    s = graph_data["stats"]
    print(f"Pages: {s['totalPages']}")
    print(f"Links: {s['totalLinks']}")
    print(f"Avg links: {s['avgLinks']}")
    print(f"Orphans: {s['orphanPages']}")
    print(f"Phantoms: {s['phantomPages']}")
    print(f"Most linked: {s['mostLinked']['page']} ({s['mostLinked']['count']})")
    print(f"Most linking: {s['mostLinking']['page']} ({s['mostLinking']['count']})")
    print(f"Namespaces: {list(graph_data['namespaces'].keys())}")
    print(f"Output: {args.output}")


if __name__ == "__main__":
    main()
