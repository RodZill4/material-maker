#include paint_header
#include paint_brush_functions

void fragment() {
#include paint_fragment_common

	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec2 pattern_uv = pattern_scale*texture_rotation*(vec2(bs.y/bs.x, 1.0)*(xy - vec2(0.5, 0.5)));
	vec4 color = pattern_function(fract(pattern_uv));
	
	vec2 a = fill ? vec2(1.0) : vec2(brush(0.5*local_uv+vec2(0.5)))*color.ba*tex2view.z;
	a *= texture(mask_tex, UV).r;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (reset) {
		COLOR = vec4(color.xy, a);
	} else {
		vec2 alpha_sum = min(max(a, screen_color.za), a + screen_color.za);
		COLOR = vec4((color.xy*a+screen_color.xy*(alpha_sum-a))/alpha_sum, alpha_sum);
	}
}
