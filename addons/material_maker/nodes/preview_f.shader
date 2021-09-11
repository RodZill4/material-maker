uniform float variation = 0.0;

vec4 preview_2d(vec2 uv) {
	float __seed_variation__ = variation;
	$(code)
	return vec4(vec3($(value)), 1.0);
}
