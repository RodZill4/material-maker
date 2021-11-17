#include brush_common_decl

// BEGIN_PATTERN
float brush_function(vec2 uv) {
	return clamp(max(0.0, 1.0-length(2.0*(uv-vec2(0.5)))) / 0.5, 0.0, 1.0);
}

vec4 pattern_function(vec2 uv) {
	return vec4(fract(10.0*uv.x+length(uv-vec2(0.5))*10.0), 0.0, 0.0, 1.0);
}
// END_PATTERN

float brush(vec2 uv) {
	return clamp(brush_opacity*brush_function(uv)/(1.0-brush_hardness), 0.0, 1.0);
}

vec4 pattern_color(vec2 uv) {
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	return pattern_function(fract(uv));
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
	float a = max(brush(0.5*local_uv+vec2(0.5)), pattern_alpha);
	vec4 uv = texture(view2tex_tex, UV);
	COLOR = pattern_color(uv.xy) * vec4(vec3(1.0), a*(0.5+0.5*uv.a));
}
