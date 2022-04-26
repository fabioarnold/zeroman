const za = @import("zalgebra");
const Vec2 = za.Vec2;
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const gl = @import("webgl.zig");

var video_width: f32 = 1280;
var video_height: f32 = 720;
var video_scale: f32 = 1;
const fb_width: u32 = 256;
const fb_height: u32 = 240;
var fbo: gl.GLuint = undefined;
var fbo_tex: gl.GLuint = undefined;
var blit_vbo: gl.GLuint = undefined;

var blit_scaled: struct {
    program: gl.GLuint,
    scale_loc: gl.GLint,
} = undefined;

var blit2d: struct {
    program: gl.GLuint,
    mvp_loc: gl.GLint,
    texmat_loc: gl.GLint,
} = undefined;

var tiled: struct {
    program: gl.GLuint,
    map_loc: gl.GLint,
    map_size_loc: gl.GLint,
    tiles_loc: gl.GLint,
    tiles_size_loc: gl.GLint,
    mvp_loc: gl.GLint,
    texmat_loc: gl.GLint,
} = undefined;

pub const Rect2 = struct {
    pos: Vec2,
    size: Vec2,

    pub fn new(x: f32, y: f32, w: f32, h: f32) Rect2 {
        return Rect2{ .pos = Vec2.new(x, y), .size = Vec2.new(w, h) };
    }
};

pub const RenderContext = struct {
    projection: Mat4,
    view: Mat4,
};

pub const Texture = struct {
    handle: gl.GLuint,
    size: Vec2,
};

pub const Sprite = struct {
    tex: gl.GLuint,
    tex_size: Vec2,

    pub fn load(self: *Sprite, url: []const u8, width: f32, height: f32) void {
        self.tex = gl.glLoadTexture(url.ptr, url.len);
        self.tex_size = Vec2.new(width, height);
        gl.glBindTexture(gl.GL_TEXTURE_2D, self.tex);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
    }

    pub fn draw(self: Sprite, context: RenderContext, src_rect: Rect2, dst_rect: Rect2) void {
        var translation = Mat4.fromTranslate(Vec3.new(dst_rect.pos.data[0], dst_rect.pos.data[1], 0));
        var scale = Mat4.fromScale(Vec3.new(dst_rect.size.data[0], dst_rect.size.data[1], 0));
        const model = translation.mul(scale);
        const mvp = context.projection.mul(context.view.mul(model));
        gl.glUseProgram(blit2d.program);
        gl.glUniformMatrix4fv(blit2d.mvp_loc, 1, gl.GL_FALSE, &mvp.data[0]);
        const inv_scale = Mat4.fromScale(Vec3.new(1.0 / self.tex_size.data[0], 1.0 / self.tex_size.data[1], 0));
        translation = Mat4.fromTranslate(Vec3.new(src_rect.pos.data[0], src_rect.pos.data[1], 0));
        scale = Mat4.fromScale(Vec3.new(src_rect.size.data[0], src_rect.size.data[1], 0));
        const tex_mat = inv_scale.mul(translation).mul(scale);
        gl.glUniformMatrix4fv(blit2d.texmat_loc, 1, gl.GL_FALSE, &tex_mat.data[0]);
        gl.glBindTexture(gl.GL_TEXTURE_2D, self.tex);
        gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 4, 4);
    }
};

fn loadShader(vert_src: []const u8, frag_src: []const u8) gl.GLuint {
    const vert_shader = gl.glInitShader(vert_src.ptr, vert_src.len, gl.GL_VERTEX_SHADER);
    const frag_shader = gl.glInitShader(frag_src.ptr, frag_src.len, gl.GL_FRAGMENT_SHADER);
    return gl.glLinkShaderProgram(vert_shader, frag_shader);
}

