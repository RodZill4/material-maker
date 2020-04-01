float __control(vec3 uv) {
	$(code)
	return $(value);
}

vec4 preview_2d(vec2 uv) {
	float cmin = 1.0;
	float cmax = -1.0;
	for (int i = -5; i <=5; ++i) {
		float c = 0.1*__control(vec3(uv.x+float(i)/5.0/preview_size));
		cmin = min(c, cmin);
		cmax = max(c, cmax);
	}
	vec2 y = vec2((0.5-uv.y)*2.1);
	vec2 color = step(cmin, y+1.0/preview_size)*step(y-1.0/preview_size, smax);
	return vec4(color, max(color.x, color.y), 1.0);
}
