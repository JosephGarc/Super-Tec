shader_type canvas_item;
render_mode unshaded;

uniform vec4 zenith_color : source_color = vec4(0.28, 0.68, 0.92, 1.0);
uniform vec4 horizon_color : source_color = vec4(1.0, 0.82, 0.62, 1.0);

void fragment() {
	float horizon = smoothstep(0.0, 1.0, UV.y);
	COLOR = mix(zenith_color, horizon_color, horizon);
}
