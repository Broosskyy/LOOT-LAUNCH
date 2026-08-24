shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 shallow_color : source_color = vec4(0.42, 0.86, 0.98, 0.72);
uniform vec4 deep_color : source_color = vec4(0.22, 0.62, 0.88, 0.82);
uniform float roughness : hint_range(0.0, 1.0) = 0.16;
uniform float wave_strength : hint_range(0.0, 0.08) = 0.018;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.85;
uniform float flow_strength : hint_range(0.0, 1.0) = 0.0;
uniform float waterfall_mode : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;

void vertex() {
	float phase = VERTEX.x * 0.7 + VERTEX.z * 0.55;
	float ripple = sin(TIME * wave_speed + phase) * wave_strength;
	if (waterfall_mode > 0.5) {
		ripple += sin(TIME * wave_speed * 2.2 + VERTEX.y * 1.8) * wave_strength * 1.6;
	}
	VERTEX.y += ripple;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 flow_uv = v_world_pos.xz * 0.08 + vec2(TIME * wave_speed * 0.12, TIME * wave_speed * 0.06);
	float flow = sin(flow_uv.x * 6.0 + flow_uv.y * 4.0) * 0.5 + 0.5;
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(deep_color.rgb, shallow_color.rgb, up);
	base = mix(base, shallow_color.rgb * 1.06, flow * flow_strength * 0.22);
	if (waterfall_mode > 0.5) {
		float streak = sin(v_world_pos.y * 3.2 - TIME * wave_speed * 1.8) * 0.5 + 0.5;
		base = mix(base, vec3(0.88, 0.96, 1.0), streak * 0.28);
		base *= mix(1.0, 0.88, abs(NORMAL.x) + abs(NORMAL.z));
	}
	float sparkle = sin(TIME * wave_speed * 1.4 + flow_uv.x * 12.0) * 0.5 + 0.5;
	base += vec3(0.04, 0.06, 0.08) * sparkle * 0.30;
	ALBEDO = base;
	ALPHA = mix(deep_color.a, shallow_color.a, up);
	ROUGHNESS = mix(roughness, roughness * 0.82, waterfall_mode);
	METALLIC = 0.0;
	SPECULAR = 0.22;
}
