shader_type spatial;
render_mode unshaded;

vec3 fix_unshaded(vec3 xy) {
	return pow(xy, vec3(2.22));
}

void fragment() {
	ALBEDO = fix_unshaded(vec3(UV, VERTEX.z));
}
