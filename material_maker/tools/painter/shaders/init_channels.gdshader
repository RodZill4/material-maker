shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D r_tex : hint_default_white;
uniform vec4      r_mask = vec4(1.0, 0.0, 0.0, 0.0);
uniform sampler2D g_tex : hint_default_white;
uniform vec4      g_mask = vec4(0.0, 1.0, 0.0, 0.0);
uniform sampler2D b_tex : hint_default_white;
uniform vec4      b_mask = vec4(0.0, 0.0, 1.0, 0.0);
uniform sampler2D a_tex : hint_default_white;
uniform vec4      a_mask = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	COLOR = vec4(dot(texture(r_tex, UV), r_mask), dot(texture(g_tex, UV), g_mask), dot(texture(b_tex, UV), b_mask), dot(texture(a_tex, UV), a_mask));
}
