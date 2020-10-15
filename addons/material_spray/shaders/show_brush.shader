shader_type canvas_item;

uniform vec2      brush_pos       = vec2(0.5, 0.5);
uniform vec2      brush_ppos      = vec2(0.5, 0.5);
uniform vec2      brush_size      = vec2(0.25, 0.25);
uniform float     brush_strength  = 0.5;
uniform sampler2D brush_texture : hint_white;
uniform float     pattern_scale = 10.0;
uniform float     texture_angle = 0.0;
uniform bool      stamp_mode    = false;

float brush(float v) {
	return clamp(v / (1.0-brush_strength), 0.0, 1.0);
}

vec4 pattern_color(vec2 uv) {
	mat2 texture_rotation = mat2(vec2(cos(texture_angle), sin(texture_angle)), vec2(-sin(texture_angle), cos(texture_angle)));
	vec2 pattern_uv = pattern_scale*texture_rotation*(vec2(brush_size.y/brush_size.x, 1.0)*(uv - vec2(0.5, 0.5)));
	return texture(brush_texture, fract(pattern_uv));
}

void fragment() {
	vec2 b = brush_pos/brush_size;
	vec2 bv = (brush_ppos-brush_pos)/brush_size;
	vec2 p = UV/brush_size;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	vec2 local_uv = p-(b+x*bv);
	if (stamp_mode) {
		mat2 texture_rotation = mat2(vec2(cos(texture_angle), sin(texture_angle)), vec2(-sin(texture_angle), cos(texture_angle)));
		local_uv = texture_rotation*local_uv;
		vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
		float a = stamp_limit.x*stamp_limit.y;
		COLOR = texture(brush_texture, 0.5*local_uv+vec2(0.5)) * vec4(vec3(1.0), 0.5*a);
	} else {
		float a = brush(max(0.0, 1.0-length(local_uv)));
		COLOR = pattern_color(UV) * vec4(vec3(1.0), 0.5*a);
	}
}
