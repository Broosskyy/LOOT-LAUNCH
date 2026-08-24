shader_type spatial;

uniform vec4 top_color : source_color = vec4(0.98, 0.99, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.78, 0.84, 0.94, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float side_shade : hint_range(0.0, 0.2) = 0.07;

void fragment() {
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(bottom_color.rgb, top_color.rgb, pow(up, 0.82));
	float side = 1.0 - abs(NORMAL.x) * side_shade - abs(NORMAL.z) * side_shade * 0.65;
	base *= clamp(side, 0.82, 1.0);
	if (COLOR.a > 0.001) {
		base *= mix(0.94, 1.06, COLOR.r);
	}
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.05;
}
