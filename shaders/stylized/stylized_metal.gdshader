shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_color : source_color = vec4(0.18, 0.20, 0.26, 1.0);
uniform vec3 rim_tint : source_color = vec3(0.66, 0.74, 0.88);
uniform float roughness : hint_range(0.0, 1.0) = 0.42;
uniform float metallic : hint_range(0.0, 1.0) = 0.62;
uniform float bevel_boost : hint_range(0.0, 0.3) = 0.10;
uniform float recess_darken : hint_range(0.0, 0.4) = 0.22;

void fragment() {
	vec3 base = albedo_color.rgb;
	if (COLOR.a > 0.001) {
		base *= COLOR.rgb;
	}
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	float facing = clamp(dot(NORMAL, normalize(vec3(0.35, 0.82, -0.25))), 0.0, 1.0);
	base *= mix(1.0 - recess_darken, 1.0 + bevel_boost, up);
	base = mix(base, base * rim_tint, facing * bevel_boost * metallic);
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = mix(0.12, 0.42, metallic);
}
