const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day23.txt");

const Op = enum { cpy, inc, dec, jnz, tgl };

const Instr = struct {
    op: Op,
    // operand forms: register 0-3 or literal (val_valid)
    x_is_reg: bool,
    x_reg: u2,
    x_val: i64,
    y_is_reg: bool,
    y_reg: u2,
    y_val: i64,
};

const Machine = struct {
    code: []Instr,
    regs: [4]i64,

    fn val(self: *Machine, is_reg: bool, reg: u2, v: i64) i64 {
        return if (is_reg) self.regs[reg] else v;
    }

    fn run(self: *Machine, a: i64, max_steps: u64) !i64 {
        self.regs = .{ a, 0, 0, 0 };
        var pc: usize = 0;
        var steps: u64 = 0;
        while (pc < self.code.len) {
            steps += 1;
            if (steps > max_steps) return error.TooManySteps;

            var ins = self.code[pc];
            switch (ins.op) {
                .cpy => {
                    if (ins.y_is_reg) {
                        self.regs[ins.y_reg] = self.val(ins.x_is_reg, ins.x_reg, ins.x_val);
                    }
                    pc += 1;
                },
                .inc => {
                    if (ins.x_is_reg) self.regs[ins.x_reg] += 1;
                    pc += 1;
                },
                .dec => {
                    if (ins.x_is_reg) self.regs[ins.x_reg] -= 1;
                    pc += 1;
                },
                .jnz => {
                    if (self.val(ins.x_is_reg, ins.x_reg, ins.x_val) != 0) {
                        pc = @intCast(@as(i64, @intCast(pc)) + self.val(ins.y_is_reg, ins.y_reg, ins.y_val));
                    } else pc += 1;
                },
                .tgl => {
                    const off = self.val(ins.x_is_reg, ins.x_reg, ins.x_val);
                    const target = @as(i64, @intCast(pc)) + off;
                    if (target >= 0 and target < @as(i64, @intCast(self.code.len))) {
                        const t: usize = @intCast(target);
                        self.code[t].op = switch (self.code[t].op) {
                            .inc => .dec,
                            .dec => .inc,
                            .tgl => .inc,
                            .cpy => .jnz,
                            .jnz => .cpy,
                        };
                    }
                    pc += 1;
                },
            }
            _ = &ins;
        }
        return self.regs[0];
    }
};

fn parse(alloc: std.mem.Allocator, src: []const u8) ![]Instr {
    var out: List(Instr) = .empty;
    var lines = tokenizeAny(u8, src, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const op = it.next().?;
        var ins = Instr{ .op = .cpy, .x_is_reg = false, .x_reg = 0, .x_val = 0, .y_is_reg = false, .y_reg = 0, .y_val = 0 };
        if (std.mem.eql(u8, op, "cpy") or std.mem.eql(u8, op, "jnz")) {
            ins.op = if (op[0] == 'c') .cpy else .jnz;
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
            ins.op = if (op[0] == 'i')
                .inc
            else if (op[0] == 'd')
                .dec
            else
                .tgl;
            const x = it.next().?;
            if (parseInt(i64, x, 10)) |v| {
                ins.x_val = v;
            } else |_| {
                ins.x_is_reg = true;
                ins.x_reg = regOf(x);
            }
        }
        try out.append(alloc, ins);
    }
    return out.toOwnedSlice(alloc);
}

fn regOf(s: []const u8) u2 {
    return switch (s[0]) {
        'a' => 0,
        'b' => 1,
        'c' => 2,
        else => 3,
    };
}

fn freshMachine() !Machine {
    // tgl mutates code — re-parse for every run.
    return .{ .code = try parse(gpa, data), .regs = .{ 0, 0, 0, 0 } };
}

pub fn main() !void {
    // Part 1: a = 7.
    var m = try freshMachine();
    const r7 = try m.run(7, 2_000_000_000);
    print("part 1: {d}\n", .{r7});

    // Part 2: a = 12 is far too slow raw (the factorial loop explodes), and
    // small seeds (a<7) mis-toggle the tgl program. The structure is
    // r(a) = a! + C: derive C from a=7 and VERIFY against a=8.
    const c = r7 - 5040; // 7! = 5040
    var m8 = try freshMachine();
    const r8 = try m8.run(8, 2_000_000_000);
    if (r8 != 40320 + c) { // 8! = 40320
        print("factorial-structure assumption failed: r8={d} want {d}\n", .{ r8, 40320 + c });
        return error.NoPattern;
    }
    var fact12: i64 = 1;
    var i: i64 = 2;
    while (i <= 12) : (i += 1) fact12 *= i;
    print("part 2: {d}\n", .{fact12 + c});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
