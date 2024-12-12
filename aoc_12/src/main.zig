const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Region = struct {
    sides: i64,
    perimeter: i64,
    area: i64,
    fn add(self: *Region, region: Region) void {
        self.area += region.area;
        self.perimeter += region.perimeter;
        self.sides += region.sides;
    }
};

fn isSameChar(map: *std.ArrayList([]u8), char: u8, x: i32, y: i32) bool {
    const in_bounds = y >= 0 and x < map.items[0].len and y < map.items.len and x >= 0;
    if (!in_bounds) return false;
    const val = map.items[@as(usize, @intCast(y))][@as(usize, @intCast(x))];
    return val == char;
}

fn getRegion(map: *std.ArrayList([]u8), map_visited: *std.ArrayList([]u8), char: u8, x: i32, y: i32) Region {
    const in_bounds = y >= 0 and x < map.items[0].len and y < map.items.len and x >= 0;
    var region = Region{ .area = 0, .perimeter = 0, .sides = 0 };
    if (in_bounds) {
        const visited_val = map_visited.items[@as(usize, @intCast(y))][@as(usize, @intCast(x))];
        const val = map.items[@as(usize, @intCast(y))][@as(usize, @intCast(x))];
        if (visited_val == '.') {
            if (val == char) {
                map_visited.items[@as(usize, @intCast(y))][@as(usize, @intCast(x))] = char;

                region.area += 1;
                region.perimeter += 4;

                const top_same = isSameChar(map, char, x, y - 1);
                const top_right_same = isSameChar(map, char, x + 1, y - 1);
                const top_left_same = isSameChar(map, char, x - 1, y - 1);
                const right_same = isSameChar(map, char, x + 1, y);
                const bottom_same = isSameChar(map, char, x, y + 1);
                const bottom_right_same = isSameChar(map, char, x + 1, y + 1);
                const bottom_left_same = isSameChar(map, char, x - 1, y + 1);
                const left_same = isSameChar(map, char, x - 1, y);

                if (!top_same and !left_same) region.sides += 1;
                if (!top_same and !right_same) region.sides += 1;
                if (!bottom_same and !left_same) region.sides += 1;
                if (!bottom_same and !right_same) region.sides += 1;

                if (top_same and left_same and !top_left_same) region.sides += 1;
                if (top_same and right_same and !top_right_same) region.sides += 1;
                if (bottom_same and left_same and !bottom_left_same) region.sides += 1;
                if (bottom_same and right_same and !bottom_right_same) region.sides += 1;

                if (top_same) region.perimeter -= 1;
                if (right_same) region.perimeter -= 1;
                if (bottom_same) region.perimeter -= 1;
                if (left_same) region.perimeter -= 1;

                const top_region = getRegion(map, map_visited, char, x, y - 1);
                const right_region = getRegion(map, map_visited, char, x + 1, y);
                const bottom_region = getRegion(map, map_visited, char, x, y + 1);
                const left_region = getRegion(map, map_visited, char, x - 1, y);

                region.add(top_region);
                region.add(right_region);
                region.add(bottom_region);
                region.add(left_region);

                std.log.debug("{c} {any} {any} {any}", .{ char, region, x, y });
            }
        }
    }

    return region;
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buff);

    var map = std.ArrayList([]u8).init(allocator);
    defer map.deinit();

    var map_visited = std.ArrayList([]u8).init(allocator);
    defer map_visited.deinit();
    defer for (map_visited.items) |item| allocator.free(item);

    var buff_it = std.mem.splitScalar(u8, buff, '\n');
    while (buff_it.next()) |line| {
        try map.append(@constCast(line));
        const visited = try allocator.dupe(u8, line);
        for (visited, 0..) |_, i| visited[i] = '.';
        try map_visited.append(visited);
    }

    var sum: i64 = 0;
    var sum_sides: i64 = 0;
    for (map.items, 0..) |line, y| {
        for (line, 0..) |char, x| {
            if (map_visited.items[y][x] == '.' and char != '.') {
                const region = getRegion(&map, &map_visited, char, @intCast(x), @intCast(y));
                //    std.log.debug("{any}", .{region});
                sum += region.area * region.perimeter;
                sum_sides += region.area * region.sides;
            }
        }
    }
    std.log.debug("perimeter {d}", .{sum});
    std.log.debug("    sides {d}", .{sum_sides});
}
