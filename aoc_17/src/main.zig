const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn combo(operand: i64, a: i64, b: i64, c: i64) i64 {
    return switch (operand) {
        0, 1, 2, 3 => operand,
        4 => a,
        5 => b,
        6 => c,
        else => unreachable,
    };
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buff);

    var program = std.ArrayList(i64).init(allocator);
    defer program.deinit();

    var output = std.ArrayList(i64).init(allocator);
    defer output.deinit();

    var reg_a: i64 = 0;
    var reg_b: i64 = 0;
    var reg_c: i64 = 0;
    var instruction: i64 = 0;

    var buff_it = std.mem.splitAny(u8, buff, " \n");
    for (0..2) |_| _ = buff_it.next();
    reg_a = try std.fmt.parseInt(i64, buff_it.next().?, 10);
    for (0..2) |_| _ = buff_it.next();
    reg_b = try std.fmt.parseInt(i64, buff_it.next().?, 10);
    for (0..2) |_| _ = buff_it.next();
    reg_c = try std.fmt.parseInt(i64, buff_it.next().?, 10);
    for (0..2) |_| _ = buff_it.next();
    var program_it = std.mem.splitAny(u8, buff_it.next().?, ",");
    while (program_it.next()) |el|
        try program.append(try std.fmt.parseInt(i64, el, 10));

    while (instruction < program.items.len - 1) {
        const opcode = program.items[@intCast(instruction)];
        const operand = program.items[@intCast(instruction + 1)];

        switch (opcode) {
            0 => { // adv
                reg_a = @divTrunc(reg_a, std.math.pow(i64, 2, combo(operand, reg_a, reg_b, reg_c)));
            },
            1 => { // bxl
                reg_b = reg_b ^ operand;
            },
            2 => { // bst
                reg_b = @mod(combo(operand, reg_a, reg_b, reg_c), 8);
            },
            3 => { // jnz
                if (reg_a != 0) {
                    instruction = operand;
                    continue;
                }
            },
            4 => { // bxc
                reg_b = reg_b ^ reg_c;
            },
            5 => { // out
                const out = @mod(combo(operand, reg_a, reg_b, reg_c), 8);
                std.log.debug("{d}", .{out});
            },
            6 => { //bdv
                reg_b = @divTrunc(reg_a, std.math.pow(i64, 2, combo(operand, reg_a, reg_b, reg_c)));
            },
            7 => { //bdv
                reg_c = @divTrunc(reg_a, std.math.pow(i64, 2, combo(operand, reg_a, reg_b, reg_c)));
            },
            else => unreachable,
        }

        instruction += 2;
    }
}
