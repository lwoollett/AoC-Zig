const std = @import("std");
const Allocator = std.mem.Allocator;
const util = @import("util");
const gpa = util.gpa;
const intcode = @import("intcode");

// const zom = @import("zom");

const data = @embedFile("data/day02.txt");

fn runWith(alloc: std.mem.Allocator, src: []const u8, noun: i64, verb: i64) !i64 {
    var vm = try intcode.VM.initSource(alloc, src);
    defer vm.deinit();
    try vm.write(1, noun);
    try vm.write(2, verb);
    _ = try vm.run();
    return vm.mem.items[0];
}

/// The noun/verb sweep is 10k independent vm runs — claim nouns across threads.
const Sweep = struct {
    next: std.atomic.Value(u64) = .init(0),
    result: std.atomic.Value(i64) = .init(-1),

    fn worker(self: *Sweep) void {
        // one arena per worker, reset per run — 10k vm allocations on the
        // raw page allocator would mmap-storm
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        while (self.result.load(.acquire) == -1) {
            const noun = self.next.fetchAdd(1, .acq_rel);
            if (noun >= 100) return;
            var verb: i64 = 0;
            while (verb < 100) : (verb += 1) {
                _ = arena.reset(.retain_capacity);
                const out = runWith(arena.allocator(), data, @intCast(noun), verb) catch continue;
                if (out == 19690720) {
                    self.result.store(100 * @as(i64, @intCast(noun)) + verb, .release);
                    return;
                }
            }
        }
    }
};

pub fn main() !void {
    const p1 = try runWith(gpa, data, 12, 2);
    print("part 1: {d}\n", .{p1});

    var sweep = Sweep{};
    const n_threads = try std.Thread.getCpuCount();
    var threads = try std.ArrayList(std.Thread).initCapacity(gpa, n_threads);
    defer threads.deinit(gpa);
    for (0..n_threads) |_| {
        try threads.append(gpa, try std.Thread.spawn(.{}, Sweep.worker, .{&sweep}));
    }
    for (threads.items) |t| t.join();
    print("part 2: {d}\n", .{sweep.result.load(.acquire)});
}

// Useful stdlib functions

const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
