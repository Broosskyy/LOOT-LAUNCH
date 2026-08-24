shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_color : source_color = vec4(0.56, 0.40, 0.88, 1.0);
uniform vec4 core_color : source_color = vec4(0.40, 0.24, 0.72, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.24;
uniform float emission_strength : hint_range(0.0, 2.5) = 0.34;
uniform vec3 emission_color : source_color = vec3(0.42, 0.22, 0.78);

void fragment() {
	vec3 base = base_color.rgb;
	float facet = clamp(abs(NORMAL.x) * 0.55 + abs(NORMAL.y) * 0.35 + abs(NORMAL.z) * 0.45, 0.0, 1.0);
	base = mix(core_color.rgb, base, facet);
	if (COLOR.a > 0.001) {
		base *= mix(0.88, 1.12, COLOR.r);
	}
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	base *= mix(0.92, 1.08, up);
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = 0.08;
	SPECULAR = 0.28;
	EMISSION = emission_color * emission_strength * mix(0.65, 1.0, facet);
}
