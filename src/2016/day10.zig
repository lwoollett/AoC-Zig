const std = @import("std");

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day10.txt");

const max_bots = 512;
const max_outputs = 512;

var bot_low: [max_bots]u32 = @splat(0);
var bot_high: [max_bots]u32 = @splat(0);
var bot_count: [max_bots]u8 = @splat(0);
var output: [max_outputs]u32 = @splat(0);

const Target = struct { is_bot: bool, id: u32 };
var low_target: [max_bots]Target = @splat(.{ .is_bot = true, .id = 0 });
var high_target: [max_bots]Target = @splat(.{ .is_bot = true, .id = 0 });

/// Values 61 and 17 are the puzzle's comparison pair.
const compare_a: u32 = 61;
const compare_b: u32 = 17;

var responsible: i64 = -1;

fn give(target: Target, value: u32) void {
    if (target.is_bot) {
        giveBot(target.id, value);
    } else {
        output[target.id] = value;
    }
}

fn giveBot(id: u32, value: u32) void {
    if (bot_count[id] == 0) {
        bot_low[id] = value;
        bot_count[id] = 1;
        return;
    }
    // second chip: order them
    if (value < bot_low[id]) {
        bot_high[id] = bot_low[id];
        bot_low[id] = value;
    } else {
        bot_high[id] = value;
    }
    bot_count[id] = 2;

    if ((bot_low[id] == compare_a and bot_high[id] == compare_b) or
        (bot_low[id] == compare_b and bot_high[id] == compare_a))
    {
        responsible = id;
    }

    // fire the rule
    const low = low_target[id];
    const high = high_target[id];
    bot_count[id] = 0;
    give(low, bot_low[id]);
    give(high, bot_high[id]);
}

pub fn main() !void {
    // First pass: rules ("bot N gives low to X and high to Y").
    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (!startsWith(line, "bot ")) continue;
        // bot 1 gives low to bot 3 and high to output 4
        var it = tokenizeAny(u8, line, " ");
        _ = it.next().?; // bot
        const id = try parseInt(u32, it.next().?, 10);
        _ = it.next().?; // gives
        _ = it.next().?; // low
        _ = it.next().?; // to
        const low_is_bot = std.mem.eql(u8, it.next().?, "bot");
        const low_id = try parseInt(u32, it.next().?, 10);
        _ = it.next().?; // and
        _ = it.next().?; // high
        _ = it.next().?; // to
        const high_is_bot = std.mem.eql(u8, it.next().?, "bot");
        const high_id = try parseInt(u32, it.next().?, 10);
        low_target[id] = .{ .is_bot = low_is_bot, .id = low_id };
        high_target[id] = .{ .is_bot = high_is_bot, .id = high_id };
    }

    // Second pass: values ("value 5 goes to bot 2").
    lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        if (!startsWith(line, "value ")) continue;
        var it = tokenizeAny(u8, line, " ");
        _ = it.next().?; // value
        const value = try parseInt(u32, it.next().?, 10);
        _ = it.next().?; // goes
        _ = it.next().?; // to
        _ = it.next().?; // bot
        const id = try parseInt(u32, it.next().?, 10);
        giveBot(id, value);
    }

    print("part 1: {d}\n", .{responsible});
    print("part 2: {d}\n", .{@as(u64, output[0]) * output[1] * output[2]});
}

fn startsWith(s: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, s, prefix);
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
