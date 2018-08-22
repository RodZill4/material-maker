shader_type canvas_item;

uniform sampler2D tex2view_tex;
uniform sampler2D tex2viewlsb_tex;
uniform sampler2D brush_texture : hint_white;
uniform vec2      brush_pos       = vec2(0.5, 0.5);
uniform vec2      brush_ppos      = vec2(0.5, 0.5);
uniform vec2      brush_size      = vec2(0.25, 0.25);
uniform float     brush_strength  = 1.0;
uniform vec4      brush_color     = vec4(1.0, 0.0, 0.0, 1.0);

float brush(float v) {
	return clamp(v / (1.0-brush_strength), 0.0, 1.0);
}

void fragment() {
	vec4 t2v = texture(tex2view_tex, UV);
	vec4 t2vlsb = texture(tex2viewlsb_tex, UV);
	vec2 xy = t2v.xy+t2vlsb.xy/256.0;
	vec2 b = brush_pos/brush_size;
	vec2 bv = (brush_ppos-brush_pos)/brush_size;
	vec2 p = xy/brush_size;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	float a = 1.0-length(p-(b+x*bv));
	a = brush(max(0.0, a))*brush_color.w*t2v.z;
	vec4 color = brush_color*texture(brush_texture, 2.0*vec2(brush_size.y/brush_size.x, 1.0)*xy);
	COLOR = vec4(color.xyz, a);
}
