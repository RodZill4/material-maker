shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform bool      texture_space = false;
uniform vec2      rect_size;
uniform vec2      texture_center = vec2(0.5);
uniform float     texture_scale = 1.0;

uniform sampler2D tex2view_tex;
uniform float     texture_size = 512.0;
uniform sampler2D seams : hint_white;
uniform float     seams_multiplier = 256.0;
uniform sampler2D mesh_normal_tex;
uniform sampler2D mesh_tangent_tex;
uniform sampler2D mask_tex;
uniform sampler2D layer_albedo_tex;
uniform sampler2D layer_mr_tex;
uniform sampler2D layer_emission_tex;
uniform sampler2D layer_depth_tex;
uniform vec3      view_back;
uniform vec3      view_right;
uniform vec3      view_up;

uniform bool      fill              = false;
uniform bool      reset             = false;
uniform float     pressure          = 1.0;
uniform vec2      tilt              = vec2(0.0, 0.0);
uniform vec2      brush_pos         = vec2(0.5, 0.5);
uniform vec2      brush_ppos        = vec2(0.5, 0.5);
uniform float     brush_size        = 0.5;
uniform float     brush_hardness    = 0.5;
uniform bool      jitter = true;
uniform float     jitter_position = 0.0;
uniform float     jitter_size     = 0.0;
uniform float     jitter_angle    = 0.0;
uniform float     jitter_opacity  = 0.0;
uniform float     stroke_length     = 0.0;
uniform float     stroke_angle      = 0.0;
uniform float     stroke_seed       = 0.0;
uniform float     pattern_scale     = 10.0;
uniform float     pattern_angle     = 0.0;

#if BRUSH_MODE == "uv_pattern"
uniform vec3      mesh_aabb_position = vec3(-0.5);
uniform vec3      mesh_aabb_size = vec3(1.0);
uniform sampler2D mesh_inv_uv_tex;
#endif

GENERATED_CODE

float brush(vec2 uv, float jo) {
	return clamp(jo*brush_function(uv)/(1.0-brush_hardness), 0.0, 1.0);
}

vec2 seams_uv(vec2 uv) {
	vec2 seams_value = texture(seams, uv).xy-vec2(0.5);
	return fract(uv+seams_value*seams_multiplier/texture_size);
}

#if TEXTURE_TYPE == "paint_nm"
vec2 tex2view(vec2 uv, vec2 duv) {
	vec4 v = texture(tex2view_tex, seams_uv(uv));
	if (v.w < 0.99) {
		v = texture(tex2view_tex, seams_uv(duv));
	}
	return v.xy;
}

vec2 dTex2View(vec2 uv, vec2 epsilon) {
	vec2 returnValue = tex2view(uv+epsilon, uv);
	returnValue += 0.5*tex2view(uv+2.0*epsilon, uv);
	returnValue -= tex2view(uv-epsilon, uv);
	returnValue -= 0.5*tex2view(uv-2.0*epsilon, uv);
	return normalize(returnValue.xy);
}
#endif

