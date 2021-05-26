#include paint_header
#include paint_brush_functions_nm

void fragment() {
#include paint_fragment_common

	vec2 epsilon = vec2(1.0/texture_size, 0.0);
	vec2 tex2view_dx = dTex2View(UV, epsilon);
	vec2 tex2view_dy = dTex2View(UV, epsilon.yx);
	mat2 view_mat = inverse(mat2(vec2(tex2view_dx.x, tex2view_dx.y), vec2(tex2view_dy.x, tex2view_dy.y)));

	float pattern_angle_cos = cos(pattern_angle);
	float pattern_angle_sin = sin(pattern_angle);
	mat2 texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));

	local_uv = texture_rotation*local_uv;
	vec2 local_uv2 = p-b-bv;
	local_uv2 = texture_rotation*local_uv2;
	vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
	vec4 color = pattern_function(0.5*local_uv2+vec2(0.5));
	pattern_angle_cos = cos(-pattern_angle);
	pattern_angle_sin = sin(-pattern_angle);
	texture_rotation = mat2(vec2(pattern_angle_cos, pattern_angle_sin), vec2(-pattern_angle_sin, pattern_angle_cos));
	color.xy = view_mat*(texture_rotation*(color.xy-vec2(0.5)))+vec2(0.5);
	
	float a = fill ? 1.0 : stamp_limit.x*stamp_limit.y*brush(0.5*local_uv+vec2(0.5))*color.a*tex2view.z;
	
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
