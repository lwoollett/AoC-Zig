const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day12.txt");

const offset = 200; // pot index bias
const width = 2000;

fn stepGen(state: []const u8, rules: *const [32]bool) [width]u8 {
    var next: [width]u8 = @splat('.');
    for (2..width - 2) |i| {
        var key: u5 = 0;
        for (0..5) |k| {
            if (state[i - 2 + k] == '#') key |= @as(u5, 1) << @intCast(4 - k);
        }
        next[i] = if (rules[key]) '#' else '.';
    }
    return next;
}

fn sumOf(state: []const u8) i64 {
    var sum: i64 = 0;
    for (state, 0..) |c, i| {
        if (c == '#') sum += @as(i64, @intCast(i)) - offset;
    }
    return sum;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const first = lines.next().?; // initial state: #..##
    var state: [width]u8 = @splat('.');
    @memcpy(state[offset .. offset + first.len - "initial state: ".len], first["initial state: ".len..]);

    var rules: [32]bool = @splat(false);
    while (lines.next()) |line| {
        // "##.#. => #"
        if (line.len < 10) continue;
        if (line[9] != '#') continue;
        var key: u5 = 0;
        for (0..5) |k| {
            if (line[k] == '#') key |= @as(u5, 1) << @intCast(4 - k);
        }
        rules[key] = true;
    }

    // part 1: 20 generations
    var gen: u64 = 0;
    while (gen < 20) : (gen += 1) {
        state = stepGen(&state, &rules);
    }
    print("part 1: {d}\n", .{sumOf(&state)});

    // part 2: run until the pattern drifts linearly (delta stabilizes)
    var prev_sum = sumOf(&state);
    var delta: i64 = 0;
    var stable: u32 = 0;
    var g: u64 = 20;
    while (g < 1000) : (g += 1) {
        state = stepGen(&state, &rules);
        const s = sumOf(&state);
        const d = s - prev_sum;
        if (d == delta) {
            stable += 1;
            if (stable > 10) break;
        } else {
            stable = 0;
            delta = d;
        }
        prev_sum = s;
    }
    const total_gens = 50_000_000_000;
    const answer = prev_sum + delta * @as(i64, @intCast(total_gens - g));
    print("part 2: {d}\n", .{answer});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
