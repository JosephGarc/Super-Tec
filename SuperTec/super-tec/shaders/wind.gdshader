shader_type canvas_item;

uniform float wind_speed = 1.4;
uniform float wind_amplitude = 1.5;

void vertex() {
	VERTEX.x += sin(TIME * wind_speed + VERTEX.y * 0.035) * wind_amplitude * (1.0 - UV.y);
}
