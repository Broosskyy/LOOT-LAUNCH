shader_type spatial;

uniform vec4 top_color : source_color = vec4(0.96, 0.97, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.86, 0.90, 0.96, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(bottom_color.rgb, top_color.rgb, up);
	if (COLOR.a > 0.001) {
		base *= mix(0.96, 1.04, COLOR.r);
	}
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.04;
}
