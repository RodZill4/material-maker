shader_type canvas_item;
render_mode blend_disabled;


uniform int view_style = VIEW_STYLE;
varying float elapsed_time;


float dot2(vec2 x) {
	return dot(x, x);
}

float rand(vec2 x) {
    return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}

vec2 rand2(vec2 x) {
    return fract(cos(mod(vec2(dot(x, vec2(13.9898, 8.141)),
						      dot(x, vec2(3.4562, 17.398))), vec2(3.14))) * 43758.5453);
}

vec3 rand3(vec2 x) {
    return fract(cos(mod(vec3(dot(x, vec2(13.9898, 8.141)),
							  dot(x, vec2(3.4562, 17.398)),
                              dot(x, vec2(13.254, 5.867))), vec3(3.14))) * 43758.5453);
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

GENERATED_GLOBALS

GENERATED_INSTANCE

uniform vec2 preview_2d_size = vec2(100.0);
uniform float preview_2d_scale = 1.2;
uniform vec2 preview_2d_center = vec2(0.5);
uniform vec4 background_color_1 = vec4(0.0);
uniform vec4 background_color_2 = vec4(1.0);

float sstep(float v1, float v2) {
	float edgewidth = 0.002*preview_2d_scale;
	return smoothstep(v1-edgewidth, v1+edgewidth, v2);
}

void fragment() {
	float _seed_variation_ = 0.0;
	vec2 ratio = preview_2d_size;
	vec2 uv = preview_2d_center-vec2(0.5)+(UV-0.5)*preview_2d_scale*ratio/min(ratio.x, ratio.y);
	
	GENERATED_CODE
	
	float edgewidth = 0.0001;
	float d = -DIST_FCT(uv, 0, _seed_variation_);
	float d2 = -DIST_FCT(uv, int(round(INDEX_UNIFORM)), _seed_variation_);
	float d3 = -DIST_FCT(uv, -int(round(INDEX_UNIFORM)), _seed_variation_);
	float color = 0.5*sstep(0.0, d);
	color += sstep(abs(d2), 0.002*preview_2d_scale);
	color += sstep(abs(d3), 0.003*preview_2d_scale);
	color += 0.05*sin(d*251.327412287);
	vec4 albedo;
	COLOR_FCT(uv, albedo, _seed_variation_);
	vec4 image;
	if (view_style == 0) {
		 image = clamp(albedo+vec4(vec3(clamp(color, 0.0, 1.0)), 1.0), vec4(0.0), vec4(1.0));
	} else if (view_style == 1) {
		 image = clamp(vec4(vec3(clamp(color, 0.0, 1.0)), 1.0), vec4(0.0), vec4(1.0));
	} else if (view_style == 2) {
		 image = clamp(albedo, vec4(0.0), vec4(1.0));
	}
	float checkerboard = mod(floor(uv.x*32.0)+floor(uv.y*32.0), 2.0);
	vec3 image_with_background = mix(mix(background_color_1, background_color_2, checkerboard).rgb, image.rgb, image.a);
	COLOR = vec4(image_with_background, 1.0);
}
