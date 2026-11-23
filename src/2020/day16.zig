const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day16.txt");

const Range = struct { lo: u32, hi: u32 };
const Field = struct { name: []const u8, ranges: [2]Range };

var fields: List(Field) = .empty;

fn matchesAny(v: u32) bool {
    for (fields.items) |f| {
        for (f.ranges) |r| {
            if (v >= r.lo and v <= r.hi) return true;
        }
    }
    return false;
}

fn matchesField(f: Field, v: u32) bool {
    for (f.ranges) |r| {
        if (v >= r.lo and v <= r.hi) return true;
    }
    return false;
}

pub fn main() !void {
    var your_ticket: List(u32) = .empty;
    defer your_ticket.deinit(gpa);
    var nearby: List([]u32) = .empty;
    defer {
        for (nearby.items) |t| gpa.free(t);
        nearby.deinit(gpa);
    }

    var lines = tokenizeAny(u8, data, "\n");
    var section: u8 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "your ticket:")) {
            section = 1;
            continue;
        } else if (std.mem.startsWith(u8, line, "nearby tickets:")) {
            section = 2;
            continue;
        }
        switch (section) {
            0 => {
                // "class: 1-3 or 5-7"
                const colon = indexOf(u8, line, ':').?;
                const rest = line[colon + 2 ..];
                var it = tokenizeAny(u8, rest, "or- ");
                const lo1 = try parseInt(u32, it.next().?, 10);
                const hi1 = try parseInt(u32, it.next().?, 10);
                const lo2 = try parseInt(u32, it.next().?, 10);
                const hi2 = try parseInt(u32, it.next().?, 10);
                try fields.append(gpa, .{ .name = line[0..colon], .ranges = .{
                    .{ .lo = lo1, .hi = hi1 },
                    .{ .lo = lo2, .hi = hi2 },
                } });
            },
            1 => {
                var it = tokenizeSca(u8, line, ',');
                while (it.next()) |tok| {
                    try your_ticket.append(gpa, try parseInt(u32, tok, 10));
                }
            },
            2 => {
                var vals: List(u32) = .empty;
                var it = tokenizeSca(u8, line, ',');
                while (it.next()) |tok| {
                    try vals.append(gpa, try parseInt(u32, tok, 10));
                }
                try nearby.append(gpa, try vals.toOwnedSlice(gpa));
            },
            else => {},
        }
    }

    // part 1: error rate
    var error_rate: u64 = 0;
    for (nearby.items) |t| {
        for (t) |v| {
            if (!matchesAny(v)) error_rate += v;
        }
    }
    print("part 1: {d}\n", .{error_rate});

    // part 2: valid tickets only
    const n = your_ticket.items.len;
    // possible[field][pos]
    var possible = try gpa.alloc([]bool, fields.items.len);
    defer {
        for (possible) |p| gpa.free(p);
        gpa.free(possible);
    }
    for (possible) |*p| {
        p.* = try gpa.alloc(bool, n);
        @memset(p.*, true);
    }

    var valid_count: usize = 0;
    for (nearby.items) |t| {
        var all_ok = true;
        for (t) |v| {
            if (!matchesAny(v)) {
                all_ok = false;
                break;
            }
        }
        if (!all_ok) continue;
        valid_count += 1;
        for (t, 0..) |v, pos| {
            for (fields.items, 0..) |f, fi| {
                if (!matchesField(f, v)) {
                    possible[fi][pos] = false;
                }
            }
        }
    }

    // elimination
    var field_of_pos = try gpa.alloc(usize, n);
    defer gpa.free(field_of_pos);
    @memset(field_of_pos, std.math.maxInt(usize));
    var assigned: usize = 0;
    while (assigned < fields.items.len) {
        for (possible, 0..) |p, fi| {
            var count: usize = 0;
            var only: usize = 0;
            for (p, 0..) |ok, pos| {
                if (ok and field_of_pos[pos] == std.math.maxInt(usize)) {
                    count += 1;
                    only = pos;
                }
            }
            if (count == 1) {
                field_of_pos[only] = fi;
                assigned += 1;
            }
        }
    }

    var product: u64 = 1;
    for (field_of_pos, 0..) |fi, pos| {
        if (std.mem.startsWith(u8, fields.items[fi].name, "departure")) {
            product *= your_ticket.items[pos];
        }
    }
    print("part 2: {d}\n", .{product});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
