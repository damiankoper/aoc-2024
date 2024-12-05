const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));

    var buff_it = std.mem.splitSequence(u8, buff, "\n\n");

    var rules = std.AutoHashMap(i32, std.ArrayList(i32)).init(allocator);
    defer rules.deinit();

    var rules_defer_it = rules.iterator();
    defer while (rules_defer_it.next()) |k| k.value_ptr.deinit();

    const rules_buff = buff_it.next();
    if (rules_buff != null) {
        var rules_it = std.mem.splitScalar(u8, rules_buff.?, '\n');
        while (rules_it.next()) |rule_buff| {
            var rule_it = std.mem.splitScalar(u8, rule_buff, '|');
            const left = try std.fmt.parseInt(i32, rule_it.next().?, 10);
            const right = try std.fmt.parseInt(i32, rule_it.next().?, 10);

            const must_be_after = try rules.getOrPut(left);
            const value = std.ArrayList(i32).init(allocator);
            if (!must_be_after.found_existing) {
                must_be_after.value_ptr.* = value;
            }
            try must_be_after.value_ptr.append(right);
        }
    }

    var sum_correct: i32 = 0;
    var sum_incorrect: i32 = 0;
    const updates_buff = buff_it.next();
    if (updates_buff != null) {
        var updates_it = std.mem.splitScalar(u8, updates_buff.?, '\n');
        while (updates_it.next()) |update_buff| {
            var update_it = std.mem.splitScalar(u8, update_buff, ',');
            var update_values = std.ArrayList(i32).init(allocator);
            defer update_values.deinit();
            while (update_it.next()) |update_value| {
                const value_parsed = try std.fmt.parseInt(i32, update_value, 10);
                try update_values.append(value_parsed);
            }

            var right_order = true;
            for (update_values.items, 0..) |value, i| {
                const must_be_after = rules.get(value);
                if (must_be_after != null) {
                    for (must_be_after.?.items) |after_value| {
                        const found = std.mem.indexOfScalar(i32, update_values.items[0..i], after_value);
                        if (found != null) {
                            right_order = false;
                        }
                    }
                }
            }

            if (right_order) {
                sum_correct += update_values.items[update_values.items.len / 2];
            } else {
                const cmp = struct {
                    pub fn call(_rules: std.AutoHashMap(i32, std.ArrayList(i32)), lhs: i32, rhs: i32) bool {
                        const must_be_after = _rules.get(lhs);
                        if (must_be_after != null) {
                            const found = std.mem.indexOfScalar(i32, must_be_after.?.items, rhs);
                            if (found != null) return true;
                        }
                        return false;
                    }
                }.call;

                std.log.debug("{any}", .{update_values.items});
                std.mem.sort(i32, update_values.items, rules, cmp);
                std.log.debug("{any}", .{update_values.items});
                sum_incorrect += update_values.items[update_values.items.len / 2];
            }
        }
    }

    std.log.debug("{d}", .{sum_correct});
    std.log.debug("{d}", .{sum_incorrect});
}
