# Advent of Code — Zig (2015–2026)

One Zig project for every AoC year, adapted from
[SpexGuy/Zig-AoC-Template](https://github.com/SpexGuy/Zig-AoC-Template) for
**Zig 0.17** and multiple years. Each day is its own tiny executable, so you
only ever compile the day you're working on.

Requires Zig **0.17.0+** and the [zom](../zom) runtime checked out as a
sibling directory (`~/repos/zom`) — it's a path dependency, used only by days
that opt in (see below).

## Layout

```
build.zig              one exe + steps per (year, day)
build.zig.zon          zom path dependency
src/util.zig           shared helpers/aliases + gpa (import as @import("util"))
src/test_all.zig       aggregate test entry (hand-maintainable)
src/test_all.gen.zig   generated list of day imports — do not edit
src/<year>/dayNN.zig   one file per day
src/<year>/data/       puzzle inputs, saved as dayNN.txt (embedded at compile time)
template/template.zig  the day stub template ($ = day number)
template/generate.zig  regenerates stubs; only overwrites unmodified days
template/hashes.bin    modification tracking for the generator
```

## Day timings (ReleaseSafe)

Per-day wall time in milliseconds (`s` = seconds), min of 3 runs of the
`zig-out/bin/<year>_<day>` binaries after `zig build install_all
-Doptimize=ReleaseSafe`. `tools/bench_all.py` regenerates this table and
verifies every answer against the manifests. **Every year completes in under
1 second**; whole suite: **~8.5s** across 262 days. Slowest day: 2016 d14
(0.36s — ~46M stretched MD5 hashes; threaded AND 8-lane SIMD via
`util.md5x4`; the hash count is inherent to the puzzle). `—` = not
implemented yet.

| Day | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 | 2022 | 2023 | 2024 | 2025 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 4 | 3 | 3 | 11 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| 2 | 3 | 3 | 3 | 3 | 8 | 3 | 3 | 3 | 3 | 5 | 67 |
| 3 | 4 | 3 | 3 | 6 | 19 | 3 | 3 | 3 | 4 | 3 | 4 |
| 4 | 63 | 3 | 15 | 3 | 6 | 3 | 3 | 3 | 4 | 3 | 7 |
| 5 | 3 | 175 | 50 | 10 | 3 | 3 | 12 | 3 | 4 | 4 | 3 |
| 6 | 18 | 3 | 30 | 11 | 5 | 6 | 3 | 4 | 26 | 36 | 12 |
| 7 | 3 | 13 | 5 | 3 | 31 | 5 | 6 | 4 | 3 | 21 | 4 |
| 8 | 3 | 3 | 3 | 5 | 3 | 3 | 4 | 5 | 9 | 3 | 64 |
| 9 | 3 | 3 | 3 | 39 | 6 | 3 | 6 | 4 | 14 | 91 | 49 |
| 10 | 203 | 3 | 3 | 12 | 15 | 3 | 3 | 3 | 3 | 6 | 7 |
| 11 | 8 | 22 | 3 | 12 | 4 | 17 | 3 | 6 | 3 | 18 | 8 |
| 12 | 4 | 49 | 3 | 3 | 35 | 3 | 18 | 3 | 104 | 8 | 37 |
| 13 | 8 | 3 | 11 | 6 | 9 | 3 | 4 | 4 | 6 | 3 | — |
| 14 | 3 | 367 | 6 | 170 | 5 | 7 | 3 | 6 | 20 | 19 | — |
| 15 | 8 | 8 | 296 | 256 | 4 | 311 | 27 | 3 | 3 | 3 | — |
| 16 | 3 | 64 | 17 | 3 | 218 | 4 | 3 | 60 | 188 | 10 | — |
| 17 | 11 | 137 | 50 | 18 | 5 | 13 | 8 | 4 | 229 | 4 | — |
| 18 | 6 | 4 | 4 | 12 | 285 | 3 | 73 | 6 | 3 | 6 | — |
| 19 | 7 | 17 | 4 | 109 | 119 | 8 | 190 | 30 | 7 | 27 | — |
| 20 | 57 | 3 | 89 | 37 | 66 | 7 | 30 | 76 | 18 | 221 | — |
| 21 | 3 | 3 | 26 | 3 | 8 | 4 | 13 | 7 | 32 | 3 | — |
| 22 | 18 | 9 | 65 | 119 | 3 | 166 | 32 | 3 | 13 | 43 | — |
| 23 | 3 | 3 | 3 | 60 | 7 | 139 | 60 | 301 | 59 | 5 | — |
| 24 | 15 | 6 | 68 | 43 | 31 | 43 | 263 | 75 | 18 | 349 | — |
| 25 | 76 | 17 | 151 | 5 | 13 | 93 | 28 | 3 | 124 | 3 | — |
| **total** | 536 | 924 | 915 | 960 | 912 | 853 | 802 | 621 | 901 | 897 | 265 |

whole suite: 8.6s across 262 days


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

## Using zom (managed objects)

Any day can opt into the zom Managed Object Runtime. build.zig scans each
day's source at configure time: an **uncommented** `@import("zom")` wires the
zom module (with its vendored SQLite) into that day's build. Every other day
stays small and fast (no SQLite linked).

```zig
const zom = @import("zom");

const Elf = struct {
    pub const zom = .{ .auto_ids = true, .layout_version = 1 };
    name: []const u8,
    calories: i64,
};

pub fn main() !void {
    const db = try zom.Database.open(std.heap.page_allocator, "day07.db", .{});
    defer db.close();
    try db.registerClass(Elf);

    var session = db.session();
    var tx = try session.begin(.read_write);
    defer tx.deinit();

    const e = try tx.create(Elf, .{ .name = "sugar", .calories = 100 });
    print("{d}\n", .{try tx.get(e, .calories)});

    switch (try tx.commit()) {
        .committed => {},
        .conflict => return error.Conflict,
    }
}
```

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

## JADE answer schemas (tools/jade/aoc20XX.scm, 2015-2025)

For the bit: the 2015 answers as JADE managed objects, with a JADE unit-test harness — validated by the [zom](../zom) JIZZ runtime (a Zig reimplementation of the JADE runtime running `.scm` schemas directly).

```sh
for Y in 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025; do
  ~/repos/zom/zig-out/bin/zom-jizz tools/jade/aoc$Y.scm --db /tmp/aoc$Y.db \
    --exec 'call JadeScript.populateData; commit'
  ~/repos/zom/zig-out/bin/zom-jizz tools/jade/aoc$Y.scm --db /tmp/aoc$Y.db \
    --exec 'call JadeScript.runTests'
  # => "all 49 assertions passed"
done
```

Schema: `AocController` → `Year` → `Day` → `Part` (answer, correct), member-key dicts (`YearByNumber`/`DayByNumber`/`PartByNumber`), explicit inverses. `AocTestCase`/`AnswerTests` are a transient JadeTestCase-style harness (`check`/`report`); when solvers get ported to JADE methods, `populateData` swaps to computing answers and the same 49 assertions validate them.

## When 2027 starts

Bump `last_year` in **both** `build.zig` and `template/generate.zig`, then
`zig build generate` (this also creates the new year's directory and
rewrites `src/test_all.gen.zig`).
