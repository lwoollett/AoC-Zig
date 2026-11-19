const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// The zom Managed Object Runtime (../zom) is available to every day.
// To use managed objects, uncomment the import below (or reference zom
// anywhere in this file) and rebuild — the day is then compiled and
// linked with zom and its vendored SQLite automatically:
// const zom = @import("zom");

const data = @embedFile("data/day12.txt");

pub fn main() !void {}

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
