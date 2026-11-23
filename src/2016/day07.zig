const std = @import("std");

const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day07.txt");

fn hasAbba(s: []const u8) bool {
    if (s.len < 4) return false;
    var i: usize = 0;
    while (i + 3 < s.len) : (i += 1) {
        if (s[i] != s[i + 1] and s[i] == s[i + 3] and s[i + 1] == s[i + 2]) return true;
    }
    return false;
}

fn hasAba(s: []const u8, out: [][2]u8) usize {
    var n: usize = 0;
    var i: usize = 0;
    while (i + 2 < s.len and n < out.len) : (i += 1) {
        if (s[i] != s[i + 1] and s[i] == s[i + 2]) {
            out[n] = .{ s[i], s[i + 1] };
            n += 1;
        }
    }
    return n;
}

fn hasBab(s: []const u8, pair: [2]u8) bool {
    var i: usize = 0;
    while (i + 2 < s.len) : (i += 1) {
        if (s[i] == pair[1] and s[i + 1] == pair[0] and s[i + 2] == pair[1]) return true;
    }
    return false;
}

pub fn main() !void {
    var tls: u32 = 0;
    var ssl: u32 = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // split into supernet / hypernet segments
        var supernet = std.ArrayList([]const u8).empty;
        defer supernet.deinit(gpa);
        var hypernet = std.ArrayList([]const u8).empty;
        defer hypernet.deinit(gpa);

        var rest = line;
        var in_hyper = false;
        while (rest.len > 0) {
            const bracket = std.mem.findScalar(u8, rest, if (in_hyper) ']' else '[');
            const seg = if (bracket) |b| rest[0..b] else rest;
            if (in_hyper) {
                try hypernet.append(gpa, seg);
            } else {
                try supernet.append(gpa, seg);
            }
            rest = if (bracket) |b| rest[b + 1 ..] else "";
            in_hyper = !in_hyper;
        }

        // TLS
        var abba_outside = false;
        var abba_inside = false;
        for (supernet.items) |s| {
            if (hasAbba(s)) abba_outside = true;
        }
        for (hypernet.items) |s| {
            if (hasAbba(s)) abba_inside = true;
        }
        if (abba_outside and !abba_inside) tls += 1;

        // SSL
        var abas: [64][2]u8 = undefined;
        var n_abas: usize = 0;
        for (supernet.items) |s| {
            n_abas += hasAba(s, abas[n_abas..]);
        }
        ssl_loop: for (abas[0..n_abas]) |aba| {
            for (hypernet.items) |s| {
                if (hasBab(s, aba)) {
                    ssl += 1;
                    break :ssl_loop;
                }
            }
        }
    }

    print("part 1: {d}\n", .{tls});
    print("part 2: {d}\n", .{ssl});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
