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

vec3 brick(vec2 uv, vec2 bmin, vec2 bmax, float mortar, float bevel) {
	float color = 0.5;
    vec2 c1 = (uv-bmin-vec2(mortar))/bevel;
    vec2 c2 = (bmax-uv-vec2(mortar))/bevel;
    vec2 c = min(c1, c2);
    color = clamp(min(c.x, c.y), 0.0, 1.0);
	return vec3(color, mod(bmin, vec2(1.0, 1.0)));
}

vec3 bricks_rb(vec2 uv, vec2 count, float repeat, float offset, float mortar, float bevel) {
	count *= repeat;
	mortar /= max(count.x, count.y);
	bevel /= max(count.x, count.y);
    float x_offset = offset*step(0.5, fract(uv.y*count.y*0.5));
    vec2 bmin = floor(vec2(uv.x*count.x-x_offset, uv.y*count.y));
    bmin.x += x_offset;
    bmin /= count;
	return brick(uv, bmin, bmin+vec2(1.0)/count, mortar, bevel);
}

vec3 bricks_rb2(vec2 uv, vec2 count, float repeat, float offset, float mortar, float bevel) {
	count *= repeat;
	mortar /= max(2.0*count.x, count.y);
	bevel /= max(2.0*count.x, count.y);
    float x_offset = offset*step(0.5, fract(uv.y*count.y*0.5));
    count.x = count.x*(1.0+step(0.5, fract(uv.y*count.y*0.5)));
    vec2 bmin = floor(vec2(uv.x*count.x-x_offset, uv.y*count.y));
    bmin.x += x_offset;
    bmin /= count;
	return brick(uv, bmin, bmin+vec2(1.0)/count, mortar, bevel);
}

vec3 bricks_hb(vec2 uv, vec2 count, float repeat, float offset, float mortar, float bevel) {
   	float pc = count.x+count.y;
    float c = pc*repeat;
	mortar /= c;
	bevel /= c;
    vec2 corner = floor(uv*c);
    float cdiff = mod(corner.x-corner.y, pc);
    if (cdiff < count.x) {
		return brick(uv, (corner-vec2(cdiff, 0.0))/c, (corner-vec2(cdiff, 0.0)+vec2(count.x, 1.0))/c, mortar, bevel);
    } else {
		return brick(uv, (corner-vec2(0.0, pc-cdiff-1.0))/c, (corner-vec2(0.0, pc-cdiff-1.0)+vec2(1.0, count.y))/c, mortar, bevel);
    }
}

vec3 bricks_bw(vec2 uv, vec2 count, float repeat, float offset, float mortar, float bevel) {
   	vec2 c = 2.0*count*repeat;
    float mc = max(c.x, c.y);
	mortar /= mc;
	bevel /= mc;
    vec2 corner1 = floor(uv*c);
    vec2 corner2 = count*floor(repeat*2.0*uv);
    float cdiff = mod(dot(floor(repeat*2.0*uv), vec2(1.0)), 2.0);
    vec2 corner;
    vec2 size;
    if (cdiff == 0.0) {
        corner = vec2(corner1.x, corner2.y);
        size = vec2(1.0, count.y);
    } else {
        corner = vec2(corner2.x, corner1.y);
        size = vec2(count.x, 1.0);
    }
	return brick(uv, corner/c, (corner+size)/c, mortar, bevel);
}

vec3 bricks_sb(vec2 uv, vec2 count, float repeat, float offset, float mortar, float bevel) {
   	vec2 c = (count+vec2(1.0))*repeat;
    float mc = max(c.x, c.y);
	mortar /= mc;
	bevel /= mc;
    vec2 corner1 = floor(uv*c);
    vec2 corner2 = (count+vec2(1.0))*floor(repeat*uv);
    vec2 rcorner = corner1 - corner2;
    vec2 corner;
    vec2 size;
    if (rcorner.x == 0.0 && rcorner.y < count.y) {
        corner = corner2;
        size = vec2(1.0, count.y);
    } else if (rcorner.y == 0.0) {
        corner = corner2+vec2(1.0, 0.0);
        size = vec2(count.x, 1.0);
    } else if (rcorner.x == count.x) {
        corner = corner2+vec2(count.x, 1.0);
        size = vec2(1.0, count.y);
    } else if (rcorner.y == count.y) {
        corner = corner2+vec2(0.0, count.y);
        size = vec2(count.x, 1.0);
    } else {
        corner = corner2+vec2(1.0);
        size = vec2(count.x-1.0, count.y-1.0);
    }
	return brick(uv, corner/c, (corner+size)/c, mortar, bevel);
}

float colored_bricks(vec2 uv, vec2 count, float offset) {
	float x = floor(uv.x*count.x+offset*step(0.5, fract(uv.y*count.y*0.5)));
	float y = floor(uv.y*count.y);
	return fract(x/3.0+y/7.0);
}

float dots(vec2 uv, float size, float density, int seed) {
	vec2 seed2 = rand2(vec2(float(seed), 1.0-float(seed)));
	uv /= size;
	vec2 point_pos = floor(uv)+vec2(0.5);
	float color = step(rand(seed2+point_pos), density);
    return color;
}

float perlin(vec2 uv, vec2 size, int iterations, float persistence, int seed) {
	vec2 seed2 = rand2(vec2(float(seed), 1.0-float(seed)));
    float rv = 0.0;
    float coef = 1.0;
    float acc = 0.0;
    for (int i = 0; i < iterations; ++i) {
    	vec2 step = vec2(1.0)/size;
		vec2 xy = floor(uv*size);
        float f0 = rand(seed2+mod(xy, size));
        float f1 = rand(seed2+mod(xy+vec2(1.0, 0.0), size));
        float f2 = rand(seed2+mod(xy+vec2(0.0, 1.0), size));
        float f3 = rand(seed2+mod(xy+vec2(1.0, 1.0), size));
        vec2 mixval = smoothstep(0.0, 1.0, fract(uv*size));
        rv += coef * mix(mix(f0, f1, mixval.x), mix(f2, f3, mixval.x), mixval.y);
        acc += coef;
        size *= 2.0;
        coef *= persistence;
    }
    
    return rv / acc;
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
