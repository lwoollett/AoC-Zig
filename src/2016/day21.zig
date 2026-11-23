const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day21.txt");

fn rotateRight(s: []u8, n: usize) void {
    const len = s.len;
    var tmp: [32]u8 = undefined;
    for (s, 0..) |c, i| {
        tmp[(i + n) % len] = c;
    }
    @memcpy(s, tmp[0..len]);
}

fn rotateLeft(s: []u8, n: usize) void {
    rotateRight(s, s.len - n % s.len);
}

const Op = union(enum) {
    swap_pos: [2]usize,
    swap_letter: [2]u8,
    rotate: struct { right: bool, n: usize },
    rotate_based: u8,
    reverse: [2]usize,
    move: [2]usize,
};

fn apply(s: []u8, op: Op) void {
    switch (op) {
        .swap_pos => |p| {
            std.mem.swap(u8, &s[p[0]], &s[p[1]]);
        },
        .swap_letter => |l| {
            for (s) |*c| {
                if (c.* == l[0]) {
                    c.* = l[1];
                } else if (c.* == l[1]) {
                    c.* = l[0];
                }
            }
        },
        .rotate => |r| {
            if (r.right) {
                rotateRight(s, r.n);
            } else {
                rotateLeft(s, r.n);
            }
        },
        .rotate_based => |letter| {
            const idx = std.mem.findScalar(u8, s, letter).?;
            var n = idx + 1;
            if (idx >= 4) n += 1;
            rotateRight(s, n);
        },
        .reverse => |r| {
            std.mem.reverse(u8, s[r[0] .. r[1] + 1]);
        },
        .move => |m| {
            const c = s[m[0]];
            if (m[0] < m[1]) {
                std.mem.copyForwards(u8, s[m[0]..m[1]], s[m[0] + 1 .. m[1] + 1]);
            } else {
                std.mem.copyBackwards(u8, s[m[1] + 1 .. m[0] + 1], s[m[1]..m[0]]);
            }
            s[m[1]] = c;
        },
    }
}

fn unapply(s: []u8, op: Op) void {
    switch (op) {
        .swap_pos, .swap_letter => apply(s, op), // self-inverse
        .rotate => |r| apply(s, .{ .rotate = .{ .right = !r.right, .n = r.n } }),
        .reverse => apply(s, op), // self-inverse
        .move => |m| apply(s, .{ .move = .{ m[1], m[0] } }),
        .rotate_based => |letter| {
            // brute force: find the left-rotation that forward-applies to s
            var n: usize = 0;
            while (n < s.len) : (n += 1) {
                var cand: [32]u8 = undefined;
                @memcpy(cand[0..s.len], s);
                rotateLeft(cand[0..s.len], n);
                apply(cand[0..s.len], .{ .rotate_based = letter });
                if (std.mem.eql(u8, cand[0..s.len], s)) {
                    rotateLeft(s, n);
                    return;
                }
            }
        },
    }
}

pub fn main() !void {
    var ops: List(Op) = .empty;
    defer ops.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n\r");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " \r");
        const op = it.next().?;
        if (std.mem.eql(u8, op, "swap")) {
            const kind = it.next().?;
            if (std.mem.eql(u8, kind, "position")) {
                const x = try parseInt(usize, it.next().?, 10);
                _ = it.next().?; // with
                _ = it.next().?; // position
                const y = try parseInt(usize, it.next().?, 10);
                try ops.append(gpa, .{ .swap_pos = .{ x, y } });
            } else {
                const x = it.next().?[0];
                _ = it.next().?; // with
                _ = it.next().?; // letter
                const y = it.next().?[0];
                try ops.append(gpa, .{ .swap_letter = .{ x, y } });
            }
        } else if (std.mem.eql(u8, op, "rotate")) {
            const kind = it.next().?;
            if (std.mem.eql(u8, kind, "based")) {
                // rotate based on position of letter X
                var it2 = tokenizeAny(u8, line, " \r");
                var letter: u8 = 0;
                while (it2.next()) |t| {
                    if (t.len == 1 and t[0] >= 'a' and t[0] <= 'h') letter = t[0];
                }
                try ops.append(gpa, .{ .rotate_based = letter });
            } else {
                const right = std.mem.eql(u8, kind, "right");
                const n = try parseInt(usize, it.next().?, 10);
                try ops.append(gpa, .{ .rotate = .{ .right = right, .n = n } });
            }
        } else if (std.mem.eql(u8, op, "reverse")) {
            _ = it.next().?; // positions
            const x = try parseInt(usize, it.next().?, 10);
            _ = it.next().?; // through
            const y = try parseInt(usize, it.next().?, 10);
            try ops.append(gpa, .{ .reverse = .{ x, y } });
        } else if (std.mem.eql(u8, op, "move")) {
            _ = it.next().?; // position
            const x = try parseInt(usize, it.next().?, 10);
            _ = it.next().?; // to
            _ = it.next().?; // position
            const y = try parseInt(usize, it.next().?, 10);
            try ops.append(gpa, .{ .move = .{ x, y } });
        }
    }

    // Part 1: scramble "abcdefgh".
    var p1: [32]u8 = undefined;
    const seed = "abcdefgh";
    @memcpy(p1[0..seed.len], seed);
    for (ops.items) |op| {
        apply(p1[0..seed.len], op);
    }
    print("part 1: {s}\n", .{p1[0..seed.len]});

    // Part 2: unscramble "fbgdceah" (reverse ops in reverse order).
    var p2: [32]u8 = undefined;
    const scrambled = "fbgdceah";
    @memcpy(p2[0..scrambled.len], scrambled);
    var i: usize = ops.items.len;
    while (i > 0) {
        i -= 1;
        unapply(p2[0..scrambled.len], ops.items[i]);
    }
    print("part 2: {s}\n", .{p2[0..scrambled.len]});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
