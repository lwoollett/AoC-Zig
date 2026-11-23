const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day02.txt");

pub fn main() !void {
    var paper: u64 = 0;
    var ribbon: u64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var dims = splitSca(u8, line, 'x');
        const l = try parseInt(u32, dims.next().?, 10);
        const w = try parseInt(u32, dims.next().?, 10);
        const h = try parseInt(u32, dims.next().?, 10);

        const lw: u64 = l * w;
        const wh: u64 = w * h;
        const hl: u64 = h * l;
        const slack = @min(lw, @min(wh, hl));
        paper += 2 * lw + 2 * wh + 2 * hl + slack;

        // ribbon: smallest perimeter + volume
        const mx = @max(l, @max(w, h));
        const perimeter = 2 * (@as(u64, l) + w + h - mx);
        ribbon += perimeter + l * w * h;
    }

    print("part 1: {d}\n", .{paper});
    print("part 2: {d}\n", .{ribbon});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const splitSca = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
