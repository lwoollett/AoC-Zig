const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day14.txt");

const Md5 = std.crypto.hash.Md5;

const HashCache = Map(u64, [32]u8);

fn hexOf(digest: [16]u8) [32]u8 {
    var out: [32]u8 = undefined;
    const hex = "0123456789abcdef";
    for (digest, 0..) |b, i| {
        out[i * 2] = hex[b >> 4];
        out[i * 2 + 1] = hex[b & 0x0f];
    }
    return out;
}

fn getHash(salt: []const u8, idx: u64, stretch: bool, cache: *HashCache) ![32]u8 {
    if (cache.get(idx)) |h| return h;
    var buf: [64]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "{s}{d}", .{ salt, idx });
    var digest: [16]u8 = undefined;
    Md5.hash(msg, &digest, .{});
    var h = hexOf(digest);
    if (stretch) {
        var round: usize = 0;
        while (round < 2016) : (round += 1) {
            Md5.hash(&h, &digest, .{});
            h = hexOf(digest);
        }
    }
    try cache.put(idx, h);
    return h;
}

fn tripletChar(h: *const [32]u8) ?u8 {
    var i: usize = 0;
    while (i + 2 < 32) : (i += 1) {
        if (h[i] == h[i + 1] and h[i + 1] == h[i + 2]) return h[i];
    }
    return null;
}

fn hasFiveOf(h: *const [32]u8, c: u8) bool {
    var run: usize = 0;
    for (h) |x| {
        if (x == c) {
            run += 1;
            if (run == 5) return true;
        } else {
            run = 0;
        }
    }
    return false;
}

fn findKey(salt: []const u8, stretch: bool) !u64 {
    var cache = HashCache.init(gpa);
    defer cache.deinit();

    var keys: u32 = 0;
    var i: u64 = 0;
    while (keys < 64) : (i += 1) {
        const h = try getHash(salt, i, stretch, &cache);
        const c = tripletChar(&h) orelse continue;
        var j: u64 = i + 1;
        while (j <= i + 1000) : (j += 1) {
            const h2 = try getHash(salt, j, stretch, &cache);
            if (hasFiveOf(&h2, c)) {
                keys += 1;
                break;
            }
        }
    }
    return i - 1;
}

pub fn main() !void {
    const salt = trim(u8, data, " \n\r\t");
    print("part 1: {d}\n", .{try findKey(salt, false)});
    print("part 2: {d}\n", .{try findKey(salt, true)});
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
