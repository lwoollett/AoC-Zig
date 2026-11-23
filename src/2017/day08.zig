const std = @import("std");
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day08.txt");

const Cond = enum { gt, ge, lt, le, eq, ne };

pub fn main() !void {
    var regs = StrMap(i64).init(gpa);
    defer regs.deinit();

    var max_final: i64 = 0;
    var max_ever: i64 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "b inc 5 if a > 1"
        var it = tokenizeAny(u8, line, " ");
        const reg = it.next().?;
        const op = it.next().?;
        const amount = try parseInt(i64, it.next().?, 10);
        _ = it.next().?; // if
        const creg = it.next().?;
        const cop = it.next().?;
        const cval = try parseInt(i64, it.next().?, 10);

        const cur = regs.get(creg) orelse 0;
        const cond = switch (cop[0]) {
            '>' => if (cop.len > 1) Cond.ge else Cond.gt,
            '<' => if (cop.len > 1) Cond.le else Cond.lt,
            '=' => Cond.eq,
            '!' => Cond.ne,
            else => unreachable,
        };
        const pass = switch (cond) {
            .gt => cur > cval,
            .ge => cur >= cval,
            .lt => cur < cval,
            .le => cur <= cval,
            .eq => cur == cval,
            .ne => cur != cval,
        };
        if (!pass) continue;

        const delta: i64 = if (std.mem.eql(u8, op, "inc")) amount else -amount;
        const newv = (regs.get(reg) orelse 0) + delta;
        try regs.put(reg, newv);
        max_ever = @max(max_ever, newv);
    }

    var it2 = regs.valueIterator();
    while (it2.next()) |v| {
        max_final = @max(max_final, v.*);
    }

    print("part 1: {d}\n", .{max_final});
    print("part 2: {d}\n", .{max_ever});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
