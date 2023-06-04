shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform bool erase = false;
uniform sampler2D tex;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 screen_color = clamp(texture(SCREEN_TEXTURE, UV), vec4(0.0), vec4(1.0));
	vec4 color = clamp(texture(tex, UV), vec4(0.0), vec4(1.0));
	vec2 a = color.ba*COLOR.a;
	if (erase) {
		COLOR = vec4(screen_color.rg, max(screen_color.ba-a, 0.0));
	} else {
		vec2 alpha_sum = min(vec2(1.0), a + screen_color.ba);
		COLOR = vec4((color.rg*a+screen_color.rg*(alpha_sum-a))/alpha_sum, alpha_sum);
	}
}
