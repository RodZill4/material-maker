shader_type spatial;
render_mode unshaded, cull_front;

uniform sampler2D view2texture;
uniform mat4      model_transform;
uniform float     fovy_degrees = 45;
uniform float     z_near = 0.01;
uniform float     z_far = 60.0;
uniform float     aspect = 1.0;

varying vec4 global_position;
varying vec3 normal;

mat4 get_projection_matrix() {
	float PI = 3.14159265359;
	
	float rads = fovy_degrees / 2.0 * PI / 180.0;

	float deltaZ = z_far - z_near;
	float sine = sin(rads);

	if (deltaZ == 0.0 || sine == 0.0 || aspect == 0.0)
		return mat4(0.0);
	
	float cotangent = cos(rads) / sine;

	mat4 matrix = mat4(1.0);
	matrix[0][0] = cotangent / aspect;
	matrix[1][1] = cotangent;
	matrix[2][2] = (z_far + z_near) / deltaZ;
	matrix[2][3] = 1.0; //try +1
	matrix[3][2] = 2.0 * z_near * z_far / deltaZ; 
	
	matrix[3][3] = 0.0;
	
	return matrix;
}

void vertex() {
	global_position = model_transform*vec4(VERTEX, 1.0);
	normal = (model_transform*vec4(NORMAL, 0.0)).xyz;
	VERTEX=vec3(UV.x, UV.y, 0.0);
	COLOR=vec4(1.0);
}

vec2 fix_unshaded(vec2 xy) {
	return pow(xy, vec2(2.22));
}

void fragment() {
	vec4 color = get_projection_matrix()*vec4(global_position.xyz, 1.0);
	color.xyz /= color.w;
	vec3 xyz = vec3(0.5-0.5*color.x, 0.5+0.5*color.y, -0.5*color.z);
	xyz.xy = fract(xyz.xy*255.0);
	ALBEDO = vec3(fix_unshaded(xyz.xy), 0.0);
}
