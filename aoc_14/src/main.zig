const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Robot = struct { px: i64, py: i64, vx: i64, vy: i64 };

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buff);

    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();

    const space_w: i64 = 101;
    const space_h: i64 = 103;
    const seconds: i64 = 100000;

    var map = try allocator.alloc(u8, (space_h + 1) * (space_w + 1));
    for (map) |*v| v.* = '.';

    var buff_it = std.mem.splitSequence(u8, buff, "\n");
    while (buff_it.next()) |line| {
        if (line.len == 0) continue;
        var line_it = std.mem.splitAny(u8, line, "=, ");
        for (0..1) |_| _ = line_it.next();
        const px_str = line_it.next();
        const px = try std.fmt.parseInt(i64, px_str.?, 10);
        const py_str = line_it.next();
        const py = try std.fmt.parseInt(i64, py_str.?, 10);
        for (0..1) |_| _ = line_it.next();
        const vx_str = line_it.next();
        const vx = try std.fmt.parseInt(i64, vx_str.?, 10);
        const vy_str = line_it.next();
        const vy = try std.fmt.parseInt(i64, vy_str.?, 10);

        const robot = Robot{ .px = px, .py = py, .vx = vx, .vy = vy };
        try robots.append(robot);
    }

    for (0..seconds) |s| {
        for (robots.items) |*robot| {
            robot.px = @mod(robot.px + robot.vx, space_w);
            robot.py = @mod(robot.py + robot.vy, space_h);
            map[@intCast(robot.py * space_h + robot.px)] = 'X';
        }

        const tree_branch = std.mem.indexOf(u8, map, "XXXXXXXX");
        if (tree_branch != null) {
            std.log.debug("{d}", .{s});
            for (0..space_h) |y| {
                std.log.debug("{s}", .{map[(y * space_w)..((y + 1) * (space_w))]});
            }
        }

        for (robots.items) |*robot| {
            map[@intCast(robot.py * space_h + robot.px)] = '.';
        }
    }

    var top_left: i64 = 0;
    var top_right: i64 = 0;
    var bottom_right: i64 = 0;
    var bottom_left: i64 = 0;

    for (robots.items) |robot| {
        if (robot.px < space_w / 2 and robot.py < space_h / 2) top_left += 1;
        if (robot.px > space_w / 2 and robot.py < space_h / 2) top_right += 1;

        if (robot.px < space_w / 2 and robot.py > space_h / 2) bottom_left += 1;
        if (robot.px > space_w / 2 and robot.py > space_h / 2) bottom_right += 1;
    }

    std.log.debug("{any} {any} {any} {any}", .{ top_left, top_right, bottom_left, bottom_right });
    std.log.debug("{any}", .{top_left * top_right * bottom_left * bottom_right});
}
