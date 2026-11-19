const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

const subject = 7;
const modulus: u64 = 20201227;

fn transform(sub: u64, loops: u64) u64 {
    var v: u64 = 1;
    var i: u64 = 0;
    while (i < loops) : (i += 1) {
        v = v * sub % modulus;
    }
    return v;
}

fn loopSize(pk: u64) u64 {
    var v: u64 = 1;
    var i: u64 = 0;
    while (true) : (i += 1) {
        if (v == pk) return i;
        v = v * subject % modulus;
    }
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    const card_pk = try parseInt(u64, lines.next().?, 10);
    const door_pk = try parseInt(u64, lines.next().?, 10);

    const card_loops = loopSize(card_pk);
    const key = transform(door_pk, card_loops);
    print("part 1: {d}\n", .{key});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
