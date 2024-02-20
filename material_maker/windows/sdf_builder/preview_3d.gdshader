shader_type spatial;

varying float elapsed_time;

varying vec3 world_camera;
varying vec3 world_position;

const int MAX_STEPS = 100;
const float MAX_DIST = 200.0;
const float SURF_DIST = 1e-3;

float dot2(vec2 x) {
	return dot(x, x);
}

float rand(vec2 x) {
    return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}

vec2 rand2(vec2 x) {
    return fract(cos(mod(vec2(dot(x, vec2(13.9898, 8.141)),
						      dot(x, vec2(3.4562, 17.398))), vec2(3.14))) * 43758.5453);
}

vec3 rand3(vec2 x) {
    return fract(cos(mod(vec3(dot(x, vec2(13.9898, 8.141)),
							  dot(x, vec2(3.4562, 17.398)),
                              dot(x, vec2(13.254, 5.867))), vec3(3.14))) * 43758.5453);
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

GENERATED_GLOBALS

GENERATED_INSTANCE

float GetDist(vec3 uv) {
	return DIST_FCT(uv, 0, 0.0);
}

float RayMarch(vec3 ro, vec3 rd) {
	float dO = 0.0;
	float color = 0.0;
	float dS;
	
	for (int i = 0; i < MAX_STEPS; i++)
	{
		vec3 p = ro + dO * rd;
		dS = GetDist(p);
		dO += dS;
		
		if (abs(dS) < SURF_DIST || dO > MAX_DIST) {
			break;
		}
	}
	return dO;
}

vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1e-2, 0);
	
	vec3 n = GetDist(p) - vec3(
		GetDist(p - e.xyy),
		GetDist(p - e.yxy),
		GetDist(p - e.yyx)
	);
	
	return normalize(n);
}

void vertex() {
	elapsed_time = TIME;
	vec4 world_position_xyzw = MODEL_MATRIX*vec4(VERTEX, 1.0);
	world_position = world_position_xyzw.xyz/world_position_xyzw.w;
	vec4 world_camera_xyzw = INV_VIEW_MATRIX * vec4(0, 0, 0, 1);
	world_camera = world_camera_xyzw.xyz/world_camera_xyzw.w;
}

void fragment() {
    float _seed_variation_ = 0.0;
	vec3 ro = world_camera;
	vec3 rd =  normalize(world_position - world_camera);
	
	float d = RayMarch(ro, rd);

	if (d >= MAX_DIST) {
		discard;
	} else {
		vec3 p = ro + rd * d;
		vec4 albedo;
		float metallic;
		float roughness;
		vec3 emission;
		COLOR_FCT(p, albedo, metallic, roughness, emission, _seed_variation_);
		ALBEDO = albedo.rgb;
		ROUGHNESS = roughness;
		METALLIC = metallic;
		NORMAL = (VIEW_MATRIX*vec4(GetNormal(p), 0.0)).xyz;
		EMISSION = emission;
	}
}
