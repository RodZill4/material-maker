uniform float variation = 0.0;

vec4 preview_2d(vec2 uv) {
	float _seed_variation_ = variation;
	$(code)
	float d = $(value);

	float border = $(border_thickness) * 0.25;
	float it = $(isolines_thickness);
	float io = $(isolines_opacity);
	float _is = max($(isolines_smoothness), 0.0001);
	float id = $(isolines_density) * 250.0;
	float sha = $(shadow_opacity);

	vec3 col = ( d >0.0 ) ? $(bg) : mix($(fg1), $(fg2), smoothstep(0.0,0.5,abs(d)));
	it = (it * 2.0 - 1.0) * (1.0 + _is * 0.75);

	col *= 1.2 - exp(-6.0 * abs(d)) * sha;
	col *= 0.8 + 0.1 * io *smoothstep( it + _is ,it - _is, cos(id * d));
	col = mix(col, vec3(1.0), 1.0 - smoothstep(border - 0.007, border, abs(d)));
	return vec4(col, 1.0);
}