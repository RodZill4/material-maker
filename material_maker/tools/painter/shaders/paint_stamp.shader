#include paint_header
#include paint_brush_functions

void fragment() {
#include paint_fragment_common

	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	local_uv = texture_rotation*local_uv;
	vec2 local_uv2 = p-b-bv;
	local_uv2 = texture_rotation*local_uv2;
	vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
	vec4 color = pattern_function(0.5*local_uv2+vec2(0.5));
	
	float a = fill ? 1.0 : stamp_limit.x*stamp_limit.y*brush(0.5*local_uv+vec2(0.5))*color.a*tex2view.z;
	a *= texture(mask_tex, UV).r;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (reset) {
		COLOR = vec4(color.xyz, a);
	} else {
		float alpha_sum = min(max(a, screen_color.a), a + screen_color.a);
		COLOR = vec4((color.xyz*a+screen_color.xyz*(vec3(alpha_sum)-a))/alpha_sum, alpha_sum);
	}
}
