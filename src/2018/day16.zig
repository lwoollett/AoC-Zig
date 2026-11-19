const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day16.txt");

const Regs = [4]u32;

fn apply(op: u8, regs: Regs, a: u32, b: u32, c: u32) Regs {
    var r = regs;
    switch (op) {
        0 => r[c] = r[a] + r[b], // addr
        1 => r[c] = r[a] + b, // addi
        2 => r[c] = r[a] * r[b], // mulr
        3 => r[c] = r[a] * b, // muli
        4 => r[c] = r[a] & r[b], // banr
        5 => r[c] = r[a] & b, // bani
        6 => r[c] = r[a] | r[b], // borr
        7 => r[c] = r[a] | b, // bori
        8 => r[c] = r[a], // setr
        9 => r[c] = a, // seti
        10 => r[c] = if (a > r[b]) 1 else 0, // gtir
        11 => r[c] = if (r[a] > b) 1 else 0, // gtri
        12 => r[c] = if (r[a] > r[b]) 1 else 0, // gtrr
        13 => r[c] = if (a == r[b]) 1 else 0, // eqir
        14 => r[c] = if (r[a] == b) 1 else 0, // eqri
        15 => r[c] = if (r[a] == r[b]) 1 else 0, // eqrr
        else => unreachable,
    }
    return r;
}

pub fn main() !void {
    var lines = std.mem.tokenizeAny(u8, data, "\n");

    // samples until a blank stretch, then the program
    var possible: [16]u16 = @splat(0); // bitmask of candidate ops per opcode
    for (&possible) |*p| p.* = 0xFFFF;

    var samples_3way: u32 = 0;

    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "Before:")) {
            // program section begins
            break;
        }
        const before = parseRegs(line["Before: ".len..]);
        const ins_line = lines.next().?;
        var it = tokenizeAny(u8, ins_line, " ");
        const opcode = try parseInt(u8, it.next().?, 10);
        const a = try parseInt(u32, it.next().?, 10);
        const b = try parseInt(u32, it.next().?, 10);
        const c = try parseInt(u32, it.next().?, 10);
        const after_line = lines.next().?;
        const after = parseRegs(after_line["After: ".len..]);

        var matches: u32 = 0;
        var mask: u16 = 0;
        for (0..16) |op| {
            const result = apply(@intCast(op), before, a, b, c);
            if (std.meta.eql(result, after)) {
                matches += 1;
                mask |= @as(u16, 1) << @intCast(op);
            }
        }
        if (matches >= 3) samples_3way += 1;
        possible[opcode] &= mask;
    }

    print("part 1: {d}\n", .{samples_3way});

    // resolve the mapping by elimination
    var mapping: [16]u8 = @splat(255);
    var resolved: u16 = 0;
    while (@popCount(resolved) < 16) {
        for (possible, 0..) |mask, code| {
            if (@popCount(mask) == 1) {
                const op: u8 = @intCast(@ctz(mask));
                mapping[code] = op;
                resolved |= @as(u16, 1) << @intCast(code);
                for (&possible) |*p| {
                    p.* &= ~mask;
                }
            }
        }
    }

    // run the program: everything after the LAST "After:" line
    var regs: Regs = .{ 0, 0, 0, 0 };
    var last_after: usize = 0;
    var offset: usize = 0;
    while (std.mem.indexOfPos(u8, data, offset, "After:")) |at| {
        last_after = at;
        offset = at + 6;
    }
    const newline_after = std.mem.findScalarPos(u8, data, last_after, '\n').?;
    var pit = std.mem.tokenizeAny(u8, data[newline_after..], "\n");
    while (pit.next()) |line| {
        if (line.len == 0) continue;
        var it = tokenizeAny(u8, line, " ");
        const opcode = try parseInt(u8, it.next().?, 10);
        const a = try parseInt(u32, it.next().?, 10);
        const b = try parseInt(u32, it.next().?, 10);
        const c = try parseInt(u32, it.next().?, 10);
        regs = apply(mapping[opcode], regs, a, b, c);
    }

    print("part 2: {d}\n", .{regs[0]});
}

fn parseRegs(s: []const u8) Regs {
    var r: Regs = .{ 0, 0, 0, 0 };
    var i: usize = 0;
    var n: usize = 0;
    while (i < s.len and n < 4) : (i += 1) {
        if (s[i] >= '0' and s[i] <= '9') {
            r[n] = @intCast(s[i] - '0');
            n += 1;
        }
    }
    return r;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
