const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const StringIterator = struct {
    string: []const u8,
    index: usize = 0,
    fn peek(self: *StringIterator) ?u8 {
        if (self.string.len - 1 < self.index) {
            return null;
        } else {
            return self.string[self.index];
        }
    }
    fn next(self: *StringIterator) ?u8 {
        const value: ?u8 = self.peek();
        if (self.string.len - 1 >= self.index)
            self.index += 1;
        return value;
    }
};

const MulParseResult = struct { left: i32, right: i32 };

fn parseNumber(chars: *StringIterator) !?i32 {
    var charBuff = std.ArrayList(u8).init(allocator);
    defer charBuff.deinit();

    while (chars.peek()) |char| {
        switch (char) {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                _ = try charBuff.append(char);
                _ = chars.next();
            },
            else => {
                break;
            },
        }
        std.log.debug("parseNumber: {c}", .{char});
    }

    const number = std.fmt.parseInt(i32, charBuff.items, 10);
    std.log.debug("{any}", .{number});
    return number catch return null;
}

fn parseMul(chars: *StringIterator) !?MulParseResult {
    if (chars.next().? != 'm') return null;
    if (chars.next().? != 'u') return null;
    if (chars.next().? != 'l') return null;
    if (chars.next().? != '(') return null;
    const left = try parseNumber(chars);
    if (left == null) return null;
    if (chars.next().? != ',') return null;
    const right = try parseNumber(chars);
    if (right == null) return null;
    if (chars.next().? != ')') return null;

    return .{ .left = left.?, .right = right.? };
}

fn parseDo(chars: *StringIterator) bool {
    if (chars.next().? != 'd') return false;
    if (chars.next().? != 'o') return false;
    if (chars.next().? != '(') return false;
    if (chars.next().? != ')') return false;

    return true;
}

fn parseDont(chars: *StringIterator) bool {
    std.log.debug("{c}", .{chars.peek().?});
    if (chars.next().? != 'd') return false;
    if (chars.next().? != 'o') return false;
    if (chars.next().? != 'n') return false;
    if (chars.next().? != '\'') return false;
    if (chars.next().? != 't') return false;
    if (chars.next().? != '(') return false;
    if (chars.next().? != ')') return false;

    return true;
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));

    var sum: i32 = 0;
    var chars = StringIterator{ .string = buff };
    var enabled = true;
    while (chars.peek()) |char| {
        switch (char) {
            'd' => {
                var chars_clone_do = chars;
                const do = parseDo(&chars_clone_do);
                if (do) enabled = true;
                const dont = parseDont(&chars);
                if (dont) enabled = false;
            },
            'm' => {
                const result = try parseMul(&chars);
                if (result != null and enabled) {
                    sum += result.?.left * result.?.right;
                }
            },
            else => {
                _ = chars.next();
            },
        }
    }

    std.log.debug("sum: {d}", .{sum});
}