pub fn init() void {
    gl.glEnable(gl.GL_BLEND);
    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA);

    gl.glGenFramebuffers(1, &fbo);
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fbo);
    gl.glGenTextures(1, &fbo_tex);
    gl.glBindTexture(gl.GL_TEXTURE_2D, fbo_tex);
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, fb_width, fb_height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, null, 0);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, fbo_tex, 0);
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0);
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);

    const blit_frag_src = @embedFile("shaders/blit.frag");
    const tiled_frag_src = @embedFile("shaders/tiled.frag");
    const blit2d_vert_src = @embedFile("shaders/blit2d.vert");
    const blitscaled_vert_src = @embedFile("shaders/blitscaled.vert");
    blit2d.program = loadShader(blit2d_vert_src, blit_frag_src);
    gl.glUseProgram(blit2d.program);
    blit2d.mvp_loc = gl.glGetUniformLocation(blit2d.program, "u_mvp", "u_mvp".len);
    blit2d.texmat_loc = gl.glGetUniformLocation(blit2d.program, "u_texmat", "u_texmat".len);
    blit_scaled.program = loadShader(blitscaled_vert_src, blit_frag_src);
    gl.glUseProgram(blit_scaled.program);
    blit_scaled.scale_loc = gl.glGetUniformLocation(blit_scaled.program, "u_scale", "u_scale".len);
    tiled.program = loadShader(blit2d_vert_src, tiled_frag_src);
    gl.glUseProgram(tiled.program);
    tiled.map_loc = gl.glGetUniformLocation(tiled.program, "u_map", "u_map".len);
    tiled.map_size_loc = gl.glGetUniformLocation(tiled.program, "u_map_size", "u_map_size".len);
    tiled.tiles_loc = gl.glGetUniformLocation(tiled.program, "u_tiles", "u_tiles".len);
    tiled.tiles_size_loc = gl.glGetUniformLocation(tiled.program, "u_tiles_size", "u_tiles_size".len);
    tiled.mvp_loc = gl.glGetUniformLocation(tiled.program, "u_mvp", "u_mvp".len);
    tiled.texmat_loc = gl.glGetUniformLocation(tiled.program, "u_texmat", "u_texmat".len);

    const triangles = [_]f32{
        -1.0, -1.0,
        1.0,  -1.0,
        -1.0, 1.0,
        1.0,  1.0,

        0.0,  0.0,
        0.0,  1.0,
        1.0,  0.0,
        1.0,  1.0,
    };
    gl.glGenBuffers(1, &blit_vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, blit_vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, triangles.len * @sizeOf(f32), &triangles, gl.GL_STATIC_DRAW);

    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, blit_vbo);
    gl.glEnableVertexAttribArray(0);
    gl.glVertexAttribPointer(0, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
}

pub fn resize(width: f32, height: f32, scale: f32) void {
    video_width = width;
    video_height = height;
    video_scale = scale;
}

pub fn clear() void {
    gl.glClearColor(0.5, 0.5, 0.5, 1);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
}

pub fn drawTilemap(mvp: Mat4, map: Texture, tiles: Texture) void {
    const identity = Mat4.identity();
    gl.glUseProgram(tiled.program);
    gl.glUniformMatrix4fv(tiled.mvp_loc, 1, gl.GL_FALSE, &mvp.data[0]);
    gl.glUniformMatrix4fv(tiled.texmat_loc, 1, gl.GL_FALSE, &identity.data[0]);
    gl.glUniform1i(tiled.map_loc, 0);
    gl.glUniform2f(tiled.map_size_loc, map.size.data[0], map.size.data[1]);
    gl.glUniform1i(tiled.tiles_loc, 1);
    gl.glUniform2f(tiled.tiles_size_loc, tiles.size.data[0], tiles.size.data[1]);

    gl.glActiveTexture(gl.GL_TEXTURE1);
    gl.glBindTexture(gl.GL_TEXTURE_2D, tiles.handle);
    gl.glActiveTexture(gl.GL_TEXTURE0);
    gl.glBindTexture(gl.GL_TEXTURE_2D, map.handle);
    gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 4, 4);
}

pub fn beginDraw() void {
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fbo);
    gl.glViewport(0, 0, fb_width, fb_height);
}

pub fn endDraw() void {
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);

    const fb_ar = @intToFloat(f32, fb_width) / @intToFloat(f32, fb_height);
    const video_ar = video_width / video_height;

    gl.glViewport(0, 0, @floatToInt(u32, video_scale * video_width), @floatToInt(u32, video_scale * video_height));
    gl.glClearColor(0, 0, 0, 0);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
    gl.glUseProgram(blit_scaled.program);
    if (fb_ar < video_ar) {
        gl.glUniform2f(blit_scaled.scale_loc, fb_ar / video_ar, 1.0);
    } else {
        gl.glUniform2f(blit_scaled.scale_loc, 1.0, video_ar / fb_ar);
    }
    gl.glBindTexture(gl.GL_TEXTURE_2D, fbo_tex);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, blit_vbo);
    gl.glVertexAttribPointer(0, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
    gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 0, 4);
}
