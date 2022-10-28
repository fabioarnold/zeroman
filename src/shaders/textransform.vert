precision mediump float;

uniform mat4 u_mvp;
uniform mat4 u_texmat;

attribute vec2 a_position;

varying vec2 v_texcoord;

void main() {
	v_texcoord = (u_texmat * vec4(a_position, 0, 1)).xy;
	gl_Position = u_mvp * vec4(a_position, 0, 1);
}