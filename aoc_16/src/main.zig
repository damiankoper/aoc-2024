const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Vector = struct {
    x: i64,
    y: i64,

    pub fn create_i64(_x: i64, _y: i64) Vector {
        return Vector{ .x = _x, .y = _y };
    }

    pub fn create_usize(_x: usize, _y: usize) Vector {
        return Vector{ .x = @intCast(_x), .y = @intCast(_y) };
    }

    fn eq(self: *const Vector, vector: Vector) bool {
        return self.x == vector.x and self.y == vector.y;
    }
    fn add(self: *const Vector, vector: Vector) Vector {
        return Vector.create_i64(self.x + vector.x, self.y + vector.y);
    }
    fn rotLeft(self: *const Vector) Vector {
        return Vector.create_i64(self.y, -self.x);
    }
    fn rotRight(self: *const Vector) Vector {
        return Vector.create_i64(-self.y, self.x);
    }
    fn reverse(self: *const Vector) Vector {
        return Vector.create_i64(-self.x, -self.y);
    }
};

const PathStep = struct {
    step: Vector,
    dir: Vector,

    pub fn create(step: Vector, dir: Vector) PathStep {
        return PathStep{ .step = step, .dir = dir };
    }
};

const Path = struct {
    score: i64,
    steps: std.ArrayList(PathStep),

    pub fn create(score: i64, path_step: PathStep, prev_path_steps: ?std.ArrayList(PathStep)) !Path {
        var path_steps = std.ArrayList(PathStep).init(allocator);
        if (prev_path_steps != null)
            try path_steps.appendSlice(prev_path_steps.?.items);
        try path_steps.append(path_step);

        return Path{ .score = score, .steps = path_steps };
    }

    fn lastPathStep(self: *const Path) PathStep {
        return self.steps.items[self.steps.items.len - 1];
    }

    fn lastStep(self: *const Path) Vector {
        return self.steps.items[self.steps.items.len - 1].step;
    }

    fn lastDir(self: *const Path) Vector {
        return self.steps.items[self.steps.items.len - 1].dir;
    }

    fn deinit(self: *const Path) void {
        self.steps.deinit();
    }
};

fn printMap(map: std.ArrayList([]u8)) void {
    for (map.items) |line| {
        std.log.debug("{s}", .{line});
    }
    std.log.debug("\n", .{});
}

fn printNumMap(map: std.ArrayList([]i64)) void {
    for (map.items) |line| {
        for (line) |*i| {
            if (i.* == std.math.maxInt(i64)) i.* = 9999;
        }
        std.log.debug("{any}", .{line});
    }
    std.log.debug("\n", .{});
}

fn findPos(map: *std.ArrayList([]u8), pos: u8) Vector {
    for (map.items, 0..) |line, _y| {
        for (line, 0..) |char, _x| {
            if (char == pos) return Vector.create_usize(_x, _y);
        }
    }
    unreachable;
}

fn cloneMap(visited_map: std.ArrayList([]u8)) !std.ArrayList([]u8) {
    const result = try visited_map.clone();
    for (result.items) |*item| {
        item.* = try allocator.dupe(u8, item.*);
    }
    return result;
}

fn vectorIn(vector: Vector, arr: std.ArrayList(Vector)) bool {
    for (arr.items) |item| {
        if (item.eq(vector)) return true;
    }
    return false;
}
var c: i64 = 0;
fn getScore(
    map: *std.ArrayList([]u8),
    min_score_map: *std.AutoHashMap(PathStep, i64),
    path_step: PathStep,
    score: i64,
    dir_changed: bool,
) ?i64 {
    const curr = map.items[@intCast(path_step.step.y)][@intCast(path_step.step.x)];
    const curr_score = min_score_map.get(path_step);

    if (curr == '#') {
        return null;
    } else {
        var new_score: i64 = score + 1;
        if (dir_changed) new_score += 1000;
        if (curr_score == null or new_score <= curr_score.?) return new_score;
    }

    return null;
}

