vec2 calcdist(vec3 uv) {
	$(code)
	vec2 v = $(value);
	return vec2(min(v.x, uv.z), v.y);
}

vec2 raymarch(vec3 ro, vec3 rd) {
	float d=0.0;
	float color;
	for (int i = 0; i < 50; i++) {
		vec3 p = ro + rd*d;
		vec2 dstep = calcdist(p);
		d += dstep.x;
		if (dstep.x < 0.0001) {
			color = dstep.y;
			break;
		}
	}
	return vec2(d, color);
}
vec3 normal(vec3 p) {
	float d = calcdist(p).x;
    float e = .0001;
    vec3 n = d - vec3(calcdist(p-vec3(e, 0.0, 0.0)).x, calcdist(p-vec3(0.0, e, 0.0)).x, calcdist(p-vec3(0.0, 0.0, e)).x);
    return normalize(n);
}

vec3 rm_color(float c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(vec3(c) + K.xyz) * 6.0 - K.www);
	return 1.0 * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), 1.0);
}

void fragment() {
	vec2 uv = UV-vec2(0.5);
	vec2 rm = raymarch(vec3(uv, 2.0), vec3(0.0, 0.0, -1.0));
	vec3 p = vec3(uv, 2.0-rm.x);
	vec3 n = normal(p);
	vec3 l = vec3(5.0, 5.0, 10.0);
	vec3 ld = normalize(l-p);
	float o = step(p.z, 0.001);
	float shadow = 1.0-0.75*step(raymarch(l, -ld).x, length(l-p)-0.01);
	float light = 0.3+0.7*dot(n, ld)*shadow;
	COLOR = vec4(mix(rm_color(fract(rm.y)), vec3(0.9), o)*light, 1.0);
}
