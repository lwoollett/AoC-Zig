const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day17.txt");

const gw = 2000;
const gh = 2000;
var ground: [gh][gw]u8 = undefined; // each row is gw wide: '#' clay, '|' flowing, '~' settled, ' ' sand
var min_x: usize = gw;
var max_x: usize = 0;
var min_y: usize = gh;
var max_y: usize = 0;

fn cell(x: i64, y: i64) u8 {
    if (x < 0 or y < 0 or x >= gw or y >= gh) return ' ';
    return ground[@intCast(y)][@intCast(x)];
}
fn setCell(x: i64, y: i64, v: u8) void {
    ground[@intCast(y)][@intCast(x)] = v;
}

fn supported(x: i64, y: i64) bool {
    const below = cell(x, y + 1);
    return below == '#' or below == '~';
}

/// setCell + mark the row dirty for the fixpoint's candidate-set tracking.
var dirty_now: [gh]bool = undefined;

fn mark(x: i64, y: i64, v: u8) void {
    setCell(x, y, v);
    dirty_now[@intCast(y)] = true;
}

/// Fixpoint simulation: repeat passes until nothing changes. Each pass only
/// re-scans rows that could possibly have become actionable — rows within
/// one row of a change in the previous pass (the rules only ever look at
/// rows y-1, y, y+1). Cells change monotonically (' '→'|'→'~'), so this
/// reaches the same fixed point as scanning everything every pass.
fn simulate() void {
    var cand: [gh]bool = @splat(false);
    for (min_y..@min(max_y + 2, gh)) |y| cand[y] = true;

    while (true) {
        @memset(&dirty_now, false);

        // 1. water falls: a '|' cell with sand below wets the below cell
        var yy: i64 = @intCast(min_y);
        while (yy <= @as(i64, @intCast(max_y)) + 1) : (yy += 1) {
            if (!cand[@intCast(yy)]) continue;
            var x: i64 = @as(i64, @intCast(min_x)) - 1;
            while (x <= @as(i64, @intCast(max_x)) + 1) : (x += 1) {
                if (cell(x, yy) == '|' and cell(x, yy + 1) == ' ') {
                    mark(x, yy + 1, '|');
                }
            }
        }
        // 2. sideways spread & settling: for each supported flowing cell,
        //    spread; if bounded both sides, settle to '~'
        var allow: [gh]bool = undefined;
        for (0..gh) |y| allow[y] = cand[y] or dirty_now[y];
        var y: i64 = @intCast(min_y);
        while (y <= @as(i64, @intCast(max_y))) : (y += 1) {
            if (!allow[@intCast(y)]) continue;
            var x: i64 = @as(i64, @intCast(min_x)) - 1;
            while (x <= @as(i64, @intCast(max_x)) + 1) : (x += 1) {
                if (cell(x, y) != '|' or !supported(x, y)) continue;
                // walk left
                var lx = x;
                while (cell(lx - 1, y) != '#' and supported(lx - 1, y)) lx -= 1;
                var rx = x;
                while (cell(rx + 1, y) != '#' and supported(rx + 1, y)) rx += 1;
                const lwall = cell(lx - 1, y) == '#';
                const rwall = cell(rx + 1, y) == '#';
                if (lwall and rwall) {
                    var i = lx;
                    while (i <= rx) : (i += 1) {
                        if (cell(i, y) != '~') {
                            mark(i, y, '~');
                        }
                    }
                } else {
                    // flow to the edges; water pours over unsupported ends
                    if (!lwall) {
                        if (cell(lx - 1, y) == ' ') {
                            mark(lx - 1, y, '|');
                        }
                    }
                    if (!rwall) {
                        if (cell(rx + 1, y) == ' ') {
                            mark(rx + 1, y, '|');
                        }
                    }
                    var i = lx;
                    while (i <= rx) : (i += 1) {
                        if (cell(i, y) == ' ') {
                            mark(i, y, '|');
                        }
                    }
                }
                x = rx; // skip the processed stretch
            }
        }

        // next pass: only rows within one of a change can act
        var next: [gh]bool = @splat(false);
        var any = false;
        for (0..gh) |r| {
            if (!dirty_now[r]) continue;
            any = true;
            if (r >= 1) next[r - 1] = true;
            next[r] = true;
            if (r + 1 < gh) next[r + 1] = true;
        }
        if (!any) break;
        cand = next;
    }
}

pub fn main() !void {
    for (0..gh) |i| ground[i] = @splat(' ');

    // parse: x=495, y=2..7  |  y=13, x=498..506
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, "=,. ");
        const first = it.next().?;
        if (first[0] == 'x') {
            const x = try parseInt(i64, it.next().?, 10);
            _ = it.next().?; // y
            const y1 = try parseInt(i64, it.next().?, 10);
            const y2 = try parseInt(i64, it.next().?, 10);
            var y = y1;
            while (y <= y2) : (y += 1) setCell(x, y, '#');
        } else {
            const y = try parseInt(i64, it.next().?, 10);
            _ = it.next().?; // x
            const x1 = try parseInt(i64, it.next().?, 10);
            const x2 = try parseInt(i64, it.next().?, 10);
            var x = x1;
            while (x <= x2) : (x += 1) setCell(x, y, '#');
        }
    }

    // bounds (scan clay)
    for (0..gh) |y| {
        for (0..gw) |x| {
            if (ground[y][x] == '#') {
                min_x = @min(min_x, x);
                max_x = @max(max_x, x);
                if (min_y == gh) min_y = y;
                max_y = y;
            }
        }
    }

    setCell(500, @intCast(min_y), '|');
    simulate();

    var wet: u64 = 0;
    var settled: u64 = 0;
    var y = min_y;
    while (y <= max_y) : (y += 1) {
        for (min_x - 1..max_x + 2) |x| {
            const c = ground[y][x];
            if (c == '|') wet += 1;
            if (c == '~') {
                wet += 1;
                settled += 1;
            }
        }
    }
    print("part 1: {d}\n", .{wet});
    print("part 2: {d}\n", .{settled});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
