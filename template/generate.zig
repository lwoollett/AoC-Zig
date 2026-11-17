const std = @import("std");

// Keep in sync with build.zig.
const first_year = 2015;
const last_year = 2026;

const days_per_year = 25;
const year_count = last_year - first_year + 1;
const max_size: usize = 100_000_000;
const hashes_file = "template/hashes.bin";
const test_all_gen_file = "src/test_all.gen.zig";

var gpa_impl: std.heap.DebugAllocator(.{}) = .init;
const gpa = gpa_impl.allocator();

const Hash = std.crypto.hash.Md5;

fn instantiateTemplate(alloc: std.mem.Allocator, template: []const u8, day: u32) ![]u8 {
    var list: std.ArrayList(u8) = .empty;
    errdefer list.deinit(alloc);

    var day_buf: [2]u8 = undefined;
    const day_str = std.fmt.bufPrint(&day_buf, "{d:0>2}", .{day}) catch unreachable;

    try list.ensureTotalCapacity(alloc, @intCast(template.len + template.len / 8 + 8));
    var rest = template;
    while (std.mem.indexOfScalar(u8, rest, '$')) |index| {
        try list.appendSlice(alloc, rest[0..index]);
        try list.appendSlice(alloc, day_str);
        rest = rest[index + 1 ..];
    }
    try list.appendSlice(alloc, rest);
    return list.toOwnedSlice(alloc);
}

fn hashIndex(year: u32, day: u32) usize {
    return (@as(usize, year - first_year) * days_per_year + (day - 1)) * Hash.digest_length;
}

const Hashes = struct {
    bytes: []u8, // year_count * 25 * digest_length, zeroed = "assume modified"

    fn get(self: Hashes, year: u32, day: u32) *const [Hash.digest_length]u8 {
        const i = hashIndex(year, day);
        return self.bytes[i..][0..Hash.digest_length];
    }

    fn set(self: Hashes, year: u32, day: u32, hash: *const [Hash.digest_length]u8) void {
        const i = hashIndex(year, day);
        @memcpy(self.bytes[i..][0..Hash.digest_length], hash);
    }
};

fn readHashes(io: std.Io) !Hashes {
    const expected_len = year_count * days_per_year * Hash.digest_length;
    const bytes = std.Io.Dir.cwd().readFileAlloc(
        io,
        hashes_file,
        gpa,
        // The limit is inclusive ("reached or exceeded" errors), so allow
        // one extra byte and validate the exact length below.
        .limited(expected_len + 1),
    ) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print(
                "{s} doesn't exist, will assume all files have been modified.\n" ++
                    "Delete src/<year>/dayXX.zig and rerun `zig build generate` to regenerate it.\n",
                .{hashes_file},
            );
            const mem = try gpa.alloc(u8, expected_len);
            @memset(mem, 0);
            return .{ .bytes = mem };
        },
        error.FileTooBig => return error.InvalidFormat,
        else => |e| return e,
    };
    if (bytes.len != expected_len) return error.InvalidFormat;
    return .{ .bytes = bytes };
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    const template = try cwd.readFileAlloc(io, "template/template.zig", gpa, .limited(max_size));

    const hashes: Hashes = readHashes(io) catch |err| switch (err) {
        error.InvalidFormat => {
            std.debug.print(
                "{s} is corrupted, delete it to silence this warning and assume all days have been modified.\n",
                .{hashes_file},
            );
            return error.InvalidFormat;
        },
        else => |e| {
            std.debug.print("Failed to open {s}: {}\n", .{ hashes_file, e });
            return e;
        },
    };

    var skipped_any = false;
    var updated_hashes = false;

    var year: u32 = first_year;
    while (year <= last_year) : (year += 1) {
        const year_str = try std.fmt.allocPrint(gpa, "{d}", .{year});
        defer gpa.free(year_str);

        // Keep the data/ directory present in git and on disk.
        const data_dir = try std.fmt.allocPrint(gpa, "src/{s}/data", .{year_str});
        defer gpa.free(data_dir);
        cwd.createDirPath(io, data_dir) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        const keep_file = try std.fmt.allocPrint(gpa, "src/{s}/data/keep_directory_in_git.txt", .{year_str});
        defer gpa.free(keep_file);
        if (cwd.access(io, keep_file, .{})) |_| {} else |_| {
            try cwd.writeFile(io, .{
                .sub_path = keep_file,
                .data = "Puzzle inputs live here as dayNN.txt files.\n",
            });
        }

        var day: u32 = 1;
        while (day <= days_per_year) : (day += 1) {
            const filename = try std.fmt.allocPrint(gpa, "src/{s}/day{d:0>2}.zig", .{ year_str, day });
            defer gpa.free(filename);

            const contents: ?[]u8 = cwd.readFileAlloc(io, filename, gpa, .limited(max_size)) catch |err| switch (err) {
                error.FileNotFound => null,
                error.StreamTooLong => blk: {
                    std.debug.print("Skipping modified day {s}\n", .{filename});
                    skipped_any = true;
                    break :blk null;
                },
                else => |e| return e,
            };
            defer if (contents) |c| gpa.free(c);

            const regenerate = if (contents) |c| blk: {
                var hash: [Hash.digest_length]u8 = undefined;
                Hash.hash(c, &hash, .{});
                break :blk std.mem.eql(u8, &hash, hashes.get(year, day));
            } else true;

            if (regenerate) {
                const text = try instantiateTemplate(gpa, template, day);
                defer gpa.free(text);

                var hash: [Hash.digest_length]u8 = undefined;
                Hash.hash(text, &hash, .{});
                hashes.set(year, day, &hash);
                updated_hashes = true;

                try cwd.writeFile(io, .{ .sub_path = filename, .data = text });
                if (contents == null) {
                    std.debug.print("Creating new file {s} from template.\n", .{filename});
                } else {
                    std.debug.print("Updated {s}\n", .{filename});
                }
            } else {
                std.debug.print("Skipping modified day {s}\n", .{filename});
                skipped_any = true;
            }
        }
    }

    // Regenerate src/test_all.gen.zig. Zig requires string LITERALS as
    // @import operands, so the aggregate import list cannot be built with
    // comptime path formatting — it must be emitted verbatim, one line per
    // day, and rewritten whenever the year range changes.
    {
        var out: std.ArrayList(u8) = .empty;
        errdefer out.deinit(gpa);
        try out.appendSlice(gpa, "// Generated by `zig build generate` — do not edit.\ntest {\n");
        var gen_year: u32 = first_year;
        while (gen_year <= last_year) : (gen_year += 1) {
            var gen_day: u32 = 1;
            while (gen_day <= days_per_year) : (gen_day += 1) {
                const line = try std.fmt.allocPrint(
                    gpa,
                    "    _ = @import(\"{d}/day{d:0>2}.zig\");\n",
                    .{ gen_year, gen_day },
                );
                defer gpa.free(line);
                try out.appendSlice(gpa, line);
            }
        }
        try out.appendSlice(gpa, "}\n");
        try cwd.writeFile(io, .{ .sub_path = test_all_gen_file, .data = out.items });
        out.deinit(gpa);
    }

    if (updated_hashes) {
        try cwd.writeFile(io, .{ .sub_path = hashes_file, .data = hashes.bytes });
        if (skipped_any) {
            std.debug.print("Some days were skipped. Delete them to force regeneration.\n", .{});
        }
    } else {
        std.debug.print("No updates made, all days were modified. Delete src/<year>/dayXX.zig to force regeneration.\n", .{});
    }
}
