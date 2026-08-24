shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_color : source_color = vec4(0.30, 0.58, 0.34, 1.0);
uniform vec3 highlight_tint : source_color = vec3(0.72, 0.92, 0.62);
uniform float roughness : hint_range(0.0, 1.0) = 0.88;
uniform float variation_strength : hint_range(0.0, 0.2) = 0.08;

void fragment() {
	vec3 base = albedo_color.rgb;
	if (COLOR.a > 0.001) {
		base *= COLOR.rgb;
	}
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	float side = abs(NORMAL.x) + abs(NORMAL.z);
	base = mix(base, base * highlight_tint, up * variation_strength * 2.5);
	base *= mix(1.0 - variation_strength * 0.5, 1.0 + variation_strength * 0.4, 1.0 - side * 0.25);
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.14;
}
