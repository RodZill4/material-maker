uniform float variation = 0.0;

vec4 mfield(vec4 uv) {
    float _seed_variation_ = variation;
	$(code)
    return $(value);
}

float raymarch(vec3 ro, vec3 rd) {
    float d=0.0;
    for (int i = 0; i < 200; i++) {
        vec3 p = ro + rd*d;
        float dstep = mfield(vec4(p,0.0)).w;
        d += dstep;
        if (dstep < 0.0001) break;
    }
    return d;
}
vec3 normal(vec3 p) {
    float d = mfield(vec4(p,0.0)).w;
    float e = .0001;
    vec3 n = d - vec3(mfield(vec4(p-vec3(e, 0.0, 0.0),0.0)).w, mfield(vec4(p-vec3(0.0, e, 0.0),0.0)).w, mfield(vec4(p-vec3(0.0, 0.0, e),0.0)).w);
    return normalize(n);
}

vec4 preview_2d(vec2 uv) {
    uv -= vec2(0.5);
    vec3 p = vec3(uv, 2.0-raymarch(vec3(uv, 2.0), vec3(0.0, 0.0, -1.0)));
    vec3 n = normal(p);
    vec3 l = vec3(5.0, 5.0, 10.0);
    vec3 ld = normalize(l-p);
    float o = step(p.z, 0.001);
    float shadow = 1.0-0.75*step(raymarch(l, -ld), length(l-p)-0.01);
    float light = 0.3+0.7*dot(n, ld)*shadow;
    return vec4(mfield(vec4(p, 1.0)).xyz*light, 1.0);
}
