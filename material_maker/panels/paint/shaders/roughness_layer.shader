shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR=vec4(0.0, tex.g, 0.0, tex.a);
}