shader_type canvas_item;

uniform sampler2D normal_tex;
uniform sampler2D depth_tex;
uniform float bump_strength = 0.5;
uniform float epsilon = 0.00048828125;

vec3 normal_blend(vec3 n1, vec3 n2, float opacity) {
	n1.z = 1.0 - n1.z; // inverting z channel before calculations
	n2.z = 1.0 - n2.z; // inverting z channel before calculations
	vec3 t = n1*vec3( 2,  2, 2) + vec3(-1, -1,  0);
	vec3 u = n2*vec3(-2, -2, 2) + vec3( 1,  1, -1);
	vec3 r = mix(n2 * 2.0 - 1.0, t * dot(t, u) / t.z - u, opacity);
	r.z = r.z * -1.0; // inverting z channel after calculations
	return r * 0.5 + 0.5;
}
void fragment() {
	vec2 uv = UV;
	vec3 normal_from_bump = vec3(0.0);
	normal_from_bump += vec3(-1.0, -1.0, 0.0) * texture(depth_tex, uv+vec2(-epsilon, -epsilon)).rgb;
	normal_from_bump += vec3(0.0, -2.0, 0.0) * texture(depth_tex, uv+vec2(0.0, -epsilon)).rgb;
	normal_from_bump += vec3(1.0, -1.0, 0.0) * texture(depth_tex, uv+vec2(epsilon, -epsilon)).rgb;
	normal_from_bump += vec3(-2.0, 0.0, 0.0) * texture(depth_tex, uv+vec2(-epsilon, 0.0)).rgb;
	normal_from_bump += vec3(2.0, 0.0, 0.0) * texture(depth_tex, uv+vec2(epsilon, 0.0)).rgb;
	normal_from_bump += vec3(-1.0, 1.0, 0.0) * texture(depth_tex, uv+vec2(-epsilon, epsilon)).rgb;
	normal_from_bump += vec3(0.0, 2.0, 0.0) * texture(depth_tex, uv+vec2(0.0, epsilon)).rgb;
	normal_from_bump += vec3(1.0, 1.0, 0.0) * texture(depth_tex, uv+vec2(epsilon, epsilon)).rgb;
	normal_from_bump *= vec3(1.0, -1.0, 0.0);
	normal_from_bump += vec3(0.0, 0.0, -1.0);
	normal_from_bump = normalize(normal_from_bump);
	vec3 painted_normal = 2.0*texture(normal_tex, uv).rgb-vec3(1.0);
	COLOR = vec4(0.5*normalize(mix(painted_normal, normal_from_bump, bump_strength))+vec3(0.5), 1.0);
}