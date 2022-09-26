uniform float variation = 0.0;

vec4 preview_2d(vec2 uv) {
	float _seed_variation_ = variation;
	$(code)
	return vec4(sign(dot($(value),vec4(1.0)))*(vec3(0.1)+0.9*fract(vec3(3456.765, 6523.12, 2373.987)*$(value).rgb+2341.876*$(value).aaa)), 1.0);
}
