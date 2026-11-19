const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");

// const zom = @import("zom");

const data = @embedFile("data/day25.txt");

var vm: intcode.VM = undefined;
var consumed: usize = 0;

/// Items that kill/teleport/lock the droid — never take these.
const traps = [_][]const u8{
    "giant electromagnet",
    "infinite loop",
    "molten lava",
    "escape pod",
    "photonic cluster",
    "photons",
};

fn isTrap(item: []const u8) bool {
    for (traps) |t| {
        if (std.mem.eql(u8, t, item)) return true;
    }
    return false;
}

/// Read pending output (runs the VM until it wants input).
fn readResponse() ![]u8 {
    while (!vm.halted) {
        const r = try vm.step();
        if (r == .need_input) break;
    }
    var buf: List(u8) = .empty;
    for (vm.outputs.items[consumed..]) |v| {
        try buf.append(gpa, @intCast(v));
    }
    consumed = vm.outputs.items.len;
    return buf.items;
}

/// Send a command; returns the response text.
fn command(cmd: []const u8) ![]u8 {
    for (cmd) |c| try vm.addInput(c);
    try vm.addInput('\n');
    return readResponse();
}

const Room = struct {
    name: []const u8,
    doors: List([]const u8) = .empty,
    visited: bool = false,
};

var guarded_room: ?[]const u8 = null;
var guarded_dir: []const u8 = "north";

var rooms = StrMap(*Room).init(std.heap.page_allocator);
var inventory: List([]const u8) = .empty;
/// "fromRoom|door" -> "toRoom"
var edges = StrMap([]const u8).init(std.heap.page_allocator);

fn parseRoom(text: []const u8) !?*Room {
    // "== Name =="
    const marker = "== ";
    if (std.mem.indexOf(u8, text, marker)) |i| {
        const rest = text[i + 3 ..];
        const end = std.mem.indexOf(u8, rest, " ==") orelse return null;
        const name = try std.heap.page_allocator.dupe(u8, rest[0..end]);
        const gop = try rooms.getOrPut(name);
        if (!gop.found_existing) {
            const room = try std.heap.page_allocator.create(Room);
            room.* = .{ .name = name };
            gop.value_ptr.* = room;
        }
        // parse doors and items
        var lines = std.mem.splitScalar(u8, text, '\n');
        var in_doors = false;
        var in_items = false;
        while (lines.next()) |line| {
            const t = trim(u8, line, " \r");
            if (std.mem.startsWith(u8, t, "Doors here lead:")) {
                in_doors = true;
                in_items = false;
                continue;
            } else if (std.mem.startsWith(u8, t, "Items here:")) {
                in_items = true;
                in_doors = false;
                continue;
            } else if (std.mem.startsWith(u8, t, "- ")) {
                const item_or_door = t[2..];
                if (in_doors) {
                    const d = try std.heap.page_allocator.dupe(u8, item_or_door);
                    var have = false;
                    for (gop.value_ptr.*.doors.items) |ex| {
                        if (std.mem.eql(u8, ex, d)) have = true;
                    }
                    if (!have) try gop.value_ptr.*.doors.append(std.heap.page_allocator, d);
                } else if (in_items) {
                    // item pickup decisions are handled by the caller
                    // (itemsHere parses the same list)
                }
            } else {
                if (t.len > 0 and !std.mem.startsWith(u8, t, "-")) {
                    in_doors = false;
                    in_items = false;
                }
            }
        }
        return gop.value_ptr.*;
    }
    return null;
}

/// Items listed in the current response text.
fn itemsHere(text: []const u8) !List([]const u8) {
    var items: List([]const u8) = .empty;
    var lines = std.mem.splitScalar(u8, text, '\n');
    var in_items = false;
    while (lines.next()) |line| {
        const t = trim(u8, line, " \r");
        if (std.mem.startsWith(u8, t, "Items here:")) {
            in_items = true;
            continue;
        }
        if (in_items) {
            if (std.mem.startsWith(u8, t, "- ")) {
                try items.append(std.heap.page_allocator, t[2..]);
            } else if (t.len > 0) {
                in_items = false;
            }
        }
    }
    return items;
}

fn opposite(dir: []const u8) []const u8 {
    if (std.mem.eql(u8, dir, "north")) return "south";
    if (std.mem.eql(u8, dir, "south")) return "north";
    if (std.mem.eql(u8, dir, "east")) return "west";
    if (std.mem.eql(u8, dir, "west")) return "east";
    return dir;
}

