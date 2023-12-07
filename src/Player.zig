const std = @import("std");
const web = @import("web.zig");
const keys = @import("keys.zig");
const Box = @import("Box.zig");
const Renderer = @import("Renderer.zig");
const Rect = Renderer.Rect;
const Tile = @import("Tile.zig");
const Room = @import("Room.zig");

const use_joys_sprite = false;

pub const State = enum {
    idle,
    running,
    sliding,
    jumping,
    climbing,
    hurting,
};

pub const Input = struct {
    left: bool,
    right: bool,
    up: bool,
    down: bool,
    jump: bool,
    shoot: bool,

    pub fn combine(a: Input, b: Input) Input {
        return .{
            .left = a.left or b.left,
            .right = a.right or b.right,
            .up = a.up or b.up,
            .down = a.down or b.down,
            .jump = a.jump or b.jump,
            .shoot = a.shoot or b.shoot,
        };
    }

    pub fn scanKeyboard() Input {
        return .{
            .left = web.isKeyDown(keys.KEY_LEFT) or web.isKeyDown(keys.KEY_A),
            .right = web.isKeyDown(keys.KEY_RIGHT) or web.isKeyDown(keys.KEY_D),
            .up = web.isKeyDown(keys.KEY_UP) or web.isKeyDown(keys.KEY_W),
            .down = web.isKeyDown(keys.KEY_DOWN) or web.isKeyDown(keys.KEY_S),
            .jump = web.isKeyDown(keys.KEY_SPACE),
            .shoot = web.isKeyDown(keys.KEY_SHIFT),
        };
    }

    pub fn scanGamepad() Input {
        return .{
            .left = web.isButtonDown(14),
            .right = web.isButtonDown(15),
            .up = web.isButtonDown(12),
            .down = web.isButtonDown(13),
            .jump = web.isButtonDown(0),
            .shoot = web.isButtonDown(1),
        };
    }
};

const Player = @This();

pub const width = 16;
pub const height = 24;
const jump_speed = -0x04A5; // mega man 3
pub const vmax = 0x0700;
const max_health = 31;

var sprite: Renderer.Texture = undefined;
var hurt_fx: Renderer.Texture = undefined;
pub var no_clip: bool = false;

box: Box = .{ .x = 0, .y = 0, .w = width, .h = height },
vx: i32 = 0, // fixed point
vy: i32 = 0,
state: State = .idle,
face_left: bool = false,
health: u8 = max_health,
invincibility_frames: u8 = 0,
anim_time: u32 = 0,
slide_frames: u8 = 0,
shoot_frames: u8 = 0,

pub fn reset(self: *Player) void {
    self.* = .{};
}

pub fn load() void {
    if (use_joys_sprite) {
        sprite.loadFromUrl("img/zero-v2.png", 240, 32);
    } else {
        sprite.loadFromUrl("img/zero.png", 256, 64);
    }
    hurt_fx.loadFromUrl("img/hurt.png", 24, 24);
}

pub fn tick(self: *Player) void {
    self.anim_time +%= 1;
    self.invincibility_frames -|= 1;
    self.slide_frames -|= 1;
    self.shoot_frames -|= 1;
}

pub fn hurt(self: *Player, damage: u8) void {
    if (no_clip) return;
    if (self.invincibility_frames > 0) return;

    self.health -|= damage;
    if (self.state != .sliding) self.state = .hurting;
    self.invincibility_frames = 60;
}

