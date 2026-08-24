shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 shallow_color : source_color = vec4(0.42, 0.86, 0.98, 0.72);
uniform vec4 deep_color : source_color = vec4(0.22, 0.62, 0.88, 0.82);
uniform float roughness : hint_range(0.0, 1.0) = 0.18;
uniform float wave_strength : hint_range(0.0, 0.08) = 0.018;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.85;

void vertex() {
	float phase = VERTEX.x * 0.7 + VERTEX.z * 0.55;
	float ripple = sin(TIME * wave_speed + phase) * wave_strength;
	VERTEX.y += ripple;
}

void fragment() {
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(deep_color.rgb, shallow_color.rgb, up);
	float sparkle = sin(TIME * wave_speed * 1.4 + UV.x * 12.0 + UV.y * 9.0) * 0.5 + 0.5;
	base += vec3(0.04, 0.06, 0.08) * sparkle * 0.35;
	ALBEDO = base;
	ALPHA = mix(deep_color.a, shallow_color.a, up);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.22;
}