fn setMinScore(
    min_score_map: *std.AutoHashMap(PathStep, i64),
    path_step: PathStep,
    score: i64,
) !void {
    try min_score_map.put(path_step, score);
}

fn setVisited(
    map: *std.ArrayList([]u8),
    pos: Vector,
) void {
    if (map.items[@intCast(pos.y)][@intCast(pos.x)] == 'K') {
        map.items[@intCast(pos.y)][@intCast(pos.x)] = 'O';
    } else {
        map.items[@intCast(pos.y)][@intCast(pos.x)] = 'K';
    }
}

fn isWall(map: *std.ArrayList([]u8), pos: Vector) bool {
    return map.items[@intCast(pos.y)][@intCast(pos.x)] == '#';
}

pub fn main() !void {
    var stdio_reader = std.io.getStdIn().reader();
    const buff = try stdio_reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buff);

    var map = std.ArrayList([]u8).init(allocator);
    defer map.deinit();

    var min_score_map = std.AutoHashMap(PathStep, i64).init(allocator);
    defer min_score_map.deinit();

    var buff_it = std.mem.splitSequence(u8, buff, "\n");
    while (buff_it.next()) |line| {
        try map.append(try allocator.dupe(u8, line));

        const min_score_line = try allocator.alloc(i64, line.len);
        for (min_score_line) |*item| item.* = std.math.maxInt(i64);
    }

    const start = findPos(&map, 'S');
    const end = findPos(&map, 'E');

    var queue = std.ArrayList(Path).init(allocator);
    var best_paths = std.ArrayList(Path).init(allocator);

    const path_start = try Path.create(0, PathStep.create(start, Vector.create_i64(1, 0)), null);
    try queue.append(path_start);

    while (queue.items.len > 0) {
        var newQueue = std.ArrayList(Path).init(allocator);
        for (queue.items) |path_curr| {
            const step = path_curr.lastStep();
            const dir = path_curr.lastDir();
            const score = path_curr.score;

            if (@mod(c, 1000) == 0) {
                c += 1;
                std.log.debug("{?}", .{step});
            }

            if (step.eq(end)) {
                if (best_paths.items.len > 0 and score < best_paths.items[0].score)
                    best_paths.clearAndFree();

                if (best_paths.items.len == 0 or score <= best_paths.items[0].score)
                    try best_paths.append(path_curr);
                continue;
            }
            defer path_curr.deinit();

            if (isWall(&map, step)) continue;

            const min_score = min_score_map.get(path_curr.lastPathStep());
            if (min_score != null and score > min_score.?) continue;

            try min_score_map.put(path_curr.lastPathStep(), score);

            const step_straight = step.add(dir);
            const step_straight_path_step = PathStep.create(step_straight, dir);
            const path_next_straight = try Path.create(score + 1, step_straight_path_step, path_curr.steps);
            try newQueue.append(path_next_straight);

            const right_dir = dir.rotRight();
            const step_right = step.add(right_dir);
            const step_right_path_step = PathStep.create(step_right, right_dir);
            const path_next_right = try Path.create(score + 1001, step_right_path_step, path_curr.steps);
            try newQueue.append(path_next_right);

            const left_dir = dir.rotLeft();
            const step_left = step.add(left_dir);
            const step_left_path_step = PathStep.create(step_left, left_dir);
            const path_next_left = try Path.create(score + 1001, step_left_path_step, path_curr.steps);
            try newQueue.append(path_next_left);

            // std.log.debug("{?}", .{min_score_map.get(path_curr.lastPathStep())});
            // setVisited(&map, step);
            // printMap(map);
            // std.time.sleep(std.time.ns_per_s / 32);
        }
        queue.clearAndFree();
        queue = newQueue;
    }

    var view_tiles: i64 = 0;
    for (best_paths.items) |path| {
        for (path.steps.items) |step| {
            setVisited(&map, step.step);
        }
    }

    for (map.items) |line| {
        for (line) |char| {
            if (char == 'O')
                view_tiles += 1;
        }
    }

    std.log.debug("{?} {?}", .{ view_tiles, c });
    // printNumMap(min_score_map);

}
