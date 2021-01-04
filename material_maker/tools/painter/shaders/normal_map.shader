shader_type canvas_item;

uniform sampler2D tex;
uniform float epsilon = 0.00048828125 ;

void fragment() {
	vec2 uv = UV;
	vec3 color = vec3(0.0);
	color += vec3(-1.0, -1.0, 0.0) * texture(tex, uv+vec2(-epsilon, -epsilon)).rgb;
	color += vec3(0.0, -2.0, 0.0) * texture(tex, uv+vec2(0.0, -epsilon)).rgb;
	color += vec3(1.0, -1.0, 0.0) * texture(tex, uv+vec2(epsilon, -epsilon)).rgb;
	color += vec3(-2.0, 0.0, 0.0) * texture(tex, uv+vec2(-epsilon, 0.0)).rgb;
	color += vec3(2.0, 0.0, 0.0) * texture(tex, uv+vec2(epsilon, 0.0)).rgb;
	color += vec3(-1.0, 1.0, 0.0) * texture(tex, uv+vec2(-epsilon, epsilon)).rgb;
	color += vec3(0.0, 2.0, 0.0) * texture(tex, uv+vec2(0.0, epsilon)).rgb;
	color += vec3(1.0, 1.0, 0.0) * texture(tex, uv+vec2(epsilon, epsilon)).rgb;
	color *= vec3(1.0, -1.0, 0.0);
	color += vec3(0.0, 0.0, -1.0);
	color = normalize(color);
	color *= 0.5;
	color += vec3(0.5, 0.5, 0.5);
	COLOR = vec4(color, 1.0);
}