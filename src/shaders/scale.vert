precision mediump float;
uniform vec2 u_scale;
attribute vec2 a_position;
varying vec2 v_texcoord;

void main() {
	v_texcoord = 0.5 + 0.5 * a_position;
	gl_Position = vec4(u_scale * a_position + vec2(0, 1.0 - u_scale.y), 0, 1);
}