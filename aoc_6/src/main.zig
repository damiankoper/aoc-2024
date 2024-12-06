const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Point = struct {
    x: usize,
    y: usize,
};

const Direction = struct {
    x: i32,
    y: i32,
};

const PointDir = struct {
    point: Point,
    direction: Direction,
};

fn turnRight(dir: Direction) Direction {
    if (dir.x == 0 and dir.y == 1) return Direction{ .x = -1, .y = 0 };
    if (dir.x == -1 and dir.y == 0) return Direction{ .x = 0, .y = -1 };
    if (dir.x == 0 and dir.y == -1) return Direction{ .x = 1, .y = 0 };
    if (dir.x == 1 and dir.y == 0) return Direction{ .x = 0, .y = 1 };
    return dir;
}

fn findStart(lines: std.ArrayList([]u8)) ?Point {
    for (lines.items, 0..) |line, y| {
        for (line, 0..) |char, x| {
            if (char == '^') return Point{ .x = x, .y = y };
        }
    }
    return null;
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));

    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

    var buff_it = std.mem.splitScalar(u8, buff, '\n');
    while (buff_it.next()) |line| {
        try lines.append(@constCast(line));
    }

    var direction = Direction{ .x = 0, .y = -1 };
    const start = findStart(lines);
    var position = start;

    while (true) {
        lines.items[position.?.y][position.?.x] = 'X';
        const new_x: i32 = direction.x + @as(i32, @intCast(position.?.x));
        const new_y: i32 = direction.y + @as(i32, @intCast(position.?.y));
        if (new_y < 0 or new_y >= lines.items.len) break;
        if (new_x < 0 or new_x >= lines.items[0].len) break;

        const new_char = lines.items[@intCast(new_y)][@intCast(new_x)];
        if (new_char != '#') {
            position.?.x = @intCast(new_x);
            position.?.y = @intCast(new_y);
        } else {
            direction = turnRight(direction);
        }
    }
    std.log.debug("{any}", .{position});

    var visited_count: i32 = 0;
    for (lines.items) |line| {
        for (line) |char| {
            if (char == 'X') visited_count += 1;
        }
    }
    std.log.debug("{any}", .{visited_count});

    // Extra slow brute force
    var placement_count: i32 = 0;
    var c: i32 = 0;
    for (lines.items, 0..) |line, obstacle_y| {
        for (line, 0..) |char, obstacle_x| {
            if (char == 'X' and (obstacle_x != start.?.x or obstacle_y != start.?.y)) {
                direction = Direction{ .x = 0, .y = -1 };
                position = start;
                c += 1;
                std.log.debug("{c} {d} {d} x {d} y {d}", .{ char, c, placement_count, obstacle_x, obstacle_y });

                var visited = std.ArrayList(PointDir).init(allocator);
                defer visited.deinit();

                while (true) {
                    lines.items[position.?.y][position.?.x] = 'X';
                    const new_x: i32 = direction.x + @as(i32, @intCast(position.?.x));
                    const new_y: i32 = direction.y + @as(i32, @intCast(position.?.y));
                    if (new_y < 0 or new_y >= lines.items.len) break;
                    if (new_x < 0 or new_x >= lines.items[0].len) break;

                    // std.log.debug("{d} {d}", .{ new_x, new_y });

                    const new_char = lines.items[@intCast(new_y)][@intCast(new_x)];
                    if (new_char != '#' and !(new_x == obstacle_x and new_y == obstacle_y)) {
                        position.?.x = @intCast(new_x);
                        position.?.y = @intCast(new_y);
                        const visited_curr = PointDir{ .point = .{ .x = @intCast(new_x), .y = @intCast(new_y) }, .direction = direction };
                        var already_here = false;
                        for (visited.items) |visited_item| {
                            const same_dir_x = visited_item.direction.x == visited_curr.direction.x;
                            const same_dir_y = visited_item.direction.y == visited_curr.direction.y;
                            const same_point_x = visited_item.point.x == visited_curr.point.x;
                            const same_point_y = visited_item.point.y == visited_curr.point.y;
                            if (same_dir_x and same_dir_y and same_point_x and same_point_y) {
                                already_here = true;
                                break;
                            }
                        }
                        if (already_here) {
                            placement_count += 1;
                            std.log.debug("cycle", .{});
                            break;
                        } else {
                            // std.log.debug("new_here {any}", .{visited_curr});
                            try visited.append(visited_curr);
                        }
                    } else {
                        direction = turnRight(direction);
                    }
                }
                // std.log.debug("end {d} {d}\n", .{ x, y });
            }
        }
    }
    std.log.debug("{any}", .{placement_count});
}
