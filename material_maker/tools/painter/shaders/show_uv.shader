shader_type spatial;
render_mode unshaded;

void fragment() {
	ALBEDO = vec3(UV, 0.0);
}
