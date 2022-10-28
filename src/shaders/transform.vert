precision mediump float;

uniform mat4 u_mvp;

attribute vec2 a_position;

void main() {
	gl_Position = u_mvp * vec4(a_position, 0, 1);
}