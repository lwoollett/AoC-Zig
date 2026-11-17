const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day24.txt");

const max_pkgs = 32;

var weights: [max_pkgs]u64 = @splat(0);
var n: usize = 0;
var target: u64 = 0;
var groups_total: u32 = 0;

var best_size: usize = std.math.maxInt(usize);
var best_qe: u128 = std.math.maxInt(u128);
var scratch: [max_pkgs]bool = @splat(false);

/// True if the unused packages (per `mark`) can be partitioned into
/// `groups` groups each summing to `target`.
fn canSplit(mark: []bool, groups: u32) bool {
    if (groups == 0) return true;
    return splitDfs(mark, groups, 0, 0);
}

fn splitDfs(mark: []bool, groups: u32, from: usize, sum: u64) bool {
    if (sum == target) return canSplit(mark, groups - 1);
    var j = from;
    while (j < n) : (j += 1) {
        if (mark[j]) continue;
        if (sum + weights[j] > target) continue;
        mark[j] = true;
        if (splitDfs(mark, groups, j + 1, sum + weights[j])) return true;
        mark[j] = false;
    }
    return false;
}

/// Enumerate group-1 candidates; keeps the smallest size, then min QE.
fn search(mark: []bool, from: usize, count: usize, sum: u64, qe: u128) void {
    if (sum == target) {
        if (count < best_size or (count == best_size and qe < best_qe)) {
            // Verify the rest still splits into equal groups.
            @memcpy(scratch[0..n], mark[0..n]);
            if (canSplit(scratch[0..n], groups_total - 1)) {
                best_size = count;
                best_qe = qe;
            }
        }
        return;
    }
    if (count + 1 > best_size and best_size != std.math.maxInt(usize)) {
        // Even one more package can't beat the incumbent size.
        return;
    }
    var j = from;
    while (j < n) : (j += 1) {
        if (sum + weights[j] > target) continue;
        mark[j] = true;
        search(mark, j + 1, count + 1, sum + weights[j], qe *% weights[j]);
        mark[j] = false;
    }
}

fn solve(groups: u32) u128 {
    var total: u64 = 0;
    for (weights[0..n]) |w| total += w;
    target = total / groups;
    groups_total = groups;

    best_size = std.math.maxInt(usize);
    best_qe = std.math.maxInt(u128);

    var mark: [max_pkgs]bool = @splat(false);
    search(mark[0..n], 0, 0, 0, 1);
    return best_qe;
}

pub fn main() !void {
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        weights[n] = try parseInt(u64, line, 10);
        n += 1;
    }

    print("part 1: {d}\n", .{solve(3)});
    print("part 2: {d}\n", .{solve(4)});
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
