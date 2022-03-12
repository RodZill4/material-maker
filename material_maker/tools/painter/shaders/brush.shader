shader_type canvas_item;

uniform bool      texture_space   = false;
uniform bool      texture_view    = false;
uniform vec2      rect_size;
uniform vec2      brush_pos       = vec2(0.5, 0.5);
uniform vec2      brush_ppos      = vec2(0.5, 0.5);
uniform float     brush_size      = 0.5;
uniform float     brush_hardness  = 0.5;
const float       brush_opacity   = 1.0;
uniform float     stroke_length   = 0.0;
uniform float     stroke_angle    = 0.0;
uniform float     stroke_seed     = 0.0;
uniform float     pattern_scale   = 10.0;
uniform float     pattern_angle   = 0.0;
uniform float     pattern_alpha   = 0.0;
uniform float     pressure        = 1.0;

uniform sampler2D view2tex_tex;
uniform vec3      mesh_aabb_position = vec3(-0.5);
uniform vec3      mesh_aabb_size = vec3(1.0);
uniform sampler2D mesh_inv_uv_tex;
uniform sampler2D mesh_normal_tex;
uniform sampler2D mask_tex;
uniform sampler2D layer_albedo_tex;
uniform sampler2D layer_mr_tex;
uniform sampler2D layer_emission_tex;
uniform sampler2D layer_depth_tex;

GENERATED_CODE

float brush(vec2 uv) {
	return clamp(brush_opacity*brush_function(uv)/(1.0-brush_hardness), 0.0, 1.0);
}

#if brush_type == "pattern"
vec4 pattern_color(vec2 uv, vec2 bs) {
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec2 pattern_uv = pattern_scale*texture_rotation*(vec2(bs.y/bs.x, 1.0)*(uv - vec2(0.5, 0.5)));
	return pattern_function(fract(pattern_uv));
}
#elif brush_type == "uv_pattern"
vec4 pattern_color(vec2 uv) {
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	return pattern_function(fract(uv));
}
#endif

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
#if brush_type == "stamp"
	vec2 local_uv2 = p-b-bv;
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	local_uv = texture_rotation*local_uv;
	vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
	float a = (0.2+0.8*texture(mask_tex, texture(view2tex_tex, UV).xy).r)*stamp_limit.x*stamp_limit.y;
	COLOR = vec4(1.0, 1.0, 1.0, a)*pattern_function(0.5*texture_rotation*local_uv2+vec2(0.5)) * vec4(vec3(1.0), brush(0.5*local_uv+vec2(0.5)));
#elif brush_type == "pattern"
	float a = (0.2+0.8*texture(mask_tex, texture(view2tex_tex, UV).xy).r)*max(brush(0.5*local_uv+vec2(0.5)), pattern_alpha);
	COLOR = pattern_color(UV, bs) * vec4(vec3(1.0), a);
#elif brush_type == "uv_pattern"
	float a = (0.2+0.8*texture(mask_tex, texture(view2tex_tex, UV).xy).r)*max(brush(0.5*local_uv+vec2(0.5)), pattern_alpha);
	vec4 uv = texture(view2tex_tex, UV);
	COLOR = pattern_color(uv.xy) * vec4(vec3(1.0), a*(0.5+0.5*uv.a));
#endif
}
