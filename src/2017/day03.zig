const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day03.txt");

fn abs(x: i64) i64 {
    return if (x < 0) -x else x;
}

/// Ring r (0-based; ring 1 is the first move out) starts at square with
/// side length 2r+1. Returns (x, y) for n on the Ulam spiral.
fn spiralPos(n: u64) [2]i64 {
    if (n == 1) return .{ 0, 0 };
    var ring: u64 = 1;
    while (n > (2 * ring + 1) * (2 * ring + 1)) ring += 1;
    const r: i64 = @intCast(ring);
    const max: i64 = @intCast((2 * ring + 1) * (2 * ring + 1));
    var steps = max - @as(i64, @intCast(n)); // 0..8r-1
    const side: i64 = 2 * r;
    // walk backwards (counterclockwise) from the ring end (r, -r):
    // bottom (leftward), left (upward), top (rightward), right (downward)
    if (steps <= side - 1) {
        return .{ r - steps, -r };
    }
    steps -= side;
    if (steps <= side - 1) {
        return .{ -r, -r + steps };
    }
    steps -= side;
    if (steps <= side - 1) {
        return .{ -r + steps, r };
    }
    steps -= side;
    return .{ r, r - steps };
}

pub fn main() !void {
    const n = try parseInt(u64, trim(u8, data, " \n\r\t"), 10);

    const p = spiralPos(n);
    print("part 1: {d}\n", .{abs(p[0]) + abs(p[1])});

    // Part 2: spiral-write sums of already-written neighbors.
    const size: usize = 31; // covers ring 15
    var grid: [size][size]u64 = @splat(@splat(0));
    const c = size / 2;
    grid[c][c] = 1;
    var i: u64 = 2;
    while (true) : (i += 1) {
        const sp = spiralPos(i);
        const x: usize = @intCast(@as(i64, @intCast(c)) + sp[0]);
        const y: usize = @intCast(@as(i64, @intCast(c)) - sp[1]);
        var sum: u64 = 0;
        for ([3]isize{ -1, 0, 1 }) |dy| {
            for ([3]isize{ -1, 0, 1 }) |dx| {
                const yy = @as(isize, @intCast(y)) + dy;
                const xx = @as(isize, @intCast(x)) + dx;
                if (yy < 0 or xx < 0 or yy >= size or xx >= size) continue;
                sum += grid[@intCast(yy)][@intCast(xx)];
            }
        }
        grid[y][x] = sum;
        if (sum > n) {
            print("part 2: {d}\n", .{sum});
            return;
        }
    }
}

// Useful stdlib functions
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
