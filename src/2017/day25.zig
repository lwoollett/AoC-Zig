const std = @import("std");
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day25.txt");

const Action = struct { write: u8, right: bool, next: u8 };
const StateDef = struct { on0: Action, on1: Action };

pub fn main() !void {
    var states: [26]StateDef = undefined;
    var start_state: u8 = 0;
    var steps: u64 = 0;

    var lines = std.mem.tokenizeAny(u8, data, "\n");
    while (lines.next()) |line_raw| {
        const line = trim(u8, line_raw, " \r");
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "Begin in state ")) {
            start_state = line["Begin in state ".len] - 'A';
        } else if (std.mem.startsWith(u8, line, "Perform a diagnostic checksum after ")) {
            var it = tokenizeAny(u8, line, " ");
            _ = it.next().?; // Perform
            _ = it.next().?; // a
            _ = it.next().?; // diagnostic
            _ = it.next().?; // checksum
            _ = it.next().?; // after
            steps = try parseInt(u64, it.next().?, 10);
        } else if (std.mem.startsWith(u8, line, "In state ")) {
            const sid = line["In state ".len] - 'A';
            // two branches: value 0 and value 1
            var actions: [2]Action = undefined;
            for (0..2) |branch| {
                // skip "If the current value is N:"
                const ifline = lines.next() orelse return error.BadInput;
                _ = ifline;
                actions[branch] = .{
                    .write = 0,
                    .right = true,
                    .next = 0,
                };
                // "- Write the value N."
                const wline = trim(u8, lines.next().?, " \r");
                actions[branch].write = @intCast(wline[wline.len - 2] - '0');
                // "- Move one slot to the left/right."
                const mline = trim(u8, lines.next().?, " \r");
                actions[branch].right = std.mem.endsWith(u8, mline, "right.");
                // "- Continue with state X."
                const cline = trim(u8, lines.next().?, " \r");
                actions[branch].next = cline[cline.len - 2] - 'A';
            }
            states[sid] = .{ .on0 = actions[0], .on1 = actions[1] };
        }
    }

    // run
    var tape = Map(i64, u8).init(gpa);
    defer tape.deinit();
    var pos: i64 = 0;
    var state: u8 = start_state;
    var step: u64 = 0;
    while (step < steps) : (step += 1) {
        const cur = tape.get(pos) orelse 0;
        const action = if (cur == 0) states[state].on0 else states[state].on1;
        try tape.put(pos, action.write);
        pos += if (action.right) 1 else -1;
        state = action.next;
    }

    var checksum: u64 = 0;
    var vit = tape.valueIterator();
    while (vit.next()) |v| {
        checksum += v.*;
    }
    print("part 1: {d}\n", .{checksum});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
