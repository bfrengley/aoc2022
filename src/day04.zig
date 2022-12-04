const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day04.txt");

pub fn main() !void {
    try stdout.print("Part 1: {}\n", .{try doPart(data, comptime Assignment.contains)});
    try stdout.print("Part 2: {}\n", .{try doPart(data, comptime Assignment.overlaps)});
}

fn doPart(input: []const u8, comptime pred: @TypeOf(Assignment.contains)) !i32 {
    var lines = util.lines(input);
    var count: i32 = 0;

    while (lines.next()) |line| {
        var parts = split(u8, line, ",");
        const a1 = try Assignment.parse(parts.next().?);
        const a2 = try Assignment.parse(parts.next().?);

        if (pred(a1, a2) or pred(a2, a1)) {
            count += 1;
        }
    }

    return count;
}

const Assignment = struct {
    min: i32,
    max: i32,

    fn parse(str: []const u8) !Assignment {
        var parts = split(u8, str, "-");
        const from = try parseInt(i32, parts.next().?, 10);
        const to = try parseInt(i32, parts.next().?, 10);
        return Assignment{ .min = from, .max = to };
    }

    fn contains(self: Assignment, other: Assignment) bool {
        return self.min >= other.min and self.max <= other.max;
    }

    fn overlaps(self: Assignment, other: Assignment) bool {
        return (self.min >= other.min and self.min <= other.max) or (self.max >= other.min and self.max <= other.max);
    }
};

const test_input: []const u8 =
    \\2-4,6-8
    \\2-3,4-5
    \\5-7,7-9
    \\2-8,3-7
    \\6-6,4-6
    \\2-6,4-8
    \\
;

test "day 4 part 1" {
    try t.expectEqual(@as(i32, 2), try doPart(test_input, comptime Assignment.contains));
}

test "day 4 part 2" {
    try t.expectEqual(@as(i32, 4), try doPart(test_input, comptime Assignment.overlaps));
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
