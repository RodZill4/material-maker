shader_type canvas_item;

uniform sampler2D tex : hint_white;
uniform sampler2D seams : hint_white;

void fragment() {
	COLOR = texture(tex, UV+(texture(seams, UV).xy-vec2(0.5))/64.0);
}
