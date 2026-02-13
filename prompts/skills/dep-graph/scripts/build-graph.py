#!/usr/bin/env python3
"""Build file-level dependency graph and generate vis-network HTML report.

Supports Java, TypeScript/JavaScript, and Python.
Uses only the Python standard library (3.10+).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from fnmatch import fnmatch
from pathlib import Path

PALETTE = [
    "#4FC3F7", "#81C784", "#FFB74D", "#E57373",
    "#BA68C8", "#4DD0E1", "#FFD54F", "#A1887F",
    "#90A4AE", "#F06292", "#AED581", "#7986CB",
]

DEFAULT_EXCLUDE_DIRS = {
    "node_modules", ".next", "build", "dist", ".git",
    "__tests__", "test", "target", "__pycache__",
    ".tox", "venv", ".venv", "env",
}

EXCLUDE_FILE_RES = [
    re.compile(r"\.test\."),
    re.compile(r"\.spec\."),
    re.compile(r"\.d\.ts$"),
]


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Build file-level dependency graph → vis-network HTML",
    )
    p.add_argument("--root", required=True, type=Path, help="Project root directory")
    p.add_argument("--scope", default=".", help="Sub-directory to analyze (relative to root)")
    p.add_argument("--depth", type=int, default=0, help="Max import trace depth (0 = unlimited)")
    p.add_argument("--exclude", action="append", default=[], help="Additional exclude glob (repeatable)")
    p.add_argument("--template", type=Path, help="Path to report.html template")
    p.add_argument("--output", type=Path, default=Path("dep-graph.html"), help="Output HTML file")
    p.add_argument("--json", action="store_true", dest="json_output", help="Print JSON stats to stdout")
    p.add_argument("--group-by", choices=["dir", "role"], default="role", dest="group_by",
                   help="Color nodes by directory or role (default: role)")
    return p.parse_args()


# ---------------------------------------------------------------------------
# Filtering
# ---------------------------------------------------------------------------

def _in_excluded_dir(rel_parts: tuple[str, ...]) -> bool:
    return any(d in rel_parts for d in DEFAULT_EXCLUDE_DIRS)


def should_exclude(path: Path, root: Path, extra_excludes: list[str]) -> bool:
    rel = path.relative_to(root)
    parts = rel.parts
    if _in_excluded_dir(parts):
        return True
    name = path.name
    if name == "package-info.java":
        return True
    for pat in EXCLUDE_FILE_RES:
        if pat.search(name):
            return True
    rel_str = str(rel)
    for pattern in extra_excludes:
        if fnmatch(rel_str, pattern):
            return True
    return False


def _dir_excluded(dirpath: Path, root: Path) -> bool:
    return _in_excluded_dir(dirpath.relative_to(root).parts)


# ---------------------------------------------------------------------------
# Source root discovery
# ---------------------------------------------------------------------------

def find_java_roots(scope: Path, root: Path) -> list[Path]:
    """Auto-discover Java source roots (**/src/main/java)."""
    roots = []
    for d in scope.rglob("src/main/java"):
        if d.is_dir() and not _dir_excluded(d, root):
            roots.append(d)
    return sorted(roots)


def find_ts_roots(scope: Path, root: Path) -> list[Path]:
    """Auto-discover TS/JS project roots via tsconfig.json (leaf nodes only)."""
    candidates = []
    for tc in scope.rglob("tsconfig.json"):
        if _dir_excluded(tc.parent, root):
            continue
        candidates.append(tc.parent)
    if len(candidates) <= 1:
        return sorted(candidates)
    # Keep leaf nodes only (remove parents whose children are also candidates)
    leaves = [
        c for c in candidates
        if not any(o != c and str(o).startswith(str(c) + "/") for o in candidates)
    ]
    return sorted(leaves) if leaves else sorted(candidates)


def find_internal_packages(java_roots: list[Path]) -> set[str]:
    """Collect top-level package prefixes (depth-3) from Java source roots."""
    prefixes: set[str] = set()
    for jr in java_roots:
        if not jr.exists():
            continue
        for jf in jr.rglob("*.java"):
            rel = jf.relative_to(jr)
            parts = rel.parts[:-1]  # exclude filename
            if len(parts) >= 2:
                prefixes.add(".".join(parts[:3]))
    return prefixes


def build_source_roots_map(
    java_roots: list[Path],
    ts_roots: list[Path],
    root: Path,
) -> dict[str, str]:
    """Map long source-root prefix → short prefix for shorten_id.

    Example: {"backend/src/main/java/": "backend/"}
    """
    mapping: dict[str, str] = {}
    for jr in java_roots:
        rel = str(jr.relative_to(root))
        parts = Path(rel).parts
        try:
            src_idx = parts.index("src")
            parent_name = parts[src_idx - 1] if src_idx > 0 else parts[0]
        except ValueError:
            parent_name = parts[-1]
        mapping[rel + "/"] = parent_name + "/"
    for tr in ts_roots:
        rel = str(tr.relative_to(root))
        mapping[rel + "/"] = tr.name + "/"
    return mapping


# ---------------------------------------------------------------------------
# File collection
# ---------------------------------------------------------------------------

def collect_java_files(
    java_roots: list[Path], root: Path, excludes: list[str],
) -> list[tuple[Path, str]]:
    files = []
    for jr in java_roots:
        if not jr.exists():
            continue
        for f in jr.rglob("*.java"):
            if not should_exclude(f, root, excludes):
                files.append((f, str(f.relative_to(root))))
    return files


def collect_ts_files(
    ts_roots: list[Path], root: Path, excludes: list[str],
) -> list[tuple[Path, str]]:
    files = []
    seen: set[str] = set()
    for tr in ts_roots:
        if not tr.exists():
            continue
        for ext in ("*.ts", "*.tsx", "*.js", "*.jsx", "*.mjs", "*.mts"):
            for f in tr.rglob(ext):
                if should_exclude(f, root, excludes):
                    continue
                rel = str(f.relative_to(root))
                if rel not in seen:
                    seen.add(rel)
                    files.append((f, rel))
    return files


def collect_python_files(
    scope: Path, root: Path, excludes: list[str],
) -> list[tuple[Path, str]]:
    files = []
    for f in scope.rglob("*.py"):
        if not should_exclude(f, root, excludes):
            files.append((f, str(f.relative_to(root))))
    return files


# ---------------------------------------------------------------------------
# Import extraction
# ---------------------------------------------------------------------------

def extract_java_imports(filepath: Path) -> list[str]:
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"warn: {filepath}: {e}", file=sys.stderr)
        return []
    imports = []
    for line in content.splitlines():
        line = line.strip()
        if line.startswith("import ") and line.endswith(";"):
            imp = line[7:-1].strip()
            if imp.startswith("static "):
                imp = imp[7:].strip()
            imports.append(imp)
    return imports


_TS_IMPORT_RES = [
    re.compile(r'''from\s+['"]([^'"]+)['"]'''),
    re.compile(r'''import\s+['"]([^'"]+)['"]'''),
    re.compile(r'''require\(\s*['"]([^'"]+)['"]\s*\)'''),
]


def extract_ts_imports(filepath: Path) -> list[str]:
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"warn: {filepath}: {e}", file=sys.stderr)
        return []
    imports = []
    for pat in _TS_IMPORT_RES:
        for m in pat.finditer(content):
            imports.append(m.group(1))
    return imports


_PY_FROM_RE = re.compile(r"^from\s+([\w.]+)\s+import", re.MULTILINE)
_PY_IMPORT_RE = re.compile(r"^import\s+([\w.]+)", re.MULTILINE)


def extract_python_imports(filepath: Path) -> list[str]:
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"warn: {filepath}: {e}", file=sys.stderr)
        return []
    return [m.group(1) for m in _PY_FROM_RE.finditer(content)] + \
           [m.group(1) for m in _PY_IMPORT_RE.finditer(content)]


# ---------------------------------------------------------------------------
# Import resolution
# ---------------------------------------------------------------------------

def resolve_java_import(
    imp: str,
    java_roots: list[Path],
    known_files: dict[str, str],
    root: Path,
) -> str | None:
    if imp.endswith(".*"):
        return None
    path_part = imp.replace(".", "/") + ".java"
    for jr in java_roots:
        if not jr.exists():
            continue
        candidate = jr / path_part
        if candidate.exists():
            rel = str(candidate.relative_to(root))
            if rel in known_files:
                return rel
    return None


def _strip_jsonc(text: str) -> str:
    """Remove // and /* */ comments from JSONC, respecting string literals."""
    out: list[str] = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == '"':
            out.append(c)
            i += 1
            while i < n:
                ch = text[i]
                out.append(ch)
                if ch == '\\' and i + 1 < n:
                    i += 1
                    out.append(text[i])
                elif ch == '"':
                    break
                i += 1
        elif c == '/' and i + 1 < n:
            if text[i + 1] == '/':
                i += 2
                while i < n and text[i] != '\n':
                    i += 1
                continue
            elif text[i + 1] == '*':
                i += 2
                while i < n - 1 and not (text[i] == '*' and text[i + 1] == '/'):
                    i += 1
                i += 2
                continue
            else:
                out.append(c)
        else:
            out.append(c)
        i += 1
    result = ''.join(out)
    # Remove trailing commas (common in JSONC)
    result = re.sub(r',\s*([\]}])', r'\1', result)
    return result


