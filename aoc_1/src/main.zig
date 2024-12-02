const std = @import("std");

fn minWithIndex(arr: []i32) struct { min: i32, i: usize } {
    var min: i32 = std.math.maxInt(i32);
    var i: usize = 0;
    for (arr, 0..) |item, index| {
        if (item < min) {
            min = item;
            i = index;
        }
    }
    return .{ .min = min, .i = i };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, 1000000);

    var left = std.ArrayList(i32).init(allocator);
    defer left.deinit();
    var right = std.ArrayList(i32).init(allocator);
    defer right.deinit();

    var n_split = std.mem.split(u8, buff, "\n");
    while (n_split.next()) |line| {
        var val_split = std.mem.split(u8, line, "   ");
        while (true) {
            const left_val = val_split.next();
            const right_val = val_split.next();
            if ((left_val == null) or (right_val == null)) break;

            const left_int = try std.fmt.parseInt(i32, left_val.?, 10);
            const right_int = try std.fmt.parseInt(i32, right_val.?, 10);
            try left.append(left_int);
            try right.append(right_int);
        }
    }

    var left_distance = try left.clone();
    var right_distance = try right.clone();
    var distance_sum: i32 = 0;
    while (left_distance.items.len > 0 and right_distance.items.len > 0) {
        const left_min = minWithIndex(left_distance.items);
        const right_min = minWithIndex(right_distance.items);

        const diff = left_min.min - right_min.min;
        const distance = diff * std.math.sign(diff);
        distance_sum += distance;

        _ = left_distance.swapRemove(left_min.i);
        _ = right_distance.swapRemove(right_min.i);
    }

    std.log.debug("Distance sum: {d}", .{distance_sum});

    const left_similarity = try left.clone();
    const right_similarity = try right.clone();

    var similarity_score: i32 = 0;
    for (left_similarity.items) |left_value| {
        var count: i32 = 0;
        for (right_similarity.items) |right_value| {
            if (left_value == right_value) count += 1;
        }
        similarity_score += left_value * count;
    }

    std.log.debug("Similarity score: {d}", .{similarity_score});
}
