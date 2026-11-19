const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day08.txt");

const Instr = struct { op: u8, arg: i32 };

fn parse(out: *List(Instr)) !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const sp = indexOf(u8, line, ' ').?;
        const arg = try parseInt(i32, line[sp + 1 ..], 10);
        try out.append(gpa, .{ .op = line[0], .arg = arg });
    }
}

/// Run until loop or halt; returns .{acc, terminated}.
fn run(prog: []const Instr) struct { acc: i64, terminated: bool } {
    var visited = gpa.alloc(bool, prog.len) catch unreachable;
    defer gpa.free(visited);
    @memset(visited, false);
    var pc: usize = 0;
    var acc: i64 = 0;
    while (pc < prog.len) {
        if (visited[pc]) return .{ .acc = acc, .terminated = false };
        visited[pc] = true;
        switch (prog[pc].op) {
            'a' => { // acc
                acc += prog[pc].arg;
                pc += 1;
            },
            'j' => { // jmp
                pc = @intCast(@as(i64, @intCast(pc)) + prog[pc].arg);
            },
            else => pc += 1, // nop
        }
    }
    return .{ .acc = acc, .terminated = true };
}

pub fn main() !void {
    var prog: List(Instr) = .empty;
    defer prog.deinit(gpa);
    try parse(&prog);

    print("part 1: {d}\n", .{run(prog.items).acc});

    for (prog.items) |*ins| {
        const orig = ins.op;
        if (ins.op == 'a') continue;
        ins.op = if (ins.op == 'j') 'n' else 'j';
        const r = run(prog.items);
        if (r.terminated) {
            print("part 2: {d}\n", .{r.acc});
            return;
        }
        ins.op = orig;
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