void fragment() {
	// Get UV from seams texture
	vec2 uv;
	
	vec2 xy;
	vec2 b;
	vec2 bv;
	vec2 bs;
	vec4 tex2view;
	vec2 jp = vec2(0.0);
	float js = 1.0;
	float ja = 0.0;
	float jo = 1.0;
	if (true || jitter) {
		vec3 r = rand3(vec2(stroke_seed, fract(stroke_length*456.34)));
		r.y *= 6.28318530718;
		jp = jitter_position*r.x*vec2(cos(r.y), sin(r.y));
		js = (2.0*fract(r.z)-1.0)*jitter_size+1.0;
		r = rand3(r.xz);
		ja = 6.28318530718*(r.x-0.5)*jitter_angle;
		jo = (2.0*fract(r.y)-1.0)*jitter_opacity+1.0;
	}
	// Get View position
	if (texture_space) {
		uv = UV;
		tex2view = vec4(1.0);
		xy = uv;
		float min_size = min(rect_size.x, rect_size.y);
		bs = js*vec2(brush_size)/min_size;
		b = ((brush_pos+jp-0.5*rect_size)*texture_scale/min_size+texture_center)/bs;
		bv = ((brush_ppos-brush_pos)*texture_scale/min_size)/bs;
	} else {
		uv = seams_uv(UV);
		tex2view = texture(tex2view_tex, uv);
		xy = tex2view.xy;
		bs = js*vec2(brush_size)/rect_size;
		b = (brush_pos+jp)/rect_size/bs;
		bv = (brush_ppos-brush_pos)/rect_size/bs;
	}
	// Get distance to brush center
	vec2 p = xy/bs;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	// Get position in brush
	vec2 local_uv = p-(b+x*bv);

#if TEXTURE_TYPE == "paint_mask"

	float pattern_angle_cos = cos(pattern_angle+ja);
	float pattern_angle_sin = sin(pattern_angle+ja);
	mat2 texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));
	local_uv = texture_rotation*local_uv;
	vec4 color = vec4(1.0)*pattern_function(fract(uv));
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5), jo)*tex2view.z;
	a *= texture(mask_tex, UV).r;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	COLOR = vec4(color.rgb, max(screen_color.a, a*color.a));

#elif TEXTURE_TYPE == "paint_mr"

#if BRUSH_MODE == "pattern"
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec2 pattern_uv = pattern_scale*texture_rotation*(vec2(bs.y/bs.x, 1.0)*(xy - vec2(0.5, 0.5)));
	vec4 color = pattern_function(fract(pattern_uv));
	
	vec2 a = fill ? vec2(1.0) : vec2(brush(0.5*local_uv+vec2(0.5), jo))*color.ba*tex2view.z;
	a *= texture(mask_tex, UV).r;
#elif BRUSH_MODE == "stamp"
	float pattern_angle_cos = cos(pattern_angle+ja);
	float pattern_angle_sin = sin(pattern_angle+ja);
	mat2 texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));
	local_uv = texture_rotation*local_uv;
	vec2 local_uv2 = p-b-bv;
	local_uv2 = texture_rotation*local_uv2;
	vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
	vec4 color = pattern_function(0.5*local_uv2+vec2(0.5));
	
	vec2 a = fill ? vec2(1.0) : vec2(stamp_limit.x*stamp_limit.y*brush(0.5*local_uv+vec2(0.5), jo))*color.ba*tex2view.z;
	a *= texture(mask_tex, UV).r;
#elif BRUSH_MODE == "uv_pattern"
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec4 color = pattern_function(fract(uv));
	
	vec2 a = fill ? vec2(1.0) : vec2(brush(0.5*local_uv+vec2(0.5), jo))*tex2view.z;
	a *= color.ba;
	a *= texture(mask_tex, UV).r;
#endif
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (reset) {
		COLOR = vec4(color.xy, a);
	} else {
		vec2 alpha_sum = min(max(a, screen_color.ba), a + screen_color.ba);
		COLOR = vec4((color.xy*a+screen_color.xy*(alpha_sum-a))/alpha_sum, alpha_sum);
	}

#elif TEXTURE_TYPE == "paint_nm"

#if BRUSH_MODE == "pattern"
	vec2 epsilon = vec2(1.0/texture_size, 0.0);
	vec2 tex2view_dx = dTex2View(UV, epsilon);
	vec2 tex2view_dy = dTex2View(UV, epsilon.yx);
	mat2 view_mat = inverse(mat2(vec2(tex2view_dx.x, tex2view_dx.y), vec2(tex2view_dy.x, tex2view_dy.y)));

	float pattern_angle_cos = cos(pattern_angle);
	float pattern_angle_sin = sin(pattern_angle);
	mat2 texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));

	vec2 pattern_uv = pattern_scale*texture_rotation*(vec2(bs.y/bs.x, 1.0)*(xy - vec2(0.5, 0.5)));
	vec4 color = pattern_function(fract(pattern_uv));
	pattern_angle_cos = cos(-pattern_angle);
	pattern_angle_sin = sin(-pattern_angle);
	texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));
	color.xy = view_mat*(texture_rotation*(color.xy-vec2(0.5)))+vec2(0.5);
	
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5), jo)*color.a*tex2view.z;
	a *= texture(mask_tex, UV).r;
