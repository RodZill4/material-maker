shader_type spatial;
render_mode unshaded;

vec3 fix_unshaded(vec3 xy) {
    return xy;
	return mix(pow((xy+vec3(0.055))/vec3(1.055), vec3(2.4)), xy/vec3(12.92), lessThan(xy, vec3(0.0031308*12.92)));
}

void fragment() {
	float depth = FRAGCOORD.z/FRAGCOORD.w;
	ALBEDO = fix_unshaded(vec3(UV.xy, 0.0));
}
