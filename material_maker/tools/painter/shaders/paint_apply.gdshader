shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform bool erase = false;
uniform sampler2D tex;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	vec4 color = texture(tex, UV);
	float a = color.a*COLOR.a;
	if (erase) {
		COLOR = vec4(screen_color.rgb, max(screen_color.a-a, 0.0));
	} else {
		float alpha_sum = min(1.0, a + screen_color.a);
		COLOR = vec4((color.xyz*a+screen_color.xyz*(vec3(alpha_sum)-a))/alpha_sum, alpha_sum);
	}
}