def read_tsconfig_paths(tsconfig_dir: Path) -> dict[str, str]:
    """Read compilerOptions.paths from tsconfig.json (JSONC-tolerant)."""
    tsconfig_file = tsconfig_dir / "tsconfig.json"
    if not tsconfig_file.exists():
        return {}
    try:
        text = tsconfig_file.read_text(encoding="utf-8")
        text = _strip_jsonc(text)
        data = json.loads(text)
        raw = data.get("compilerOptions", {}).get("paths", {})
        result: dict[str, str] = {}
        for alias, targets in raw.items():
            if targets and isinstance(targets, list):
                result[alias.replace("*", "")] = targets[0].replace("*", "").lstrip("./")
        return result
    except Exception as e:
        print(f"warn: {tsconfig_file}: {e}", file=sys.stderr)
        return {}


def resolve_ts_import(
    imp: str,
    source_file: Path,
    known_files: dict[str, str],
    ts_root: Path,
    tsconfig_paths: dict[str, str],
    root: Path,
) -> str | None:
    resolved = imp
    base_dir = source_file.parent

    for alias_prefix, target_prefix in tsconfig_paths.items():
        if imp.startswith(alias_prefix):
            remainder = imp[len(alias_prefix):]
            resolved = "./" + target_prefix + remainder
            base_dir = ts_root
            break
    else:
        if not imp.startswith("."):
            return None  # external

    extensions = [".ts", ".tsx", ".js", ".jsx", "/index.ts", "/index.tsx", "/index.js"]
    for ext in [""] + extensions:
        candidate = (base_dir / (resolved + ext)).resolve()
        if candidate.exists() and candidate.is_file():
            try:
                rel = str(candidate.relative_to(root))
                if rel in known_files:
                    return rel
            except ValueError:
                pass
    return None


