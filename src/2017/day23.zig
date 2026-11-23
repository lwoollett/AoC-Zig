const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day23.txt");

const Instr = struct {
    op: enum { set, sub, mul, jnz },
    x_lit: ?i64,
    x_reg: ?u8, // 'a'..'h'
    y_lit: ?i64,
    y_reg: ?u8,
};

fn isPrime(n: u64) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    var d: u64 = 3;
    while (d * d <= n) : (d += 2) {
        if (n % d == 0) return false;
    }
    return true;
}

pub fn main() !void {
    var instrs: List(Instr) = .empty;
    defer instrs.deinit(gpa);

    var set_b_init: i64 = 0;
    var mul_factor: i64 = 100;
    var b_plus: i64 = 100000;
    var c_plus: i64 = 17000;
    var step: i64 = 17;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const op = it.next().?;
        const x = it.next().?;
        const y = it.next() orelse "";

        var ins = Instr{ .op = .set, .x_lit = null, .x_reg = null, .y_lit = null, .y_reg = null };
        ins.op = std.meta.stringToEnum(@TypeOf(ins.op), op).?;
        if (parseInt(i64, x, 10)) |v| ins.x_lit = v else |_| ins.x_reg = x[0] - 'a';
        if (y.len > 0) {
            if (parseInt(i64, y, 10)) |v| ins.y_lit = v else |_| ins.y_reg = y[0] - 'a';
        }
        try instrs.append(gpa, ins);

        // harvest the constants that shape the composite-counting loop
        if (std.mem.eql(u8, line, "set b 99")) set_b_init = try parseInt(i64, y, 10);
        if (ins.op == .mul and ins.x_reg == @as(u8, 1) and ins.y_lit != null) {
            if (ins.y_lit.? > 10) mul_factor = ins.y_lit.?;
        }
        if (ins.op == .sub and ins.x_reg == @as(u8, 1) and ins.y_lit != null and ins.y_lit.? <= -1000) b_plus = -ins.y_lit.?;
        if (ins.op == .sub and ins.x_reg == @as(u8, 2) and ins.y_lit != null and ins.y_lit.? <= -1000) c_plus = -ins.y_lit.?;
        if (ins.op == .sub and ins.x_reg == @as(u8, 1) and ins.y_lit != null and -ins.y_lit.? > 0 and -ins.y_lit.? < 100) step = -ins.y_lit.?;
    }

    // Part 1: direct simulation with a=0 (fast for this program).
    {
        var regs: [8]i64 = @splat(0);
        var pc: usize = 0;
        var muls: u64 = 0;
        var steps: u64 = 0;
        while (pc < instrs.items.len) {
            steps += 1;
            if (steps > 50_000_000) break;
            const ins = instrs.items[pc];
            const xval = if (ins.x_reg) |r| regs[r] else ins.x_lit.?;
            const yval: i64 = if (ins.y_reg) |r| regs[r] else (ins.y_lit orelse 0);
            switch (ins.op) {
                .set => {
                    if (ins.x_reg) |r| regs[r] = yval;
                    pc += 1;
                },
                .sub => {
                    if (ins.x_reg) |r| regs[r] -= yval;
                    pc += 1;
                },
                .mul => {
                    if (ins.x_reg) |r| regs[r] *= yval;
                    muls += 1;
                    pc += 1;
                },
                .jnz => {
                    pc = if (xval != 0) @intCast(@as(i64, @intCast(pc)) + yval) else pc + 1;
                },
            }
        }
        print("part 1: {d}\n", .{muls});
    }

    // Part 2 (a=1): the program counts composites in [b0, c0] stepping by
    // `step`, where b0 = init*factor + b_plus and c0 = b0 + c_plus.
    {
        const b0 = set_b_init * mul_factor + b_plus;
        const c0 = b0 + c_plus;
        var h: u64 = 0;
        var b = b0;
        while (b <= c0) : (b += step) {
            if (!isPrime(@intCast(b))) h += 1;
        }
        print("part 2: {d}\n", .{h});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
