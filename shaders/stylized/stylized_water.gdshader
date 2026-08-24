shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 shallow_color : source_color = vec4(0.42, 0.86, 0.98, 0.72);
uniform vec4 deep_color : source_color = vec4(0.22, 0.62, 0.88, 0.82);
uniform float roughness : hint_range(0.0, 1.0) = 0.16;
uniform float wave_strength : hint_range(0.0, 0.08) = 0.018;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.85;
uniform float flow_strength : hint_range(0.0, 1.0) = 0.0;
uniform float foam_strength : hint_range(0.0, 1.0) = 0.0;
uniform float waterfall_mode : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;

void vertex() {
	float phase = VERTEX.x * 0.7 + VERTEX.z * 0.55;
	float ripple = sin(TIME * wave_speed + phase) * wave_strength;
	if (waterfall_mode > 0.5) {
		ripple += sin(TIME * wave_speed * 2.4 + VERTEX.y * 2.0) * wave_strength * 1.8;
		VERTEX.x += sin(TIME * wave_speed * 1.6 + VERTEX.y * 0.9) * wave_strength * 0.35;
	}
	VERTEX.y += ripple;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 flow_uv = v_world_pos.xz * 0.08 + vec2(TIME * wave_speed * 0.14, TIME * wave_speed * 0.07);
	float flow = sin(flow_uv.x * 6.0 + flow_uv.y * 4.0) * 0.5 + 0.5;
	float band = sin(flow_uv.y * 14.0 - TIME * wave_speed * 0.9) * 0.5 + 0.5;
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(deep_color.rgb, shallow_color.rgb, up);
	base = mix(base, shallow_color.rgb * 1.08, flow * flow_strength * 0.26);
	base = mix(base, vec3(0.92, 0.98, 1.0), band * flow_strength * 0.12);
	float foam = sin(v_world_pos.x * 4.2 + TIME * wave_speed) * sin(v_world_pos.z * 3.6 - TIME * wave_speed * 0.8);
	foam = smoothstep(0.55, 0.92, foam * 0.5 + 0.5) * foam_strength * (1.0 - waterfall_mode);
	base = mix(base, vec3(0.94, 0.99, 1.0), foam * 0.42);
	if (waterfall_mode > 0.5) {
		float streak = sin(v_world_pos.y * 3.6 - TIME * wave_speed * 2.0) * 0.5 + 0.5;
		float streak2 = sin(v_world_pos.y * 5.8 - TIME * wave_speed * 2.6 + v_world_pos.x) * 0.5 + 0.5;
		base = mix(base, vec3(0.90, 0.97, 1.0), streak * 0.32);
		base = mix(base, vec3(0.78, 0.92, 1.0), streak2 * 0.18);
		base *= mix(1.0, 0.86, abs(NORMAL.x) + abs(NORMAL.z));
	}
	float sparkle = sin(TIME * wave_speed * 1.5 + flow_uv.x * 12.0) * 0.5 + 0.5;
	base += vec3(0.05, 0.07, 0.09) * sparkle * 0.28;
	ALBEDO = base;
	ALPHA = mix(deep_color.a, shallow_color.a, up);
	ROUGHNESS = mix(roughness, roughness * 0.78, waterfall_mode);
	METALLIC = 0.0;
	SPECULAR = mix(0.22, 0.30, waterfall_mode);
}
