const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn check(matrix: [][]const u8, x: usize, y: usize, x_dir: i32, y_dir: i32, next: u8) bool {
    std.log.debug("enter {d} {d} {d} {d}, {c}", .{ x, y, x_dir, y_dir, next });
    const new_x: i32 = @as(i32, @intCast(x)) + x_dir;
    const new_y: i32 = @as(i32, @intCast(y)) + y_dir;
    if (new_x < 0 or new_x >= matrix[0].len) return false;
    if (new_y < 0 or new_y >= matrix.len) return false;

    const new_matrix = matrix[@intCast(new_y)][@intCast(new_x)];

    if (new_matrix == next and next == 'A') {
        std.log.debug("A {d} {d}", .{ x, y });
        const a = check(matrix, x, y, 1, 1, 'M');
        const b = check(matrix, x, y, -1, -1, 'M');
        const c = check(matrix, x, y, -1, 1, 'M');
        const d = check(matrix, x, y, 1, -1, 'M');
        return ((a or b) and (c or d));
    } else if (new_matrix == next and next == 'M') {
        std.log.debug("M {d} {d}", .{ new_x, new_y });
        return check(matrix, x, y, -1 * x_dir, -1 * y_dir, 'S');
    } else if (new_matrix == next) {
        std.log.debug("S {d} {d}", .{ new_x, new_y });
        return true;
    }

    return false;
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));

    var line_it = std.mem.splitScalar(u8, buff, '\n');
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    while (line_it.next()) |line| try lines.append(line);
    var xmas_sum: i32 = 0;
    xmas_sum += 0;

    for (lines.items, 0..) |line, y| {
        for (line, 0..) |_, x| {
            if (check(lines.items, x, y, 0, 0, 'A')) xmas_sum += 1;
        }
    }

    std.log.debug("{d}", .{xmas_sum});
}
