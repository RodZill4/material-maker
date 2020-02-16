float calcdist(vec3 uv) {
	$(code)
	return min($(value), uv.z);
}

float raymarch(vec3 ro, vec3 rd) {
	float d=0.0;
	for (int i = 0; i < 50; i++) {
		vec3 p = ro + rd*d;
		float dstep = calcdist(p);
		d += dstep;
		if (dstep < 0.0001) break;
	}
	return d;
}
vec3 normal(vec3 p) {
	float d = calcdist(p);
    float e = .0001;
    vec3 n = d - vec3(calcdist(p-vec3(e, 0.0, 0.0)), calcdist(p-vec3(0.0, e, 0.0)), calcdist(p-vec3(0.0, 0.0, e)));
    return normalize(n);
}

void fragment() {
	vec2 uv = UV-vec2(0.5);
	vec3 p = vec3(uv, 2.0-raymarch(vec3(uv, 2.0), vec3(0.0, 0.0, -1.0)));
	vec3 n = normal(p);
	vec3 l = vec3(5.0, 5.0, 10.0);
	vec3 ld = normalize(l-p);
	float o = step(p.z, 0.001);
	float shadow = 1.0-0.75*step(raymarch(l, -ld), length(l-p)-0.01);
	float light = 0.3+0.7*dot(n, ld)*shadow;
	COLOR = vec4(vec3(0.8+0.2*o, 0.8+0.2*o, 1.0)*light, 1.0);
}
