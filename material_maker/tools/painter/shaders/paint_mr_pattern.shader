#include paint_header

// BEGIN_PATTERN
float brush_function(vec2 uv) {
	return clamp(max(0.0, 1.0-length(2.0*(uv-vec2(0.5)))) / (0.5), 0.0, 1.0);
}

uniform sampler2D brush_texture : hint_white;
vec4 pattern_function(vec2 uv) {
	return texture(brush_texture, uv);
}
// END_PATTERN

float brush(vec2 uv) {
	return clamp(brush_opacity*brush_function(uv)/(1.0-brush_hardness), 0.0, 1.0);
}

void fragment() {
	// Get UV from seams texture
	vec2 seams_value = texture(seams, UV).xy-vec2(0.5);
	vec2 uv = fract(UV+seams_value*seams_multiplier/texture_size);
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
	vec2 pattern_uv = pattern_scale*texture_rotation*(vec2(brush_size.y/brush_size.x, 1.0)*(xy - vec2(0.5, 0.5)));
	vec4 color = pattern_function(fract(pattern_uv));
	
	vec2 a = fill ? vec2(1.0) : vec2(brush(0.5*local_uv+vec2(0.5)))*color.ba*tex2view.z;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	if (erase) {
		COLOR = vec4(screen_color.xy, max(screen_color.za-a, 0.0));
	} else if (reset) {
		COLOR = vec4(color.xy, a);
	} else {
		vec2 alpha_sum = min(vec2(1.0), a + screen_color.za);
		COLOR = vec4((color.xy*a+screen_color.xy*(alpha_sum-a))/alpha_sum, alpha_sum);
	}
}
