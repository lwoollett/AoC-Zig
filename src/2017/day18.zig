const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day18.txt");

const Instr = struct {
    op: enum { snd, set, add, mul, mod, rcv, jgz },
    x_lit: ?i64,
    x_reg: ?u8,
    y_lit: ?i64,
    y_reg: ?u8,
};

const Program = struct {
    regs: [26]i64 = @splat(0),
    pc: usize = 0,
    queue: List(i64) = .empty,
    q_head: usize = 0,
    sent: u64 = 0,

    fn recv(self: *Program) ?i64 {
        if (self.q_head >= self.queue.items.len) return null;
        const v = self.queue.items[self.q_head];
        self.q_head += 1;
        return v;
    }
};

pub fn main() !void {
    var instrs: List(Instr) = .empty;
    defer instrs.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const op = it.next().?;
        const x = it.next().?;
        const y = if (it.next()) |yy| yy else null;

        var ins = Instr{ .op = .snd, .x_lit = null, .x_reg = null, .y_lit = null, .y_reg = null };
        ins.op = std.meta.stringToEnum(@TypeOf(ins.op), op).?;
        if (parseInt(i64, x, 10)) |v| ins.x_lit = v else |_| ins.x_reg = x[0] - 'a';
        if (y) |yy| {
            if (parseInt(i64, yy, 10)) |v| ins.y_lit = v else |_| ins.y_reg = yy[0] - 'a';
        }
        try instrs.append(gpa, ins);
    }

    // Part 1: single program, sound/recover.
    {
        var regs: [26]i64 = @splat(0);
        var last_sound: i64 = 0;
        var pc: usize = 0;
        var answer: ?i64 = null;
        while (pc < instrs.items.len and answer == null) {
            const ins = instrs.items[pc];
            const xval = if (ins.x_reg) |r| regs[r] else ins.x_lit.?;
            const yval: i64 = if (ins.y_reg) |r| regs[r] else (ins.y_lit orelse 0);
            switch (ins.op) {
                .snd => {
                    last_sound = xval;
                    pc += 1;
                },
                .set => {
                    if (ins.x_reg) |r| regs[r] = yval;
                    pc += 1;
                },
                .add => {
                    if (ins.x_reg) |r| regs[r] += yval;
                    pc += 1;
                },
                .mul => {
                    if (ins.x_reg) |r| regs[r] *= yval;
                    pc += 1;
                },
                .mod => {
                    if (ins.x_reg) |r| regs[r] = @rem(regs[r], yval);
                    pc += 1;
                },
                .rcv => {
                    if (xval != 0) answer = last_sound;
                    pc += 1;
                },
                .jgz => {
                    pc = if (xval > 0) @intCast(@as(i64, @intCast(pc)) + yval) else pc + 1;
                },
            }
        }
        print("part 1: {d}\n", .{answer.?});
    }

    // Part 2: two programs exchanging via queues.
    {
        var p0 = Program{};
        var p1 = Program{};
        p1.regs['p' - 'a'] = 1;
        defer p0.queue.deinit(gpa);
        defer p1.queue.deinit(gpa);

        const progs = [2]*Program{ &p0, &p1 };
        var cur: usize = 0;
        var steps: u64 = 0;
        while (steps < 10_000_000) : (steps += 1) {
            const me = progs[cur];
            const other = progs[1 - cur];
            const ins = instrs.items[me.pc];
            const xval = if (ins.x_reg) |r| me.regs[r] else ins.x_lit.?;
            const yval: i64 = if (ins.y_reg) |r| me.regs[r] else (ins.y_lit orelse 0);
            switch (ins.op) {
                .snd => {
                    try other.queue.append(gpa, xval);
                    me.sent += 1;
                    me.pc += 1;
                },
                .set => {
                    me.regs[ins.x_reg.?] = yval;
                    me.pc += 1;
                },
                .add => {
                    me.regs[ins.x_reg.?] += yval;
                    me.pc += 1;
                },
                .mul => {
                    me.regs[ins.x_reg.?] *= yval;
                    me.pc += 1;
                },
                .mod => {
                    me.regs[ins.x_reg.?] = @rem(me.regs[ins.x_reg.?], yval);
                    me.pc += 1;
                },
                .rcv => {
                    if (me.recv()) |v| {
                        me.regs[ins.x_reg.?] = v;
                        me.pc += 1;
                    } else if (other.pc >= instrs.items.len or blk: {
                        // deadlock: other is also waiting with an empty queue
                        const oins = instrs.items[other.pc];
                        break :blk oins.op == .rcv and other.q_head >= other.queue.items.len;
                    }) {
                        break;
                    } else {
                        cur = 1 - cur;
                    }
                },
                .jgz => {
                    me.pc = if (xval > 0) @intCast(@as(i64, @intCast(me.pc)) + yval) else me.pc + 1;
                },
            }
            if (me.pc >= instrs.items.len) {
                // current program halted; switch to the other, stop if both stuck
                if (other.pc >= instrs.items.len) break;
                cur = 1 - cur;
                continue;
            }
        }
        print("part 2: {d}\n", .{p1.sent});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
