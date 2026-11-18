const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day20.txt");

const Mod = struct {
    kind: u8, // '%' flipflop, '&' conj, 'b' broadcast
    outputs: List([]const u8) = .empty,
    on: bool = false, // flipflop state
    last: StrMap(u8) = undefined, // conj: last pulse per input
};

var mods = StrMap(*Mod).init(std.heap.page_allocator);

const Pulse = struct { from: []const u8, to: []const u8, high: bool };

fn pressButton(counters: ?*[2]u64) !void {
    var q: List(Pulse) = .empty;
    defer q.deinit(gpa);
    try q.append(gpa, .{ .from = "button", .to = "broadcaster", .high = false });
    var head: usize = 0;
    while (head < q.items.len) : (head += 1) {
        const p = q.items[head];
        if (counters) |c| {
            if (p.high) c[0] += 1 else c[1] += 1;
        }
        const m = mods.get(p.to) orelse continue;
        var out_high: ?bool = null;
        switch (m.kind) {
            'b' => out_high = p.high,
            '%' => {
                if (!p.high) {
                    m.on = !m.on;
                    out_high = m.on;
                }
            },
            '&' => {
                m.last.put(p.from, @intFromBool(p.high)) catch {};
                var all_high = true;
                var it = m.last.valueIterator();
                while (it.next()) |v| {
                    if (v.* == 0) all_high = false;
                }
                out_high = !all_high;
            },
            else => {},
        }
        if (out_high) |oh| {
            for (m.outputs.items) |o| {
                try q.append(gpa, .{ .from = p.to, .to = o, .high = oh });
            }
        }
    }
}

pub fn main() !void {
    // parse
    {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            // "%fh -> a, b, c"
            const arrow = std.mem.indexOf(u8, line, " -> ").?;
            var name_raw = line[0..arrow];
            var kind: u8 = 'b';
            if (name_raw[0] == '%' or name_raw[0] == '&') {
                kind = name_raw[0];
                name_raw = name_raw[1..];
            }
            const name = try std.heap.page_allocator.dupe(u8, name_raw);
            const m = try std.heap.page_allocator.create(Mod);
            m.* = .{ .kind = kind };
            var it = tokenizeAny(u8, line[arrow + 4 ..], ", ");
            while (it.next()) |o| {
                try m.outputs.append(std.heap.page_allocator, try std.heap.page_allocator.dupe(u8, o));
            }
            if (kind == '&') {
                m.last = StrMap(u8).init(std.heap.page_allocator);
            }
            try mods.put(name, m);
        }
    }
    // init conj inputs
    {
        var it = mods.iterator();
        while (it.next()) |e| {
            const m = e.value_ptr.*;
            if (m.kind != '&') continue;
            var it2 = mods.iterator();
            while (it2.next()) |e2| {
                for (e2.value_ptr.*.outputs.items) |o| {
                    if (std.mem.eql(u8, o, e.key_ptr.*)) {
                        try m.last.put(e2.key_ptr.*, 0);
                    }
                }
            }
        }
    }

    // part 1: 1000 presses
    var counters = [2]u64{ 0, 0 };
    for (0..1000) |_| {
        try pressButton(&counters);
    }
    print("part 1: {d}\n", .{counters[0] * counters[1]});

    // part 2: find rx — its (single) conj source must send LOW; each of ITS
    // inputs must go HIGH; find each input's cycle length by re-pressing
    // find the conj feeding rx
    var rx_source: []const u8 = "";
    {
        var it = mods.iterator();
        while (it.next()) |e| {
            for (e.value_ptr.*.outputs.items) |o| {
                if (std.mem.eql(u8, o, "rx")) rx_source = e.key_ptr.*;
            }
        }
    }
    const rx_src = mods.get(rx_source).?;
    // track when each input of rx_src sends a HIGH pulse
    var cycles = StrMap(u64).init(gpa);
    defer cycles.deinit();
    var presses: u64 = 0;
    outer: while (presses < 100000) : (presses += 1) {
        var q: List(Pulse) = .empty;
        defer q.deinit(gpa);
        try q.append(gpa, .{ .from = "button", .to = "broadcaster", .high = false });
        var head: usize = 0;
        while (head < q.items.len) : (head += 1) {
            const p = q.items[head];
            if (std.mem.eql(u8, p.to, rx_source) and p.high) {
                if (!cycles.contains(p.from)) {
                    try cycles.put(p.from, presses + 1);
                    if (cycles.count() == rx_src.last.count()) {
                        break :outer;
                    }
                }
            }
            const m = mods.get(p.to) orelse continue;
            var out_high: ?bool = null;
            switch (m.kind) {
                'b' => out_high = p.high,
                '%' => {
                    if (!p.high) {
                        m.on = !m.on;
                        out_high = m.on;
                    }
                },
                '&' => {
                    m.last.put(p.from, @intFromBool(p.high)) catch {};
                    var all_high = true;
                    var it = m.last.valueIterator();
                    while (it.next()) |v| {
                        if (v.* == 0) all_high = false;
                    }
                    out_high = !all_high;
                },
                else => {},
            }
            if (out_high) |oh| {
                for (m.outputs.items) |o| {
                    try q.append(gpa, .{ .from = p.to, .to = o, .high = oh });
                }
            }
        }
    }

    var lcm: u64 = 1;
    var cit = cycles.valueIterator();
    while (cit.next()) |c| {
        const g = std.math.gcd(lcm, c.*);
        lcm = lcm / g * c.*;
    }
    print("part 2: {d}\n", .{lcm});
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
