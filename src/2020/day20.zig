const std = @import("std");
const List = std.ArrayList;
const Map = std.AutoHashMap;
const util = @import("util");
const gpa = util.gpa;


const data = @embedFile("data/day20.txt");

const tile_size = 10;

const Tile = struct {
    id: u64,
    grid: [tile_size][tile_size]u8,

    fn edge(self: *const Tile, side: u8) u32 {
        // side: 0=top, 1=right, 2=bottom, 3=left (as read)
        var v: u32 = 0;
        for (0..tile_size) |i| {
            v <<= 1;
            const c: u8 = switch (side) {
                0 => self.grid[0][i],
                1 => self.grid[i][tile_size - 1],
                2 => self.grid[tile_size - 1][i],
                else => self.grid[i][0],
            };
            if (c == '#') v |= 1;
        }
        return v;
    }

    fn rot90(self: *const Tile) Tile {
        var t = Tile{ .id = self.id, .grid = @splat(@splat('.')) };
        for (0..tile_size) |y| {
            for (0..tile_size) |x| {
                t.grid[x][tile_size - 1 - y] = self.grid[y][x];
            }
        }
        return t;
    }

    fn flipH(self: *const Tile) Tile {
        var t = Tile{ .id = self.id, .grid = @splat(@splat('.')) };
        for (0..tile_size) |y| {
            for (0..tile_size) |x| {
                t.grid[y][tile_size - 1 - x] = self.grid[y][x];
            }
        }
        return t;
    }
};

fn reverseBits10(v: u32) u32 {
    var r: u32 = 0;
    for (0..10) |i| {
        r = (r << 1) | ((v >> @intCast(i)) & 1);
    }
    return r;
}

fn canonEdge(v: u32) u32 {
    return @min(v, reverseBits10(v));
}

var tiles: List(Tile) = .empty;

