const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day23.txt");

const Instr = union(enum) {
    hlf: u1, // register
    tpl: u1,
    inc: u1,
    jmp: isize,
    jie: struct { r: u1, off: isize },
    jio: struct { r: u1, off: isize },
};

fn parseOffset(s: []const u8) isize {
    const v = parseInt(i32, s, 10) catch unreachable;
    return @intCast(v);
}

pub fn main() !void {
    var instrs: List(Instr) = .empty;
    defer instrs.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ,");
        const op = it.next().?;
        const instr: Instr =
            if (std.mem.eql(u8, op, "hlf"))
            .{ .hlf = reg(it.next().?) }
        else if (std.mem.eql(u8, op, "tpl"))
            .{ .tpl = reg(it.next().?) }
        else if (std.mem.eql(u8, op, "inc"))
            .{ .inc = reg(it.next().?) }
        else if (std.mem.eql(u8, op, "jmp"))
            .{ .jmp = parseOffset(it.next().?) }
        else if (std.mem.eql(u8, op, "jie"))
            .{ .jie = .{ .r = reg(it.next().?), .off = parseOffset(it.next().?) } }
        else if (std.mem.eql(u8, op, "jio"))
            .{ .jio = .{ .r = reg(it.next().?), .off = parseOffset(it.next().?) } }
        else
            unreachable;
        try instrs.append(gpa, instr);
    }

    print("part 1: {d}\n", .{run(instrs.items, 0)});
    print("part 2: {d}\n", .{run(instrs.items, 1)});
}

fn reg(s: []const u8) u1 {
    return if (s[0] == 'a') 0 else 1;
}

fn run(instrs: []const Instr, a_start: u32) u32 {
    var regs = [2]u32{ a_start, 0 };
    var pc: isize = 0;
    while (pc >= 0 and pc < @as(isize, @intCast(instrs.len))) {
        const i: usize = @intCast(pc);
        pc += 1;
        switch (instrs[i]) {
            .hlf => |r| {
                regs[r] /= 2;
            },
            .tpl => |r| {
                regs[r] *= 3;
            },
            .inc => |r| {
                regs[r] += 1;
            },
            .jmp => |off| {
                pc += off - 1;
            },
            .jie => |j| {
                if (regs[j.r] % 2 == 0) pc += j.off - 1;
            },
            .jio => |j| {
                if (regs[j.r] == 1) pc += j.off - 1;
            },
        }
    }
    return regs[1];
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.findScalar;
const indexOfAny = std.mem.findAny;
const indexOfStr = std.mem.findPos;
const lastIndexOf = std.mem.findScalarLast;
const lastIndexOfAny = std.mem.findLastAny;
const lastIndexOfStr = std.mem.findLastLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
