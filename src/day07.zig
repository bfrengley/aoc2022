const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const stdout = std.io.getStdOut().writer();

const data = @embedFile("data/day07.txt");

pub fn main() !void {
    var dt = try DirTree.parse(gpa, data);
    defer dt.deinit();

    try stdout.print("Part 1: {}\n", .{dt.part1()});
    try stdout.print("Part 2: {}\n", .{dt.part2()});
}

const DirTree = struct {
    const Dir = struct {
        alloc: Allocator,
        name: []const u8,
        parent: ?*Dir,
        size: ?usize,
        subdirs: StrMap(Dir),
        files: StrMap(File),

        fn init(alloc: Allocator, dir_name: []const u8, parent_dir: ?*Dir) Dir {
            return Dir{
                .alloc = alloc,
                .name = dir_name,
                .parent = parent_dir,
                .size = null,
                .subdirs = StrMap(Dir).init(alloc),
                .files = StrMap(File).init(alloc),
            };
        }

        fn addFile(self: *Dir, name: []const u8, size: usize) !void {
            try self.files.putNoClobber(name, File{ .name = name, .size = size, .parent = self });
        }

        fn addDir(self: *Dir, dir_name: []const u8) !void {
            try self.subdirs.putNoClobber(dir_name, Dir.init(self.alloc, dir_name, self));
        }

        fn subdir(self: Dir, dir_name: []const u8) ?*Dir {
            return self.subdirs.getPtr(dir_name);
        }

        fn getSize(self: *Dir) usize {
            if (self.size == null) {
                self.updateSize();
            }
            return self.size.?;
        }

        fn updateSize(self: *Dir) void {
            var new_size: usize = 0;

            var file_iter = self.files.valueIterator();
            while (file_iter.next()) |file| {
                new_size += file.size;
            }

            var dir_iter = self.subdirs.valueIterator();
            while (dir_iter.next()) |dir| {
                new_size += dir.getSize();
            }

            self.size = new_size;
        }

        fn part1(self: *Dir) usize {
            var sum = if (self.getSize() <= 100_000) self.getSize() else 0;

            var dir_iter = self.subdirs.valueIterator();
            while (dir_iter.next()) |dir| {
                sum += dir.part1();
            }

            return sum;
        }

        fn part2(self: *Dir, min_size: usize, best_cand: usize) ?*const Dir {
            const size = self.getSize();

            if (size < min_size) {
                return null;
            }

            var cand: ?*const Dir = if (size < best_cand) self else null;

            var dir_iter = self.subdirs.valueIterator();
            while (dir_iter.next()) |dir| {
                const best_subdir = dir.part2(min_size, if (cand) |c| c.size.? else best_cand);
                if (best_subdir) |best| {
                    if (cand) |c| {
                        if (best.size.? < c.size.?) {
                            cand = best_subdir;
                        }
                    } else {
                        cand = best_subdir;
                    }
                }
            }

            return cand;
        }
    };

    const File = struct {
        name: []const u8,
        parent: *Dir,
        size: usize,
    };

    arena: ArenaAllocator,
    root: Dir,

    fn init(self: *DirTree, alloc: Allocator, root_name: []const u8) !void {
        self.arena = ArenaAllocator.init(alloc);
        self.root = Dir.init(self.arena.allocator(), root_name, null);
    }

    fn deinit(self: *DirTree) void {
        self.arena.deinit();
    }

    fn parse(alloc: Allocator, input: []const u8) !DirTree {
        var term_lines = util.lines(input);

        const root_line = term_lines.first();
        assert(std.mem.eql(u8, "$ cd ", root_line[0..5])); // should be `$ cd /`
        var tree: DirTree = undefined;
        try tree.init(alloc, root_line[5..root_line.len]);
        var curr_dir = &tree.root;

        while (term_lines.next()) |line| {
            var toks = tokenize(u8, line, " ");
            const fst = toks.next().?;
            if (std.mem.eql(u8, "$", fst)) {
                if (std.mem.eql(u8, "cd", toks.next().?)) {
                    const dest = toks.next().?;

                    if (std.mem.eql(u8, "..", dest)) {
                        // move up
                        curr_dir = curr_dir.parent.?;
                    } else {
                        // move down
                        curr_dir = curr_dir.subdir(dest).?;
                    }
                }

                // ls is a no-op
                continue;
            } else if (std.mem.eql(u8, "dir", fst)) {
                // we're in a dir listing, this is a subdir
                try curr_dir.addDir(toks.next().?);
            } else {
                const size = try parseInt(usize, fst, 10);
                try curr_dir.addFile(toks.next().?, size);
            }
        }

        return tree;
    }

    fn part1(self: *DirTree) usize {
        return self.root.part1();
    }

    fn part2(self: *DirTree) usize {
        const total_size = 70_000_000;
        const used_size = self.root.getSize();
        const needed_size = 30_000_000 - (total_size - used_size);
        const del_dir = self.root.part2(needed_size, used_size).?;
        return del_dir.size.?;
    }
};

const test_input: []const u8 =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
    \\
;

test "DirTree.parse" {
    var dt = try DirTree.parse(test_alloc, test_input);
    defer dt.deinit();

    try t.expectEqual(@as(usize, 48381165), dt.root.getSize());
}

test "day 7 part 1" {
    var dt = try DirTree.parse(test_alloc, test_input);
    defer dt.deinit();

    try t.expectEqual(@as(usize, 95437), dt.part1());
}

test "day 7 part 2" {
    var dt = try DirTree.parse(test_alloc, test_input);
    defer dt.deinit();

    try t.expectEqual(@as(usize, 24933642), dt.part2());
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
