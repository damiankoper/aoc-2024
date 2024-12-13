const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Point = struct { x: i64, y: i64 };

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buff);

    var sum: f64 = 0;

    var buff_it = std.mem.splitSequence(u8, buff, "\n\n");
    while (buff_it.next()) |line| {
        if (line.len == 0) continue;
        var line_it = std.mem.splitAny(u8, line, "+,= \n");
        for (0..3) |_| _ = line_it.next();
        const ax_str = line_it.next();
        const ax = try std.fmt.parseFloat(f64, ax_str.?);
        for (0..2) |_| _ = line_it.next();
        const ay_str = line_it.next();
        const ay = try std.fmt.parseFloat(f64, ay_str.?);

        for (0..3) |_| _ = line_it.next();
        const bx_str = line_it.next();
        const bx = try std.fmt.parseFloat(f64, bx_str.?);
        for (0..2) |_| _ = line_it.next();
        const by_str = line_it.next();
        const by = try std.fmt.parseFloat(f64, by_str.?);

        for (0..2) |_| _ = line_it.next();
        const px_str = line_it.next();
        const px = try std.fmt.parseFloat(f64, px_str.?) + 10000000000000;
        for (0..2) |_| _ = line_it.next();
        const py_str = line_it.next();
        const py = try std.fmt.parseFloat(f64, py_str.?) + 10000000000000;

        const a = (py * bx - by * px) / (bx * ay - by * ax);
        const b = (ay * px - py * ax) / (bx * ay - by * ax);
        if (@floor(a) == a and @floor(b) == b)
            sum += a * 3 + b;
        std.log.debug("{d} {d}", .{ a, b });
    }

    std.log.debug("perimeter {d}", .{sum});
}