pub fn main() !void {
    // parse tiles
    {
        var lines = tokenizeAny(u8, data, "\n");
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "Tile")) {
                const id = try parseInt(u64, line[5 .. line.len - 1], 10);
                var t = Tile{ .id = id, .grid = @splat(@splat('.')) };
                for (0..tile_size) |y| {
                    const l = lines.next().?;
                    @memcpy(t.grid[y][0..tile_size], l);
                }
                try tiles.append(gpa, t);
            }
        }
    }

    const n = tiles.items.len;
    const side: usize = @intFromFloat(@sqrt(@as(f64, @floatFromInt(n))));

    // edge -> count of tiles having it
    var edge_count = Map(u32, u32).init(gpa);
    defer edge_count.deinit();
    for (tiles.items) |*t| {
        var seen_edges: [4]u32 = undefined;
        for (0..4) |s| {
            const e = t.edge(@intCast(s));
            const c = canonEdge(e);
            seen_edges[s] = c;
        }
        for (seen_edges) |e| {
            const gop = try edge_count.getOrPut(e);
            if (!gop.found_existing) gop.value_ptr.* = 0;
            gop.value_ptr.* += 1;
        }
    }

    // part 1: corners = tiles with 2 unique edges
    var product: u64 = 1;
    for (tiles.items) |*t| {
        var unique: u32 = 0;
        for (0..4) |s| {
            const c = canonEdge(t.edge(@intCast(s)));
            if (edge_count.get(c).? == 1) unique += 1;
        }
        if (unique == 2) product *= t.id;
    }
    print("part 1: {d}\n", .{product});

    // part 2: assemble
    // variants of each tile (8 orientations)
    var variants = try gpa.alloc([]Tile, n);
    for (variants, 0..) |*v, i| {
        v.* = try gpa.alloc(Tile, 8);
        v.*[0] = tiles.items[i];
        v.*[1] = tiles.items[i].rot90();
        v.*[2] = v.*[1].rot90();
        v.*[3] = v.*[2].rot90();
        v.*[4] = tiles.items[i].flipH();
        v.*[5] = v.*[1].flipH();
        v.*[6] = v.*[2].flipH();
        v.*[7] = v.*[3].flipH();
    }
    var used = try gpa.alloc(bool, n);
    defer gpa.free(used);
    @memset(used, false);

    // assembled[grid position] = variant index into variants[tile]
    var placed = try gpa.alloc(?struct { tile: usize, variant: usize }, side * side);
    defer gpa.free(placed);
    for (placed) |*p| p.* = null;

    // find a corner variant whose right and bottom edges are non-unique
    // (i.e., matching neighbors) — place it top-left
    outer: for (variants, 0..) |vs, ti| {
        for (vs, 0..) |v, vi| {
            const top_e = canonEdge(v.edge(0));
            const left_e = canonEdge(v.edge(3));
            const right = canonEdge(v.edge(1));
            const bottom = canonEdge(v.edge(2));
            // a real corner: top/left unique, right/bottom shared
            if (edge_count.get(top_e).? == 1 and edge_count.get(left_e).? == 1 and
                edge_count.get(right).? >= 2 and edge_count.get(bottom).? >= 2)
            {
                placed[0] = .{ .tile = ti, .variant = vi };
                used[ti] = true;
                break :outer;
            }
        }
    }

    // fill row-major: match left neighbor's right edge and top neighbor's bottom edge
    var idx: usize = 0;
    while (idx < side * side) : (idx += 1) {
        if (placed[idx] != null) continue;
        const gx = idx % side;
        const gy = idx / side;

        var need_left: ?u32 = null;
        var need_top: ?u32 = null;
        if (gx > 0) {
            const left = placed[idx - 1].?;
            need_left = variants[left.tile][left.variant].edge(1); // raw right edge
        }
        if (gy > 0) {
            const top = placed[idx - side].?;
            need_top = variants[top.tile][top.variant].edge(2); // raw bottom edge
        }

        search: for (variants, 0..) |vs, ti| {
            if (used[ti]) continue;
            for (vs, 0..) |v, vi| {
                if (need_left) |nl| {
                    if (v.edge(3) != nl) continue;
                }
                if (need_top) |nt| {
                    if (v.edge(0) != nt) continue;
                }
                placed[idx] = .{ .tile = ti, .variant = vi };
                used[ti] = true;
                break :search;
            }
        }
    }

    // build the image (strip tile borders)
    const iw = side * (tile_size - 2);
    var img = try gpa.alloc([]u8, iw);
    defer {
        for (img) |r| gpa.free(r);
        gpa.free(img);
    }
    for (img) |*r| r.* = try gpa.alloc(u8, iw);

    for (0..side) |ty| {
        for (0..side) |tx| {
            const p = placed[ty * side + tx].?;
            const v = &variants[p.tile][p.variant];
            for (1..tile_size - 1) |y| {
                for (1..tile_size - 1) |x| {
                    img[ty * (tile_size - 2) + (y - 1)][tx * (tile_size - 2) + (x - 1)] = v.grid[y][x];
                }
            }
        }
    }

    // sea monster pattern (3 rows)
    const monster = [_][]const u8{
        "                  # ",
        "#    ##    ##    ###",
        " #  #  #  #  #  #   ",
    };

    // try all 8 orientations of the image, count monsters
    var best_monsters: usize = 0;
    var hash_total: usize = 0;
    for (img) |r| {
        for (r) |c| {
            if (c == '#') hash_total += 1;
        }
    }

    var img_variants: [8][][]u8 = undefined;
    img_variants[0] = img;
    for (1..4) |k| img_variants[k] = try rotateImg(img_variants[k - 1], iw);
    img_variants[4] = try flipImg(img, iw);
    for (5..8) |k| img_variants[k] = try rotateImg(img_variants[k - 1], iw);

    for (img_variants) |iv| {
        var count: usize = 0;
        for (1..iw - 1) |y| {
            for (0..iw - 20) |x| {
                var ok = true;
                for (monster, 0..) |mrow, my| {
                    for (mrow, 0..) |mc, mx| {
                        if (mc == '#' and iv[y + my - 1][x + mx] != '#') {
                            ok = false;
                            break;
                        }
                    }
                    if (!ok) break;
                }
                if (ok) count += 1;
            }
        }
        best_monsters = @max(best_monsters, count);
    }

    print("part 2: {d}\n", .{hash_total - best_monsters * 15});
}

fn rotateImg(src: [][]u8, size: usize) ![][]u8 {
    var dst = try gpa.alloc([]u8, size);
    for (dst) |*r| r.* = try gpa.alloc(u8, size);
    for (0..size) |y| {
        for (0..size) |x| {
            dst[x][size - 1 - y] = src[y][x];
        }
    }
    return dst;
}

fn flipImg(src: [][]u8, size: usize) ![][]u8 {
    var dst = try gpa.alloc([]u8, size);
    for (dst) |*r| r.* = try gpa.alloc(u8, size);
    for (0..size) |y| {
        for (0..size) |x| {
            dst[y][size - 1 - x] = src[y][x];
        }
    }
    return dst;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
