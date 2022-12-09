const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.StaticBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day06.txt");

pub fn main() !void {
    try stdout.print("Part 1: {}\n", .{doPart(4, data)});
    try stdout.print("Part 2: {}\n", .{doPart(14, data)});
}

fn doPart(comptime size: usize, input: []const u8) usize {
    var windows = util.windows(u8, input, size);
    while (windows.next()) |window| {
        var bs = BitSet(32).initEmpty();
        for (window) |c| {
            bs.set(c - 'a');
        }
        if (bs.count() == size) {
            return windows.index.? + windows.window_size - 1;
        }
    }

    unreachable;
}

const test_inputs = [_][]const u8{
    "mjqjpqmgbljsphdztnvjfqwrcgsmlb",
    "bvwbjplbgvbhsrlpgdmjqwftvncz",
    "nppdvjthqldpwncqszvftbrmjlhg",
    "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg",
    "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw",
};

test "day 6 part 1" {
    const expected = [_]usize{ 7, 5, 6, 10, 11 };
    for (test_inputs) |input, i| {
        try t.expectEqual(expected[i], doPart(4, input));
    }
}

test "day 6 part 2" {
    const expected = [_]usize{ 19, 23, 23, 29, 26 };
    for (test_inputs) |input, i| {
        try t.expectEqual(expected[i], doPart(14, input));
    }
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

const t = std.testing;
const test_alloc = t.allocator;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
