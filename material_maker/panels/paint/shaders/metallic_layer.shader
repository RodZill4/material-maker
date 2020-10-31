shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR=vec4(tex.r, 0.0, 0.0, tex.b);
}