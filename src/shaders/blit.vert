precision mediump float;
attribute vec2 a_position;
varying vec2 v_texcoord;

void main() {
	v_texcoord = 0.5 + 0.5 * a_position;
	gl_Position = vec4(a_position, 0, 1);
}