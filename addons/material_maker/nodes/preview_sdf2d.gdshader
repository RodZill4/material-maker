uniform float variation = 0.0;

vec4 preview_2d(vec2 uv) {
	float _seed_variation_ = variation;
	$(code)
	float d = $(value);

	float border = $(border_thickness);
	float it = $(isolines_thickness);
	float io = $(isolines_opacity);
	float is = max($(isolines_smoothness),0.0001);
	float id = $(isolines_density);
	float sha = $(shadow_opacity);

    vec3 col = ( d >0.0 ) ? $(bg) : mix($(fg1), $(fg2), smoothstep(0.0,0.5,abs(d)));
	border *= 0.25; id *= 250.0;
	it = (it * 2.0 - 1.0) * (1.0 + is * 0.75);
    col *= 1.2 - exp( -6.0 * abs(d) ) * sha;
    col *= 0.8 + 0.1 * io *smoothstep( it + 1.0 * is ,it - 1.0 * is, cos(id * d));
    col = mix(col, vec3(1.0), 1.0 - smoothstep(border - 0.008, border, abs(d)));
    return vec4(col, 1.0);
}