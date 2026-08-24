shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_color : source_color = vec4(0.29, 0.62, 0.36, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.94;
uniform float variation_strength : hint_range(0.0, 0.2) = 0.08;

void fragment() {
	vec3 base = albedo_color.rgb;
	if (COLOR.a > 0.001) {
		base *= COLOR.rgb;
	}
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	base *= mix(1.0 - variation_strength * 0.6, 1.0 + variation_strength * 0.5, up);
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.12;
}
