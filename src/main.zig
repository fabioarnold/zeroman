const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const gl = @import("webgl.zig");
const keys = @import("keys.zig");

var video_width: f32 = 1280;
var video_height: f32 = 720;
var video_scale: f32 = 1;

var mvp_loc: c_int = undefined;
var color_loc: c_int = undefined;

export fn onInit() void {
    gl.glEnable(gl.GL_DEPTH_TEST);

    const vert_src = @embedFile("../data/transform.vert");
    const frag_src = @embedFile("../data/color.frag");
    const vert_shader = gl.glInitShader(vert_src, vert_src.len, gl.GL_VERTEX_SHADER);
    const frag_shader = gl.glInitShader(frag_src, frag_src.len, gl.GL_FRAGMENT_SHADER);
    const program = gl.glLinkShaderProgram(vert_shader, frag_shader);
    gl.glUseProgram(program);
    mvp_loc = gl.glGetUniformLocation(program, "mvp", 3);
    color_loc = gl.glGetUniformLocation(program, "color", 5);

    var buf: c_uint = undefined;
    gl.glGenBuffers(1, &buf);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, buf);
    const vertex_data = @import("zig-mark.zig").positions;
    gl.glBufferData(gl.GL_ARRAY_BUFFER, vertex_data.len * @sizeOf(f32), &vertex_data, gl.GL_STATIC_DRAW);
}

export fn onResize(w: c_uint, h: c_uint, s: f32) void {
    video_width = @intToFloat(f32, w);
    video_height = @intToFloat(f32, h);
    video_scale = s;
    gl.glViewport(0, 0, @floatToInt(i32, s * video_width), @floatToInt(i32, s * video_height));
}

var cam_x: f32 = 0;
var cam_y: f32 = 0;
export fn onKeyDown(key: c_uint) void {
    switch (key) {
        keys.KEY_LEFT => cam_x -= 0.1,
        keys.KEY_RIGHT => cam_x += 0.1,
        keys.KEY_DOWN => cam_y -= 0.1,
        keys.KEY_UP => cam_y += 0.1,
        else => {},
    }
}

var frame: usize = 0;
export fn onAnimationFrame() void {
    gl.glClearColor(0.5, 0.5, 0.5, 1);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);

    const projection = za.perspective(45.0, video_width / video_height, 0.1, 10.0);
    const view = Mat4.fromTranslate(Vec3.new(cam_x, cam_y, -4));
    const model = Mat4.fromRotation(2 * @intToFloat(f32, frame), Vec3.up());

    const mvp = projection.mult(view.mult(model));
    gl.glUniformMatrix4fv(mvp_loc, 1, gl.GL_FALSE, &mvp.data[0]);

    gl.glEnableVertexAttribArray(0);
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, null);

    gl.glUniform4f(color_loc, 0.97, 0.64, 0.11, 1);
    gl.glDrawArrays(gl.GL_TRIANGLES, 0, 120);
    gl.glUniform4f(color_loc, 0.98, 0.82, 0.6, 1);
    gl.glDrawArrays(gl.GL_TRIANGLES, 120, 66);
    gl.glUniform4f(color_loc, 0.6, 0.35, 0.02, 1);
    gl.glDrawArrays(gl.GL_TRIANGLES, 186, 90);

    frame += 1;
}
