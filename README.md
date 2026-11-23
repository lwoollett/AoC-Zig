# Advent of Code — Zig (2015–202x)

One Zig project for every AoC year, adapted from
[SpexGuy/Zig-AoC-Template](https://github.com/SpexGuy/Zig-AoC-Template) for
**Zig 0.17** and multiple years. Each day is its own tiny executable, so you
only ever compile the day you're working on.

Requires Zig **0.17.0+**.

## Layout

```
build.zig              one exe + steps per (year, day)
src/util.zig           shared helpers/aliases + gpa (import as @import("util"))
src/test_all.zig       aggregate test entry (hand-maintainable)
src/test_all.gen.zig   generated list of day imports — do not edit
src/<year>/dayNN.zig   one file per day
src/<year>/data/       puzzle inputs, saved as dayNN.txt (embedded at compile time)
template/template.zig  the day stub template ($ = day number)
template/generate.zig  regenerates stubs; only overwrites unmodified days
template/hashes.bin    modification tracking for the generator
```

## Timings (ReleaseSafe)

Per-year wall time, min of 3 runs of the `zig-out/bin/<year>_<day>` binaries
after `zig build install_all -Doptimize=ReleaseSafe` — every year lands under
1 second. `tools/bench_all.py` regenerates this table and verifies every
answer against the manifests.

| Year | Total |
|---:|---:|
| 2015 | 0.54s |
| 2016 | 0.95s |
| 2017 | 0.93s |
| 2018 | 0.89s |
| 2019 | 0.90s |
| 2020 | 0.85s |
| 2021 | 0.81s |
| 2022 | 0.62s |
| 2023 | 0.90s |
| 2024 | 0.89s |
| 2025 | 0.27s |
| **all** | **8.6s** |

## Everyday commands

```sh
zig build 2015_03            # run 2015 day 3
zig build 2015_03 -Doptimize=ReleaseSafe
zig build 2015_03 -- -v      # extra args pass through to the program
zig build install_2015_03    # binary lands in zig-out/bin
zig build test_2015_03       # run tests inside that day's file
zig build run_2015           # run every day of 2015 in sequence
zig build test_2015          # tests for all of 2015
zig build test               # all tests, all years (one binary)
zig build run_all            # everything, every year
```

Puzzle inputs are **gitignored** (AoC asks that personal inputs not be
published). Fetch yours into `src/<year>/data/dayNN.txt` — e.g.
`./zig-out/bin/aoc-mcp input 2016 1 > src/2016/data/day01.txt` — before
building days. The day file already
declares `const data = @embedFile("data/dayNN.txt")`, which only loads if you
actually reference `data` (no input file needed yet).

## Changing the day template

Edit `template/template.zig`, then `zig build generate`. The `$` character
becomes the two-digit day number. Only days you haven't touched are
overwritten; commit `template/hashes.bin` afterwards. Delete a day file and
re-run generate to force-reset it.

## aoc-mcp (tools/aoc-mcp/)

A Zig reimplementation of [mazharenko/aoc-mcp](https://github.com/mazharenko/aoc-mcp) — an MCP server for adventofcode.com — with a CLI mode bolted on. Built with `zig build aoc-mcp` (binary: `zig-out/bin/aoc-mcp`).

```sh
./zig-out/bin/aoc-mcp progress 2015            # star count for a year
./zig-out/bin/aoc-mcp input 2015 1              # personal puzzle input
./zig-out/bin/aoc-mcp submit 2015 2 1 1606483   # submit; waits out rate limits
./zig-out/bin/aoc-mcp                            # MCP server over stdio
```

Session resolution: `--session <cookie>` flag, `$AOC_SESSION`, `$SESSION_COOKIE`, or a `.aoc_session` file in the cwd (gitignored — the cookie is a secret, never commit it).

MCP tools (same names as the original): `GetAocProgress`, `SubmitAnswer`, `GetInputResource`, plus the `aocinput://{year}/{day}` resource template. VS Code/Claude config:

```json
{ "mcpServers": { "aoc": { "command": "<repo>/zig-out/bin/aoc-mcp" } } }
```
