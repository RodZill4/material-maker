shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform vec4      col = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D tex : hint_white;

void fragment() {
	COLOR = col * texture(tex, UV);
}
