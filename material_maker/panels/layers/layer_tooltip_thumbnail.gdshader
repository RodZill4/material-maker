shader_type canvas_item;

uniform sampler2D tex;

void fragment() {
	vec4 color = texture(tex, UV);
	vec2 uv = floor(16.0 * UV);
	float checkerboard = 0.5+0.5*mod(uv.x + uv.y, 2.);
	COLOR = vec4(mix(vec3(checkerboard), color.rgb, color.a), 1.0);
}