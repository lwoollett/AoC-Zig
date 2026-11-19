const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day04.txt");

const Board = struct {
    nums: [25]u32,
    marked: [25]bool = @splat(false),

    fn mark(self: *Board, n: u32) void {
        for (self.nums, 0..) |v, i| {
            if (v == n) self.marked[i] = true;
        }
    }

    fn wins(self: *const Board) bool {
        for (0..5) |r| {
            var full = true;
            for (0..5) |c| {
                if (!self.marked[r * 5 + c]) full = false;
            }
            if (full) return true;
        }
        for (0..5) |c| {
            var full = true;
            for (0..5) |r| {
                if (!self.marked[r * 5 + c]) full = false;
            }
            if (full) return true;
        }
        return false;
    }

    fn score(self: *const Board, last: u32) u64 {
        var unmarked: u64 = 0;
        for (self.nums, 0..) |v, i| {
            if (!self.marked[i]) unmarked += v;
        }
        return unmarked * last;
    }
};

pub fn main() !void {
    var draws: List(u32) = .empty;
    defer draws.deinit(gpa);
    var boards: List(Board) = .empty;
    defer boards.deinit(gpa);

    var lines = splitSca(u8, data, '\n');
    {
        const first = lines.next().?;
        var it = tokenizeSca(u8, first, ',');
        while (it.next()) |tok| {
            try draws.append(gpa, try parseInt(u32, tok, 10));
        }
    }
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) continue;
        var b = Board{ .nums = undefined };
        {
            var num_it = tokenizeSca(u8, line, ' ');
            for (0..5) |col| {
                b.nums[col] = try parseInt(u32, num_it.next().?, 10);
            }
        }
        for (1..5) |row| {
            const row_line = lines.next().?;
            var num_it = tokenizeSca(u8, row_line, ' ');
            for (0..5) |col| {
                b.nums[row * 5 + col] = try parseInt(u32, num_it.next().?, 10);
            }
        }
        try boards.append(gpa, b);
    }

    var first_score: ?u64 = null;
    var last_score: u64 = 0;
    var won_count: usize = 0;
    var won = try gpa.alloc(bool, boards.items.len);
    defer gpa.free(won);
    @memset(won, false);

    outer: for (draws.items) |n| {
        for (boards.items, 0..) |*b, bi| {
            if (won[bi]) continue;
            b.mark(n);
            if (b.wins()) {
                won[bi] = true;
                won_count += 1;
                if (first_score == null) first_score = b.score(n);
                last_score = b.score(n);
                if (won_count == boards.items.len) {
                    break :outer;
                }
            }
        }
    }
    print("part 1: {d}\n", .{first_score.?});
    print("part 2: {d}\n", .{last_score});
}

// Useful stdlib functions
const tokenizeSca = std.mem.tokenizeScalar;
const splitSca = std.mem.splitScalar;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
