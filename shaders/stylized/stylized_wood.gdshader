shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_color : source_color = vec4(0.42, 0.26, 0.16, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.90;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D grain_tex : repeat_enable, filter_linear_mipmap;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo_color.rgb;
	if (COLOR.a > 0.001) {
		base *= COLOR.rgb;
	}
	vec2 grain_uv = vec2(v_world_pos.y * 0.35 + v_world_pos.x * 0.04, v_world_pos.z * 0.02);
	float grain = texture(grain_tex, grain_uv).r;
	grain = mix(0.5, grain, grain_strength);
	base *= mix(0.86, 1.08, grain);
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	base *= mix(0.88, 1.04, up);
	float end_dark = clamp(abs(fract(v_world_pos.y * 0.5) - 0.5) * 2.0, 0.0, 1.0);
	base *= mix(1.0, 0.92, end_dark * 0.35);
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.10;
}
