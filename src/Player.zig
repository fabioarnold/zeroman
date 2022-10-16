const web = @import("web.zig");
const keys = @import("keys.zig");
const Box = @import("Box.zig");
const Renderer = @import("Renderer.zig");
const Tile = @import("Tile.zig");
const Room = @import("Room.zig");

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

    pub fn combine(a: Input, b: Input) Input {
        return .{
            .left = a.left or b.left,
            .right = a.right or b.right,
            .up = a.up or b.up,
            .down = a.down or b.down,
            .jump = a.jump or b.jump,
        };
    }

    pub fn scanKeyboard() Input {
        return .{
            .left = web.isKeyDown(keys.KEY_LEFT),
            .right = web.isKeyDown(keys.KEY_RIGHT),
            .up = web.isKeyDown(keys.KEY_UP),
            .down = web.isKeyDown(keys.KEY_DOWN),
            .jump = web.isKeyDown(keys.KEY_SPACE),
        };
    }

    pub fn scanGamepad() Input {
        return .{
            .left = web.isButtonDown(14),
            .right = web.isButtonDown(15),
            .up = web.isButtonDown(12),
            .down = web.isButtonDown(13),
            .jump = web.isButtonDown(0),
        };
    }
};

const Player = @This();

pub const width = 16;
pub const height = 24;
const jump_speed = -0x04A5; // mega man 3

box: Box = .{ .x = 0, .y = 0, .w = width, .h = height },
vx: i32 = 0, // fixed point
vy: i32 = 0,
state: State = .idle,
anim_time: i32 = 0,
slide_frames: u8 = 0,
face_left: bool = false,
sprite: Renderer.Sprite,

pub fn load(self: *Player) void {
    self.sprite.texture.loadFromUrl("img/zero.png", 224, 32);
}

pub fn tick(self: *Player) void {
    self.anim_time += 1;
    if (self.slide_frames > 0) {
        self.slide_frames -= 1;
    }
}

pub fn draw(self: *Player, context: Renderer.RenderContext) void {
    const bigger_sprite = true;
    var src_rect = if (bigger_sprite) Renderer.Rect2.new(0, 0, 24, 32) else Renderer.Rect2.new(0, 8, 24, 24);
    var flip_x = self.face_left;
    switch (self.state) {
        .idle => {
            if (self.anim_time > 200) src_rect.pos.data[0] = 24;
            if (self.anim_time > 210) self.anim_time = 0;
        },
        .sliding => {
            src_rect.pos.data[0] = 144;
            src_rect.pos.data[1] = 6;
            src_rect.size.data[0] = 32;
            src_rect.size.data[1] = 26;
        },
        .running => {
            if (self.anim_time >= 40) self.anim_time = 0;
            const frame = @divTrunc(self.anim_time, 10);
            if (frame == 0) {
                src_rect.pos.data[0] = 48;
            } else if (frame == 1 or frame == 3) {
                src_rect.pos.data[0] = 80;
            } else if (frame == 2) {
                src_rect.pos.data[0] = 112;
            }
            src_rect.size.data[0] = 32;
        },
        .jumping => {
            src_rect.pos.data[0] = 176;
            src_rect.pos.data[1] = 0;
            src_rect.size.data[0] = 32;
            src_rect.size.data[1] = 32;
        },
        .climbing => {
            src_rect.pos.data[0] = 208;
            src_rect.pos.data[1] = 0;
            src_rect.size.data[0] = 16;
            src_rect.size.data[1] = 32;
            flip_x = @mod(self.box.y, 20) < 10;
        },
        else => unreachable,
    }
    var dst_rect = Renderer.Rect2.new(@intToFloat(f32, self.box.x + @divTrunc(self.box.w - @floatToInt(i32, src_rect.size.data[0]), 2)), @intToFloat(f32, self.box.y), src_rect.size.data[0], src_rect.size.data[1]);
    if (bigger_sprite) {
        dst_rect.pos.data[1] -= 8;
        if (self.state == .climbing) dst_rect.pos.data[1] += 4;
        if (self.state == .jumping) dst_rect.pos.data[1] += 5;
    } else {
        if (self.state == .sliding) dst_rect.pos.data[1] -= 8;
        if (self.state == .climbing) dst_rect.pos.data[1] -= 4;
    }
    if (flip_x) {
        src_rect.pos.data[0] += src_rect.size.data[0];
        src_rect.size.data[0] = -src_rect.size.data[0];
    }
    self.sprite.draw(context, src_rect, dst_rect);
}

pub fn handleInput(player: *Player, room: Room, attribs: []const Tile.Attrib, input: Input, prev_input: Input) void {
    switch (player.state) {
        .idle, .running, .jumping => doMovement(player, room, attribs, input, prev_input),
        .climbing => doClimbing(player, room, attribs, input, prev_input),
        .sliding => doSliding(player, room, attribs, input, prev_input),
        else => {},
    }
}

fn doMovement(player: *Player, room: Room, attribs: []const Tile.Attrib, input: Input, prev_input: Input) void {
    player.vx = 0;
    var on_ground = room.clipY(attribs, player.box, 1) == 0; // moving 1 pixel down
    if (!on_ground) {
        // apply gravity
        player.vy += 0x40;
        if (player.vy > 0x0700) player.vy = 0x0700; // vmax
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
        var on_ground = room.clipY(attribs, player.box, 1) == 0; // moving 1 pixel down
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
        const tile_y = @divTrunc(sense_y, Tile.size);
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

    var on_ground = room.clipY(attribs, player.box, 1) == 0; // moving 1 pixel down
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
