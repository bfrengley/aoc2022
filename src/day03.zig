const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.StaticBitSet(52);

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part 1: {}\n", .{part1(data)});
    try stdout.print("Part 2: {}\n", .{part2(data)});
}

fn part1(input: []const u8) usize {
    var lines = split(u8, trim(u8, input, "\n"), "\n");
    var sum: usize = 0;

    while (lines.next()) |line| {
        sum += Rucksack.parse(line).common() orelse 0;
    }

    return sum;
}

fn part2(input: []const u8) usize {
    var lines = split(u8, trim(u8, input, "\n"), "\n");
    var sum: usize = 0;

    while (lines.next()) |line| {
        const rs1 = Rucksack.parse(line);
        const rs2 = Rucksack.parse(lines.next().?);
        const rs3 = Rucksack.parse(lines.next().?);

        var common = BitSet.initFull();
        common.setIntersection(rs1.allItems());
        common.setIntersection(rs2.allItems());
        common.setIntersection(rs3.allItems());

        sum += common.findFirstSet().? + 1;
    }

    return sum;
}

fn toBit(c: u8) usize {
    return switch (c) {
        'a'...'z' => c - 'a',
        'A'...'Z' => 26 + c - 'A',
        else => unreachable,
    };
}

const Rucksack = struct {
    comp1: BitSet,
    comp2: BitSet,

    fn parse(line: []const u8) Rucksack {
        const size = line.len / 2;

        var bs1 = BitSet.initEmpty();
        var bs2 = BitSet.initEmpty();

        for (line[0..size]) |c| {
            bs1.set(toBit(c));
        }

        for (line[size..line.len]) |c| {
            bs2.set(toBit(c));
        }

        return Rucksack{ .comp1 = bs1, .comp2 = bs2 };
    }

    fn allItems(self: Rucksack) BitSet {
        var items = BitSet.initEmpty();
        items.setUnion(self.comp1);
        items.setUnion(self.comp2);
        return items;
    }

    fn common(self: Rucksack) ?usize {
        var shared = BitSet.initFull();
        shared.setIntersection(self.comp1);
        shared.setIntersection(self.comp2);
        return if (shared.findFirstSet()) |n| n + 1 else null;
    }
};

const test_input: []const u8 =
    \\vJrwpWtwJgWrhcsFMMfFFhFp
    \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    \\PmmdzqPrVvPwwTWBwg
    \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    \\ttgJtRGJQctTZtZT
    \\CrZsJsPPZsGzwwsLwLmpwMDw
;

test "Rucksack.common" {
    const expecteds = [_]?usize{ 16, 38, 42, 22, 20, 19 };
    var lines = split(u8, test_input, "\n");

    for (expecteds) |expected| {
        const line = lines.next().?;

        const rucksack = Rucksack.parse(line);
        try t.expectEqual(expected, rucksack.common());
    }
}

test "day 3 part 1" {
    try t.expectEqual(@as(usize, 157), part1(test_input));
}

test "day 3 part 2" {
    try t.expectEqual(@as(usize, 70), part2(test_input));
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
