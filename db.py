#!/usr/bin/env python3
"""
Interact with the PostgreSQL practice database.

Usage:
  python db.py                    # Interactive REPL: type SQL, 'exit' or Ctrl-D to quit
  python db.py "SELECT 1;"        # Run one query and print results
  python db.py -f query.sql       # Run queries from a file
  python db.py -h                 # Help

Setup (recommend a venv):
  python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

Environment (defaults match docker-compose):
  PGHOST=localhost  PGPORT=5433  PGUSER=practice  PGPASSWORD=practice  PGDATABASE=practice_db
"""

import os
import sys

try:
    import psycopg2
except ImportError:
    print("Install the driver: pip install -r requirements.txt", file=sys.stderr)
    sys.exit(1)


def get_conn():
    return psycopg2.connect(
        host=os.environ.get("PGHOST", "localhost"),
        port=int(os.environ.get("PGPORT", "5433")),
        user=os.environ.get("PGUSER", "practice"),
        password=os.environ.get("PGPASSWORD", "practice"),
        dbname=os.environ.get("PGDATABASE", "practice_db"),
    )


def run_query(conn, query, params=None):
    """Execute a query and return (columns, rows). Raises on error."""
    with conn.cursor() as cur:
        cur.execute(query, params)
        if cur.description:
            columns = [d[0] for d in cur.description]
            rows = cur.fetchall()
            return columns, rows
        return None, None


def print_result(columns, rows):
    """Pretty-print query result."""
    if columns is None:
        print("(no result set)")
        return
    if not rows:
        print("(0 rows)")
        return
    widths = [max(len(str(c)), max(len(str(r[i])) for r in rows)) for i, c in enumerate(columns)]
    widths = [min(w, 40) for w in widths]
    fmt = " | ".join(f"{{:<{w}}}" for w in widths)
    print(fmt.format(*columns))
    print("-+-".join("-" * w for w in widths))
    for row in rows:
        print(fmt.format(*[str(x)[:40] for x in row]))
    print(f"({len(rows)} row(s))")


def run_and_print(conn, query, params=None):
    columns, rows = run_query(conn, query, params)
    print_result(columns, rows)


def main():
    if len(sys.argv) > 1:
        if sys.argv[1] == "-f" and len(sys.argv) == 3:
            with open(sys.argv[2], "r") as f:
                query = f.read()
        elif sys.argv[1] in ("-h", "--help"):
            print(__doc__)
            sys.exit(0)
        else:
            query = " ".join(sys.argv[1:])
        conn = get_conn()
        try:
            for q in query.split(";"):
                q = q.strip()
                if q:
                    try:
                        run_and_print(conn, q)
                    except Exception as e:
                        print(f"Error: {e}", file=sys.stderr)
                        conn.rollback()
        finally:
            conn.close()
        return

    # Interactive REPL
    print("PostgreSQL SQL practice — type SQL and press Enter. 'exit' or Ctrl-D to quit.")
    print("(Default: localhost:5433, user practice, db practice_db)")
    conn = get_conn()
    buffer = []
    try:
        while True:
            try:
                line = input("sql> " if not buffer else "   > ")
            except EOFError:
                break
            stripped = line.strip()
            if stripped.lower() in ("exit", "quit", "\\q"):
                break
            if not stripped or stripped.startswith("--"):
                continue
            buffer.append(line if line.endswith("\n") else line + "\n")
            stmt = " ".join(buffer).strip()
            if stmt.endswith(";"):
                try:
                    for q in stmt.split(";"):
                        q = q.strip()
                        if q:
                            run_and_print(conn, q)
                except Exception as e:
                    print(f"Error: {e}", file=sys.stderr)
                    conn.rollback()  # so next query can run
                buffer = []
    finally:
        conn.close()
    print("Bye.")


if __name__ == "__main__":
    main()
