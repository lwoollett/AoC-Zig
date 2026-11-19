#!/usr/bin/env python3
"""Build + benchmark + verify every day against the answer manifests.

Times every ReleaseSafe binary in zig-out/bin (min of 3 runs) and prints a
per-day markdown table suitable for pasting into README.md. Days whose part 2
prints a letter grid (2016 d8, 2018 d10, 2019 d8/d11, 2021 d13, 2022 d10)
can't be regex-verified; they are skipped in verification, not checked for
correctness — their part 1 answers are still verified.
"""
import os
import re
import subprocess
import time

os.chdir(os.path.dirname(os.path.abspath(__file__)) + "/..")

# expected answers
expected = {}  # (year, day) -> {part: answer}
for y in range(2015, 2026):
    try:
        with open(f"tools/aoc-mcp/answers_{y}.txt") as f:
            for line in f:
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

print("building ReleaseSafe binaries...", flush=True)
subprocess.run(["zig", "build", "install_all", "-Doptimize=ReleaseSafe"], check=True)

times = {}
fails = []
for y in range(2015, 2026):
    for d in range(1, 26):
        exp = expected.get((y, d), {})
        best, out = float("inf"), ""
        for _ in range(3):
            t0 = time.perf_counter()
            try:
                r = subprocess.run([f"zig-out/bin/{y}_{d:02}"], capture_output=True, text=True, timeout=120)
            except subprocess.TimeoutExpired:
                fails.append((y, d, "TIMEOUT", ""))
                best = float("inf")
                break
            best = min(best, time.perf_counter() - t0)
            out = (r.stderr or "") + (r.stdout or "")
        if best == float("inf"):
            times[(y, d)] = None
            continue
        if "part 1" not in out:
            continue  # not implemented yet (2025 d13+ stubs)
        times[(y, d)] = best
        for part, ans in exp.items():
            m = re.search(rf"part {part}: (\S+)", out)
            if not m:
                # picture days print a grid after "part N:" — tolerated
                if f"part {part}" in out:
                    continue
                fails.append((y, d, f"P{part}", "no output"))
            elif m.group(1) != ans:
                fails.append((y, d, f"P{part}", f"got {m.group(1)} want {ans}"))

YEARS = list(range(2015, 2026))


def fmt(t):
    if t is None:
        return "—"
    return f"{t:.2f}s"


print()
print("| Year | Total |")
print("|---:|---:|")
whole = 0.0
n_days = 0
for y in YEARS:
    tot = sum(t for t in (times.get((y, d)) for d in range(1, 26)) if t)
    whole += tot
    n_days += sum(1 for d in range(1, 26) if times.get((y, d)))
    print(f"| {y} | {fmt(tot)} |")
print(f"| **all** | **{whole:.1f}s** |")
print(f"\nacross {n_days} implemented days")

print(f"\nFAILURES: {len(fails)}")
for f in fails:
    print(" ", f)
