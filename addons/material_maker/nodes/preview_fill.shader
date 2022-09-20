uniform float variation = 0.0;

vec4 preview_2d(vec2 uv) {
	float _seed_variation_ = variation;
	$(code)
	return vec4(fract($(value).rgb+$(value).aaa), 1.0);
}
