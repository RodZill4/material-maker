shader_type canvas_item;

uniform sampler2D tex;
uniform float scale = 1.0;
uniform bool invert = false;

void fragment() {
	vec4 col = texture(tex, UV*scale);
	COLOR = invert ? col : vec4(1.0-col.rgb, col.a);
}
