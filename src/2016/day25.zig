const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

const Instr = struct {
    op: enum { cpy, inc, dec, jnz, out },
    x_is_reg: bool,
    x_reg: u2,
    x_val: i64,
    y_is_reg: bool,
    y_reg: u2,
    y_val: i64,
};

fn regOf(s: []const u8) u2 {
    return switch (s[0]) {
        'a' => 0,
        'b' => 1,
        'c' => 2,
        else => 3,
    };
}

/// Runs with a = `seed`; checks the out stream alternates 0,1,0,1...
/// for the first `need` values. Returns true if it does.
fn transmits(seed: i64, instrs: []const Instr, need: usize) !bool {
    var regs = [4]i64{ seed, 0, 0, 0 };
    var pc: usize = 0;
    var seen: usize = 0;
    var want: i64 = 0;
    var steps: u64 = 0;

    while (pc < instrs.len) {
        steps += 1;
        if (steps > 200_000) return false;
        const ins = instrs[pc];
        const xval = if (ins.x_is_reg) regs[ins.x_reg] else ins.x_val;
        switch (ins.op) {
            .cpy => {
                if (ins.y_is_reg) regs[ins.y_reg] = xval;
                pc += 1;
            },
            .inc => {
                if (ins.x_is_reg) regs[ins.x_reg] += 1;
                pc += 1;
            },
            .dec => {
                if (ins.x_is_reg) regs[ins.x_reg] -= 1;
                pc += 1;
            },
            .jnz => {
                const yv = if (ins.y_is_reg) regs[ins.y_reg] else ins.y_val;
                pc = if (xval != 0) @intCast(@as(i64, @intCast(pc)) + yv) else pc + 1;
            },
            .out => {
                if (xval != want) return false;
                want = 1 - want;
                seen += 1;
                if (seen == need) return true;
                pc += 1;
            },
        }
    }
    return false;
}

pub fn main() !void {
    var instrs: List(Instr) = .empty;
    defer instrs.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n\r");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const op = it.next().?;
        var ins = Instr{ .op = .cpy, .x_is_reg = false, .x_reg = 0, .x_val = 0, .y_is_reg = false, .y_reg = 0, .y_val = 0 };
        ins.op = if (std.mem.eql(u8, op, "cpy"))
            .cpy
        else if (std.mem.eql(u8, op, "inc"))
            .inc
        else if (std.mem.eql(u8, op, "dec"))
            .dec
        else if (std.mem.eql(u8, op, "jnz"))
            .jnz
        else
            .out;
        if (ins.op == .cpy or ins.op == .jnz) {
            const x = it.next().?;
            const y = it.next().?;
            if (parseInt(i64, x, 10)) |v| {
                ins.x_val = v;
            } else |_| {
                ins.x_is_reg = true;
                ins.x_reg = regOf(x);
            }
            if (parseInt(i64, y, 10)) |v| {
                ins.y_val = v;
            } else |_| {
                ins.y_is_reg = true;
                ins.y_reg = regOf(y);
            }
        } else {
            const x = it.next().?;
            if (parseInt(i64, x, 10)) |v| {
                ins.x_val = v;
            } else |_| {
                ins.x_is_reg = true;
                ins.x_reg = regOf(x);
            }
        }
        try instrs.append(gpa, ins);
    }

    var a: i64 = 0;
    while (a < 100_000) : (a += 1) {
        if (try transmits(a, instrs.items, 32)) {
            print("part 1: {d}\n", .{a});
            return;
        }
    }
    return error.NotFound;
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
