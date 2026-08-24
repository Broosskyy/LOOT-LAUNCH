shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 top_color : source_color = vec4(0.98, 0.99, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.78, 0.84, 0.94, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float side_shade : hint_range(0.0, 0.2) = 0.07;
uniform float depth_fade : hint_range(0.0, 0.3) = 0.0;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(bottom_color.rgb, top_color.rgb, pow(up, 0.78));
	float side = 1.0 - abs(NORMAL.x) * side_shade - abs(NORMAL.z) * side_shade * 0.68;
	base *= clamp(side, 0.80, 1.0);
	float puff = 1.0;
	if (COLOR.a > 0.001) {
		puff = mix(0.90, 1.08, COLOR.r);
		base *= puff;
	}
	float depth_mix = clamp(COLOR.g, 0.0, 1.0);
	base = mix(base, mix(base, vec3(0.92, 0.96, 1.0), 0.35), depth_mix * depth_fade);
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.04;
}
