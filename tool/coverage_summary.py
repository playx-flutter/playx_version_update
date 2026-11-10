#!/usr/bin/env python3
"""Summarizes coverage/lcov.info per file and fails below a minimum.

Usage: python3 tool/coverage_summary.py [--min PERCENT] [--lcov PATH] [--worst N]

Only files under lib/ are counted. Writes a Markdown table to
$GITHUB_STEP_SUMMARY when it is set (GitHub Actions).
"""
import argparse
import os
import sys


def parse(path):
    files = {}
    current = None
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("SF:"):
                current = line[3:]
                files[current] = [0, 0]  # found, hit
            elif line.startswith("LF:") and current:
                files[current][0] = int(line[3:])
            elif line.startswith("LH:") and current:
                files[current][1] = int(line[3:])
    return {k: v for k, v in files.items() if k.startswith("lib/") and v[0] > 0}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lcov", default="coverage/lcov.info")
    parser.add_argument("--min", type=float, default=0.0)
    parser.add_argument("--worst", type=int, default=15)
    args = parser.parse_args()

    if not os.path.exists(args.lcov):
        sys.exit(f"{args.lcov} not found; run `flutter test --coverage` first")

    files = parse(args.lcov)
    found = sum(v[0] for v in files.values())
    hit = sum(v[1] for v in files.values())
    total = 100.0 * hit / found if found else 0.0

    rows = sorted(files.items(), key=lambda kv: kv[1][1] / kv[1][0])
    lines = [f"Line coverage of lib/: {total:.1f}% ({hit}/{found} lines)", ""]
    lines.append("| File | Coverage | Lines |")
    lines.append("| --- | ---: | ---: |")
    for name, (lf, lh) in rows[: args.worst]:
        lines.append(f"| `{name}` | {100.0 * lh / lf:.0f}% | {lh}/{lf} |")
    report = "\n".join(lines)
    print(report)

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a") as f:
            f.write("### Test coverage\n\n" + report + "\n")

    if total < args.min:
        sys.exit(f"Coverage {total:.1f}% is below the minimum {args.min:.1f}%")


if __name__ == "__main__":
    main()
