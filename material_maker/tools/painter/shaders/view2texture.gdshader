shader_type spatial;
render_mode unshaded;

uniform float near;
uniform float far;

void fragment() {
	float depth = (FRAGCOORD.z/FRAGCOORD.w-near)/(far-near);
	ALBEDO = vec3(UV.xy, depth);
}
