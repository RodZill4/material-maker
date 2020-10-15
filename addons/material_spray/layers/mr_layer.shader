shader_type canvas_item;
render_mode blend_disabled;

void fragment() {
	vec4 layer = texture(TEXTURE, UV);
	vec4 back = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 alpha = min(layer.ba+back.ba, vec2(1.0));
	COLOR = vec4(mix(back.rg, layer.rg, layer.ba/alpha), alpha);
}