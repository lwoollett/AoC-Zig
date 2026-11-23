const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day03.txt");

pub fn main() !void {
    var lines: List([]const u8) = .empty;
    defer lines.deinit(gpa);
    var it = tokenizeAny(u8, data, "\n");
    while (it.next()) |line| {
        try lines.append(gpa, line);
    }
    const w = lines.items[0].len;

    // part 1
    var gamma: u64 = 0;
    for (0..w) |x| {
        var ones: u32 = 0;
        for (lines.items) |l| {
            if (l[x] == '1') ones += 1;
        }
        gamma <<= 1;
        if (ones * 2 > lines.items.len) gamma |= 1;
    }
    const epsilon = (~gamma) & ((@as(u64, 1) << @intCast(w)) - 1);
    print("part 1: {d}\n", .{gamma * epsilon});

    // part 2
    var oxy: u64 = 0;
    {
        var cands = try gpa.alloc([]const u8, lines.items.len);
        defer gpa.free(cands);
        @memcpy(cands, lines.items);
        var nc = lines.items.len;
        for (0..w) |x| {
            if (nc == 1) break;
            var ones: usize = 0;
            for (cands[0..nc]) |l| {
                if (l[x] == '1') ones += 1;
            }
            const keep_one = ones * 2 >= nc;
            var out: usize = 0;
            for (cands[0..nc]) |l| {
                if ((l[x] == '1') == keep_one) {
                    cands[out] = l;
                    out += 1;
                }
            }
            nc = out;
        }
        oxy = try parseInt(u64, cands[0], 2);
    }
    var co2: u64 = 0;
    {
        var cands = try gpa.alloc([]const u8, lines.items.len);
        defer gpa.free(cands);
        @memcpy(cands, lines.items);
        var nc = lines.items.len;
        for (0..w) |x| {
            if (nc == 1) break;
            var ones: usize = 0;
            for (cands[0..nc]) |l| {
                if (l[x] == '1') ones += 1;
            }
            const keep_one = ones * 2 < nc; // least common; tie keeps 0
            var out: usize = 0;
            for (cands[0..nc]) |l| {
                if ((l[x] == '1') == keep_one) {
                    cands[out] = l;
                    out += 1;
                }
            }
            nc = out;
        }
        co2 = try parseInt(u64, cands[0], 2);
    }
    print("part 2: {d}\n", .{oxy * co2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
