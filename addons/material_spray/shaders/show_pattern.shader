shader_type canvas_item;

uniform vec2      brush_size = vec2(0.25, 0.25);
uniform float     pattern_scale = 10.0;
uniform float     texture_angle = 0.0;

// BEGIN_PATTERN
float brush_function(vec2 uv) {
	return clamp(max(0.0, 1.0-length(2.0*(uv-vec2(0.5)))) / 0.5, 0.0, 1.0);
}

vec4 pattern_function(vec2 uv) {
	return vec4(vec3(fract(10.0*uv.x+length(uv-vec2(0.5))*10.0)), 1.0);
}
// END_PATTERN

vec4 pattern_color(vec2 uv) {
	mat2 texture_rotation = mat2(vec2(cos(texture_angle), sin(texture_angle)), vec2(-sin(texture_angle), cos(texture_angle)));
	vec2 pattern_uv = pattern_scale*texture_rotation*(vec2(brush_size.y/brush_size.x, 1.0)*(uv - vec2(0.5, 0.5)));
	return pattern_function(fract(pattern_uv));
}

void fragment() {
	COLOR = pattern_color(UV) * vec4(1.0, 1.0, 1.0, 0.2);
}
