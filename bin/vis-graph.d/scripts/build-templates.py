#!/usr/bin/env python3
"""Build flattened HTML templates by resolving all {% include %} directives.

Usage:
    python3 build-templates.py [--src <dir>] [--dist <dir>]

Defaults:
    --src  ../templates/       (source templates with partials)
    --dist ../templates/dist/  (output self-contained HTML files)
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

_INCLUDE_RE = re.compile(r"\{%\s*include\s+(\S+)((?:\s+\w+=\"[^\"]*\")*)\s*%\}")
_PARAM_RE = re.compile(r'(\w+)="([^"]*)"')


def resolve_includes(content: str, template_dir: Path) -> str:
    """Resolve {% include path key="val" ... %} directives recursively (max 5 levels)."""

    def replacer(m: re.Match) -> str:
        rel_path = m.group(1)
        params_str = m.group(2) or ""
        params = dict(_PARAM_RE.findall(params_str))

        include_path = template_dir / rel_path
        if not include_path.exists():
            print(f"warn: include not found: {include_path}", file=sys.stderr)
            return f"/* include not found: {rel_path} */"
        text = include_path.read_text(encoding="utf-8")
        for key, val in params.items():
            text = text.replace("{{" + key + "}}", val)
        return text

    for _ in range(5):
        new_content = _INCLUDE_RE.sub(replacer, content)
        if new_content == content:
            break
        content = new_content
    return content


def build(src_dir: Path, dist_dir: Path) -> None:
    """Build all top-level .html files in src_dir into dist_dir."""
    dist_dir.mkdir(parents=True, exist_ok=True)

    templates = sorted(src_dir.glob("*.html"))
    if not templates:
        print(f"error: no .html files in {src_dir}", file=sys.stderr)
        sys.exit(1)

    for tpl_path in templates:
        content = tpl_path.read_text(encoding="utf-8")
        resolved = resolve_includes(content, tpl_path.parent)

        out_path = dist_dir / tpl_path.name
        out_path.write_text(resolved, encoding="utf-8")
        print(f"  {tpl_path.name} -> dist/{tpl_path.name}")

    print(f"Built {len(templates)} template(s) in {dist_dir}")


def main(args: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Build flattened vis-graph templates")
    script_dir = Path(__file__).resolve().parent
    default_src = script_dir.parent / "templates" / "src"
    default_dist = script_dir.parent / "templates" / "dist"

    parser.add_argument("--src", type=Path, default=default_src, help="Source templates directory")
    parser.add_argument("--dist", type=Path, default=default_dist, help="Output directory")
    opts = parser.parse_args(args)

    print(f"Building templates: {opts.src} -> {opts.dist}")
    build(opts.src, opts.dist)


if __name__ == "__main__":
    main()
