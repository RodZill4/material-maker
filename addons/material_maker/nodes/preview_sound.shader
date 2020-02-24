vec2 __sound(vec3 uv) {
	$(code)
	return $(value);
}

void fragment() {
	vec3 uv = UV.xxx;
	vec2 smin = vec2(1.0);
	vec2 smax = vec2(-1.0);
	for (int i = -5; i <=5; ++i) {
		vec2 s = __sound(vec3(UV.x+float(i)/5.0/preview_size));
		smin = min(s, smin);
		smax = max(s, smax);
	}
	vec2 y = vec2((0.5-UV.y)*2.1);
	vec2 color = step(smin, y+4.0/preview_size)*step(y-4.0/preview_size, smax);
	COLOR = vec4(color, max(color.x, color.y), 1.0);
}
