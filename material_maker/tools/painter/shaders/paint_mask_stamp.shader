shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D tex2view_tex;
uniform float     texture_size = 512.0;
uniform sampler2D seams : hint_white;
uniform float     seams_multiplier = 256.0;
uniform sampler2D mesh_normal_tex;
uniform sampler2D layer_albedo_tex;
uniform sampler2D layer_mr_tex;
uniform sampler2D layer_emission_tex;
uniform sampler2D layer_depth_tex;

uniform bool      erase             = false;
uniform bool      fill              = false;
uniform float     pressure          = 1.0;
uniform vec2      brush_pos         = vec2(0.5, 0.5);
uniform vec2      brush_ppos        = vec2(0.5, 0.5);
uniform vec2      brush_size        = vec2(0.25, 0.25);
uniform float     brush_hardness    = 0.5;
uniform float     brush_opacity     = 1.0;
uniform float     stroke_length     = 0.0;
uniform float     stroke_angle      = 0.0;
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
	
	float color = erase ? 0.0 : 1.0;
	float a = fill ? 1.0 : brush(0.5*local_uv+vec2(0.5))*tex2view.z;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	COLOR = vec4(mix(screen_color.xyz, vec3(color), a), 1.0);
}
