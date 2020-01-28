void fragment() {
	vec2 uv = UV;
	$(code)
	float d = $(value);
	vec3 col = vec3(cos(d*min(256, preview_size)));
	col *= clamp(1.0-d*d, 0.0, 1.0);
	col *= vec3(1.0, vec2(step(-0.015, d)));
	col *= vec3(vec2(step(d, 0.015)), 1.0);
	COLOR = vec4(col, 1.0);
}
