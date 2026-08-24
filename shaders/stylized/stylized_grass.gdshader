shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_color : source_color = vec4(0.29, 0.62, 0.36, 1.0);
uniform vec3 dry_patch_tint : source_color = vec3(0.36, 0.72, 0.40);
uniform float roughness : hint_range(0.0, 1.0) = 0.94;
uniform float variation_strength : hint_range(0.0, 0.2) = 0.08;
uniform float macro_strength : hint_range(0.0, 1.0) = 0.0;
uniform float edge_strength : hint_range(0.0, 0.3) = 0.12;
uniform float wind_strength : hint_range(0.0, 0.2) = 0.055;
uniform float wind_speed : hint_range(0.0, 3.0) = 1.1;
uniform float wind_phase : hint_range(0.0, 100.0) = 0.0;
uniform sampler2D macro_tex : repeat_enable, filter_linear_mipmap;

varying vec3 v_world_pos;

void vertex() {
	float height = clamp(VERTEX.y + 0.15, 0.0, 1.4);
	float mask = height * height;
	float phase = wind_phase + VERTEX.x * 0.62 + VERTEX.z * 0.48;
	float sway = sin(TIME * wind_speed + phase) * wind_strength * mask;
	VERTEX.x += sway;
	VERTEX.z += cos(TIME * wind_speed * 0.86 + phase * 1.07) * wind_strength * 0.34 * mask;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo_color.rgb;
	if (COLOR.a > 0.001) {
		base *= COLOR.rgb;
	}
	vec2 wuv = (v_world_pos.xz + v_world_pos.y * 0.08) * 0.11;
	float macro = texture(macro_tex, wuv).r;
	macro = mix(0.5, macro, macro_strength);
	base = mix(base, base * dry_patch_tint, (macro - 0.5) * variation_strength * 2.2);
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	base *= mix(1.0 - variation_strength * 0.6, 1.0 + variation_strength * 0.5, up);
	float edge_mask = clamp(1.0 - COLOR.a, 0.0, 1.0) * edge_strength;
	base *= mix(1.0, 0.72, edge_mask);
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.12;
}
