"""Common utilities for vis-graph scripts.

Shared by build-graph.py, extract-schema.py, and logseq-graph.py.
Uses only the Python standard library (3.10+).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

_INCLUDE_RE = re.compile(r"\{%\s*include\s+(\S+)((?:\s+\w+=\"[^\"]*\")*)\s*%\}")
_PARAM_RE = re.compile(r'(\w+)="([^"]*)"')


def find_template(template_name: str, args_template: Path | None) -> Path:
    """Find template file with fallback chain.

    Search order:
    1. Explicit --template argument
    2. Same directory as the calling script / template_name
    3. Skill templates/ directory (../templates/template_name from script)
    """
    if args_template:
        p = args_template.resolve()
        if p.exists():
            return p
        print(f"error: template not found: {p}", file=sys.stderr)
        sys.exit(1)

    import inspect
    caller_file = inspect.stack()[1].filename
    script_dir = Path(caller_file).resolve().parent

    for candidate in [
        script_dir / template_name,
        script_dir.parent / "templates" / "dist" / template_name,
        script_dir.parent / "templates" / template_name,
    ]:
        if candidate.exists():
            return candidate

    print(
        f"error: template '{template_name}' not found. Use --template to specify.",
        file=sys.stderr,
    )
    sys.exit(1)


def _resolve_includes(content: str, template_dir: Path) -> str:
    """Resolve {% include path key="val" ... %} directives.

    Supports parameterized includes:
      {% include partials/filter-section.html title="Namespaces" id="ns-filters" %}
    Parameters replace {{key}} placeholders in the included file.
    """
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

    # Resolve iteratively (included files may contain includes)
    for _ in range(5):
        new_content = _INCLUDE_RE.sub(replacer, content)
        if new_content == content:
            break
        content = new_content
    return content


def inject_template(
    graph_data: dict, template_path: Path, output_path: Path,
) -> None:
    """Read HTML template, inject GRAPH_DATA JSON, write output.

    Expects a pre-built (flattened) template from templates/dist/.
    Falls back to resolving includes if the template still contains them.
    """
    tpl = template_path.read_text(encoding="utf-8")

    # Fallback: resolve includes if template is not pre-built
    if _INCLUDE_RE.search(tpl):
        tpl = _resolve_includes(tpl, template_path.parent)

    js = json.dumps(graph_data, ensure_ascii=False)
    js = js.replace("<", "\\u003c").replace(">", "\\u003e")
    html = tpl.replace("{{GRAPH_DATA}}", js)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html, encoding="utf-8")