#elif BRUSH_MODE == "stamp"
	vec2 epsilon = vec2(1.0/texture_size, 0.0);
	vec2 tex2view_dx = dTex2View(UV, epsilon);
	vec2 tex2view_dy = dTex2View(UV, epsilon.yx);
	mat2 view_mat = inverse(mat2(vec2(tex2view_dx.x, tex2view_dx.y), vec2(tex2view_dy.x, tex2view_dy.y)));

	float pattern_angle_cos = cos(pattern_angle+ja);
	float pattern_angle_sin = sin(pattern_angle+ja);
	mat2 texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));

	local_uv = texture_rotation*local_uv;
	vec2 local_uv2 = p-b-bv;
	local_uv2 = texture_rotation*local_uv2;
	vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
	vec4 color = pattern_function(0.5*local_uv2+vec2(0.5));
	pattern_angle_cos = cos(-pattern_angle-ja);
	pattern_angle_sin = sin(-pattern_angle-ja);
	texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));
	color.xy = view_mat*(texture_rotation*(color.xy-vec2(0.5)))+vec2(0.5);
	
	float a = fill ? 1.0 : stamp_limit.x*stamp_limit.y*brush(0.5*local_uv+vec2(0.5), jo)*color.a*tex2view.z;
	a *= texture(mask_tex, UV).r;
#elif BRUSH_MODE == "uv_pattern"
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec4 color = pattern_function(fract(uv));
	
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5), jo)*tex2view.z;
	a *= color.a;
	a *= texture(mask_tex, UV).r;
#endif
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (reset) {
		COLOR = vec4(color.xyz, a);
	} else {
		float alpha_sum = min(max(a, screen_color.a), a + screen_color.a);
		COLOR = vec4((color.xyz*a+screen_color.xyz*(vec3(alpha_sum)-a))/alpha_sum, alpha_sum);
	}

#elif TEXTURE_TYPE == "paint"

#if BRUSH_MODE == "pattern"
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec2 pattern_uv = pattern_scale*texture_rotation*(vec2(bs.y/bs.x, 1.0)*(xy - vec2(0.5, 0.5)));
	vec4 color = pattern_function(fract(pattern_uv));
	
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5), jo)*color.a*tex2view.z;
	a *= texture(mask_tex, UV).r;
#elif BRUSH_MODE == "stamp"
	float pattern_angle_cos = cos(pattern_angle+ja);
	float pattern_angle_sin = sin(pattern_angle+ja);
	mat2 texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));
	local_uv = texture_rotation*local_uv;
	vec2 local_uv2 = p-b-bv;
	local_uv2 = texture_rotation*local_uv2;
	vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
	vec4 color = pattern_function(0.5*local_uv2+vec2(0.5));
	
	float a = fill ? 1.0 : stamp_limit.x*stamp_limit.y*brush(0.5*local_uv+vec2(0.5), jo)*color.a*tex2view.z;
	a *= texture(mask_tex, UV).r;
#elif BRUSH_MODE == "uv_pattern"
	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	vec4 color = pattern_function(fract(uv));
	
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5), jo)*tex2view.z;
	a *= color.a;
	a *= texture(mask_tex, UV).r;
#endif
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (reset) {
		COLOR = vec4(color.xyz, a);
	} else {
		float alpha_sum = min(max(a, screen_color.a), a + screen_color.a);
		COLOR = vec4((color.xyz*a+screen_color.xyz*(vec3(alpha_sum)-a))/alpha_sum, alpha_sum);
	}

#endif
}
