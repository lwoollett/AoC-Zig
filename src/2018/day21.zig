const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day21.txt");

pub fn main() !void {
    var ip_reg: u3 = 0;
    var ops: [64]u8 = @splat(0);
    var aa: [64]u64 = @splat(0);
    var bb: [64]u64 = @splat(0);
    var cc: [64]u64 = @splat(0);
    var n_ins: usize = 0;

    const names = [_][]const u8{ "addr", "addi", "mulr", "muli", "banr", "bani", "borr", "bori", "setr", "seti", "gtir", "gtri", "gtrr", "eqir", "eqri", "eqrr" };

    var lines = tokenizeAny(u8, data, "\n");
    const first = lines.next().?;
    ip_reg = @intCast(try parseInt(u8, first[4..], 10));

    var seed: u64 = 0;
    var mult: u64 = 0;
    var prev_was_bori_r3: bool = false;
    while (lines.next()) |line| {
        var it = tokenizeAny(u8, line, " ");
        const opname = it.next().?;
        var op: u8 = 0;
        for (names, 0..) |nm, i| {
            if (std.mem.eql(u8, nm, opname)) op = @intCast(i);
        }
        ops[n_ins] = op;
        aa[n_ins] = try parseInt(u64, it.next().?, 10);
        bb[n_ins] = try parseInt(u64, it.next().?, 10);
        cc[n_ins] = try parseInt(u64, it.next().?, 10);

        // the generator: bori 3 65536 2; seti SEED . 3 ...; muli 3 MULT 3
        if (op == 7 and aa[n_ins] == 3 and bb[n_ins] == 65536) prev_was_bori_r3 = true;
        if (prev_was_bori_r3 and op == 9 and cc[n_ins] == 3) {
            seed = aa[n_ins];
            prev_was_bori_r3 = false;
        }
        if (op == 3 and aa[n_ins] == 3) mult = bb[n_ins];
        n_ins += 1;
    }
    if (ip_reg > 5) return error.BadIp;
    if (seed == 0 or mult == 0) return error.NoGenerator;

    // Native F: fold (x | 65536) bytes through h = ((h + byte) * mult) % 2^24.
    const F = struct {
        fn f(x: u64, s: u64, m: u64) u64 {
            var h: u64 = s;
            var y: u64 = x | 65536;
            while (y != 0) {
                h = ((h + (y & 255)) * m) & 16777215;
                y >>= 8;
            }
            return h;
        }
    }.f;

    // The program halts when r0 equals the value at the compare instruction.
    // Fewest instructions: the FIRST compared value (any r0 matching it
    // halts at the very first check). Most instructions: the LAST distinct
    // value before the generator's sequence first repeats.
    var seen = Map(u64, void).init(gpa);
    defer seen.deinit();
    const first_cmp = F(0, seed, mult); // value at the first compare (r0 = 0 prologue)
    var v: u64 = first_cmp;
    var prev: u64 = first_cmp;
    while (!seen.contains(v)) {
        try seen.put(v, {});
        prev = v;
        v = F(v, seed, mult);
    }
    print("part 1: {d}\n", .{first_cmp});
    print("part 2: {d}\n", .{prev});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