def find_python_packages(scope: Path, root: Path) -> set[str]:
    """Find top-level Python packages (dirs with __init__.py)."""
    pkgs: set[str] = set()
    for init in scope.rglob("__init__.py"):
        if _dir_excluded(init.parent, root):
            continue
        rel = init.parent.relative_to(root)
        if rel.parts:
            pkgs.add(rel.parts[0])
    return pkgs


def resolve_python_import(
    imp: str,
    source_file: Path,
    known_files: dict[str, str],
    root: Path,
    python_packages: set[str],
) -> str | None:
    if imp.startswith("."):
        dots = len(imp) - len(imp.lstrip("."))
        remainder = imp[dots:]
        base = source_file.parent
        for _ in range(dots - 1):
            base = base.parent
        if remainder:
            parts = remainder.split(".")
            module = base / "/".join(parts)
            for suffix in (".py", "/__init__.py"):
                c = Path(str(module) + suffix)
                if c.exists():
                    rel = str(c.relative_to(root))
                    if rel in known_files:
                        return rel
        return None

    top = imp.split(".")[0]
    if top not in python_packages:
        return None

    parts = imp.split(".")
    for i in range(len(parts), 0, -1):
        partial = "/".join(parts[:i])
        for suffix in (".py", "/__init__.py"):
            c = root / (partial + suffix)
            if c.exists():
                rel = str(c.relative_to(root))
                if rel in known_files:
                    return rel
    return None


