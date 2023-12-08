const math = @import("std").math;
const Renderer = @import("Renderer.zig");
const Rect = Renderer.Rect;
const Sprite = Renderer.Sprite;

var effects_tex: Renderer.Texture = undefined;
var teleport_tex: Renderer.Texture = undefined;
pub var hurt_fx: Renderer.Texture = undefined;

pub fn load() void {
    effects_tex.loadFromUrl("img/effects.png", 120, 24);
    teleport_tex.loadFromUrl("img/teleport.png", 24, 32);
    hurt_fx.loadFromUrl("img/hurt.png", 24, 24);
}

pub fn drawDeathEffect(x: i32, y: i32, counter: u32) void {
    const frame = @as(i32, @intCast((counter / 3) % 6));
    const src_rect = Rect.init(frame * 24, 0, 24, 24);

    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const angle: f32 = math.pi * @as(f32, @floatFromInt(i)) / 4.0;
        const r: f32 = 2 * @as(f32, @floatFromInt(counter));
        const dx = x + @as(i32, @intFromFloat(r * @cos(angle)));
        const dy = y + @as(i32, @intFromFloat(r * @sin(angle)));
        Sprite.drawFrame(effects_tex, src_rect, dx, dy);
    }
}

pub fn drawDeathEffectSmall(x: i32, y: i32, counter: u8) void {
    const frame = counter;
    if (frame > 4) return;
    const src_rect = Rect.init(frame * 24, 0, 24, 24);
    Sprite.drawFrame(effects_tex, src_rect, x - 12, y - 12);
}

pub fn drawTeleportEffect(player_x: i32, player_y: i32, counter: u8) void {
    if (counter < 32) return;
    const frame: i32 = counter - 32;
    const x = player_x;
    var y = player_y;
    if (frame <= 10 or frame == 15) {
        if (frame != 15) y -= 16 * (10 - frame);
        const src_rect = Rect.init(8, 0, 8, 8);
        var i: i32 = 0;
        while (i < 4) : (i += 1) {
            Sprite.drawFrame(teleport_tex, src_rect, x - 4, y + i * 8 - 32);
        }
    } else if (frame <= 12) {
        Sprite.drawFrame(teleport_tex, Rect.init(0, 16, 24, 16), x - 12, y - 16);
        Sprite.drawFrame(teleport_tex, Rect.init(0, 16, 24, 8), x - 12, y - 24);
        Sprite.drawFrame(teleport_tex, Rect.init(8, 8, 8, 8), x - 4, y - 32);
    } else if (frame <= 14) {
        Sprite.drawFrame(teleport_tex, Rect.init(0, 24, 24, 8), x - 12, y - 8);
        Sprite.drawFrame(teleport_tex, Rect.init(8, 8, 8, 8), x - 4, y - 16);
    }
}
