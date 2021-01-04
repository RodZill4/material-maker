shader_type spatial;
render_mode unshaded;

void fragment() {
	float depth = FRAGCOORD.z/FRAGCOORD.w;
	ALBEDO = vec3(UV.xy, depth);
}
