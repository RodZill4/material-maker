shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D tex;

void fragment() {
	COLOR = texture(tex, UV);
}
