const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day04.txt");

const Md5 = std.crypto.hash.Md5;

/// Returns the lowest nonce whose md5(secret ++ nonce) has `zero_bytes`
/// leading zero bytes (2 => 4 hex zeros, 2.5 => 5 hex zeros).
fn mine(secret: []const u8, hex_zeros: usize) !u64 {
    var nonce: u64 = 0;
    while (true) : (nonce += 1) {
        var buf: [64]u8 = undefined;
        const msg = try std.fmt.bufPrint(&buf, "{s}{d}", .{ secret, nonce });
        var digest: [Md5.digest_length]u8 = undefined;
        Md5.hash(msg, &digest, .{});
        // hex_zeros * 4 bits must be zero.
        const zero_bytes = hex_zeros / 2; // full bytes
        const half_byte = hex_zeros % 2 != 0; // one extra nibble
        var ok = true;
        for (digest[0..zero_bytes]) |b| {
            if (b != 0) {
                ok = false;
                break;
            }
        }
        if (ok and half_byte and digest[zero_bytes] > 0x0f) ok = false;
        if (ok) return nonce;
    }
}

pub fn main() !void {
    const secret = trim(u8, data, " \n\r\t");
    print("part 1: {d}\n", .{try mine(secret, 5)});
    print("part 2: {d}\n", .{try mine(secret, 6)});
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
