shader_type canvas_item;

uniform sampler2D brush_texture : hint_albedo;
uniform vec2      brush_pos       = vec2(0.5, 0.5);
uniform vec2      brush_ppos      = vec2(0.5, 0.5);
uniform vec2      brush_size      = vec2(0.25, 0.25);
uniform float     brush_strength  = 0.5;

float brush(float v) {
	return clamp(v / (1.0-brush_strength), 0.0, 1.0);
}

void fragment() {
	vec2 b = brush_pos/brush_size;
	vec2 bv = (brush_ppos-brush_pos)/brush_size;
	vec2 p = UV/brush_size;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	float a = 1.0-length(p-(b+x*bv));
	a = brush(max(0.0, a));
	COLOR = vec4(vec3(1.0), 0.5*a);
}
