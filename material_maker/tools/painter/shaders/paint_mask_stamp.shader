#include paint_header
#include paint_brush_functions

void fragment() {
#include paint_fragment_common

	vec4 color = vec4(vec3(erase ? 0.0 : 1.0), 1.0)*pattern_function(fract(uv));
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5))*tex2view.z;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	COLOR = vec4(mix(screen_color.xyz, color.xyz, a*color.a), 1.0);
}
