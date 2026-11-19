const std = @import("std");
const List = std.ArrayList;
const StrMap = std.StringHashMap;
const util = @import("util");
const gpa = util.gpa;

// const zom = @import("zom");

const data = @embedFile("data/day21.txt");

const Food = struct {
    ingredients: [][]const u8,
    allergens: [][]const u8,
};

fn hasIngredient(food: Food, ing: []const u8) bool {
    for (food.ingredients) |i| {
        if (std.mem.eql(u8, i, ing)) return true;
    }
    return false;
}

pub fn main() !void {
    var foods: List(Food) = .empty;
    defer foods.deinit(gpa);

    var lines = tokenizeAny(u8, data, "\n");
    while (lines.next()) |line| {
        const paren = indexOf(u8, line, '(').?;
        var ings: List([]const u8) = .empty;
        var it = tokenizeSca(u8, line[0..paren], ' ');
        while (it.next()) |tok| {
            try ings.append(gpa, tok);
        }
        var alls: List([]const u8) = .empty;
        var it2 = tokenizeAny(u8, line[paren + 10 .. line.len - 1], ", ");
        while (it2.next()) |tok| {
            try alls.append(gpa, tok);
        }
        try foods.append(gpa, .{
            .ingredients = try ings.toOwnedSlice(gpa),
            .allergens = try alls.toOwnedSlice(gpa),
        });
    }

    // allergen -> possible ingredients (intersection over foods listing it)
    var possible = StrMap(*List([]const u8)).init(std.heap.page_allocator);
    var ait = foods.items;
    _ = &ait;
    for (foods.items) |food| {
        for (food.allergens) |all| {
            if (!possible.contains(all)) {
                const l = try std.heap.page_allocator.create(List([]const u8));
                l.* = .empty;
                try l.appendSlice(std.heap.page_allocator, food.ingredients);
                try possible.put(all, l);
            } else {
                // intersect
                const cur = possible.get(all).?;
                var kept: List([]const u8) = .empty;
                for (cur.items) |ing| {
                    if (hasIngredient(food, ing)) {
                        try kept.append(std.heap.page_allocator, ing);
                    }
                }
                const slot = possible.get(all).?;
                slot.deinit(std.heap.page_allocator);
                slot.* = kept;
            }
        }
    }

    // ingredients that could contain an allergen
    var maybe_allergen = StrMap(void).init(std.heap.page_allocator);
    var pit = possible.valueIterator();
    while (pit.next()) |list| {
        for (list.*.items) |ing| {
            try maybe_allergen.put(ing, {});
        }
    }

    // part 1: count appearances of non-allergen ingredients
    var count: u64 = 0;
    for (foods.items) |food| {
        for (food.ingredients) |ing| {
            if (!maybe_allergen.contains(ing)) count += 1;
        }
    }
    print("part 1: {d}\n", .{count});

    // part 2: eliminate
    var resolved = StrMap([]const u8).init(std.heap.page_allocator); // allergen -> ingredient
    var resolved_ings = StrMap(void).init(std.heap.page_allocator);
    var done = false;
    while (!done) {
        done = true;
        var it3 = possible.iterator();
        while (it3.next()) |e| {
            if (resolved.contains(e.key_ptr.*)) continue;
            var candidates: List([]const u8) = .empty;
            for (e.value_ptr.*.items) |ing| {
                if (!resolved_ings.contains(ing)) {
                    try candidates.append(std.heap.page_allocator, ing);
                }
            }
            if (candidates.items.len == 1) {
                const ing = candidates.items[0];
                try resolved.put(e.key_ptr.*, ing);
                try resolved_ings.put(ing, {});
                done = false;
            }
        }
    }

    // sort allergens alphabetically, list ingredients
    var names: List([]const u8) = .empty;
    defer names.deinit(std.heap.page_allocator);
    var it4 = resolved.keyIterator();
    while (it4.next()) |k| {
        try names.append(std.heap.page_allocator, k.*);
    }
    std.mem.sort([]const u8, names.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);
    print("part 2: ", .{});
    for (names.items, 0..) |n, i| {
        if (i > 0) print(",", .{});
        print("{s}", .{resolved.get(n).?});
    }
    print("\n", .{});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSca = std.mem.tokenizeScalar;
const indexOf = std.mem.findScalar;
const print = std.debug.print;
const sort = std.sort.block;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
