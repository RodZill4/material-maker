shader_type canvas_item;

uniform sampler2D tex : hint_white;
uniform sampler2D seams : hint_white;

void fragment() {
	float best_distance = 1.0;
	vec2 best_dv = vec2(0.0);
	for (int i = -28; i <= 28; ++i) {
		float dx1 = float(i)/4096.0;
		float dx2 = float(i+4*sign(i))/4096.0;
		for (int j = -28; j <= 28; ++j) {
			vec2 dv1 = vec2(dx1, float(j)/4096.0);
			vec2 p1 = UV+dv1;
			vec2 dv2 = vec2(dx2, float(j+4*sign(j))/4096.0);
			vec2 p2 = UV+dv2;
			if (p1.x < 0.0 || p1.y < 0.0 || p1.x > 1.0 || p1.y > 1.0) {
				continue;
			}
			float d = length(dv1);
			if (d < best_distance && texture(tex, p1).a > 0.99 && texture(tex, p2).a > 0.99) {
				best_dv = dv2;
				best_distance = d;
			}
			
		}
	}
	COLOR = vec4(vec2(0.5)+64.0*best_dv, 0.0, 1.0);
}
