const std = @import("std");
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day07.txt");

const Dir = struct {
    parent: ?*Dir,
    dirs: List(*Dir) = .empty,
    files: List(u64) = .empty,
    size: u64 = 0, // computed later
};

var all_dirs: List(*Dir) = .empty;

fn computeSize(d: *Dir) u64 {
    d.size = 0;
    for (d.files.items) |f| d.size += f;
    for (d.dirs.items) |sub| d.size += computeSize(sub);
    return d.size;
}

pub fn main() !void {
    var root = Dir{ .parent = null };
    try all_dirs.append(gpa, &root);
    var cwd: *Dir = &root;

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "$ cd ")) {
            const target = line[5..];
            if (std.mem.eql(u8, target, "/")) {
                cwd = &root;
            } else if (std.mem.eql(u8, target, "..")) {
                cwd = cwd.parent.?;
            } else {
                // each directory is ls'd/cd'd once in these inputs — create
                // lazily on first cd
                const nd = try gpa.create(Dir);
                nd.* = Dir{ .parent = cwd };
                try cwd.dirs.append(gpa, nd);
                try all_dirs.append(gpa, nd);
                cwd = nd;
            }
        } else if (std.mem.startsWith(u8, line, "$ ls")) {
            // handled implicitly
        } else if (std.mem.startsWith(u8, line, "dir ")) {
            // pre-declared dir: create lazily on cd
        } else {
            // file line "12345 name"
            const sp = indexOf(u8, line, ' ').?;
            const size = try parseInt(u64, line[0..sp], 10);
            try cwd.files.append(gpa, size);
        }
    }

    _ = computeSize(&root);

    var total1: u64 = 0;
    for (all_dirs.items) |d| {
        if (d.size <= 100000) total1 += d.size;
    }
    print("part 1: {d}\n", .{total1});

    const free_space = 70000000 - root.size;
    const need = 30000000 - free_space;
    var best: u64 = std.math.maxInt(u64);
    for (all_dirs.items) |d| {
        if (d.size >= need and d.size < best) best = d.size;
    }
    print("part 2: {d}\n", .{best});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.findScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
