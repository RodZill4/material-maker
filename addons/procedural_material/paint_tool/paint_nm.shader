shader_type canvas_item;

uniform sampler2D self_tex;
uniform sampler2D tex2view_tex;
uniform sampler2D brush_texture : hint_normal;
uniform vec2      brush_pos      = vec2(0.5, 0.5);
uniform vec2      brush_ppos     = vec2(0.5, 0.5);
uniform vec2      brush_size     = vec2(0.25, 0.25);
uniform float     brush_strength = 1.0;

float brush(float v) {
	return clamp(v / (1.0-brush_strength), 0.0, 1.0);
}

void fragment() {
	vec4 t2v = textureLod(tex2view_tex, UV, 0.0);
	vec2 xy = t2v.xy;
	vec2 b = brush_pos/brush_size;
	vec2 bv = (brush_ppos-brush_pos)/brush_size;
	vec2 p = xy/brush_size;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	float a = 1.0-length(p-(b+x*bv));
	a = brush(max(0.0, a))*t2v.z;
	vec3 old = texture(self_tex, UV).xyz;
	vec3 new = texture(brush_texture, 2.0*vec2(brush_size.y/brush_size.x, 1.0)*xy).xyz;
	vec3 color = normalize(mix(old, new, a)-vec3(0.5));
	COLOR = vec4(0.5*color+0.5, 1.0);
}
