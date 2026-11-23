const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day15.txt");

const fa: u64 = 16807;
const fb: u64 = 48271;
const mask: u64 = 2147483647;
const low16: u64 = 0xffff;

/// v * f mod (2^31 - 1) without division: 2^31 == 1 (mod 2^31-1), so fold
/// the high 31 bits into the low ones, then one conditional subtract.
inline fn step(v: u64, f: u64) u64 {
    const p = v * f;
    const s = (p >> 31) + (p & mask);
    return if (s >= mask) s - mask else s;
}

fn lastInt(line: []const u8) []const u8 {
    var last: []const u8 = "";
    var it = tokenizeAny(u8, line, " ");
    while (it.next()) |t| last = t;
    return last;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const line_a = lines.next().?;
    const line_b = lines.next().?;
    const seed_a = try parseInt(u64, lastInt(line_a), 10);
    const seed_b = try parseInt(u64, lastInt(line_b), 10);

    // both parts are independent lcg loops — run them concurrently
    var count: u32 = 0;
    const t = try std.Thread.spawn(.{}, part1, .{ seed_a, seed_b, &count });
    const count2 = part2(seed_a, seed_b);
    t.join();
    print("part 1: {d}\n", .{count});
    print("part 2: {d}\n", .{count2});
}

/// Part 1: 40M plain pairs. Lanes jump 4 terms ahead via f^4, so each
/// @Vector(4,u64) step advances both generators 4 time steps at once.
fn part1(seed_a: u64, seed_b: u64, count: *u32) void {
    const fa4 = step(step(step(step(1, fa), fa), fa), fa); // fa^4 mod m
    const fb4 = step(step(step(step(1, fb), fb), fb), fb);
    var va: @Vector(4, u64) = .{
        seed_a,
        step(seed_a, fa),
        step(step(seed_a, fa), fa),
        step(step(step(seed_a, fa), fa), fa),
    };
    var vb: @Vector(4, u64) = .{
        seed_b,
        step(seed_b, fb),
        step(step(seed_b, fb), fb),
        step(step(step(seed_b, fb), fb), fb),
    };
    const vfa: @Vector(4, u64) = @splat(fa4);
    const vfb: @Vector(4, u64) = @splat(fb4);
    const vmask: @Vector(4, u64) = @splat(mask);
    const vlow: @Vector(4, u64) = @splat(low16);
    var c: u32 = 0;
    var i: u64 = 0;
    while (i < 40_000_000 / 4) : (i += 1) {
        const pa = va *% vfa;
        const sa = (pa >> @as(@Vector(4, u6), @splat(31))) + (pa & vmask);
        va = sa -% @select(u64, sa >= vmask, vmask, @as(@Vector(4, u64), @splat(0)));
        const pb = vb *% vfb;
        const sb = (pb >> @as(@Vector(4, u6), @splat(31))) + (pb & vmask);
        vb = sb -% @select(u64, sb >= vmask, vmask, @as(@Vector(4, u64), @splat(0)));
        const eq = (va & vlow) == (vb & vlow);
        c += @popCount(@as(u4, @bitCast(eq)));
    }
    count.* = c;
}

/// Part 2: 5M picky pairs.
fn part2(seed_a: u64, seed_b: u64) u32 {
    var a = seed_a;
    var b = seed_b;
    var count: u32 = 0;
    var i: u64 = 0;
    while (i < 5_000_000) : (i += 1) {
        while (true) {
            a = step(a, fa);
            if (a % 4 == 0) break;
        }
        while (true) {
            b = step(b, fb);
            if (b % 8 == 0) break;
        }
        if (a & low16 == b & low16) count += 1;
    }
    return count;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