# ---------------------------------------------------------------------------
# ID / group helpers
# ---------------------------------------------------------------------------

def shorten_id(full_rel_path: str, source_roots_map: dict[str, str]) -> str:
    """Strip source-root prefix → short ID.

    Longest-match-first so nested roots work correctly.
    """
    for prefix, short in sorted(source_roots_map.items(), key=lambda x: -len(x[0])):
        if full_rel_path.startswith(prefix):
            return short + full_rel_path[len(prefix):]
    return full_rel_path


def get_group(short_id: str) -> str:
    """First directory segment of short ID."""
    parts = short_id.split("/")
    return parts[0] if len(parts) > 1 else "root"


# ---------------------------------------------------------------------------
# Role classification
# ---------------------------------------------------------------------------

ROLE_COLORS: dict[str, str] = {
    # Data Layer (Cool — blue tones)
    "entity":     "#1565C0",   # Deep Blue
    "model":      "#1E88E5",   # Blue
    "dto":        "#26C6DA",   # Cyan
    # Logic Layer (Warm — green tones)
    "service":    "#2E7D32",   # Green
    "handler":    "#43A047",   # Light Green
    # Interface (Hot — purple tones)
    "controller": "#7B1FA2",   # Purple
    "page":       "#8E24AA",   # Violet
    "api":        "#AB47BC",   # Light Purple
    # Infrastructure (Neutral — orange/brown)
    "repository": "#E65100",   # Orange
    "client":     "#FF8F00",   # Amber
    "config":     "#5D4037",   # Brown
    # Cross-cutting
    "exception":  "#C62828",   # Red
    "util":       "#546E7A",   # Grey
    "hook":       "#00695C",   # Teal
    "component":  "#00838F",   # Cyan
    "store":      "#006064",   # Deep Cyan
    "type":       "#455A64",   # Blue Grey
    "other":      "#90A4AE",   # Light Grey
}


