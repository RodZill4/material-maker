#include "paint_header_uv_pattern.shader"
#include "paint_brush_functions.shader"

void fragment() {
#include "paint_fragment_common.shader"

	vec4 color = vec4(1.0)*pattern_function(fract(uv));
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5))*tex2view.z;
	a *= texture(mask_tex, UV).r;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	COLOR = vec4(color.rgb, max(screen_color.a, a*color.a));
}
