const std = @import("std");

fn allIncreasing(items: []i32) bool {
    var prev_report_value = items[0];
    for (items[1..]) |curr_report_value| {
        if (prev_report_value < curr_report_value) {
            return false;
        }
        prev_report_value = curr_report_value;
    }
    return true;
}

fn allDecreasing(items: []i32) bool {
    var prev_report_value = items[0];
    for (items[1..]) |curr_report_value| {
        if (prev_report_value > curr_report_value) {
            return false;
        }
        prev_report_value = curr_report_value;
    }
    return true;
}

fn maxDiff(items: []i32, diff: i32) bool {
    var prev_report_value = items[0];
    for (items[1..]) |curr_report_value| {
        if (@abs(prev_report_value - curr_report_value) > diff) {
            return false;
        }
        prev_report_value = curr_report_value;
    }
    return true;
}

fn minDiff(items: []i32, diff: i32) bool {
    var prev_report_value = items[0];
    for (items[1..]) |curr_report_value| {
        if (@abs(prev_report_value - curr_report_value) < diff) {
            return false;
        }
        prev_report_value = curr_report_value;
    }
    return true;
}
fn isSafe(items: []i32) bool {
    return (allDecreasing(items) or allIncreasing(items)) and maxDiff(items, 3) and minDiff(items, 1);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, 10000000);

    var count: i32 = 0;
    var safe_count: i32 = 0;
    var reports = std.mem.split(u8, buff, "\n");
    while (reports.next()) |report| {
        count += 1;
        var report_values_str = std.mem.split(u8, report, " ");

        var report_values = std.ArrayList(i32).init(allocator);
        defer report_values.deinit();

        while (report_values_str.next()) |report_value_str| {
            const report_value = try std.fmt.parseInt(i32, report_value_str, 10);
            try report_values.append(report_value);
        }

        var safe = isSafe(report_values.items);

        if (!safe) {
            for (0..report_values.items.len) |i| {
                var report_values_clone = try report_values.clone();
                defer report_values_clone.deinit();

                _ = report_values_clone.orderedRemove(i);
                safe = isSafe(report_values_clone.items);
                if (safe) {
                    break;
                }
            }
        }

        if (safe) {
            safe_count += 1;
        } else std.log.debug("{any}", .{report_values.items});
    }
    std.log.debug("{d}", .{count});
    std.log.debug("{d}", .{safe_count});
}
