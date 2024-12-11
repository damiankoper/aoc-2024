const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const StoneBlink = struct { left: u64, right: ?u64 };

fn applyBlinkToStone(stone: u64) !StoneBlink {
    if (stone == 0) {
        return StoneBlink{ .left = 1, .right = null };
    } else {
        const str = try std.fmt.allocPrint(allocator, "{d}", .{stone});
        if (str.len % 2 == 0) {
            const left = try std.fmt.parseInt(u64, str[0 .. str.len / 2], 10);
            const right = try std.fmt.parseInt(u64, str[str.len / 2 .. str.len], 10);
            return StoneBlink{ .left = left, .right = right };
        } else {
            return StoneBlink{ .left = stone * 2024, .right = null };
        }
    }
}

fn applyBlink(stone: u64, blink: usize, memo: *std.ArrayList(std.AutoHashMap(u64, u64))) !u64 {
    const memo_stone = memo.items[blink].get(stone);
    if (memo_stone != null) return memo_stone.?;

    if (blink == 75) return 1;
    std.log.debug("{any}", .{blink});
    const after_blink = try applyBlinkToStone(stone);
    // std.log.debug("{any}", .{after_blink});

    const left_blink = try applyBlink(after_blink.left, blink + 1, memo);

    var right_blink: u64 = 0;
    if (after_blink.right != null) {
        right_blink += try applyBlink(after_blink.right.?, blink + 1, memo);
    }

    const result = left_blink + right_blink;
    try memo.items[blink].put(stone, result);
    return result;
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    var buff_it = std.mem.splitScalar(u8, buff, ' ');

    var memo = std.ArrayList(std.AutoHashMap(u64, u64)).init(allocator);
    defer memo.deinit();
    defer for (memo.items, 0..) |_, i| memo.items[i].deinit();

    for (0..76) |_| {
        try memo.append(std.AutoHashMap(u64, u64).init(allocator));
    }

    var stone_count: u64 = 0;
    while (buff_it.next()) |line| {
        const stone = try std.fmt.parseInt(u64, line, 10);

        stone_count += try applyBlink(stone, 0, &memo);
    }
    std.log.debug("{any}", .{stone_count});
}
