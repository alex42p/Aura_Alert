#!/usr/bin/env python3
"""
Simple script to create a local SQLite database (matching the Flutter app schema)
and populate it with dummy biometric readings for testing.

Usage:
  python tools/populate_sqlite.py [output_db_path] [num_rows]

Defaults:
  output_db_path: assets/aura_alert.db
  num_rows: 1000
"""

import sqlite3 as sql
import sys
from pathlib import Path
from datetime import datetime, timedelta
import random


def create_and_populate(db_path: Path, num_rows: int = 1000):
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sql.connect(str(db_path))
    cur = conn.cursor()

    cur.execute('''
    CREATE TABLE IF NOT EXISTS readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        value REAL NOT NULL,
        type TEXT NOT NULL
    )
    ''')

    conn.commit()

    # Generate data spread over the past 90 days
    now = datetime.now()
    start = now - timedelta(days=90)

    types = [
        ('hr', 60, 100),        # heart rate typical range
        ('temp', 30.0, 37.5),   # skin temperature in Celsius
        ('o2', 90.0, 100.0),    # oxygen saturation
    ]

    # pick random types for rows in a somewhat balanced way
    for i in range(num_rows):
        t = random.choice(types)
        typ = t[0]
        if typ == 'hr':
            value = random.gauss(75, 8)
            value = max(30, min(200, value))
        elif typ == 'temp':
            value = random.gauss(33.5, 1.2)
            value = max(20.0, min(45.0, value))
        elif typ == 'o2':
            value = random.gauss(97.0, 1.5)
            value = max(50.0, min(100.0, value))
        else:
            value = 0.0

        # a timestamp uniformly distributed between start and now
        delta = now - start
        rand_seconds = random.uniform(0, delta.total_seconds())
        ts = start + timedelta(seconds=rand_seconds)

        cur.execute('INSERT INTO readings (timestamp, value, type) VALUES (?, ?, ?)',
                    (ts.isoformat(), float(value), typ))

        # commit in batches to avoid long transactions
        if (i + 1) % 200 == 0:
            conn.commit()

    conn.commit()
    count = cur.execute('SELECT COUNT(*) FROM readings').fetchone()[0]
    conn.close()
    print(f'Populated {count} rows into {db_path}')


if __name__ == '__main__':
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('assets/aura_alert.db')
    num = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
    create_and_populate(out, num)
