const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn getResult(combination: []u8, parts: []u64) !u64 {
    var buff: u64 = parts[0];
    for (parts[1..], 0..) |part, i| {
        if (combination[i] == 0) {
            buff += part;
        } else if (combination[i] == 1) {
            buff *= part;
        } else if (combination[i] == 2) {
            const buff_str = try std.fmt.allocPrint(allocator, "{d}{d}", .{ buff, part });
            buff = try std.fmt.parseInt(u64, buff_str, 10);
        }
    }
    // std.log.debug("\nresult {d}\n", .{buff});

    return buff;
}

fn increment(combination: []u8) void {
    var carry: u8 = 0;

    for (combination, 0..) |_, i| {
        if (i == 0) combination[i] += 1;
        combination[i] += carry;
        carry = 0;
        if (combination[i] == 3) {
            carry = 1;
            combination[i] = 0;
        } else {
            break;
        }
    }
}

fn stop(combination: []u8) bool {
    for (combination) |val| {
        if (val != 2) return false;
    }
    return true;
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));

    var c: u64 = 0;
    var sum: u64 = 0;
    var buff_it = std.mem.splitScalar(u8, buff, '\n');
    while (buff_it.next()) |equations_buf| {
        var equation_it = std.mem.splitSequence(u8, equations_buf, ": ");
        const result: u64 = try std.fmt.parseInt(u64, equation_it.next().?, 10);
        //std.log.debug("{d}", .{result});

        var parts = std.ArrayList(u64).init(allocator);
        defer parts.deinit();

        var combination = std.ArrayList(u8).init(allocator);
        defer combination.deinit();

        var parts_it = std.mem.splitScalar(u8, equation_it.next().?, ' ');
        while (parts_it.next()) |parts_buf| {
            try parts.append(try std.fmt.parseInt(u64, parts_buf, 10));
            if (parts_it.peek() != null)
                try combination.append(0);
        }

        while (true) {
            const temp_result = try getResult(combination.items, parts.items);

            if (temp_result == result) {
                sum += result;
                break; // multiple combinations possible
            }
            if (stop(combination.items)) break;

            increment(combination.items);
        }
        c += 1;
        std.log.debug("{d}", .{c});
    }
    std.log.debug("sum {d}", .{sum});
}
