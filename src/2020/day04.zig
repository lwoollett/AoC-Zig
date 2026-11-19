const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day04.txt");

fn validField(key: []const u8, value: []const u8) bool {
    if (std.mem.eql(u8, key, "byr")) {
        const n = std.fmt.parseInt(u32, value, 10) catch return false;
        return value.len == 4 and n >= 1920 and n <= 2002;
    } else if (std.mem.eql(u8, key, "iyr")) {
        const n = std.fmt.parseInt(u32, value, 10) catch return false;
        return value.len == 4 and n >= 2010 and n <= 2020;
    } else if (std.mem.eql(u8, key, "eyr")) {
        const n = std.fmt.parseInt(u32, value, 10) catch return false;
        return value.len == 4 and n >= 2020 and n <= 2030;
    } else if (std.mem.eql(u8, key, "hgt")) {
        if (std.mem.endsWith(u8, value, "cm")) {
            const n = std.fmt.parseInt(u32, value[0 .. value.len - 2], 10) catch return false;
            return n >= 150 and n <= 193;
        } else if (std.mem.endsWith(u8, value, "in")) {
            const n = std.fmt.parseInt(u32, value[0 .. value.len - 2], 10) catch return false;
            return n >= 59 and n <= 76;
        }
        return false;
    } else if (std.mem.eql(u8, key, "hcl")) {
        if (value.len != 7 or value[0] != '#') return false;
        for (value[1..]) |c| {
            if (!std.ascii.isHex(c)) return false;
        }
        return true;
    } else if (std.mem.eql(u8, key, "ecl")) {
        const colors = [_][]const u8{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };
        for (colors) |col| {
            if (std.mem.eql(u8, value, col)) return true;
        }
        return false;
    } else if (std.mem.eql(u8, key, "pid")) {
        if (value.len != 9) return false;
        for (value) |c| {
            if (c < '0' or c > '9') return false;
        }
        return true;
    }
    return true; // cid or unknown
}

const required = [_][]const u8{ "byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid" };

pub fn main() !void {
    var count1: u32 = 0;
    var count2: u32 = 0;

    var passport: List([]const u8) = .empty;
    defer passport.deinit(gpa);

    var lines = splitAny(u8, data, "\n");
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) {
            // evaluate passport
            if (passport.items.len > 0) {
                var all_present = true;
                var all_valid = true;
                for (required) |req| {
                    var found = false;
                    for (passport.items) |f| {
                        if (std.mem.startsWith(u8, f, req) and f.len > req.len and f[req.len] == ':') {
                            found = true;
                            if (!validField(req, f[req.len + 1 ..])) all_valid = false;
                            break;
                        }
                    }
                    if (!found) all_present = false;
                }
                if (all_present) count1 += 1;
                if (all_present and all_valid) count2 += 1;
                passport.clearRetainingCapacity();
            }
            continue;
        }
        var fields = tokenizeSca(u8, line, ' ');
        while (fields.next()) |f| {
            try passport.append(gpa, f);
        }
    }

    print("part 1: {d}\n", .{count1});
    print("part 2: {d}\n", .{count2});
}

// Useful stdlib functions
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
