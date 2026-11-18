#!/usr/bin/env python3
"""Build + benchmark + verify every day against the answer manifests."""
import re, subprocess, sys, time, glob, os, json
from collections import defaultdict

os.chdir(os.path.dirname(os.path.abspath(__file__)) + "/..")

# expected answers
expected = {}  # (year, day) -> {part: answer}
for y in range(2015, 2026):
    try:
        for line in open(f"tools/aoc-mcp/answers_{y}.txt"):
            line = line.strip()
            m = re.match(rf"^{y} (\d+) ([12]) (\S+)$", line)
            if m:
                expected.setdefault((y, int(m.group(1))), {})[int(m.group(2))] = m.group(3)
            elif y == 2015:
                m2 = re.match(r"^(\d+) ([12]) (\S+)$", line)
                if m2:
                    expected.setdefault((2015, int(m2.group(1))), {})[int(m2.group(2))] = m2.group(3)
    except FileNotFoundError:
        pass

results = []
fails = []

# ensure all exes built (release)
print("building release binaries...", flush=True)
subprocess.run(["zig", "build", "-Doptimize=ReleaseSafe", "bench_placeholder_ignored"],
               capture_output=True)  # no-op guard
for y in range(2015, 2026):
    days = sorted(d for (yy, d) in expected if yy == y)
    for d in days:
        r = subprocess.run(["zig", "build", f"{y}_{d:02}", "-Doptimize=ReleaseSafe"],
                           capture_output=True, text=True)
        if r.returncode != 0:
            fails.append((y, d, "BUILD", r.stderr[-300:]))
            continue

# locate binaries
bins = {}
for path in glob.glob(".zig-cache/o/*/*"):
    name = os.path.basename(path)
    m = re.match(r"^(\d{4})_(\d{2})$", name)
    if m:
        key = (int(m.group(1)), int(m.group(2)))
        if key not in bins or os.path.getmtime(path) > os.path.getmtime(bins[key]):
            bins[key] = path

for (y, d) in sorted(bins):
    exp = expected.get((y, d), {})
    t0 = time.time()
    try:
        r = subprocess.run([bins[(y, d)]], capture_output=True, text=True, timeout=120)
        dt = time.time() - t0
    except subprocess.TimeoutExpired:
        fails.append((y, d, "TIMEOUT", ">600s"))
        results.append((y, d, 999, len(exp)))
        continue
    out = (r.stderr or "") + (r.stdout or "")
    for part, ans in exp.items():
        pat = rf"part {part}: (\S+)"
        m = re.search(pat, out)
        if not m:
            fails.append((y, d, f"P{part}", f"no output; stderr={r.stderr[-200:]}"))
        elif m.group(1) != ans:
            fails.append((y, d, f"P{part}", f"got {m.group(1)} want {ans}"))
    results.append((y, d, dt, len(exp)))

results.sort(key=lambda t: -t[2])
print(f"\n{'year':>5} {'day':>4} {'secs':>8}  parts")
for (y, d, dt, np) in results:
    flag = "  <<< SLOW" if dt > 5 else ""
    print(f"{y:>5} {d:>4} {dt:>8.2f}  {np}{flag}")

total = sum(r[2] for r in results)
print(f"\ntotal runtime: {total:.1f}s across {len(results)} days")
print(f"\nFAILURES: {len(fails)}")
for f in fails:
    print(" ", f)
