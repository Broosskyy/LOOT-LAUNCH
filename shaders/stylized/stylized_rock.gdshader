shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_color : source_color = vec4(0.56, 0.54, 0.52, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.93;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float cool_shadow : hint_range(0.0, 0.25) = 0.12;
uniform float warm_highlight : hint_range(0.0, 0.2) = 0.08;

void fragment() {
	vec3 base = albedo_color.rgb;
	if (COLOR.a > 0.001) {
		base *= COLOR.rgb;
	}
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	float down = 1.0 - up;
	base *= mix(1.0 - cool_shadow, 1.0 + warm_highlight, up);
	base *= mix(1.0, 1.0 - cool_shadow * 0.85, down);
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = mix(0.08, 0.18, metallic);
}
