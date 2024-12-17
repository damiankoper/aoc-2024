const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Vector = struct {
    x: i64,
    y: i64,
    fn eq(self: *const Vector, vector: Vector) bool {
        return self.x == vector.x and self.y == vector.y;
    }
    fn add(self: *const Vector, vector: Vector) Vector {
        return Vector{ .x = self.x + vector.x, .y = self.y + vector.y };
    }
    fn rotLeft(self: *const Vector) Vector {
        return Vector{ .x = -self.y, .y = self.x };
    }
    fn rotRight(self: *const Vector) Vector {
        return Vector{ .x = self.y, .y = -self.x };
    }
};

fn printMap(map: std.ArrayList([]u8)) void {
    for (map.items) |line| {
        std.log.debug("{s}", .{line});
    }
    std.log.debug("\n", .{});
}

fn printNumMap(map: std.ArrayList([]i64)) void {
    for (map.items) |line| {
        for (line) |*i| {
            if (i.* == std.math.maxInt(i64)) i.* = 9999;
        }

        std.log.debug("{any}", .{line});
    }
    std.log.debug("\n", .{});
}

fn findPos(map: *std.ArrayList([]u8), pos: u8) Vector {
    for (map.items, 0..) |line, _y| {
        for (line, 0..) |char, _x| {
            if (char == pos) {
                return Vector{ .x = @intCast(_x), .y = @intCast(_y) };
            }
        }
    }
    unreachable;
}

fn calcScore(dirs: ?std.ArrayList(Vector)) i64 {
    if (dirs == null) return std.math.maxInt(i64);
    var score: i64 = 0;
    var last_dir: ?Vector = null;
    for (dirs.?.items) |dir| {
        if (last_dir != null) {
            if (last_dir.?.eq(dir)) {
                score += 1;
            } else {
                score += 1001;
            }
        }
        last_dir = dir;
    }
    return score;
}

fn cloneMap(visited_map: std.ArrayList([]u8)) !std.ArrayList([]u8) {
    const result = try visited_map.clone();
    for (result.items) |*item| {
        item.* = try allocator.dupe(u8, item.*);
    }
    return result;
}

fn valueInArray(value: Vector, array: std.ArrayList(Vector)) bool {
    for (array.items) |num| {
        if (value.eq(num)) {
            return true;
        }
    }
    return false;
}

fn makeMove(map: *std.ArrayList([]u8), min_score_map: *std.ArrayList([]i64), from_map: *std.ArrayList(std.ArrayList(std.ArrayList(Vector))), pos: Vector, dir: Vector, from: ?Vector, score: i64) !i64 {
    const current = map.items[@intCast(pos.y)][@intCast(pos.x)];
    const current_score = min_score_map.items[@intCast(pos.y)][@intCast(pos.x)];

    if (current != '#') {
        if (score - 1001 <= current_score) {
            min_score_map.items[@intCast(pos.y)][@intCast(pos.x)] = score;
            if ((score) < current_score) {
                from_map.items[@intCast(pos.y)].items[@intCast(pos.x)].clearAndFree();
            }
            if (from != null and !valueInArray(from.?, from_map.items[@intCast(pos.y)].items[@intCast(pos.x)])) {
                try from_map.items[@intCast(pos.y)].items[@intCast(pos.x)].append(from.?);
            }

            const next_pos_straight = pos.add(dir);
            _ = try makeMove(map, min_score_map, from_map, next_pos_straight, dir, pos, score + 1);

            const right_dir = dir.rotRight();
            const next_pos_right = pos.add(right_dir);
            _ = try makeMove(map, min_score_map, from_map, next_pos_right, right_dir, pos, score + 1001);

            const left_dir = dir.rotLeft();
            const next_pos_left = pos.add(left_dir);
            _ = try makeMove(map, min_score_map, from_map, next_pos_left, left_dir, pos, score + 1001);
        }
    }

    return score;
}

var x: i64 = 0;
// var x: u8 = 0;
fn markWalls(walls_map: *std.ArrayList([]u8), from_map: *std.ArrayList(std.ArrayList(std.ArrayList(Vector))), end: Vector) void {
    const from = from_map.items[@intCast(end.y)].items[@intCast(end.x)];

    if (walls_map.items[@intCast(end.y)][@intCast(end.x)] != '0') {
        x += 1;
        //std.log.debug("{d}", .{x});
        walls_map.items[@intCast(end.y)][@intCast(end.x)] = '0';
    }
    // x = (x + 1) % 10;}

    // std.time.sleep(1 * std.time.ns_per_s / 8);
    // printMap(walls_map.*);
    // std.log.debug("{any} {any}", .{ end, from.items });
    // if (from.items.len > 0)
    //     from.clearAndFree();
    //std.log.debug("{any}", .{from.items});

    for (from.items) |vec| {
        //std.time.sleep(1 * std.time.ns_per_s);
        // printMap(walls_map.*);
        markWalls(walls_map, from_map, vec);
    }
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buff);

    var map = std.ArrayList([]u8).init(allocator);
    defer map.deinit();

    var walls_map = std.ArrayList([]u8).init(allocator);
    defer walls_map.deinit();

    var from_map = std.ArrayList(std.ArrayList(std.ArrayList(Vector))).init(allocator);
    defer from_map.deinit();

    var min_score_map = std.ArrayList([]i64).init(allocator);
    defer min_score_map.deinit();

    var buff_it = std.mem.splitSequence(u8, buff, "\n");
    while (buff_it.next()) |line| {
        try map.append(try allocator.dupe(u8, line));
        try walls_map.append(try allocator.dupe(u8, line));

        const min_score_line = try allocator.alloc(i64, line.len);
        for (min_score_line) |*item| item.* = std.math.maxInt(i64);
        try min_score_map.append(min_score_line);

        var line_from_map = std.ArrayList(std.ArrayList(Vector)).init(allocator);
        for (line) |_| {
            const char_from = std.ArrayList(Vector).init(allocator);
            try line_from_map.append(char_from);
        }
        try from_map.append(line_from_map);
    }

    const start = findPos(&map, 'S');
    const end = findPos(&map, 'E');
    _ = try makeMove(&map, &min_score_map, &from_map, start, Vector{ .x = 1, .y = 0 }, null, 0);

    //printMap(walls_map);
    // printNumMap(min_score_map);

    const end_score = min_score_map.items[@intCast(end.y)][@intCast(end.x)];
    std.log.debug("{any}", .{end_score});

    std.log.debug("{any}", .{from_map.items[13].items[1].items});

    markWalls(&walls_map, &from_map, end);

    //printMap(walls_map);
    std.log.debug("{any}", .{x});
}
