const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day16.txt");

const Thing = enum {
    children,
    cats,
    samoyeds,
    pomeranians,
    akitas,
    vizslas,
    goldfish,
    trees,
    cars,
    perfumes,

    fn fromName(s: []const u8) ?Thing {
        const info = @typeInfo(Thing).@"enum";
        inline for (info.field_names, 0..) |name, i| {
            if (std.mem.eql(u8, s, name)) return @fromBackingInt(@intCast(i));
        }
        return null;
    }
};

// The MFCSAM scan of the gift package.
const detected = [_]i64{
    3, // children
    7, // cats
    2, // samoyeds
    3, // pomeranians
    0, // akitas
    0, // vizslas
    5, // goldfish
    3, // trees
    2, // cars
    1, // perfumes
};

fn matches(t: Thing, count: i64, retroencabulator: bool) bool {
    const idx = @backingInt(t);
    const known = detected[idx];
    if (!retroencabulator) return count == known;
    return switch (t) {
        .cats, .trees => count > known,
        .pomeranians, .goldfish => count < known,
        else => count == known,
    };
}

pub fn main() !void {
    var sue1: usize = 0;
    var sue2: usize = 0;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        // "Sue 1: children: 1, cars: 8, vizslas: 7"
        var it = tokenizeAny(u8, line, " ,:");
        _ = it.next().?; // Sue
        const num = try parseInt(usize, it.next().?, 10);

        var ok1 = true;
        var ok2 = true;
        while (it.next()) |name| {
            const count = try parseInt(i64, it.next().?, 10);
            const thing = Thing.fromName(name) orelse continue;
            if (!matches(thing, count, false)) ok1 = false;
            if (!matches(thing, count, true)) ok2 = false;
        }
        if (ok1) sue1 = num;
        if (ok2) sue2 = num;
    }

    print("part 1: {d}\n", .{sue1});
    print("part 2: {d}\n", .{sue2});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
