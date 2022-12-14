const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;
const split = util.split;
const count = util.count;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day08.txt");

const tree_grid = blk: {
    @setEvalBranchQuota(20_000);
    const rows = count(u8, data, '\n');
    break :blk split(u8, rows, data, '\n');
};

pub fn main() !void {
    try stdout.print("Part 1: {}\n", .{countVisible(tree_grid[0..tree_grid.len])});
    try stdout.print("Part 2: {}\n", .{bestScore(tree_grid[0..tree_grid.len])});
}

fn countVisible(trees: []const []const u8) u32 {
    var visible: u32 = 0;
    for (trees) |row, y| {
        for (row) |_, x| {
            if (visibility(bool, trees, x, y)) {
                visible += 1;
            }
        }
    }
    return visible;
}

fn bestScore(trees: []const []const u8) isize {
    var best: isize = 0;
    for (trees) |row, y| {
        for (row) |_, x| {
            const vis = visibility(isize, trees, x, y);
            best = max(best, vis);
        }
    }
    return best;
}

fn visibility(comptime T: type, trees: []const []const u8, x: usize, y: usize) T {
    const x_max = trees[0].len - 1;
    const y_max = trees.len - 1;

    // edges always visible
    if (x == 0 or y == 0 or x == x_max or y == y_max) {
        return switch (T) {
            bool => true,
            isize => 0,
            else => @compileError("unexpected return type, expected bool or isize"),
        };
    }

    const x_dirs = [_]isize{ -1, 0, 1, 0 };
    const y_dirs = [_]isize{ 0, -1, 0, 1 };

    var res: T = switch (T) {
        bool => false,
        isize => 1,
        else => @compileError("unexpected return type, expected bool or isize"),
    };

    inline for (x_dirs) |x_dir, i| {
        const vis = dirVis(T, trees, x, y, x_dir, y_dirs[i]);
        switch (T) {
            bool => res = res or vis,
            isize => res *= vis,
            else => @compileError("unexpected return type, expected bool or isize"),
        }
    }
    return res;
}

fn dirVis(comptime T: type, trees: []const []const u8, x: usize, y: usize, x_dir: isize, y_dir: isize) T {
    var x_: isize = @bitCast(isize, x) + x_dir;
    var y_: isize = @bitCast(isize, y) + y_dir;
    const tree = trees[y][x];
    const x_max = @bitCast(isize, trees[0].len);
    const y_max = @bitCast(isize, trees.len);

    while (y_ >= 0 and y_ < y_max and x_ >= 0 and x_ < x_max) {
        if (trees[@bitCast(usize, y_)][@bitCast(usize, x_)] >= tree) {
            return switch (T) {
                bool => false,
                isize => (absInt(x_dir * (@bitCast(isize, x) - x_)) catch unreachable) +
                    (absInt(y_dir * (@bitCast(isize, y) - y_)) catch unreachable),
                else => @compileError("unexpected return type, expected bool or isize"),
            };
        }
        x_ += x_dir;
        y_ += y_dir;
    }

    return switch (T) {
        bool => true,
        isize => (absInt(x_dir * (@bitCast(isize, x) - x_)) catch unreachable) +
            (absInt(y_dir * (@bitCast(isize, y) - y_)) catch unreachable) - 1,
        else => @compileError("unexpected return type, expected bool or isize"),
    };
}

const test_input: []const u8 =
    \\30373
    \\25512
    \\65332
    \\33549
    \\35390
    \\
;

const test_grid = blk: {
    const test_rows = count(u8, test_input, '\n');
    break :blk split(u8, test_rows, test_input, '\n');
};

test "comptime split" {
    const expected = [_][]const u8{
        "30373",
        "25512",
        "65332",
        "33549",
        "35390",
    };

    for (expected) |r, i| {
        try t.expectEqualSlices(u8, r, test_grid[i]);
    }
}

test "day 8 part 1" {
    const input: []const []const u8 = test_grid[0..test_grid.len];
    try t.expectEqual(@as(u32, 21), countVisible(input));
}

test "day 8 part 2" {
    const input: []const []const u8 = test_grid[0..test_grid.len];
    try t.expectEqual(@as(isize, 8), bestScore(input));
}

test "day 8 part 2 - example" {
    const input: []const []const u8 = test_grid[0..test_grid.len];
    try t.expectEqual(@as(isize, 8), visibility(isize, input, 2, 3));
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;
const absInt = std.math.absInt;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;

const t = std.testing;
const test_alloc = t.allocator;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
