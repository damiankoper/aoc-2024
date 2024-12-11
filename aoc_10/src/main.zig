const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Point = struct { x: i32, y: i32 };

fn getReachableCount(map: std.ArrayList([]u8), visited: *std.ArrayList(Point), expected: i32, x: i32, y: i32) !i32 {
    const current = map.items[@intCast(y)][@intCast(x)];

    if (current != expected) return 0;
    if (current == 9) {
        return 1;
        // var already = false;
        // for (visited.items) |point| {
        //     if (point.x == x and point.y == y) already = true;
        // }

        // if (!already) {
        //     try visited.append(Point{ .x = x, .y = y });
        // }
    }

    var count: i32 = 0;
    if (x > 0) count += try getReachableCount(map, visited, expected + 1, x - 1, y);
    if (x < map.items[0].len - 1) count += try getReachableCount(map, visited, expected + 1, x + 1, y);
    if (y > 0) count += try getReachableCount(map, visited, expected + 1, x, y - 1);
    if (y < map.items.len - 1) count += try getReachableCount(map, visited, expected + 1, x, y + 1);

    return count;
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));

    var map = std.ArrayList([]u8).init(allocator);
    defer map.deinit();

    var buff_it = std.mem.splitScalar(u8, buff, '\n');
    while (buff_it.next()) |line| {
        var line_var = @constCast(line);
        for (line_var, 0..) |_, i| line_var[i] -= '0';
        try map.append(line_var);
    }

    var sum: i32 = 0;
    for (map.items, 0..) |_, y| {
        for (map.items[y], 0..) |_, x| {
            if (map.items[y][x] == 0) {
                var visited = std.ArrayList(Point).init(allocator);
                defer visited.deinit();

                const count = try getReachableCount(map, &visited, 0, @intCast(x), @intCast(y));
                std.log.debug("{any}", .{count});
                sum += count;
            }
        }
    }

    std.log.debug("{any}", .{sum});
}
