#include paint_header_uv_pattern
#include paint_brush_functions

void fragment() {
#include paint_fragment_common

	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec4 color = pattern_function(fract(uv));
	
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5))*tex2view.z;
	a *= color.a;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (erase) {
		COLOR = vec4(screen_color.xyz, max(screen_color.a-a, 0.0));
	} else if (reset) {
		COLOR = vec4(color.xyz, a);
	} else {
		float alpha_sum = min(1.0, a + screen_color.a);
		COLOR = vec4((color.xyz*a+screen_color.xyz*(vec3(alpha_sum)-a))/alpha_sum, alpha_sum);
	}
}
