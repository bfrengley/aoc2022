const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const calories = try getCaloriesPerElf(gpa, data);
    defer gpa.free(calories);

    try stdout.print("Part 1: {}\n", .{part1(calories)});
    try stdout.print("Part 2: {}\n", .{part2(calories)});
}

fn part1(calories: []u64) u64 {
    return calories[0];
}

fn part2(calories: []u64) u64 {
    return calories[0] + calories[1] + calories[2];
}

fn getCaloriesPerElf(allocator: Allocator, input: []const u8) ![]u64 {
    var lines = split(u8, input, "\n");

    var calories = List(u64).init(allocator);
    defer calories.deinit();

    var curr: u64 = 0;

    while (lines.next()) |line| {
        if (line.len == 0) {
            try calories.append(curr);
            curr = 0;
            continue;
        }

        curr += try parseInt(u64, line, 10);
    }

    if (curr != 0) {
        try calories.append(curr);
    }

    var slice = calories.toOwnedSlice();
    sort(u64, slice, {}, comptime desc(u64));
    return slice;
}

const test_input: []const u8 =
    \\1000
    \\2000
    \\3000
    \\
    \\4000
    \\
    \\5000
    \\6000
    \\
    \\7000
    \\8000
    \\9000
    \\
    \\10000
    \\
;

test "getCaloriesPerElf" {
    const calories = try getCaloriesPerElf(std.testing.allocator, test_input);
    defer std.testing.allocator.free(calories);
    try std.testing.expectEqualSlices(u64, &[_]u64{ 24000, 11000, 10000, 6000, 4000 }, calories);
}

test "day 1 part 1" {
    const calories = try getCaloriesPerElf(std.testing.allocator, test_input);
    defer std.testing.allocator.free(calories);
    try std.testing.expectEqual(@as(u64, 24000), part1(calories));
}

test "day 1 part 2" {
    const calories = try getCaloriesPerElf(std.testing.allocator, test_input);
    defer std.testing.allocator.free(calories);
    try std.testing.expectEqual(@as(u64, 45000), part2(calories));
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
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

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
