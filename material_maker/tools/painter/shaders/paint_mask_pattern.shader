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
	
	vec4 color = vec4(vec3(erase ? 0.0 : 1.0), 1.0)*pattern_function(fract(uv));
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5))*tex2view.z;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	COLOR = vec4(mix(screen_color.xyz, color.xyz, a*color.a), 1.0);
}
