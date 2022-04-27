shader_type spatial;

varying float elapsed_time;

varying vec3 world_camera;
varying vec3 world_position;

const int MAX_STEPS = 100;
const float MAX_DIST = 100.0;
const float SURF_DIST = 1e-3;

GENERATED_GLOBALS

GENERATED_INSTANCE

vec2 GetDist(vec3 uv) {
	float _seed_variation_ = 0.0;

GENERATED_CODE

	return vec2(GENERATED_OUTPUT, 0.0);
}

vec2 RayMarch(vec3 ro, vec3 rd) {
	float dO = 0.0;
	float color = 0.0;
	vec2 dS;
	
	for (int i = 0; i < MAX_STEPS; i++)
	{
		vec3 p = ro + dO * rd;
		dS = GetDist(p);
		dO += dS.x;
		
		if (dS.x < SURF_DIST || dO > MAX_DIST) {
			color = dS.y;
			break;
		}
	}
	return vec2(dO, color);
}

vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1e-2, 0);
	
	vec3 n = GetDist(p).x - vec3(
		GetDist(p - e.xyy).x,
		GetDist(p - e.yxy).x,
		GetDist(p - e.yyx).x
	);
	
	return normalize(n);
}

void vertex() {
	elapsed_time = TIME;
	vec4 world_position_xyzw = WORLD_MATRIX*vec4(VERTEX, 1.0);
	world_position = world_position_xyzw.xyz/world_position_xyzw.w;
	vec4 world_camera_xyzw = CAMERA_MATRIX * vec4(0, 0, 0, 1);
	world_camera = world_camera_xyzw.xyz/world_camera_xyzw.w;
}

void fragment() {
    float _seed_variation_ = 0.0;
	vec3 ro = world_camera;
	vec3 rd =  normalize(world_position - ro);
	
	vec2 rm  = RayMarch(ro, rd);
	float d = rm.x;

	if (d >= MAX_DIST) {
		discard;
	} else {
		vec3 p = ro + rd * d;
		ALBEDO = vec3(1.0);
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		NORMAL = (INV_CAMERA_MATRIX*WORLD_MATRIX*vec4(GetNormal(p), 0.0)).xyz;
	}
}