/// Doors that terminate the droid program (the pressure floor among them).
var halting_doors = StrMap(void).init(std.heap.page_allocator);

pub fn main() !void {
    var attempt: usize = 0;
    while (attempt < 6) : (attempt += 1) {
        const done = try runOnce();
        if (done) return;
        // otherwise a new halting door was recorded; retry on a fresh VM
    }
    print("gave up after repeated halts\n", .{});
}

fn runOnce() !bool {
    vm = try intcode.VM.initSource(gpa, data);
    defer vm.deinit();
    rooms = StrMap(*Room).init(std.heap.page_allocator);
    edges = StrMap([]const u8).init(std.heap.page_allocator);
    inventory = .empty;
    guarded_room = null;
    guarded_dir = "north";
    consumed = 0;

    // first response: intro + start room
    const text = try readResponse();
    var room = (try parseRoom(text)).?;
    room.visited = true;

    // collect items at start
    {
        const items = try itemsHere(text);
        for (items.items) |item| {
            if (!isTrap(item)) {
                _ = try command(try std.fmt.allocPrint(gpa, "take {s}", .{item}));
                try inventory.append(gpa, item);
            }
        }
    }

    // explore: try every (room, door) pair once; enter new rooms, step back
    // from known ones; backtrack to parent when a room is exhausted.
    {
        var tried = StrMap(void).init(std.heap.page_allocator);
        defer tried.deinit();
        var visited = StrMap(void).init(std.heap.page_allocator);
        defer visited.deinit();
        try visited.put(room.name, {});
        var path: List([]const u8) = .empty;
        defer path.deinit(std.heap.page_allocator);
        var guard2: usize = 0;
        outer: while (guard2 < 500) : (guard2 += 1) {
            doors: for (room.doors.items) |d| {
                const key = try std.fmt.allocPrint(std.heap.page_allocator, "{s}|{s}", .{ room.name, d });
                if (tried.contains(key)) continue :doors;
                try tried.put(key, {});
                if (halting_doors.contains(key)) continue :doors;
                const resp = try command(d);
                if (vm.halted) {
                    try halting_doors.put(key, {});
                    return false; // retry with this door banned
                }
                if (try parseRoom(resp)) |nr| {
                    // entering the pressure floor with the wrong weight bounces
                    // you back (the response still shows the room header) —
                    // treat it as a guarded door and restart with it banned
                    if (std.mem.indexOf(u8, nr.name, "Pressure-Sensitive") != null) {
                        const gkey = try std.fmt.allocPrint(std.heap.page_allocator, "{s}|{s}", .{ room.name, d });
                        try halting_doors.put(gkey, {});
                        return false;
                    }
                    const ekey = try std.fmt.allocPrint(std.heap.page_allocator, "{s}|{s}", .{ room.name, d });
                    try edges.put(ekey, nr.name);
                    if (!visited.contains(nr.name)) {
                        try visited.put(nr.name, {});
                        room = nr;
                        try path.append(std.heap.page_allocator, d);
                        // grab any safe items in the new room
                        const items = try itemsHere(resp);
                        for (items.items) |item| {
                            if (!isTrap(item)) {
                                _ = try command(try std.fmt.allocPrint(gpa, "take {s}", .{item}));
                                try inventory.append(gpa, item);
                            }
                        }
                        continue :outer;
                    }
                    // known room: step back
                    _ = try command(opposite(d));
                    continue :doors;
                }
                // bounce (pressure floor) — remember it; try next door
                if (guarded_room == null) {
                    guarded_room = room.name;
                    guarded_dir = try std.heap.page_allocator.dupe(u8, d);
                }
                continue :doors;
            }
            // exhausted this room: backtrack (or finish at the start)
            if (path.items.len == 0) break;
            const back = path.pop() orelse break;
            const resp = try command(opposite(back));
            if (try parseRoom(resp)) |nr| room = nr;
        }
    }

    // walk to the security checkpoint
    // (cheap approach: repeat the exploration from any room until there)
    // the guarded door: either seen as a live bounce or known from a halt
    if (guarded_room == null) {
        var hit = halting_doors.keyIterator();
        while (hit.next()) |k| {
            const sep = std.mem.indexOfScalar(u8, k.*, '|') orelse continue;
            guarded_room = k.*[0..sep];
            guarded_dir = k.*[sep + 1 ..];
        }
    }
    var checkpoint: ?*Room = null;
    if (guarded_room) |gr| {
        if (rooms.get(gr)) |r| checkpoint = r;
    }

    if (checkpoint == null) {
        print("no guarded door found; rooms:\n", .{});
        var it = rooms.keyIterator();
        while (it.next()) |k| print("  {s}\n", .{k.*});
        return true;
    }

    // BFS over the recorded edge graph, then walk the path
    {
        var prev_room = StrMap([]const u8).init(std.heap.page_allocator); // room -> door taken to reach it
        defer prev_room.deinit();
        var q: List([]const u8) = .empty;
        defer q.deinit(std.heap.page_allocator);
        try prev_room.put(room.name, "");
        try q.append(std.heap.page_allocator, room.name);
        var head: usize = 0;
        while (head < q.items.len) : (head += 1) {
            const cur = q.items[head];
            if (std.mem.eql(u8, cur, checkpoint.?.name)) break;
            var eit = edges.iterator();
            while (eit.next()) |e| {
                const key = e.key_ptr.*;
                const sep = std.mem.indexOfScalar(u8, key, '|').?;
                const from = key[0..sep];
                if (!std.mem.eql(u8, from, cur)) continue;
                const to = e.value_ptr.*;
                if (prev_room.contains(to)) continue;
                try prev_room.put(to, key[sep + 1 ..]);
                try q.append(std.heap.page_allocator, to);
            }
        }
        if (!prev_room.contains(checkpoint.?.name)) {
            print("checkpoint unreachable in known graph\n", .{});
            return true;
        }
        // reconstruct path (rooms from checkpoint back to start)
        var rev: List([]const u8) = .empty;
        defer rev.deinit(std.heap.page_allocator);
        var cur_name = checkpoint.?.name;
        while (!std.mem.eql(u8, cur_name, room.name)) {
            const door = prev_room.get(cur_name) orelse break;
            if (door.len == 0) break;
            try rev.append(std.heap.page_allocator, door);
            const ekey = try std.fmt.allocPrint(std.heap.page_allocator, "{s}|{s}", .{ cur_name, "" });
            _ = ekey;
            // find predecessor: search edges whose target is cur_name and door matches
            var pit = edges.iterator();
            while (pit.next()) |e| {
                if (std.mem.eql(u8, e.value_ptr.*, cur_name)) {
                    const key = e.key_ptr.*;
                    const sep = std.mem.indexOfScalar(u8, key, '|').?;
                    if (std.mem.eql(u8, key[sep + 1 ..], door)) {
                        cur_name = key[0..sep];
                        break;
                    }
                }
            }
        }
        // walk (reverse order)
        var i: usize = rev.items.len;
        while (i > 0) {
            i -= 1;
            const resp = try command(rev.items[i]);
            if (try parseRoom(resp)) |nr| room = nr;
        }
    }

    // drop everything
    for (inventory.items) |item| {
        _ = try command(try std.fmt.allocPrint(gpa, "drop {s}", .{item}));
    }

    // subset search: try carrying each subset (singles first)
    const n = inventory.items.len;
    if (n > 12) {
        print("too many items ({d})\n", .{n});
        return true;
    }
    var mask: u32 = 0;
    while (mask < (@as(u32, 1) << @intCast(n))) : (mask += 1) {
        // carry subset `mask`
        var sub: List([]const u8) = .empty;
        for (0..n) |i| {
            if ((mask >> @intCast(i)) & 1 == 1) try sub.append(std.heap.page_allocator, inventory.items[i]);
        }
        for (sub.items) |item| {
            _ = try command(try std.fmt.allocPrint(gpa, "take {s}", .{item}));
        }
        const resp = try command(guarded_dir);
        // success: response contains a big number (the code)
        if (std.mem.indexOf(u8, resp, "Alert") == null) {
            // extract number >= 1000
            var i: usize = 0;
            while (i < resp.len) : (i += 1) {
                if (resp[i] >= '0' and resp[i] <= '9') {
                    var j = i;
                    while (j < resp.len and resp[j] >= '0' and resp[j] <= '9') j += 1;
                    if (j - i >= 4) {
                        const num = resp[i..j];
                        print("part 1: {s}\n", .{num});
                        return true;
                    }
                    i = j;
                }
            }
            // no number found — print the text for manual inspection
            print("passed the floor but no code found:\n{s}\n", .{resp});
            return true;
        }
        for (sub.items) |item| {
            _ = try command(try std.fmt.allocPrint(gpa, "drop {s}", .{item}));
        }
    }
    print("no passing subset found\n", .{});
    return true;
}

// Useful stdlib functions
const indexOf = std.mem.findScalar;
const trim = std.mem.trim;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
