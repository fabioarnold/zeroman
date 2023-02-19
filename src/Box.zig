const Rect2i = @import("Renderer.zig").Rect2i;

const Box = @This();

x: i32,
y: i32,
w: i32,
h: i32,

pub fn init(x: i32, y: i32, w: i32, h: i32) Box {
    return Box{ .x = x, .y = y, .w = w, .h = h };
}

pub fn toRect2i(self: Box) Rect2i {
    return Rect2i.init(self.x, self.y, self.w, self.h);
}

pub fn overlaps(self: Box, other: Box) bool {
    return self.x < other.x + other.w and self.x + self.w > other.x and self.y < other.y + other.h and self.y + self.h > other.y;
}

// like raycast in x dir by amount
pub fn castX(self: Box, amount: i32, other: Box) i32 {
    // check y interval
    if (self.y >= other.y + other.h or self.y + self.h <= other.y) return amount;

    if (amount > 0 and self.x < other.x + other.w) {
        if (self.x + self.w + amount > other.x) {
            return other.x - (self.x + self.w);
        }
    } else if (amount < 0 and self.x + self.w > other.x) {
        if (self.x + amount < other.x + other.w) {
            return other.x + other.w - self.x;
        }
    }

    return amount;
}

// like raycast in y dir by amount
pub fn castY(self: Box, amount: i32, other: Box) i32 {
    // check x interval
    if (self.x >= other.x + other.w or self.x + self.w <= other.x) return amount;

    if (amount > 0 and self.y < other.y + other.h) {
        if (self.y + self.h + amount > other.y) {
            return other.y - (self.y + self.h);
        }
    } else if (amount < 0 and self.y + self.h > other.y) {
        if (self.y + amount < other.y + other.h) {
            return other.y + other.h - self.y;
        }
    }

    return amount;
}
