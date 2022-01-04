#include paint_header_uv_pattern
#include paint_brush_functions

void fragment() {
#include paint_fragment_common

	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec4 color = pattern_function(fract(uv));
	
	vec2 a = fill ? vec2(1.0) : vec2(brush(0.5*local_uv+vec2(0.5)))*tex2view.z;
	a *= color.ba;
	a *= texture(mask_tex, UV).r;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (reset) {
		COLOR = vec4(color.xy, a);
	} else {
		vec2 alpha_sum = min(max(a, screen_color.ba), a + screen_color.ba);
		COLOR = vec4((color.xy*a+screen_color.xy*(alpha_sum-a))/alpha_sum, alpha_sum);
	}
}