def classify_role(short_id: str) -> str:
    """Classify a file into a role based on name and path patterns."""
    name = short_id.split("/")[-1]          # e.g. "WalletService.java"
    stem = name.rsplit(".", 1)[0]            # e.g. "WalletService"
    ext = "." + name.rsplit(".", 1)[-1] if "." in name else ""
    path_lower = short_id.lower()
    parts_lower = path_lower.split("/")

    # --- Java ---
    if ext == ".java":
        # Name suffix (most reliable)
        if stem.endswith(("Controller", "RestController")):
            return "controller"
        if stem.endswith(("ServiceImpl", "Service")):
            return "service"
        if stem.endswith(("Repository", "Mapper", "Dao")):
            return "repository"
        if stem.endswith("Entity"):
            return "entity"
        if stem.endswith(("Dto", "DTO", "Request", "Response", "Payload")):
            return "dto"
        if stem.endswith(("Config", "Configuration", "Properties")):
            return "config"
        if stem.endswith(("Exception", "Error")):
            return "exception"
        if stem.endswith(("Util", "Utils", "Helper", "Constants")):
            return "util"
        if stem.endswith("Client"):
            return "client"
        if stem.endswith("Model"):
            return "model"
        if stem.endswith(("Interceptor", "Filter", "Handler", "Advice", "Listener")):
            return "handler"
        # Package path fallback
        for seg in parts_lower[:-1]:
            if seg in ("controller", "api", "web", "rest"):
                return "controller"
            if seg in ("service", "usecase"):
                return "service"
            if seg in ("repository", "dao", "mapper"):
                return "repository"
            if seg in ("entity", "domain"):
                return "entity"
            if seg in ("dto", "request", "response", "payload"):
                return "dto"
            if seg in ("config", "configuration"):
                return "config"
            if seg in ("exception", "error"):
                return "exception"
            if seg in ("util", "utils", "common", "helper"):
                return "util"
            if seg in ("client",):
                return "client"
            if seg in ("model",):
                return "model"
            if seg in ("interceptor", "filter", "handler", "advice"):
                return "handler"
        return "other"

    # --- TypeScript / JavaScript ---
    if ext in (".ts", ".tsx", ".js", ".jsx", ".mjs", ".mts"):
        if name in ("page.tsx", "page.ts", "layout.tsx", "layout.ts",
                     "loading.tsx", "error.tsx", "not-found.tsx",
                     "page.jsx", "layout.jsx"):
            return "page"
        if stem.startswith("use") and len(stem) > 3 and stem[3:4].isupper():
            return "hook"
        if name.endswith((".config.ts", ".config.js", ".config.mjs",
                          ".config.mts", ".config.tsx")):
            return "config"
        for seg in parts_lower[:-1]:
            if seg in ("hooks",):
                return "hook"
            if seg in ("components", "ui"):
                return "component"
            if seg in ("store", "stores", "context"):
                return "store"
            if seg in ("types",):
                return "type"
            if seg in ("utils", "lib", "helpers"):
                return "util"
            if seg in ("api", "services"):
                return "api"
        if ext == ".tsx":
            return "component"
        return "other"

    # --- Python ---
    if ext == ".py":
        if stem in ("models", "model") or stem.endswith(("_model", "_models")):
            return "model"
        if stem in ("views", "routes") or stem.endswith(("_view", "_views", "_router")):
            return "controller"
        if stem in ("services", "service") or stem.endswith(("_service",)):
            return "service"
        if stem in ("schemas", "serializers") or stem.endswith(("_schema", "_dto")):
            return "dto"
        if stem in ("config", "settings", "conf"):
            return "config"
        if stem in ("utils", "helpers") or stem.endswith(("_utils", "_helpers")):
            return "util"
        return "other"

    return "other"


# ---------------------------------------------------------------------------
# Cycle detection (iterative DFS)
# ---------------------------------------------------------------------------

def detect_cycles(edges: list[dict]) -> list[list[str]]:
    adj: dict[str, list[str]] = defaultdict(list)
    for e in edges:
        adj[e["from"]].append(e["to"])

    cycles: list[list[str]] = []
    visited: set[str] = set()

    for start in list(adj.keys()):
        if start in visited:
            continue
        stack: list[tuple[str, int]] = [(start, 0)]
        path: list[str] = []
        path_set: set[str] = set()

        while stack:
            node, idx = stack[-1]

            if idx == 0:
                if node in visited and node not in path_set:
                    stack.pop()
                    continue
                visited.add(node)
                path.append(node)
                path_set.add(node)

            neighbors = adj.get(node, [])
            if idx < len(neighbors):
                stack[-1] = (node, idx + 1)
                neighbor = neighbors[idx]
                if neighbor in path_set:
                    ci = path.index(neighbor)
                    cycles.append(path[ci:] + [neighbor])
                elif neighbor not in visited:
                    stack.append((neighbor, 0))
            else:
                path.pop()
                path_set.discard(node)
                stack.pop()

    return cycles


