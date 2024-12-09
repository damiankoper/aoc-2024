const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Sector = struct { pos: usize, size: usize };

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));

    var map_raw = std.ArrayList(i32).init(allocator);
    defer map_raw.deinit();

    for (buff) |times_char| {
        const times: u8 = times_char - '0';
        try map_raw.append(times);
    }

    // var left_raw: usize = 0;
    // var right_raw: usize = map_raw.items.len - 1;
    // while (true) {
    //     if (right_raw % 2 == 0) {}
    // }

    var map = std.ArrayList(i32).init(allocator);
    defer map.deinit();

    var map_file = std.ArrayList(Sector).init(allocator);
    defer map_file.deinit();

    var map_free = std.ArrayList(Sector).init(allocator);
    defer map_free.deinit();

    var free_by_size = std.AutoHashMap(u8, std.ArrayList(usize)).init(allocator);
    var free_by_size_defer_it = free_by_size.iterator();
    defer while (free_by_size_defer_it.next()) |k| k.value_ptr.deinit();

    var i_sectors: usize = 0;
    var sector: i32 = 0;
    var file_sector: bool = true;
    for (buff) |times_char| {
        const times: u8 = times_char - '0';
        if (file_sector) {
            try map.appendNTimes(sector, times);
            sector += 1;
            try map_file.append(Sector{ .pos = i_sectors, .size = times });
        } else {
            try map.appendNTimes(-1, times);
            try map_free.append(Sector{ .pos = i_sectors, .size = times });

            const result = try free_by_size.getOrPut(times);
            if (!result.found_existing)
                result.value_ptr.* = std.ArrayList(usize).init(allocator);
            try result.value_ptr.append(i_sectors);
        }
        file_sector = !file_sector;
        i_sectors += times;
    }

    // var left: usize = 0;
    // var right: usize = map.items.len - 1;
    // while (left < right) {
    //     if (map.items[left] == -1 and map.items[right] > -1)
    //         std.mem.swap(i32, &map.items[left], &map.items[right]);
    //     if (map.items[left] > -1) left += 1;
    //     if (map.items[right] == -1) right -= 1;
    // }
    // std.log.debug("{any}", .{map.items});
    // std.log.debug("{any}", .{map_free.items});

    for (0..map_file.items.len) |i_file_raw| {
        const i_file = map_file.items.len - 1 - i_file_raw;
        const file = map_file.items[i_file];

        for (0..map_free.items.len) |i_free| {
            var free = &map_free.items[i_free];

            if (free.pos >= file.pos) break;
            if (free.size >= file.size) {
                // std.log.debug("      free {any} file {any}", .{ free, file });
                std.mem.copyForwards(i32, map.items[free.pos..(free.pos + file.size)], map.items[file.pos..(file.pos + file.size)]);
                for (file.pos..(file.pos + file.size)) |i| map.items[i] = -1;

                if (free.size == file.size) {
                    _ = map_free.orderedRemove(i_free);
                } else {
                    free.size -= file.size;
                    free.pos += file.size;
                }

                // std.log.debug("after free {any} file {any}", .{ free, file });
                // std.log.debug("map {any}\n", .{map.items});
                break;
            }
        }
        // std.log.debug("{any}", .{map_free.items});
    }
    // std.log.debug("{any}", .{map.items});

    var checksum: u64 = 0;
    for (map.items, 0..) |value, i| {
        if (value >= 0) {
            checksum += @as(u64, @intCast(value)) * @as(u64, @intCast(i));
        }
    }

    std.log.debug("final {any}\n", .{checksum});
}
