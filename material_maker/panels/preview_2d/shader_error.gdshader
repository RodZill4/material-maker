shader_type canvas_item;
uniform sampler2D error_tex;

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = UV;
	vec2 s = fwidth(uv);
	uv = (uv-0.5) * max(s.x,s.y)/s + 0.5;
	float grain = hash12(floor(uv*512.0) + floor(TIME*24.0)*0.04);
	COLOR = vec4(texture(error_tex, uv).rgb+grain-0.7, 1.0);
}