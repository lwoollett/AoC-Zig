const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day19.txt");

/// Ring-buffer deque.
const Deque = struct {
    buf: []u64,
    head: usize = 0,
    count: usize = 0,

    fn init(alloc: std.mem.Allocator, capacity: usize) !Deque {
        return .{ .buf = try alloc.alloc(u64, capacity + 1) };
    }
    fn len(self: *const Deque) usize {
        return self.count;
    }
    fn pushBack(self: *Deque, v: u64) void {
        const tail = (self.head + self.count) % self.buf.len;
        self.buf[tail] = v;
        self.count += 1;
    }
    fn pushFront(self: *Deque, v: u64) void {
        self.head = (self.head + self.buf.len - 1) % self.buf.len;
        self.buf[self.head] = v;
        self.count += 1;
    }
    fn popFront(self: *Deque) u64 {
        const v = self.buf[self.head];
        self.head = (self.head + 1) % self.buf.len;
        self.count -= 1;
        return v;
    }
    fn popBack(self: *Deque) u64 {
        self.count -= 1;
        const v = self.buf[(self.head + self.count) % self.buf.len];
        return v;
    }
    fn front(self: *const Deque) u64 {
        return self.buf[self.head];
    }
};

/// O(n) two-deque simulation: current elf keeps the queue of the others
/// split so the elf directly across is right's front.
fn whiteElephant(n: u64) !u64 {
    var left = try Deque.init(gpa, n);
    var right = try Deque.init(gpa, n);
    defer gpa.free(left.buf);
    defer gpa.free(right.buf);

    // q = [2, 3, ..., n]; across = q[n/2 - 1]
    var i: u64 = 2;
    while (i <= n) : (i += 1) {
        if (i <= n / 2) {
            left.pushBack(i);
        } else {
            right.pushBack(i);
        }
    }
    // left should hold exactly k/2 - 1 elements: adjust
    while (left.len() > 0 and left.len() >= right.len() + 1) {
        right.pushFront(left.popBack());
    }

    var current: u64 = 1;
    var k: u64 = n;
    while (k > 1) {
        _ = right.popFront(); // the across elf is eliminated
        right.pushBack(current); // old current rejoins the queue tail
        if (left.len() > 0) {
            current = left.popFront();
        } else {
            current = right.popFront();
        }
        k -= 1;
        // rebalance: across sits at q[k/2 - 1]
        while (left.len() > 0 and left.len() > k / 2 -| 1) {
            right.pushFront(left.popBack());
        }
        while (left.len() < k / 2 -| 1 and right.len() > 1) {
            left.pushBack(right.popFront());
        }
    }
    return current;
}

/// O(n^2) brute force for verification on small n.
fn bruteForce(n: u64) !u64 {
    var circle: List(u64) = .empty;
    defer circle.deinit(gpa);
    var j: u64 = 1;
    while (j <= n) : (j += 1) {
        try circle.append(gpa, j);
    }
    var cur: usize = 0;
    while (circle.items.len > 1) {
        const across = (cur + circle.items.len / 2) % circle.items.len;
        const victim_before_cur = across < cur;
        _ = circle.orderedRemove(across);
        // the stealing elf's turn ends; play continues with the next elf
        // that still has presents.
        cur = if (victim_before_cur) cur % circle.items.len else (cur + 1) % circle.items.len;
    }
    return circle.items[0];
}

pub fn main() !void {
    const n = try parseInt(u64, trim(u8, data, " \n\r\t"), 10);

    // sanity: the deque algorithm must match brute force on small circles
    var v: u64 = 2;
    while (v <= 30) : (v += 1) {
        const a = try whiteElephant(v);
        const b = try bruteForce(v);
        if (a != b) {
            print("deque {d} != brute {d} at n={d}\n", .{ a, b, v });
            return error.VerificationFailed;
        }
    }

    // Part 1: classic Josephus (steal from the next elf): n = 2^m + l -> 2l+1.
    var l = n;
    var p: u64 = 1;
    while (p * 2 <= l) p *= 2;
    l = n - p;
    print("part 1: {d}\n", .{2 * l + 1});

    print("part 2: {d}\n", .{try whiteElephant(n)});
}

// Useful stdlib functions
const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
