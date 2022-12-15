const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day13.txt");

pub fn main() !void {
    var lines = util.lines(data);
    var packets = List(Packet).init(gpa);
    defer {
        for (packets.items) |pkt| {
            pkt.free(gpa);
        }
        packets.deinit();
    }

    while (lines.next()) |raw_pkt| {
        if (raw_pkt.len == 0) {
            continue;
        }

        const pkt = try Parser.parse(gpa, raw_pkt);
        errdefer pkt.free(gpa);
        try packets.append(pkt);
    }

    try stdout.print("Part 1: {}\n", .{try part1(packets.items)});
    try stdout.print("Part 2: {}\n", .{try part2(gpa, &packets)});
}

fn part1(packets: []const Packet) !usize {
    var sum: usize = 0;
    var i: usize = 1;

    var chunks = util.chunked(Packet, packets, 2);

    while (chunks.next()) |pkts| {
        if (pkts[0].compare(pkts[1]) == Order.lt) {
            sum += i;
        }

        i += 1;
    }

    return sum;
}

fn part2(alloc: Allocator, packets: *List(Packet)) !usize {
    const divider1 = try Parser.parse(alloc, "[[2]]");
    const divider2 = try Parser.parse(alloc, "[[6]]");
    try packets.append(divider1);
    try packets.append(divider2);

    sort(Packet, packets.items, {}, comptime struct {
        fn cmp(context: void, left: Packet, right: Packet) bool {
            _ = context;
            return left.compare(right) == Order.lt;
        }
    }.cmp);

    var res: usize = 1;
    for (packets.items) |pkt, i| {
        if (pkt.compare(divider1) == Order.eq or pkt.compare(divider2) == Order.eq) {
            res *= i + 1;
        }
    }

    return res;
}

const Packet = union(enum) {
    int: u8,
    arr: []const Packet,

    fn free(self: Packet, alloc: Allocator) void {
        switch (self) {
            Packet.arr => |a| {
                for (a) |pkt| {
                    pkt.free(alloc);
                }
                alloc.free(a);
            },
            else => return,
        }
    }

    fn compare(self: Packet, right: Packet) Order {
        var lefts: []const Packet = undefined;
        var rights: []const Packet = undefined;

        switch (self) {
            Packet.int => |vl| switch (right) {
                Packet.int => |vr| return order(vl, vr),
                Packet.arr => |ar| {
                    const al = [_]Packet{self};
                    rights = ar;
                    lefts = al[0..1];
                },
            },
            Packet.arr => |al| switch (right) {
                Packet.int => {
                    const ar = [_]Packet{right};
                    rights = ar[0..1];
                    lefts = al;
                },
                Packet.arr => |ar| {
                    lefts = al;
                    rights = ar;
                },
            },
        }

        var i: usize = 0;
        while (i < lefts.len and i < rights.len) {
            const ord = lefts[i].compare(rights[i]);
            // the first comparison to give an order gives the order for the whole comparison
            if (ord != Order.eq) {
                return ord;
            }

            i += 1;
        }

        // if no comparison of subpackets gave an order, try a tiebreaker
        return if (i < rights.len)
            // left ran out first => in order
            Order.lt
        else if (i < lefts.len)
            // right ran out first => out of order
            Order.gt
        else
            // same length => continue
            Order.eq;
    }
};

const ParseError = error{
    UnexpectedToken,
    UnexpectedEOF,
    ExpectedEOF,
} || Allocator.Error || std.fmt.ParseIntError;

