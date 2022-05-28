#include "brush_common_decl.shader"

GENERATED_CODE

float brush(vec2 uv) {
	return clamp(brush_opacity*brush_function(uv)/(1.0-brush_hardness), 0.0, 1.0);
}

void fragment() {
	vec2 bs;
	vec2 bp;
	vec2 bpp;
	vec2 p;
	if (texture_space) {
		float min_size = min(rect_size.x, rect_size.y);
		bs = vec2(brush_size)/min_size;
		bp = brush_pos/min_size;
		bpp = brush_ppos/min_size;
		p = texture(view2tex_tex, UV).xy/bs;
	} else {
		bs = vec2(brush_size)/rect_size;
		bp = brush_pos/rect_size;
		bpp = brush_ppos/rect_size;
		p = UV/bs;
	}
	vec2 b = bp/bs;
	vec2 bv = (bpp-bp)/bs;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	vec2 local_uv = p-(b+x*bv);
	vec2 local_uv2 = p-b-bv;
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	local_uv = texture_rotation*local_uv;
	vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
	float a = (0.2+0.8*texture(mask_tex, texture(view2tex_tex, UV).xy).r)*stamp_limit.x*stamp_limit.y;
	COLOR = vec4(1.0, 1.0, 1.0, a)*pattern_function(0.5*texture_rotation*local_uv2+vec2(0.5)) * vec4(vec3(1.0), brush(0.5*local_uv+vec2(0.5)));
}
