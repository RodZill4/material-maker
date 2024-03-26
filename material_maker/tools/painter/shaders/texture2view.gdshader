shader_type spatial;
render_mode unshaded, cull_front;

uniform sampler2D view2texture;
uniform sampler2D seams;
uniform float     seams_multiplier = 0.06125;
uniform mat4      model_transform;
uniform float     fovy_degrees = 45;
uniform float     z_near = 0.01;
uniform float     z_far = 60.0;
uniform float     texture_size = 8.0;
uniform float     aspect = 1.0;
uniform float     texel_tolerance = 1.0;

varying mat4 projection_matrix;
varying vec4 global_position;
varying vec3 normal;

mat4 get_projection_matrix() {
	float rads = fovy_degrees*0.00872664625;
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
	projection_matrix = get_projection_matrix();
}

float visibility(vec2 uv, vec3 view_pos) {
	// Compare actual UV with uv from view
	vec4 pos = textureLod(view2texture, view_pos.xy, 0.0);
	vec2 uv_delta = pos.xy-uv;
	return 1.0-texture_size*length(uv_delta)/texel_tolerance;
}

void fragment() {
	float box = 1.0;
	vec4 position = projection_matrix*vec4(global_position.xyz, 1.0);
	position.xyz /= position.w;
	vec3 xyz = vec3(0.5-0.5*position.x, 0.5+0.5*position.y, 0.5+0.5*position.z);
	float visible = 0.0;
	if (position.x > -1.0 && position.x < 1.0 && position.y > -1.0 && position.y < 1.0) {
		float visibility_multiplier = 0.0;
		vec2 epsilon = vec2(1.0/texture_size);
		for (float dx = -box*epsilon.x; dx <= box*epsilon.x; dx += epsilon.x) {
			for (float dy = -box*epsilon.y; dy <= box*epsilon.y; dy += epsilon.y) {
				visibility_multiplier += max(visibility_multiplier, visibility(UV.xy, xyz+vec3(dx, dy, 0.0)));
			}
		}
		visibility_multiplier = clamp(visibility_multiplier, 0.0, 1.0);
		float normal_multiplier = smoothstep(0.1, 0.2, normal.z);
		visible = normal_multiplier*visibility_multiplier;
	}
	ALBEDO = vec3(xyz.xy, visible);
}
