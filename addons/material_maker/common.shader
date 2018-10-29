float rand(vec2 x) {
    return fract(cos(dot(x, vec2(13.9898, 8.141))) * 43758.5453);
}

vec2 rand2(vec2 x) {
    return fract(cos(vec2(dot(x, vec2(13.9898, 8.141)),
						  dot(x, vec2(3.4562, 17.398)))) * 43758.5453);
}

vec3 rand3(vec2 x) {
    return fract(cos(vec3(dot(x, vec2(13.9898, 8.141)),
                          dot(x, vec2(3.4562, 17.398)),
                          dot(x, vec2(13.254, 5.867)))) * 43758.5453);
}

float wave_constant(float x) {
	return 1.0;
}

float wave_sin(float x) {
	return 0.5-0.5*cos(3.14159265359*2.0*x);
}

float wave_triangle(float x) {
	x = fract(x);
	return min(2.0*x, 2.0-2.0*x);
}

float wave_square(float x) {
	return (fract(x) < 0.5) ? 0.0 : 1.0;
}

float mix_multiply(float x, float y) {
	return x*y;
}

float mix_add(float x, float y) {
	return min(x+y, 1.0);
}

float mix_max(float x, float y) {
	return max(x, y);
}

float mix_min(float x, float y) {
	return min(x, y);
}

float mix_min(float x, float y) {
	return min(x, y);
}

float mix_xor(float x, float y) {
	return min(x+y, 2.0-x-y);
}

float mix_pow(float x, float y) {
	return pow(x, y);
}

vec3 blend_normal(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*c1 + (1.0-opacity)*c2;
}

vec3 blend_dissolve(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	if (rand(uv) < opacity) {
		return c1;
	} else {
		return c2;
	}
}

vec3 blend_multiply(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*c1*c2 + (1.0-opacity)*c2;
}

vec3 blend_screen(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*(1.0-(1.0-c1)*(1.0-c2)) + (1.0-opacity)*c2;
}

float blend_overlay_f(float c1, float c2) {
	return (c1 < 0.5) ? (2.0*c1*c2) : (1.0-2.0*(1.0-c1)*(1.0-c2));
}

vec3 blend_overlay(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_overlay_f(c1.x, c2.x), blend_overlay_f(c1.y, c2.y), blend_overlay_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}

vec3 blend_hard_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*0.5*(c1*c2+blend_overlay(uv, c1, c2, 1.0)) + (1.0-opacity)*c2;
}

float blend_soft_light_f(float c1, float c2) {
	return (c2 < 0.5) ? (2.0*c1*c2+c1*c1*(1.0-2.0*c2)) : 2.0*c1*(1.0-c2)+sqrt(c1)*(2.0*c2-1.0);
}

vec3 blend_soft_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_soft_light_f(c1.x, c2.x), blend_soft_light_f(c1.y, c2.y), blend_soft_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}

float blend_burn_f(float c1, float c2) {
	return (c1==0.0)?c1:max((1.0-((1.0-c2)/c1)),0.0);
}

vec3 blend_burn(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_burn_f(c1.x, c2.x), blend_burn_f(c1.y, c2.y), blend_burn_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}

float blend_dodge_f(float c1, float c2) {
	return (c1==1.0)?c1:min(c2/(1.0-c1),1.0);
}

vec3 blend_dodge(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_dodge_f(c1.x, c2.x), blend_dodge_f(c1.y, c2.y), blend_dodge_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}

vec3 blend_lighten(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*max(c1, c2) + (1.0-opacity)*c2;
}

vec3 blend_darken(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*min(c1, c2) + (1.0-opacity)*c2;
}

vec3 blend_difference(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*clamp(c2-c1, vec3(0.0), vec3(1.0)) + (1.0-opacity)*c2;
}

vec2 transform(vec2 uv, vec2 translate, float rotate, vec2 scale) {
	vec2 rv;
	uv -= vec2(0.5);
	rv.x = cos(rotate)*uv.x + sin(rotate)*uv.y;
	rv.y = -sin(rotate)*uv.x + cos(rotate)*uv.y;
	rv /= scale;
	rv += vec2(0.5);
	rv -= translate;
	return rv;
}

vec2 transform_repeat(vec2 uv, vec2 translate, float rotate, vec2 scale) {
	return fract(transform(uv, translate, rotate, scale));
}

vec2 transform_norepeat(vec2 uv, vec2 translate, float rotate, vec2 scale) {
	return clamp(transform(uv, translate, rotate, scale), vec2(0.0), vec2(1.0));
}

vec4 voronoi(vec2 uv, vec2 size, float intensity, int seed) {
	vec2 seed2 = rand2(vec2(float(seed), 1.0-float(seed)));
    uv *= size;
    float best_distance0 = 1.0;
    float best_distance1 = 1.0;
    vec2 point0;
    vec2 point1;
    vec2 p0 = floor(uv);
    for (int dx = -1; dx < 2; ++dx) {
    	for (int dy = -1; dy < 2; ++dy) {
            vec2 d = vec2(float(dx), float(dy));
            vec2 p = p0+d;
            p += rand2(seed2+mod(p, size));
            float distance = length((uv - p) / size);
            if (best_distance0 > distance) {
            	best_distance1 = best_distance0;
            	best_distance0 = distance;
                point1 = point0;
                point0 = p;
            } else if (best_distance1 > distance) {
            	best_distance1 = distance;
                point1 = p;
            }
        }
    }
    float edge_distance = dot(uv - 0.5*(point0+point1), normalize(point0-point1));
    
    return vec4(point0, best_distance0*length(size)*intensity, edge_distance);
}

// From http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
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
