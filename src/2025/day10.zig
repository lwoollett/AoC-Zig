const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

pub fn main() !void {
    var total: u64 = 0;
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "[#...#] (0,2,3) (1,2) {…}"
        const bracket_end = indexOf(u8, line, ']').?;
        var target: u32 = 0;
        for (line[1..bracket_end], 0..) |c, i| {
            if (c == '#') target |= @as(u32, 1) << @intCast(i);
        }

        var buttons: List(u32) = .empty;
        defer buttons.deinit(gpa);
        var idx = indexOf(u8, line, '(').?;
        while (idx != 0 and line[idx - 1] != '{') {
            const close = std.mem.indexOfScalarPos(u8, line, idx, ')').?;
            var mask: u32 = 0;
            var it = tokenizeAny(u8, line[idx + 1 .. close], ",");
            while (it.next()) |tok| {
                const bit = try parseInt(u5, tok, 10);
                mask |= @as(u32, 1) << bit;
            }
            try buttons.append(gpa, mask);
            const next = std.mem.indexOfScalarPos(u8, line, close + 1, '(');
            idx = next orelse break;
        }

        // brute force all button subsets for minimum presses
        const m = buttons.items.len;
        var best: u32 = std.math.maxInt(u32);
        var subset: u64 = 0;
        while (subset < (@as(u64, 1) << @intCast(m))) : (subset += 1) {
            var acc: u32 = 0;
            var presses: u32 = 0;
            for (buttons.items, 0..) |b, bi| {
                if ((subset >> @intCast(bi)) & 1 == 1) {
                    acc ^= b;
                    presses += 1;
                }
            }
            if (acc == target and presses < best) {
                best = presses;
            }
        }
        total += best;
    }
    print("part 1: {d}\n", .{total});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
