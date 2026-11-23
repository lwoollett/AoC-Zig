const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day12.txt");

const Instr = union(enum) {
    cpy_val: struct { val: i64, reg: u2 },
    cpy_reg: struct { src: u2, dst: u2 },
    inc: u2,
    dec: u2,
    jnz_val: struct { cmp: i64, off: i64 },
    jnz_reg: struct { reg: u2, off: i64 },
};

fn regOf(s: []const u8) u2 {
    return switch (s[0]) {
        'a' => 0,
        'b' => 1,
        'c' => 2,
        else => 3,
    };
}

fn run(instrs: []const Instr, a: i64, c: i64) !i64 {
    var regs = [4]i64{ a, 0, c, 0 };
    var pc: usize = 0;
    var steps: u64 = 0;
    while (pc < instrs.len) {
        steps += 1;
        if (steps > 500_000_000) return error.TooManySteps;
        switch (instrs[pc]) {
            .cpy_val => |i| {
                regs[i.reg] = i.val;
                pc += 1;
            },
            .cpy_reg => |i| {
                regs[i.dst] = regs[i.src];
                pc += 1;
            },
            .inc => |r| {
                regs[r] += 1;
                pc += 1;
            },
            .dec => |r| {
                regs[r] -= 1;
                pc += 1;
            },
            .jnz_val => |i| {
                pc = if (i.cmp != 0) @intCast(@as(i64, @intCast(pc)) + i.off) else pc + 1;
            },
            .jnz_reg => |i| {
                pc = if (regs[i.reg] != 0) @intCast(@as(i64, @intCast(pc)) + i.off) else pc + 1;
            },
        }
    }
    return regs[0];
}

pub fn main() !void {
    var instrs: List(Instr) = .empty;
    defer instrs.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const op = it.next().?;
        if (std.mem.eql(u8, op, "cpy")) {
            const x = it.next().?;
            const y = it.next().?;
            if (parseInt(i64, x, 10)) |v| {
                try instrs.append(gpa, .{ .cpy_val = .{ .val = v, .reg = regOf(y) } });
            } else |_| {
                try instrs.append(gpa, .{ .cpy_reg = .{ .src = regOf(x), .dst = regOf(y) } });
            }
        } else if (std.mem.eql(u8, op, "inc")) {
            try instrs.append(gpa, .{ .inc = regOf(it.next().?) });
        } else if (std.mem.eql(u8, op, "dec")) {
            try instrs.append(gpa, .{ .dec = regOf(it.next().?) });
        } else if (std.mem.eql(u8, op, "jnz")) {
            const x = it.next().?;
            const off = try parseInt(i64, it.next().?, 10);
            if (parseInt(i64, x, 10)) |v| {
                try instrs.append(gpa, .{ .jnz_val = .{ .cmp = v, .off = off } });
            } else |_| {
                try instrs.append(gpa, .{ .jnz_reg = .{ .reg = regOf(x), .off = off } });
            }
        }
    }

    print("part 1: {d}\n", .{try run(instrs.items, 0, 0)});
    print("part 2: {d}\n", .{try run(instrs.items, 0, 1)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