const Parser = struct {
    alloc: Allocator,
    data: []const u8,
    idx: usize = 0,

    fn parse(allocator: Allocator, input: []const u8) ParseError!Packet {
        var parser = Parser{ .alloc = allocator, .data = input };
        return parser.parseToEnd();
    }

    fn parseToEnd(self: *Parser) ParseError!Packet {
        const pkt = try self.parsePacket();
        if (self.idx != self.data.len) {
            return ParseError.ExpectedEOF;
        }
        return pkt;
    }

    fn parsePacket(self: *Parser) ParseError!Packet {
        if (self.idx >= self.data.len) {
            return ParseError.UnexpectedEOF;
        }
        if (try self.peek('[')) {
            return self.parseArrPacket();
        } else {
            return self.parseIntPacket();
        }
    }

    fn parseIntPacket(self: *Parser) ParseError!Packet {
        if (self.idx >= self.data.len) {
            return ParseError.UnexpectedEOF;
        }

        const start = self.idx;

        while (self.idx < self.data.len and isDigit(self.data[self.idx])) {
            self.idx += 1;
        }

        if (self.idx == start) {
            // no digits
            return ParseError.UnexpectedToken;
        }

        return Packet{ .int = try parseInt(u8, self.data[start..self.idx], 10) };
    }

    fn parseArrPacket(self: *Parser) ParseError!Packet {
        try self.expect('[');

        var packets = List(Packet).init(self.alloc);
        defer packets.deinit();

        while (!try self.peek(']')) {
            try packets.append(try self.parsePacket());

            if (try self.peek(',')) {
                try self.expect(',');
            }
        }

        try self.expect(']');

        return Packet{ .arr = try packets.toOwnedSlice() };
    }

    fn expect(self: *Parser, c: u8) ParseError!void {
        if (!try self.peek(c)) {
            return ParseError.UnexpectedToken;
        }
        self.idx += 1;
    }

    fn peek(self: Parser, c: u8) ParseError!bool {
        if (self.idx >= self.data.len) {
            return ParseError.UnexpectedEOF;
        }
        return self.data[self.idx] == c;
    }
};

const test_input: []const u8 = @embedFile("data/day13_test.txt");

test "parse int packet" {
    {
        var parser = Parser{ .alloc = test_alloc, .data = "0" };
        try t.expectEqual(Packet{ .int = 0 }, try parser.parseIntPacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "123" };
        try t.expectEqual(Packet{ .int = 123 }, try parser.parseIntPacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "256" };
        try t.expectError(ParseError.Overflow, parser.parseIntPacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "" };
        try t.expectError(ParseError.UnexpectedEOF, parser.parseIntPacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "a" };
        try t.expectError(ParseError.UnexpectedToken, parser.parseIntPacket());
    }
}

test "parse array packet" {
    {
        var parser = Parser{ .alloc = test_alloc, .data = "[" };
        try t.expectError(ParseError.UnexpectedEOF, parser.parseArrPacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "a" };
        try t.expectError(ParseError.UnexpectedToken, parser.parseArrPacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "1" };
        try t.expectError(ParseError.UnexpectedToken, parser.parseArrPacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "[]" };
        const pkt = try parser.parseArrPacket();
        defer pkt.free(test_alloc);

        switch (pkt) {
            Packet.int => unreachable,
            Packet.arr => |a| try t.expectEqual(@as(usize, 0), a.len),
        }
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "[1]" };
        const pkt = try parser.parseArrPacket();
        defer pkt.free(test_alloc);

        switch (pkt) {
            Packet.int => unreachable,
            Packet.arr => |a| try t.expectEqual(@as(usize, 1), a.len),
        }
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "[1,2,3,4]" };
        const pkt = try parser.parseArrPacket();
        defer pkt.free(test_alloc);

        switch (pkt) {
            Packet.int => unreachable,
            Packet.arr => |a| {
                try t.expectEqual(@as(usize, 4), a.len);
                try t.expectEqual(Packet{ .int = 3 }, a[2]);
            },
        }
    }
}

