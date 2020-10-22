shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D tex2view_tex;
uniform sampler2D tex2viewlsb_tex;
uniform sampler2D seams : hint_white;

uniform bool      erase             = false;
uniform bool      stamp_mode        = false;
uniform vec2      brush_pos         = vec2(0.5, 0.5);
uniform vec2      brush_ppos        = vec2(0.5, 0.5);
uniform vec2      brush_size        = vec2(0.25, 0.25);
uniform float     brush_strength    = 0.5;
uniform float     pattern_scale     = 10.0;
uniform float     pattern_angle     = 0.0;

// BEGIN_PATTERN
float brush_function(vec2 uv) {
	return clamp(max(0.0, 1.0-length(2.0*(uv-vec2(0.5)))) / (0.5), 0.0, 1.0);
}

uniform sampler2D brush_texture : hint_white;
vec4 pattern_function(vec2 uv) {
	return texture(brush_texture, uv);
}
// END_PATTERN


void fragment() {
	// Get UV from seams texture
	vec2 uv = UV+(texture(seams, UV).xy-vec2(0.5))/64.0;
	// Get View position
	vec4 tex2view = texture(tex2view_tex, uv);
	vec2 xy = tex2view.xy;
	// Get distance to brush center
	vec2 b = brush_pos/brush_size;
	vec2 bv = (brush_ppos-brush_pos)/brush_size;
	vec2 p = xy/brush_size;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	// Get position in brush
	vec2 local_uv = p-(b+x*bv);

	mat2 texture_rotation = mat2(vec2(cos(pattern_angle), sin(pattern_angle)), vec2(-sin(pattern_angle), cos(pattern_angle)));
	local_uv = texture_rotation*local_uv;
	vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
	vec4 color = pattern_function(0.5*local_uv+vec2(0.5));
	float a = stamp_limit.x*stamp_limit.y*brush_function(0.5*local_uv+vec2(0.5));

	a *= color.a*tex2view.z;
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (erase) {
		COLOR = vec4(screen_color.xyz, max(screen_color.a-a, 0.0));
	} else {
		float alpha_sum = min(1.0, a + screen_color.a);
		COLOR = vec4((color.xyz*a+screen_color.xyz*(vec3(alpha_sum)-a))/alpha_sum, alpha_sum);
	}
}