pub fn draw(self: *Player) void {
    if (self.invincibility_frames % 6 >= 3) {
        if (self.state == .hurting) {
            Renderer.Sprite.draw(hurt_fx, self.box.x - 4, self.box.y);
        }
        return;
    }

    var src_rect = Rect.init(0, 0, 24, 32);
    const shooting = self.shoot_frames > 0;
    var flip_x = self.face_left;
    switch (self.state) {
        .idle => {
            if (!shooting) {
                if (self.anim_time > 200) src_rect.x = 24;
                if (self.anim_time > 210) self.anim_time = 0;
            }
        },
        .sliding => src_rect = if (use_joys_sprite) Rect.init(120, 8, 24, 24) else Rect.init(144, 6, 32, 26),
        .running => {
            var frame = (self.anim_time % 40) / 10;
            frame = switch (frame) {
                0 => 0,
                1, 3 => 1,
                2 => 2,
                else => unreachable,
            };
            src_rect.w = if (use_joys_sprite) 24 else 32;
            src_rect.x = 48 + @as(i32, @intCast(frame)) * src_rect.w;
        },
        .jumping => src_rect = if (use_joys_sprite) Rect.init(144 + @as(i32, @intCast((self.anim_time % 20) / 10)) * 24, 0, 24, 32) else Rect.init(176, 0, 32, 32),
        .climbing => {
            src_rect = if (use_joys_sprite) Rect.init(216, 0, 24, 32) else Rect.init(240, 0, 16, 32);
            flip_x = @mod(self.box.y, 20) < 10;
        },
        .hurting => src_rect = if (use_joys_sprite) Rect.init(192, 0, 24, 32) else Rect.init(208, 0, 32, 32),
    }
    if (shooting) {
        src_rect.y += 32;
        src_rect.w = 32;
    }
    var dst_rect = Rect.init(self.box.x + @divTrunc(self.box.w - src_rect.w, 2), self.box.y - 8, src_rect.w, src_rect.h);
    if (shooting and self.state == .idle) {
        dst_rect.x += if (flip_x) -4 else 4;
    }
    if (!use_joys_sprite) {
        switch (self.state) {
            .climbing => dst_rect.y += 4,
            .jumping => dst_rect.y += 5,
            .hurting => dst_rect.y += 6,
            else => {},
        }
    }
    if (flip_x) {
        src_rect.x += src_rect.w;
        src_rect.w = -src_rect.w;
    }
    Renderer.Sprite.drawFromTo(sprite, src_rect, dst_rect);
}

pub fn handleInput(self: *Player, room: Room, attribs: []const Tile.Attrib, input: Input, prev_input: Input) void {
    if (no_clip) {
        self.doNoClipMovement(input);
    } else {
        switch (self.state) {
            .idle, .running, .jumping => {
                self.doMovement(room, attribs, input, prev_input);
                self.doShooting(input, prev_input);
            },
            .climbing => {
                self.doClimbing(room, attribs, input, prev_input);
                self.doShooting(input, prev_input);
            },
            .sliding => self.doSliding(room, attribs, input, prev_input),
            .hurting => self.doHurting(room, attribs),
        }
    }
}

fn doShooting(self: *Player, input: Input, prev_input: Input) void {
    if (input.shoot and !prev_input.shoot) {
        self.shoot_frames = 16;
        // TODO: spawn shot
    }
}

fn doNoClipMovement(self: *Player, input: Input) void {
    self.state = .jumping;
    self.vx = 0;
    self.vy = 0;
    if (input.left) self.vx -= 0x400;
    if (input.right) self.vx += 0x400;
    if (input.up) self.vy -= 0x400;
    if (input.down) self.vy += 0x400;
}

