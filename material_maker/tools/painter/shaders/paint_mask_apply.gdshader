shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform bool erase = false;
uniform sampler2D tex;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	vec4 color = texture(tex, UV);
	float a = color.a*COLOR.a;
	COLOR = vec4((vec3(erase?0.0:1.0)*a+screen_color.xyz*(1.0-a)), 1.0);
}
