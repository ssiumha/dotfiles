#!/usr/bin/env python3
"""Extract DB schema from PostgreSQL or SQLite and generate a vis-network HTML ERD report.

Supports PostgreSQL (via psql CLI) and SQLite (via sqlite3 module).
Uses only the Python standard library (3.10+).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
from fnmatch import fnmatch
from pathlib import Path
from urllib.parse import unquote, urlparse

PALETTE = [
    "#4FC3F7", "#81C784", "#FFB74D", "#E57373",
    "#BA68C8", "#4DD0E1", "#FFD54F", "#A1887F",
    "#90A4AE", "#F06292", "#AED581", "#7986CB",
]

TYPE_COLORS: dict[str, str] = {
    "junction":  "#7B1FA2",
    "auth":      "#C62828",
    "audit":     "#E65100",
    "config":    "#5D4037",
    "enum":      "#00695C",
    "dimension": "#1E88E5",
    "fact":      "#1565C0",
}

AUTH_PATTERNS = re.compile(
    r"^(users?|roles?|permissions?|sessions?|tokens?|accounts?|credentials?)$", re.IGNORECASE,
)
AUDIT_PATTERNS = re.compile(
    r"^(logs?|audits?|histor(y|ies)|events?|activit(y|ies))$", re.IGNORECASE,
)
CONFIG_PATTERNS = re.compile(
    r"^(configs?|settings?|parameters?|options?|preferences?)$", re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Extract DB schema -> vis-network HTML ERD report",
    )
    p.add_argument("--conn", required=True, help="DB connection URL (postgresql://... or sqlite:///...)")
    p.add_argument("--schema", action="append", default=[], help="Schema filter for PG (repeatable)")
    p.add_argument("--exclude", action="append", default=[], help="Table exclude glob (repeatable)")
    p.add_argument("--template", type=Path, help="Path to report.html template")
    p.add_argument("--output", type=Path, default=Path("schema-graph.html"), help="Output HTML file")
    p.add_argument("--json", action="store_true", dest="json_output", help="Print JSON stats to stdout")
    p.add_argument("--group-by", choices=["schema", "type"], default="schema", dest="group_by",
                   help="Color nodes by schema or type (default: schema)")
    return p.parse_args()


# ---------------------------------------------------------------------------
# Connection URL parsing
# ---------------------------------------------------------------------------

def parse_connection_url(url: str) -> dict:
    """Parse a database connection URL into components.

    Supports:
      - postgresql://user:pass@host:port/db
      - postgres://user:pass@host:port/db  (normalized)
      - sqlite:///path/to/db
      - sqlite:///path  (relative)
    """
    normalized = url
    if normalized.startswith("postgres://"):
        normalized = "postgresql://" + normalized[len("postgres://"):]

    parsed = urlparse(normalized)
    scheme = parsed.scheme.lower()

    if scheme == "sqlite":
        # SQLAlchemy convention:
        #   sqlite:///relative   (3 slashes) → relative path
        #   sqlite:////absolute  (4 slashes) → absolute path
        # urlparse gives: path="/relative" or path="//absolute"
        # Strip exactly one leading slash to normalize.
        db_path = parsed.path
        if parsed.netloc:
            db_path = parsed.netloc + db_path
        if db_path.startswith("/"):
            db_path = db_path[1:]
        # Restore absolute path prefix if it was 4-slash form
        if db_path.startswith("/"):
            pass  # already absolute
        # Empty path means no db specified
        if not db_path:
            print("error: no SQLite database path specified", file=sys.stderr)
            sys.exit(1)
        return {"scheme": "sqlite", "path": db_path}

    if scheme == "postgresql":
        return {
            "scheme": "postgresql",
            "host": parsed.hostname or "localhost",
            "port": str(parsed.port) if parsed.port else "5432",
            "user": unquote(parsed.username) if parsed.username else "postgres",
            "password": unquote(parsed.password) if parsed.password else "",
            "database": parsed.path.lstrip("/") if parsed.path else "postgres",
        }

    print(f"error: unsupported scheme '{scheme}'. Use postgresql:// or sqlite:///", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

class Column:
    __slots__ = ("name", "type", "pk", "nullable", "default", "indexed")

    def __init__(self, name: str, col_type: str, pk: bool, nullable: bool, default: str | None = None):
        self.name = name
        self.type = col_type
        self.pk = pk
        self.nullable = nullable
        self.default = default
        self.indexed = False

    def to_dict(self) -> dict:
        d = {"name": self.name, "type": self.type, "pk": self.pk, "nullable": self.nullable}
        if self.indexed:
            d["idx"] = True
        return d


class ForeignKey:
    __slots__ = ("from_table", "from_column", "to_table", "to_column")

    def __init__(self, from_table: str, from_column: str, to_table: str, to_column: str):
        self.from_table = from_table
        self.from_column = from_column
        self.to_table = to_table
        self.to_column = to_column


class TableInfo:
    __slots__ = ("schema", "name", "table_id", "columns", "fks", "indexes")

    def __init__(self, schema: str, name: str, table_id: str):
        self.schema = schema
        self.name = name
        self.table_id = table_id
        self.columns: list[Column] = []
        self.fks: list[ForeignKey] = []
        self.indexes: list[str] = []


# ---------------------------------------------------------------------------
# SQLite extraction
# ---------------------------------------------------------------------------

def extract_sqlite_schema(db_path: str, excludes: list[str]) -> list[TableInfo]:
    """Extract schema from a SQLite database file."""
    if not Path(db_path).exists():
        print(f"error: SQLite database not found: {db_path}", file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    tables: list[TableInfo] = []

    try:
        # Get table list
        cursor = conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
        )
        table_names = [row["name"] for row in cursor.fetchall()]

        for tname in table_names:
            if _is_excluded(tname, excludes):
                continue

            info = TableInfo(schema="default", name=tname, table_id=tname)

            # Columns via PRAGMA
            for row in conn.execute(f"PRAGMA table_info('{tname}')").fetchall():
                col = Column(
                    name=row["name"],
                    col_type=row["type"] or "TEXT",
                    pk=bool(row["pk"]),
                    nullable=not bool(row["notnull"]),
                    default=row["dflt_value"],
                )
                info.columns.append(col)

            # Foreign keys via PRAGMA
            for row in conn.execute(f"PRAGMA foreign_key_list('{tname}')").fetchall():
                ref_table = row["table"]
                from_col = row["from"]
                to_col = row["to"]
                fk = ForeignKey(
                    from_table=tname,
                    from_column=from_col,
                    to_table=ref_table,
                    to_column=to_col or "id",
                )
                info.fks.append(fk)

            # Indexes via PRAGMA
            for idx_row in conn.execute(f"PRAGMA index_list('{tname}')").fetchall():
                info.indexes.append(idx_row["name"])

            tables.append(info)
    finally:
        conn.close()

    return tables


# ---------------------------------------------------------------------------
# PostgreSQL extraction (psql CLI)
# ---------------------------------------------------------------------------

def _run_psql(conn_info: dict, query: str) -> list[str]:
    """Run a psql query and return output lines."""
    cmd = [
        "psql",
        "-h", conn_info["host"],
        "-p", conn_info["port"],
        "-U", conn_info["user"],
        "-d", conn_info["database"],
        "-Atc", query,
    ]
    env = {**os.environ, "PGPASSWORD": conn_info["password"]}

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=30, env=env,
        )
    except subprocess.TimeoutExpired:
        print("error: psql query timed out (30s)", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("error: psql not found. Install PostgreSQL client tools.", file=sys.stderr)
        sys.exit(1)

    if result.returncode != 0:
        stderr = result.stderr.strip()
        print(f"error: psql failed: {stderr}", file=sys.stderr)
        sys.exit(1)

    return [line for line in result.stdout.strip().splitlines() if line]


def _schema_filter(schemas: list[str], alias: str = "table_schema") -> str:
    """Build SQL AND clause for schema filtering."""
    if not schemas:
        return ""
    quoted = ", ".join(f"'{s}'" for s in schemas)
    return f" AND {alias}.{alias if alias == 'table_schema' else 'table_schema'} IN ({quoted})"


def _schema_filter_col(schemas: list[str], prefix: str = "c") -> str:
    if not schemas:
        return ""
    quoted = ", ".join(f"'{s}'" for s in schemas)
    return f" AND {prefix}.table_schema IN ({quoted})"


def _schema_filter_plain(schemas: list[str], col: str = "table_schema") -> str:
    if not schemas:
        return ""
    quoted = ", ".join(f"'{s}'" for s in schemas)
    return f" AND {col} IN ({quoted})"


def extract_postgresql_schema(conn_info: dict, schemas: list[str], excludes: list[str]) -> list[TableInfo]:
    """Extract schema from a PostgreSQL database via psql CLI."""
    if not shutil.which("psql"):
        print("error: psql not found. Install PostgreSQL client tools.", file=sys.stderr)
        sys.exit(1)

    schema_filt = _schema_filter_plain(schemas)

    # --- Tables ---
    tables_query = (
        "SELECT table_schema, table_name FROM information_schema.tables "
        "WHERE table_schema NOT IN ('pg_catalog', 'information_schema') "
        "AND table_type = 'BASE TABLE'"
        f"{schema_filt} "
        "ORDER BY table_schema, table_name"
    )
    table_rows = _run_psql(conn_info, tables_query)

    tables_map: dict[str, TableInfo] = {}
    for row in table_rows:
        parts = row.split("|")
        if len(parts) < 2:
            continue
        tschema, tname = parts[0].strip(), parts[1].strip()
        if _is_excluded(tname, excludes) or _is_excluded(f"{tschema}.{tname}", excludes):
            continue
        tid = f"{tschema}.{tname}"
        info = TableInfo(schema=tschema, name=tname, table_id=tid)
        tables_map[tid] = info

    if not tables_map:
        return []

    # --- Columns + PK ---
    col_filt = _schema_filter_col(schemas, "c")
    columns_query = (
        "SELECT c.table_schema, c.table_name, c.column_name, c.data_type, "
        "c.is_nullable, c.column_default, "
        "CASE WHEN pk.column_name IS NOT NULL THEN 'YES' ELSE 'NO' END as is_pk "
        "FROM information_schema.columns c "
        "LEFT JOIN ( "
        "  SELECT ku.table_schema, ku.table_name, ku.column_name "
        "  FROM information_schema.table_constraints tc "
        "  JOIN information_schema.key_column_usage ku "
        "    ON tc.constraint_name = ku.constraint_name "
        "    AND tc.table_schema = ku.table_schema "
        "  WHERE tc.constraint_type = 'PRIMARY KEY' "
        ") pk ON c.table_schema = pk.table_schema "
        "  AND c.table_name = pk.table_name "
        "  AND c.column_name = pk.column_name "
        "WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')"
        f"{col_filt} "
        "ORDER BY c.table_schema, c.table_name, c.ordinal_position"
    )
    col_rows = _run_psql(conn_info, columns_query)

    for row in col_rows:
        parts = row.split("|")
        if len(parts) < 7:
            continue
        tschema = parts[0].strip()
        tname = parts[1].strip()
        tid = f"{tschema}.{tname}"
        if tid not in tables_map:
            continue
        col = Column(
            name=parts[2].strip(),
            col_type=parts[3].strip(),
            pk=(parts[6].strip() == "YES"),
            nullable=(parts[4].strip() == "YES"),
            default=parts[5].strip() or None,
        )
        tables_map[tid].columns.append(col)

    # --- Foreign keys ---
    fk_filt = _schema_filter_plain(schemas, "tc.table_schema")
    fk_query = (
        "SELECT tc.table_schema, tc.table_name, kcu.column_name, "
        "ccu.table_schema AS ref_schema, ccu.table_name AS ref_table, ccu.column_name AS ref_column "
        "FROM information_schema.table_constraints tc "
        "JOIN information_schema.key_column_usage kcu "
        "  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema "
        "JOIN information_schema.constraint_column_usage ccu "
        "  ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema "
        "WHERE tc.constraint_type = 'FOREIGN KEY'"
        f"{fk_filt} "
        "ORDER BY tc.table_schema, tc.table_name"
    )
    fk_rows = _run_psql(conn_info, fk_query)

    for row in fk_rows:
        parts = row.split("|")
        if len(parts) < 6:
            continue
        tschema = parts[0].strip()
        tname = parts[1].strip()
        tid = f"{tschema}.{tname}"
        if tid not in tables_map:
            continue
        ref_schema = parts[3].strip()
        ref_table = parts[4].strip()
        ref_col = parts[5].strip()
        fk = ForeignKey(
            from_table=tid,
            from_column=parts[2].strip(),
            to_table=f"{ref_schema}.{ref_table}",
            to_column=ref_col,
        )
        tables_map[tid].fks.append(fk)

    # --- Indexes ---
    idx_filt = _schema_filter_plain(schemas, "schemaname")
    idx_query = (
        "SELECT schemaname, tablename, indexname FROM pg_indexes "
        "WHERE schemaname NOT IN ('pg_catalog', 'information_schema')"
        f"{idx_filt}"
    )
    idx_rows = _run_psql(conn_info, idx_query)

    for row in idx_rows:
        parts = row.split("|")
        if len(parts) < 3:
            continue
        tschema = parts[0].strip()
        tname = parts[1].strip()
        tid = f"{tschema}.{tname}"
        if tid in tables_map:
            tables_map[tid].indexes.append(parts[2].strip())

    # --- Index columns (mark indexed columns) ---
    idx_col_filt = _schema_filter_plain(schemas, "n.nspname")
    idx_col_query = (
        "SELECT n.nspname, t.relname, a.attname "
        "FROM pg_index ix "
        "JOIN pg_class t ON t.oid = ix.indrelid "
        "JOIN pg_namespace n ON n.oid = t.relnamespace "
        "JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey) "
        "WHERE NOT ix.indisprimary "
        "AND n.nspname NOT IN ('pg_catalog', 'information_schema')"
        f"{idx_col_filt}"
    )
    idx_col_rows = _run_psql(conn_info, idx_col_query)
    for row in idx_col_rows:
        parts = row.split("|")
        if len(parts) < 3:
            continue
        tschema = parts[0].strip()
        tname = parts[1].strip()
        col_name = parts[2].strip()
        tid = f"{tschema}.{tname}"
        if tid in tables_map:
            for col in tables_map[tid].columns:
                if col.name == col_name:
                    col.indexed = True
                    break

    return list(tables_map.values())


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _is_excluded(name: str, excludes: list[str]) -> bool:
    """Check if a table name matches any exclude glob."""
    for pattern in excludes:
        if fnmatch(name, pattern):
            return True
    return False


# ---------------------------------------------------------------------------
# Table type classification
# ---------------------------------------------------------------------------

def classify_table_type(
    name: str,
    columns: list[Column],
    fk_out: int,
    fk_in: int,
) -> str:
    """Classify a table into a semantic type based on heuristics."""
    pk_cols = {c.name for c in columns if c.pk}
    fk_col_names: set[str] = set()
    # We count FK columns from the columns that end with _id or are typical FK names
    # But the caller provides fk_out which is the actual FK count
    # For junction detection we need to know which columns are FKs
    # We'll use a simplified heuristic: columns ending in _id
    for c in columns:
        if c.name.endswith("_id") or c.name == "id":
            fk_col_names.add(c.name)

    total_cols = len(columns)
    base_name = name.split(".")[-1] if "." in name else name

    # Junction table: FK columns >= 2 AND all PKs are FKs AND total columns <= FK columns + 2
    if fk_out >= 2 and pk_cols and pk_cols.issubset(fk_col_names) and total_cols <= fk_out + 2:
        return "junction"

    # Auth tables
    if AUTH_PATTERNS.match(base_name):
        return "auth"

    # Audit tables
    if AUDIT_PATTERNS.match(base_name):
        return "audit"

    # Config tables
    if CONFIG_PATTERNS.match(base_name):
        return "config"

    # Enum / lookup: very few columns, no outgoing FKs
    if total_cols <= 3 and fk_out == 0:
        return "enum"

    # Dimension: many incoming FKs, few outgoing
    if fk_in >= 3 and fk_out <= 1:
        return "dimension"

    return "fact"


# ---------------------------------------------------------------------------
# Implicit FK inference
# ---------------------------------------------------------------------------

def infer_implicit_fks(
    tables: list[TableInfo],
) -> list[dict]:
    """Infer foreign keys from naming conventions (_id suffix)."""
    # Build lookup: table base name -> table_id
    name_to_id: dict[str, str] = {}
    for t in tables:
        base = t.name.lower()
        name_to_id[base] = t.table_id

    # Build set of existing explicit FK edges: (from_table_id, from_column)
    explicit_fks: set[tuple[str, str]] = set()
    for t in tables:
        for fk in t.fks:
            explicit_fks.add((t.table_id, fk.from_column))

    implicit_edges: list[dict] = []

    for t in tables:
        for col in t.columns:
            cname = col.name.lower()
            if not cname.endswith("_id"):
                continue

            # Skip if explicit FK already covers this column
            if (t.table_id, col.name) in explicit_fks:
                continue

            stem = cname[:-3]  # strip _id
            if not stem:
                continue

            # Try matching table names
            matched_id: str | None = None

            # Exact match
            if stem in name_to_id:
                matched_id = name_to_id[stem]
            # Plural: stem + 's'
            elif stem + "s" in name_to_id:
                matched_id = name_to_id[stem + "s"]
            # Plural: stem + 'es'
            elif stem + "es" in name_to_id:
                matched_id = name_to_id[stem + "es"]
            # Plural: stem ending in 'y' -> 'ies' (e.g., category -> categories)
            elif stem.endswith("y") and stem[:-1] + "ies" in name_to_id:
                matched_id = name_to_id[stem[:-1] + "ies"]
            # Reverse: column is like 'categories_id' -> look for 'category'
            elif stem.endswith("ies") and stem[:-3] + "y" in name_to_id:
                matched_id = name_to_id[stem[:-3] + "y"]
            elif stem.endswith("es") and stem[:-2] in name_to_id:
                matched_id = name_to_id[stem[:-2]]
            elif stem.endswith("s") and stem[:-1] in name_to_id:
                matched_id = name_to_id[stem[:-1]]

            if matched_id and matched_id != t.table_id:
                implicit_edges.append({
                    "from": t.table_id,
                    "to": matched_id,
                    "label": col.name,
                    "title": f"{t.name}.{col.name} -> {matched_id} (implicit)",
                    "arrows": "to",
                    "implicit": True,
                })

    return implicit_edges


# ---------------------------------------------------------------------------
# Graph data construction
# ---------------------------------------------------------------------------

def build_graph_data(
    tables: list[TableInfo],
    group_by: str,
) -> dict:
    """Build the vis-network compatible graph data structure."""
    # Compute FK in/out counts
    fk_out_count: dict[str, int] = {}
    fk_in_count: dict[str, int] = {}
    for t in tables:
        fk_out_count[t.table_id] = len(t.fks)
    for t in tables:
        for fk in t.fks:
            fk_in_count.setdefault(fk.to_table, 0)
            fk_in_count[fk.to_table] = fk_in_count.get(fk.to_table, 0) + 1

    # Build explicit edges
    table_ids = {t.table_id for t in tables}
    explicit_edges: list[dict] = []
    for t in tables:
        for fk in t.fks:
            if fk.to_table not in table_ids:
                continue
            explicit_edges.append({
                "from": t.table_id,
                "to": fk.to_table,
                "label": fk.from_column,
                "title": f"{t.name}.{fk.from_column} -> {fk.to_table}.{fk.to_column}",
                "arrows": "to",
                "implicit": False,
            })

    # Implicit FK edges
    implicit_edges = infer_implicit_fks(tables)
    # Deduplicate: skip implicit edges where an explicit edge already exists for same from->to pair
    explicit_pairs: set[tuple[str, str]] = {(e["from"], e["to"]) for e in explicit_edges}
    filtered_implicit = [e for e in implicit_edges if (e["from"], e["to"]) not in explicit_pairs]

    all_edges = explicit_edges + filtered_implicit

    # Recount with implicit edges included
    for e in filtered_implicit:
        fk_out_count[e["from"]] = fk_out_count.get(e["from"], 0) + 1
        fk_in_count[e["to"]] = fk_in_count.get(e["to"], 0) + 1

    # Classify table types
    table_types: dict[str, str] = {}
    for t in tables:
        table_types[t.table_id] = classify_table_type(
            t.name,
            t.columns,
            fk_out_count.get(t.table_id, 0),
            fk_in_count.get(t.table_id, 0),
        )

    # Build groups
    groups: dict[str, dict] = {}
    gi = 0
    for t in tables:
        g = t.schema
        if g not in groups:
            groups[g] = {"color": PALETTE[gi % len(PALETTE)]}
            gi += 1

    # Build nodes
    nodes: list[dict] = []
    for t in tables:
        ttype = table_types[t.table_id]
        fi = fk_in_count.get(t.table_id, 0)
        fo = fk_out_count.get(t.table_id, 0)
        ncols = len(t.columns)

        node_group = t.schema if group_by == "schema" else ttype

        tooltip = (
            f"{t.table_id}\n"
            f"Type: {ttype}\n"
            f"Columns: {ncols}\n"
            f"FK out: {fo}\n"
            f"FK in: {fi}"
        )
        nodes.append({
            "id": t.table_id,
            "label": t.name,
            "group": node_group,
            "type": ttype,
            "title": tooltip,
            "size": fi,
            "columns": [c.to_dict() for c in t.columns],
        })

    # Schemas list
    schemas_list = sorted({t.schema for t in tables})

    # Stats
    total_tables = len(tables)
    total_explicit = len(explicit_edges)
    total_implicit = len(filtered_implicit)
    total_fks = total_explicit + total_implicit
    total_indexes = sum(len(t.indexes) for t in tables)

    connected_tables: set[str] = set()
    for e in all_edges:
        connected_tables.add(e["from"])
        connected_tables.add(e["to"])
    orphan_tables = total_tables - len(connected_tables & table_ids)

    avg_columns = round(sum(len(t.columns) for t in tables) / total_tables, 1) if total_tables else 0

    max_referenced = {"table": "", "count": 0}
    if fk_in_count:
        max_table = max(fk_in_count, key=fk_in_count.get)  # type: ignore[arg-type]
        max_referenced = {"table": max_table, "count": fk_in_count[max_table]}

    stats = {
        "totalTables": total_tables,
        "totalFKs": total_fks,
        "implicitFKs": total_implicit,
        "orphanTables": orphan_tables,
        "avgColumns": avg_columns,
        "totalIndexes": total_indexes,
        "maxReferenced": max_referenced,
        "schemas": schemas_list,
    }

    # Groups for type-based grouping
    if group_by == "type":
        groups = {}
        for ttype, color in TYPE_COLORS.items():
            if any(table_types[t.table_id] == ttype for t in tables):
                groups[ttype] = {"color": color}

    graph_data = {
        "nodes": nodes,
        "edges": all_edges,
        "groups": groups,
        "types": TYPE_COLORS,
        "stats": stats,
        "groupBy": group_by,
    }

    return graph_data


# ---------------------------------------------------------------------------
# Template injection
# ---------------------------------------------------------------------------

def inject_template(graph_data: dict, template_path: Path, output_path: Path) -> None:
    """Read template, inject graph data JSON, write output HTML."""
    tpl = template_path.read_text(encoding="utf-8")
    js = json.dumps(graph_data, ensure_ascii=False)
    js = js.replace("<", "\\u003c").replace(">", "\\u003e")
    html = tpl.replace("{{GRAPH_DATA}}", js)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html, encoding="utf-8")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    args = parse_args()

    # Parse connection URL
    conn_info = parse_connection_url(args.conn)

    # Template
    if args.template:
        tpl_path = args.template.resolve()
    else:
        tpl_path = Path(__file__).resolve().parent.parent / "templates" / "report.html"
    if not tpl_path.exists():
        print(f"error: template not found: {tpl_path}", file=sys.stderr)
        sys.exit(1)

    # Output path
    out_path = args.output if args.output.is_absolute() else Path.cwd() / args.output

    # Extract schema
    if conn_info["scheme"] == "sqlite":
        tables = extract_sqlite_schema(conn_info["path"], args.exclude)
    elif conn_info["scheme"] == "postgresql":
        tables = extract_postgresql_schema(conn_info, args.schema, args.exclude)
    else:
        print(f"error: unsupported scheme '{conn_info['scheme']}'", file=sys.stderr)
        sys.exit(1)

    if not tables:
        print("warn: no tables found in database", file=sys.stderr)
        sys.exit(0)

    # Build graph
    graph_data = build_graph_data(tables, args.group_by)

    # Inject template and write output
    inject_template(graph_data, tpl_path, out_path)

    # Console output
    stats = graph_data["stats"]
    if args.json_output:
        json.dump(stats, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        explicit = stats["totalFKs"] - stats["implicitFKs"]
        print(f"Tables: {stats['totalTables']}")
        print(f"FKs: {explicit} (explicit) + {stats['implicitFKs']} (implicit)")
        print(f"Orphans: {stats['orphanTables']}")
        print(f"Avg columns: {stats['avgColumns']}")
        print(f"Indexes: {stats['totalIndexes']}")
        mr = stats["maxReferenced"]
        print(f"Most referenced: {mr['table']} ({mr['count']})")
        print(f"Schemas: {stats['schemas']}")
        print(f"Output: {out_path}")


if __name__ == "__main__":
    main()
