const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Point = struct {
    x: usize,
    y: usize,
    pub fn eq(self: *const Point, b: Point) bool {
        return self.x == b.x and self.y == b.y;
    }
};

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    var buff_it = std.mem.splitScalar(u8, buff, '\n');

    var antinodes = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer antinodes.deinit();
    defer for (antinodes.items) |k| k.deinit();

    var positions = std.AutoHashMap(u8, std.ArrayList(Point)).init(allocator);
    defer positions.deinit();
    var positions_defer_it = positions.iterator();
    defer while (positions_defer_it.next()) |k| k.value_ptr.deinit();

    var y: usize = 0;
    while (buff_it.next()) |line| : (y += 1) {
        var antinodes_row = std.ArrayList(u8).init(allocator);
        for (line, 0..) |char, x| {
            try antinodes_row.append('.');
            if (char != '.') {
                const antenna_positions = try positions.getOrPut(char);
                if (!antenna_positions.found_existing) {
                    const value = std.ArrayList(Point).init(allocator);
                    antenna_positions.value_ptr.* = value;
                }
                try antenna_positions.value_ptr.append(Point{ .x = x, .y = y });
            }
        }
        try antinodes.append(antinodes_row);
    }

    var positions_it = positions.iterator();
    while (positions_it.next()) |entry| {
        for (entry.value_ptr.items) |a| {
            for (entry.value_ptr.items) |b| {
                var antinode_y = @as(i32, @intCast(a.y));
                var antinode_x = @as(i32, @intCast(a.x));
                antinodes.items[@intCast(antinode_y)].items[@intCast(antinode_x)] = '#';

                const dir_x = @as(i32, @intCast(a.x)) - @as(i32, @intCast(b.x));
                const dir_y = @as(i32, @intCast(a.y)) - @as(i32, @intCast(b.y));
                if (dir_x != 0 or dir_y != 0) {
                    antinode_y += dir_y;
                    antinode_x += dir_x;

                    while (antinode_x >= 0 and antinode_x < antinodes.items[0].items.len and antinode_y >= 0 and antinode_y < antinodes.items.len) {
                        antinodes.items[@intCast(antinode_y)].items[@intCast(antinode_x)] = '#';
                        antinode_y += dir_y;
                        antinode_x += dir_x;
                    }
                }
            }
        }
    }

    var sum: i32 = 0;
    for (antinodes.items) |row| {
        std.log.debug("{s}", .{row.items});
        for (row.items) |char| {
            if (char == '#') {
                sum += 1;
            }
        }
    }

    std.log.debug("{any}", .{sum});
}
