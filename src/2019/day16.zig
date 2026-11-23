const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day16.txt");

fn fftPhase(digits: []u8) void {
    // block-sum form: element i's pattern is 0/+1/0/-1 in runs of (i+1),
    // period 4(i+1); with a prefix sum each output is O(n/(i+1)) block ops
    const n = digits.len;
    var next = gpa.alloc(u8, n) catch unreachable;
    defer gpa.free(next);
    const P = gpa.alloc(i64, n + 1) catch unreachable;
    defer gpa.free(P);
    P[0] = 0;
    for (0..n) |j| P[j + 1] = P[j] + @as(i64, digits[j] - '0');
    for (0..n) |i| {
        const run: usize = i + 1; // pattern run length
        const period = 4 * run;
        var sum: i64 = 0;
        // +1 block covers j in [i, 2i+1), -1 block covers [3i+2, 4i+3), per period
        var start: usize = i;
        while (start < n) : (start += period) {
            const pe = @min(start + run, n);
            sum += P[pe] - P[start];
            const ns = start + 2 * run;
            if (ns < n) {
                const ne = @min(ns + run, n);
                sum -= P[ne] - P[ns];
            }
        }
        next[i] = @as(u8, @intCast(@mod(@abs(sum), 10))) + '0';
    }
    @memcpy(digits, next);
}

pub fn main() !void {
    const input = trim(u8, data, " \n\r\t");
    const n = input.len;

    // part 1: 100 phases, first 8 digits
    {
        var digits = try gpa.alloc(u8, n);
        defer gpa.free(digits);
        @memcpy(digits, input);
        for (0..100) |_| fftPhase(digits);
        print("part 1: ", .{});
        for (digits[0..8]) |c| print("{c}", .{c});
        print("\n", .{});
    }

    // part 2: offset trick — suffix sums only
    {
        const total_len = n * 10000;
        var offset: usize = 0;
        for (input[0..7]) |c| offset = offset * 10 + (c - '0');
        // sanity: offset must be in the second half for the trick to apply
        if (offset * 2 >= total_len) {
            var tail = try gpa.alloc(u8, total_len - offset);
            defer gpa.free(tail);
            for (0..tail.len) |i| tail[i] = input[@mod(offset + i, n)];
            for (0..100) |_| {
                // value[i] = (sum of tail[i..]) mod 10
                var acc: u8 = 0;
                var i = tail.len;
                while (i > 0) {
                    i -= 1;
                    const s = acc + (tail[i] - '0');
                    acc = if (s >= 10) s - 10 else s;
                    tail[i] = acc + '0';
                }
            }
            print("part 2: ", .{});
            for (tail[0..8]) |c| print("{c}", .{c});
            print("\n", .{});
        } else {
            print("part 2: offset {d} not in second half — trick inapplicable\n", .{offset});
        }
    }
}

// Useful stdlib functions
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