test "parse mixed packet" {
    {
        var parser = Parser{ .alloc = test_alloc, .data = "[" };
        try t.expectError(ParseError.UnexpectedEOF, parser.parsePacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "a" };
        try t.expectError(ParseError.UnexpectedToken, parser.parsePacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "1" };
        try t.expectEqual(Packet{ .int = 1 }, try parser.parsePacket());
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "[[]]" };
        const pkt = try parser.parsePacket();
        defer pkt.free(test_alloc);

        switch (pkt) {
            Packet.int => unreachable,
            Packet.arr => |a| try t.expectEqual(@as(usize, 1), a.len),
        }
    }
    {
        var parser = Parser{ .alloc = test_alloc, .data = "[1,[2,[3,[4,[5,6,7]]]],8,9]" };
        const pkt = try parser.parsePacket();
        defer pkt.free(test_alloc);

        switch (pkt) {
            Packet.int => unreachable,
            Packet.arr => |a| {
                try t.expectEqual(@as(usize, 4), a.len);
                try t.expectEqual(Packet{ .int = 8 }, a[2]);
                switch (a[1]) {
                    Packet.int => unreachable,
                    Packet.arr => |a2| {
                        try t.expectEqual(@as(usize, 2), a2.len);
                        try t.expectEqual(Packet{ .int = 2 }, a2[0]);
                    },
                }
            },
        }
    }
}

test "Packet.compare" {
    {
        const left = try Parser.parse(test_alloc, "[1,1,3,1,1]");
        defer left.free(test_alloc);
        const right = try Parser.parse(test_alloc, "[1,1,5,1,1]");
        defer right.free(test_alloc);

        try t.expectEqual(Order.lt, left.compare(right));
    }
    {
        const left = try Parser.parse(test_alloc, "[[1],[2,3,4]]");
        defer left.free(test_alloc);
        const right = try Parser.parse(test_alloc, "[[1],4]");
        defer right.free(test_alloc);

        try t.expectEqual(Order.lt, left.compare(right));
    }
    {
        const left = try Parser.parse(test_alloc, "[9]");
        defer left.free(test_alloc);
        const right = try Parser.parse(test_alloc, "[[8,7,6]]");
        defer right.free(test_alloc);

        try t.expectEqual(Order.gt, left.compare(right));
    }
    {
        const left = try Parser.parse(test_alloc, "[[4,4],4,4]");
        defer left.free(test_alloc);
        const right = try Parser.parse(test_alloc, "[[4,4],4,4,4]");
        defer right.free(test_alloc);

        try t.expectEqual(Order.lt, left.compare(right));
    }
    {
        const left = try Parser.parse(test_alloc, "[7,7,7,7]");
        defer left.free(test_alloc);
        const right = try Parser.parse(test_alloc, "[7,7,7]");
        defer right.free(test_alloc);

        try t.expectEqual(Order.gt, left.compare(right));
    }
    {
        const left = try Parser.parse(test_alloc, "[]");
        defer left.free(test_alloc);
        const right = try Parser.parse(test_alloc, "[3]");
        defer right.free(test_alloc);

        try t.expectEqual(Order.lt, left.compare(right));
    }
    {
        const left = try Parser.parse(test_alloc, "[[[]]]");
        defer left.free(test_alloc);
        const right = try Parser.parse(test_alloc, "[[]]");
        defer right.free(test_alloc);

        try t.expectEqual(Order.gt, left.compare(right));
    }
    {
        const left = try Parser.parse(test_alloc, "[1,[2,[3,[4,[5,6,7]]]],8,9]");
        defer left.free(test_alloc);
        const right = try Parser.parse(test_alloc, "[1,[2,[3,[4,[5,6,0]]]],8,9]");
        defer right.free(test_alloc);

        try t.expectEqual(Order.gt, left.compare(right));
    }
}

test "day 13" {
    var lines = util.lines(test_input);
    var packets = List(Packet).init(test_alloc);
    defer {
        for (packets.items) |pkt| {
            pkt.free(test_alloc);
        }
        packets.deinit();
    }

    while (lines.next()) |raw_pkt| {
        if (raw_pkt.len == 0) {
            continue;
        }

        const pkt = try Parser.parse(test_alloc, raw_pkt);
        errdefer pkt.free(test_alloc);
        try packets.append(pkt);
    }

    {
        try t.expectEqual(@as(usize, 13), try part1(packets.items));
    }
    {
        try t.expectEqual(@as(usize, 140), try part2(test_alloc, &packets));
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
const isDigit = std.ascii.isDigit;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;
const Order = std.math.Order;
const order = std.math.order;

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