fn doMovement(player: *Player, room: Room, attribs: []const Tile.Attrib, input: Input, prev_input: Input) void {
    player.vx = 0;
    const on_ground = room.clipY(attribs, player.box, 1) == 0; // moving 1 pixel down
    if (!on_ground) {
        // apply gravity
        player.vy += 0x40;
        if (player.vy > vmax) player.vy = vmax;
    } else {
        player.vy = 0;
    }

    if (input.left) player.vx -= 0x200; //-0x014C;
    if (input.right) player.vx += 0x200; //0x014C;
    if (input.jump and !prev_input.jump and on_ground) {
        player.vy = jump_speed;
    }
    if (!input.jump and player.vy < -0x021f) {
        // jump key released
        player.vy = 0;
    }
    if (input.down and on_ground) {
        const sense_x = player.box.x + @divTrunc(player.box.w, 2);
        const sense_y = player.box.y + player.box.h;
        if (room.getTileAttribAtPixel(attribs, sense_x, sense_y) == .ladder) { // do climbing stuff
            player.box.x = @divTrunc(sense_x, Tile.size) * Tile.size;
            player.box.y = sense_y - 8;
            player.vx = 0;
            player.vy = 0;
            player.state = .climbing;
            return;
        } else if (input.jump and !prev_input.jump) {
            player.state = .sliding;
            if (player.box.h == height) {
                player.box.y += 8;
                player.box.h -= 8;
            }
            player.slide_frames = 24;
            player.shoot_frames = 0;
            player.vy = 0;
            return;
        }
    }
    if (input.up) {
        const sense_x = player.box.x + @divTrunc(player.box.w, 2);
        const sense_y = player.box.y + @divTrunc(player.box.h, 2);
        const ta = room.getTileAttribAtPixel(attribs, sense_x, sense_y);
        if (ta == .ladder) {
            player.box.x = @divTrunc(sense_x, Tile.size) * Tile.size;
            player.vx = 0;
            player.state = .climbing;
            return;
        }
    }

    if (player.vx == 0) {
        player.state = .idle;
    } else if (player.vx > 0) {
        player.state = .running;
        player.face_left = false;
    } else if (player.vx < 0) {
        player.state = .running;
        player.face_left = true;
    }
    if (!on_ground) {
        player.state = .jumping;
    }
}

fn doClimbing(player: *Player, room: Room, attribs: []const Tile.Attrib, input: Input, prev_input: Input) void {
    if (input.left) player.face_left = true;
    if (input.right) player.face_left = false;
    player.vy = 0;
    if (input.up) {
        player.vy = -0x0100;
    }
    if (input.down) {
        const on_ground = room.clipY(attribs, player.box, 1) == 0; // moving 1 pixel down
        if (on_ground) {
            player.state = .idle;
        } else {
            player.vy = 0x0100;
        }
    }
    if (input.jump and !prev_input.jump and !input.up) {
        player.state = .jumping;
        player.vy = 0;
        return;
    }

    // climb off ladder
    const sense_x = player.box.x + @divTrunc(player.box.w, 2);
    const sense_y = player.box.y + @divTrunc(player.box.h, 2);
    if (room.getTileAttribAtPixel(attribs, sense_x, sense_y) == .none) {
        const tile_y = @divFloor(sense_y, Tile.size);
        if (room.getTileAttribAtPixel(attribs, sense_x, (tile_y + 1) * Tile.size) == .ladder) {
            // top edge of ladder -> snap player's y position
            player.box.y = tile_y * Tile.size - 8;
        }
        player.vy = 0;
        player.state = .idle;
        return;
    }
}

fn doSliding(player: *Player, room: Room, attribs: []const Tile.Attrib, input: Input, prev_input: Input) void {
    var stand_up: bool = player.slide_frames == 0;

    // change direction
    if (input.left and !prev_input.left and !player.face_left) {
        player.face_left = true;
        stand_up = true;
    }
    if (input.right and !prev_input.right and player.face_left) {
        player.face_left = false;
        stand_up = true;
    }
    player.vx = if (player.face_left) -0x300 else 0x300;

    const on_ground = room.clipY(attribs, player.box, 1) == 0; // moving 1 pixel down
    if (input.jump and !prev_input.jump and on_ground) {
        player.vy = jump_speed;
        stand_up = true;
    }

    if (stand_up or !on_ground) {
        player.slide_frames = 0;
        player.state = if (!on_ground) .jumping else .idle;
        player.box.y -= 8;
        player.box.h += 8;
        if (room.overlap(attribs, player.box)) { // can't stand up
            player.box.y += 8;
            player.box.h -= 8;
            player.vy = 0;
            player.state = .sliding;
        } else {
            return;
        }
    }
}

fn doHurting(player: *Player, room: Room, attribs: []const Tile.Attrib) void {
    const on_ground = room.clipY(attribs, player.box, 1) == 0; // moving 1 pixel down
    if (!on_ground) {
        // apply gravity
        player.vy += 0x40;
        if (player.vy > vmax) player.vy = vmax;
    } else {
        player.vy = 0;
    }
    player.vx = if (player.face_left) 0x100 else -0x100; // TODO: subpixel movement

    if (player.invincibility_frames < 30) {
        player.state = .idle;
    }
}
