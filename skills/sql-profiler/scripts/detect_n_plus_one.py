#!/usr/bin/env python3
"""
Detect N+1 query patterns in SQL query logs

Usage:
    python detect_n_plus_one.py queries.log
"""

import re
import sys
from collections import Counter
from pathlib import Path


def normalize_query(query):
    """
    Normalize SQL query by removing specific values
    to identify duplicate query patterns
    """
    # Remove WHERE clause values
    query = re.sub(r"= '[^']*'", "= ?", query)
    query = re.sub(r'= "[^"]*"', "= ?", query)
    query = re.sub(r"= \d+", "= ?", query)

    # Remove IN clause lists
    query = re.sub(r"IN \([^\)]+\)", "IN (?)", query)

    # Remove LIMIT/OFFSET values
    query = re.sub(r"LIMIT \d+", "LIMIT ?", query)
    query = re.sub(r"OFFSET \d+", "OFFSET ?", query)

    # Normalize whitespace
    query = " ".join(query.split())

    return query


def detect_n_plus_one(log_file, threshold=10):
    """
    Parse SQL query log and detect N+1 patterns

    Args:
        log_file: Path to log file containing SQL queries
        threshold: Minimum query count to flag as suspicious
    """
    if not Path(log_file).exists():
        print(f"Error: Log file '{log_file}' not found")
        sys.exit(1)

    with open(log_file, 'r') as f:
        lines = f.readlines()

    # Extract SQL queries from log
    queries = []
    for line in lines:
        # Look for common SQL keywords
        if any(keyword in line.upper() for keyword in ['SELECT', 'INSERT', 'UPDATE', 'DELETE']):
            queries.append(line.strip())

    if not queries:
        print("No SQL queries found in log file")
        return

    print(f"Found {len(queries)} total queries\n")

    # Normalize and count
    normalized_queries = [normalize_query(q) for q in queries]
    query_counts = Counter(normalized_queries)

    # Find suspicious patterns
    suspicious = [(query, count) for query, count in query_counts.items() if count >= threshold]

    if not suspicious:
        print(f"✅ No suspicious query patterns (threshold: {threshold}x)")
        return

    print(f"⚠️  Potential N+1 queries (appearing {threshold}+ times):\n")
    print("=" * 80)

    for query, count in sorted(suspicious, key=lambda x: x[1], reverse=True):
        print(f"\n[{count}x] {query[:200]}")
        if len(query) > 200:
            print("    ...")

    print("\n" + "=" * 80)
    print(f"\nSummary:")
    print(f"  Total queries: {len(queries)}")
    print(f"  Unique patterns: {len(query_counts)}")
    print(f"  Suspicious patterns: {len(suspicious)}")
    print(f"\n💡 Tip: Look for queries that appear once per item in a list")
    print(f"   This often indicates an N+1 problem that needs eager loading")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python detect_n_plus_one.py <log_file> [threshold]")
        print("Example: python detect_n_plus_one.py queries.log 10")
        sys.exit(1)

    log_file = sys.argv[1]
    threshold = int(sys.argv[2]) if len(sys.argv) > 2 else 10

    detect_n_plus_one(log_file, threshold)
