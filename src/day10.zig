const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day10.txt");

pub fn main() !void {
    try stdout.print("Part 1: {}\n", .{try part1(data)});
}

fn part1(input: []const u8) !i32 {
    var lines = util.lines(input);
    var cpu = CPU{};

    while (lines.next()) |line| {
        const instr = try Instruction.parse(line);
        cpu.runInstr(instr);
    }

    return cpu.signal_strength_sum;
}

const Opcode = enum {
    noop,
    addx,
};
const Instruction = union(Opcode) {
    noop: void,
    addx: i32,

    fn parse(raw: []const u8) !Instruction {
        var parts = tokenize(u8, raw, " ");
        return switch (parts.next().?[0]) {
            'n' => Instruction.noop,
            'a' => Instruction{ .addx = try parseInt(i32, parts.next().?, 10) },
            else => unreachable,
        };
    }
};

const CPU = struct {
    cycle: i32 = 0,
    x: i32 = 1,
    signal_strength_sum: i32 = 0,

    fn runInstr(self: *CPU, instr: Instruction) void {
        switch (instr) {
            Opcode.noop => self.tick(),
            Opcode.addx => |v| {
                self.tick();
                self.tick();
                self.x += v;
            },
        }
    }

    fn tick(self: *CPU) void {
        self.cycle += 1;
        switch (self.cycle) {
            20, 60, 100, 140, 180, 220 => self.signal_strength_sum += self.cycle * self.x,
            else => {},
        }

        // draw the sprite
        print("{c}", .{@as(u8, if (util.abs(@mod(self.cycle - 1, 40) - self.x) <= 1) '#' else '.')});
        if (@mod(self.cycle, 40) == 0) {
            print("\n", .{});
        }
    }
};

const test_input = @embedFile("data/day10_test.txt");

test "day 10 part 1" {
    print("\n", .{});
    try t.expectEqual(@as(i32, 13140), try part1(test_input));
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
