const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Vector = struct {
    x: i64,
    y: i64,
    fn eq(self: *const Vector, box: Vector) bool {
        return self.x == box.x and self.y == box.y;
    }
};
const Box = struct { left: Vector, right: Vector };

fn printMap(map: *std.ArrayList([]u8)) void {
    for (map.items) |line| {
        std.log.debug("{s}", .{line});
    }
}

fn findRobot(map: *std.ArrayList([]u8)) Vector {
    for (map.items, 0..) |line, _y| {
        for (line, 0..) |char, _x| {
            if (char == '@') {
                return Vector{ .x = @intCast(_x), .y = @intCast(_y) };
            }
        }
    }
    unreachable;
}

fn inBounds(map: *std.ArrayList([]u8), pos: Vector) bool {
    return pos.y >= 0 and pos.x >= 0 and pos.y < map.items.len and pos.x < map.items[0].len;
}

fn getBox(map: *std.ArrayList([]u8), pos: Vector) ?Box {
    const current = map.items[@intCast(pos.y)][@intCast(pos.x)];
    if (current == '[') {
        return Box{ .left = pos, .right = Vector{ .x = pos.x + 1, .y = pos.y } };
    } else if (current == ']') {
        return Box{ .left = Vector{ .x = pos.x - 1, .y = pos.y }, .right = pos };
    } else return null;
}

fn moveBox(map: *std.ArrayList([]u8), box: Box, dir: Vector) void {
    map.items[@intCast(box.left.y)][@intCast(box.left.x)] = '.';
    map.items[@intCast(box.right.y)][@intCast(box.right.x)] = '.';
    map.items[@intCast(box.left.y + dir.y)][@intCast(box.left.x + dir.x)] = '[';
    map.items[@intCast(box.right.y + dir.y)][@intCast(box.right.x + dir.x)] = ']';
}

fn moveRobot(map: *std.ArrayList([]u8), robot: Vector, dir: Vector) void {
    map.items[@intCast(robot.y)][@intCast(robot.x)] = '.';
    map.items[@intCast(robot.y + dir.y)][@intCast(robot.x + dir.x)] = '@';
}

fn getNextPos(pos: Vector, dir: Vector) Vector {
    return Vector{ .x = pos.x + dir.x, .y = pos.y + dir.y };
}

fn makeMove(map: *std.ArrayList([]u8), pos: Vector, dir: Vector) !bool {
    var to_visit_queue = std.ArrayList(Vector).init(allocator);
    defer to_visit_queue.deinit();

    var to_visit_stack = std.ArrayList(Vector).init(allocator);
    defer to_visit_stack.deinit();

    var blocked = false;

    const next_pos = getNextPos(pos, dir);
    try to_visit_queue.append(next_pos);
    try to_visit_stack.append(next_pos);
    while (to_visit_queue.items.len > 0) {
        const next_pos_queue = to_visit_queue.orderedRemove(0);
        const next_box = getBox(map, next_pos_queue);
        std.log.debug("next box {any} {any}", .{ next_box, next_pos_queue });
        if (next_box != null) {
            const next_box_left = getNextPos(next_box.?.left, dir);
            const next_box_right = getNextPos(next_box.?.right, dir);
            if (dir.y != 0) {
                try to_visit_queue.append(next_box_left);
                try to_visit_stack.append(next_box_left);
                try to_visit_queue.append(next_box_right);
                try to_visit_stack.append(next_box_right);
            } else {
                if (dir.x == 1) {
                    try to_visit_queue.append(next_box_right);
                    try to_visit_stack.append(next_box_right);
                } else if (dir.x == -1) {
                    try to_visit_queue.append(next_box_left);
                    try to_visit_stack.append(next_box_left);
                }
            }
        } else {
            const current = map.items[@intCast(next_pos_queue.y)][@intCast(next_pos_queue.x)];
            if (current != '.')
                _ = to_visit_stack.pop();
            if (current == '#') {
                blocked = true;
                break;
            }
        }
    }

    std.log.debug("stack {any}", .{to_visit_stack.items});
    std.log.debug("blocked {any}", .{blocked});

    if (!blocked) {
        while (to_visit_stack.items.len > 0) {
            const next_pos_stack = to_visit_stack.pop();
            const box = getBox(map, next_pos_stack);
            if (box != null) {
                _ = moveBox(map, box.?, dir);
            }
        }
        moveRobot(map, pos, dir);
    }
    return false;
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buff);

    var map = std.ArrayList([]u8).init(allocator);
    defer map.deinit();

    var buff_it = std.mem.splitSequence(u8, buff, "\n\n");
    const parts = buff_it.next().?;
    var map_it = std.mem.splitSequence(u8, parts, "\n");
    while (map_it.next()) |line| {
        var line_x2 = try allocator.alloc(u8, line.len * 2);
        for (line, 0..) |char, x| {
            if (char == '#') {
                line_x2[2 * x] = '#';
                line_x2[2 * x + 1] = '#';
            }
            if (char == 'O') {
                line_x2[2 * x] = '[';
                line_x2[2 * x + 1] = ']';
            }
            if (char == '.') {
                line_x2[2 * x] = '.';
                line_x2[2 * x + 1] = '.';
            }
            if (char == '@') {
                line_x2[2 * x] = '@';
                line_x2[2 * x + 1] = '.';
            }
        }
        try map.append(line_x2);
    }

    printMap(&map);

    const moves = buff_it.next().?;
    for (moves, 0..) |move, i| {
        const robot = findRobot(&map);
        if (move == '^') {
            _ = try makeMove(&map, robot, Vector{ .x = 0, .y = -1 });
        } else if (move == '>') {
            _ = try makeMove(&map, robot, Vector{ .x = 1, .y = 0 });
        } else if (move == 'v') {
            _ = try makeMove(&map, robot, Vector{ .x = 0, .y = 1 });
        } else if (move == '<') {
            _ = try makeMove(&map, robot, Vector{ .x = -1, .y = 0 });
        }
        printMap(&map);
        std.log.debug("{d}/{d} \n", .{ i, moves.len });
        std.time.sleep(1 * std.time.ns_per_s / 100);
    }

    var sum: i64 = 0;

    for (map.items, 0..) |line, _y| {
        for (line, 0..) |char, _x| {
            if (char == '[') {
                sum += @as(i64, @intCast(_y)) * 100 + @as(i64, @intCast(_x));
            }
        }
    }

    std.log.debug("{d}", .{sum});
}