# ---------------------------------------------------------------------------
# Depth limit (BFS)
# ---------------------------------------------------------------------------

def apply_depth_limit(
    edges: list[dict], scope_ids: set[str], depth: int,
) -> list[dict]:
    if depth <= 0:
        return edges

    adj: dict[str, list[str]] = defaultdict(list)
    for e in edges:
        adj[e["from"]].append(e["to"])

    reachable = set(scope_ids)
    frontier = set(scope_ids)
    for _ in range(depth):
        nxt: set[str] = set()
        for node in frontier:
            for nb in adj.get(node, []):
                if nb not in reachable:
                    reachable.add(nb)
                    nxt.add(nb)
        frontier = nxt
        if not frontier:
            break

    return [e for e in edges if e["from"] in reachable and e["to"] in reachable]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    args = parse_args()
    root = args.root.resolve()
    scope = (root / args.scope).resolve()

    if not root.exists():
        print(f"error: root not found: {root}", file=sys.stderr)
        sys.exit(1)
    if not scope.exists():
        print(f"error: scope not found: {scope}", file=sys.stderr)
        sys.exit(1)

    # Template
    if args.template:
        tpl_path = args.template.resolve()
    else:
        tpl_path = Path(__file__).resolve().parent.parent / "templates" / "report.html"
    if not tpl_path.exists():
        print(f"error: template not found: {tpl_path}", file=sys.stderr)
        sys.exit(1)

    # Output
    out_path = args.output if args.output.is_absolute() else root / args.output
    extra_excludes = args.exclude

    # --- Discover ---
    java_roots = find_java_roots(scope, root)
    ts_roots = find_ts_roots(scope, root)
    src_map = build_source_roots_map(java_roots, ts_roots, root)

    # --- Collect ---
    java_files = collect_java_files(java_roots, root, extra_excludes)
    ts_files = collect_ts_files(ts_roots, root, extra_excludes)
    py_files = collect_python_files(scope, root, extra_excludes)
    all_files = java_files + ts_files + py_files

    if not all_files:
        print("warn: no source files found", file=sys.stderr)

    known: dict[str, str] = {}
    for _, rel in all_files:
        known[rel] = shorten_id(rel, src_map)

    internal_pkgs = find_internal_packages(java_roots)
    py_pkgs = find_python_packages(scope, root)

    ts_paths_map: dict[str, dict[str, str]] = {}
    for tr in ts_roots:
        ts_paths_map[str(tr)] = read_tsconfig_paths(tr)

    # --- Edges ---
    edges: list[dict] = []
    edge_set: set[tuple[str, str]] = set()
    ext_deps: set[str] = set()

    def _add_edge(short_from: str, short_to: str) -> None:
        key = (short_from, short_to)
        if key not in edge_set:
            edge_set.add(key)
            edges.append({"from": short_from, "to": short_to, "arrows": "to"})

    # Java
    for fp, rel in java_files:
        sf = known[rel]
        for imp in extract_java_imports(fp):
            is_internal = any(imp.startswith(p) for p in internal_pkgs)
            if is_internal:
                target = resolve_java_import(imp, java_roots, known, root)
                if target and target != rel:
                    _add_edge(sf, known[target])
            elif not imp.endswith(".*"):
                parts = imp.split(".")
                if len(parts) >= 2:
                    ext_deps.add(parts[0] + "." + parts[1] if parts[0] != "java" else parts[0])

    # TypeScript
    for fp, rel in ts_files:
        sf = known[rel]
        file_tr = next((tr for tr in ts_roots if fp.is_relative_to(tr)), None)
        paths = ts_paths_map.get(str(file_tr), {}) if file_tr else {}
        for imp in extract_ts_imports(fp):
            target = resolve_ts_import(imp, fp, known, file_tr or fp.parent, paths, root)
            if target and target != rel:
                _add_edge(sf, known[target])
            elif not imp.startswith(".") and not any(imp.startswith(p) for p in paths):
                pkg = imp.split("/")[0]
                if imp.startswith("@"):
                    pkg = "/".join(imp.split("/")[:2])
                ext_deps.add(pkg)

    # Python
    for fp, rel in py_files:
        sf = known[rel]
        for imp in extract_python_imports(fp):
            target = resolve_python_import(imp, fp, known, root, py_pkgs)
            if target and target != rel:
                _add_edge(sf, known[target])
            elif not imp.startswith("."):
                ext_deps.add(imp.split(".")[0])

    # --- Depth limit ---
    if args.depth > 0:
        scope_ids = {known[rel] for _, rel in all_files}
        edges = apply_depth_limit(edges, scope_ids, args.depth)

    # --- Stats ---
    fan_in: dict[str, int] = defaultdict(int)
    fan_out: dict[str, int] = defaultdict(int)
    for e in edges:
        fan_out[e["from"]] += 1
        fan_in[e["to"]] += 1

    connected: set[str] = set()
    for e in edges:
        connected.add(e["from"])
        connected.add(e["to"])
    for _, rel in all_files:
        connected.add(known[rel])

    # --- Nodes ---
    groups: dict[str, dict] = {}
    roles_seen: dict[str, dict] = {}
    gi = 0
    nodes: list[dict] = []
    for sid in sorted(connected):
        g = get_group(sid)
        if g not in groups:
            groups[g] = {"color": PALETTE[gi % len(PALETTE)]}
            gi += 1
        role = classify_role(sid)
        if role not in roles_seen:
            roles_seen[role] = {"color": ROLE_COLORS.get(role, "#90A4AE")}
        fi = fan_in.get(sid, 0)
        fo = fan_out.get(sid, 0)
        nodes.append({
            "id": sid,
            "label": sid.split("/")[-1],
            "group": g,
            "role": role,
            "title": f"{sid}\nRole: {role}\nImports: {fo}\nImported by: {fi}",
            "size": fi,
        })

    edges = [e for e in edges if e["from"] in connected and e["to"] in connected]

    max_fo = max(fan_out, key=fan_out.get) if fan_out else ""
    max_fi = max(fan_in, key=fan_in.get) if fan_in else ""
    circular = detect_cycles(edges)
    total_f = len(nodes)
    total_e = len(edges)
    avg = round(total_e / total_f, 2) if total_f else 0

    stats = {
        "totalFiles": total_f,
        "totalEdges": total_e,
        "avgDependencies": avg,
        "maxFanOut": {"file": max_fo, "count": fan_out.get(max_fo, 0)},
        "maxFanIn": {"file": max_fi, "count": fan_in.get(max_fi, 0)},
        "circular": circular,
        "externalDeps": sorted(ext_deps),
    }
    graph_data = {
        "nodes": nodes, "edges": edges,
        "groups": groups, "roles": roles_seen,
        "stats": stats, "groupBy": args.group_by,
    }

    # --- HTML ---
    tpl = tpl_path.read_text(encoding="utf-8")
    js = json.dumps(graph_data, ensure_ascii=False)
    js = js.replace("<", "\\u003c").replace(">", "\\u003e")
    html = tpl.replace("{{GRAPH_DATA}}", js)
    out_path.write_text(html, encoding="utf-8")

    # --- Report ---
    if args.json_output:
        json.dump(stats, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        print(f"Nodes: {total_f}")
        print(f"Edges: {total_e}")
        print(f"Avg deps: {avg}")
        print(f"Max fan-out: {max_fo} ({fan_out.get(max_fo, 0)})")
        print(f"Max fan-in: {max_fi} ({fan_in.get(max_fi, 0)})")
        print(f"Circular: {len(circular)}")
        print(f"External: {len(ext_deps)}")
        print(f"Groups: {list(groups.keys())}")
        print(f"Output: {out_path}")


if __name__ == "__main__":
    main()
