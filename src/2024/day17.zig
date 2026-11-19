const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day17.txt");

var program: List(u64) = .empty;

fn comboVal(operand: u64, a: u64, b: u64, c: u64) u64 {
    return switch (operand) {
        4 => a,
        5 => b,
        6 => c,
        else => operand,
    };
}

fn run(a_in: u64, b_in: u64, c_in: u64, out: *List(u64)) void {
    var a = a_in;
    var b = b_in;
    var c = c_in;
    var pc: usize = 0;
    out.clearRetainingCapacity();
    while (pc + 1 < program.items.len) {
        const op = program.items[pc];
        const lit = program.items[pc + 1];
        const combo = comboVal(lit, a, b, c);
        switch (op) {
            0 => a = a >> @intCast(combo),
            1 => b ^= lit,
            2 => b = combo % 8,
            3 => {
                if (a != 0) {
                    pc = @intCast(lit);
                    continue;
                }
            },
            4 => b ^= c,
            5 => out.append(gpa, combo % 8) catch unreachable,
            6 => b = a >> @intCast(combo),
            7 => c = a >> @intCast(combo),
            else => {},
        }
        pc += 2;
    }
}

pub fn main() !void {
    // parse: "Register A: ..", B, C, "Program: 2,4,1,.."
    var reg_a: u64 = 0;
    var reg_b: u64 = 0;
    var reg_c: u64 = 0;
    {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "Register A:")) {
                reg_a = try parseInt(u64, line[12..], 10);
            } else if (std.mem.startsWith(u8, line, "Register B:")) {
                reg_b = try parseInt(u64, line[12..], 10);
            } else if (std.mem.startsWith(u8, line, "Register C:")) {
                reg_c = try parseInt(u64, line[12..], 10);
            } else if (std.mem.startsWith(u8, line, "Program:")) {
                var it = tokenizeSca(u8, line[9..], ',');
                while (it.next()) |tok| {
                    try program.append(gpa, try parseInt(u64, tok, 10));
                }
            }
        }
    }

    var out: List(u64) = .empty;
    defer out.deinit(gpa);

    // part 1
    run(reg_a, reg_b, reg_c, &out);
    print("part 1: ", .{});
    for (out.items, 0..) |v, i| {
        if (i > 0) print(",", .{});
        print("{d}", .{v});
    }
    print("\n", .{});

    // part 2: build A's octal digits from the top
    const target = program.items;
    {
        var candidates: List(u64) = .empty;
        defer candidates.deinit(gpa);
        // top digit: find X producing the final output
        // candidates produce outputs[pos..] for pos = remaining suffix start
        try candidates.append(gpa, 0);
        var pos: usize = target.len;
        while (pos > 0) {
            pos -= 1;
            var next: List(u64) = .empty;
            for (candidates.items) |cand| {
                var d: u64 = 0;
                while (d < 8) : (d += 1) {
                    const a_new = cand * 8 + d;
                    // test with low digits zeroed: a_new << 3*pos
                    const a_test = if (pos == 0) a_new else a_new << @intCast(3 * pos);
                    run(a_test, 0, 0, &out);
                    const need = target.len - pos;
                    if (out.items.len >= need) {
                        var ok = true;
                        for (out.items[out.items.len - need ..], 0..) |v, i| {
                            if (v != target[pos + i]) ok = false;
                        }
                        if (ok) {
                            try next.append(gpa, a_new);
                        }
                    }
                }
            }
            candidates.deinit(gpa);
            candidates = next;
            if (candidates.items.len == 0) {
                print("part 2: no candidates at pos {d}\n", .{pos});
                return;
            }
        }
        // minimal full-A candidate
        var best: u64 = std.math.maxInt(u64);
        for (candidates.items) |c| {
            best = @min(best, c);
        }
        print("part 2: {d}\n", .{best});
    }
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
