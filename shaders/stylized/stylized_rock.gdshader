shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_color : source_color = vec4(0.56, 0.54, 0.52, 1.0);
uniform vec3 secondary_tint : source_color = vec3(0.72, 0.70, 0.68);
uniform float roughness : hint_range(0.0, 1.0) = 0.93;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float cool_shadow : hint_range(0.0, 0.25) = 0.12;
uniform float warm_highlight : hint_range(0.0, 0.2) = 0.08;
uniform float macro_strength : hint_range(0.0, 1.0) = 0.0;
uniform float macro_mul : hint_range(0.0, 1.5) = 1.0;
uniform float moss_strength : hint_range(0.0, 0.4) = 0.0;
uniform float wet_darken : hint_range(0.0, 0.3) = 0.1;
uniform sampler2D macro_tex : repeat_enable, filter_linear_mipmap;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo_color.rgb;
	if (COLOR.a > 0.001) {
		base *= COLOR.rgb;
	}
	vec2 wuv = v_world_pos.xz * 0.14 + v_world_pos.y * 0.02;
	float macro = texture(macro_tex, wuv).r;
	macro = mix(0.5, macro, macro_strength * macro_mul);
	base = mix(base, secondary_tint, (macro - 0.5) * 0.35);
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	float side = 1.0 - abs(NORMAL.x) * 0.08 - abs(NORMAL.z) * 0.06;
	float down = 1.0 - up;
	base *= mix(1.0 - cool_shadow, 1.0 + warm_highlight, up);
	base *= mix(1.0, 1.0 - cool_shadow * 0.85, down);
	base *= clamp(side, 0.82, 1.0);
	float moss = clamp(COLOR.g, 0.0, 1.0) * moss_strength;
	base = mix(base, base * vec3(0.62, 0.78, 0.58), moss);
	float wet = clamp(COLOR.b, 0.0, 1.0) * wet_darken;
	base *= mix(1.0, 0.78, wet);
	ALBEDO = base;
	ROUGHNESS = mix(roughness, roughness * 0.88, wet);
	METALLIC = metallic;
	SPECULAR = mix(0.08, 0.18, metallic);
}
