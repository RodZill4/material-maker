shader_type canvas_item;

render_mode unshaded, blend_mix;

uniform vec3 uv1_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv1_offset = vec3(0.0, 0.0, 0.0);
uniform float variation = 0.0;
varying float elapsed_time;
void vertex() {
	elapsed_time = TIME;
	UV = UV*uv1_scale.xy+uv1_offset.xy;
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
float param_rnd(float minimum, float maximum, float seed) {
	return minimum+(maximum-minimum)*rand(vec2(seed));
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
uniform sampler2D texture_1;
const float texture_1_size = 1024.0;
uniform sampler2D texture_2;
const float texture_2_size = 32.0;
vec2 transform2_clamp(vec2 uv) {
	return clamp(uv, vec2(0.0), vec2(1.0));
}
vec2 transform2(vec2 uv, vec2 translate, float rotate, vec2 scale) {
 	vec2 rv;
	uv -= translate;
	uv -= vec2(0.5);
	rv.x = cos(rotate)*uv.x + sin(rotate)*uv.y;
	rv.y = -sin(rotate)*uv.x + cos(rotate)*uv.y;
	rv /= scale;
	rv += vec2(0.5);
	return rv;	
}
uniform sampler2D texture_3;
const float texture_3_size = 128.0;
vec4 brick(vec2 uv, vec2 bmin, vec2 bmax, float mortar, float round, float bevel, float brick_height) {
	float color;
	vec2 size = bmax - bmin;
	float min_size = min(size.x, size.y);
	mortar *= brick_height;
	bevel *= brick_height;
	round *= brick_height;
	vec2 center = 0.5*(bmin+bmax);
	vec2 d = abs(uv-center)-0.5*(size)+vec2(round+mortar);
	color = length(max(d,vec2(0))) + min(max(d.x,d.y),0.0)-round;
	color = clamp(-color/bevel, 0.0, 1.0);
	vec2 tiled_brick_pos = mod(bmin, vec2(1.0, 1.0));
	return vec4(color, center, tiled_brick_pos.x+7.0*tiled_brick_pos.y);
}
vec4 brick_corner_bb(vec2 uv, vec2 bmin, vec2 bmax, float mortar, float corner, float brick_height) {
	vec2 center = 0.5*(bmin + bmax);
	vec2 size = bmax - bmin;
	float max_size = max(size.x, size.y);
	float min_size = min(size.x, size.y);
	mortar *= brick_height;
	corner *= brick_height;
	
	vec2 corner1 = vec2(bmin + mortar);
	vec2 corner2 = vec2(bmax.x - mortar - corner, bmin.y + mortar);
	vec2 corner3 = vec2(bmin.x + mortar, bmax.y - mortar - corner);
	vec2 corner4 = vec2(bmax - mortar - corner);
	vec2 top = uv.x < center.x ? corner1 : corner2;
	vec2 bottom = uv.x < center.x ? corner3 : corner4;
	vec2 positions = uv.y < center.y ? top : bottom;
	return vec4(round(fract(positions)*4096.0)/4096.0, corner, corner);
}
vec4 bricks_rb(vec2 uv, vec2 count, float repeat, float offset) {
	count *= repeat;
	float x_offset = offset*step(0.5, fract(uv.y*count.y*0.5));
	vec2 bmin = floor(vec2(uv.x*count.x-x_offset, uv.y*count.y));
	bmin.x += x_offset;
	bmin /= count;
	return vec4(bmin, bmin+vec2(1.0)/count);
}
vec4 bricks_rb2(vec2 uv, vec2 count, float repeat, float offset) {
	count *= repeat;
	float x_offset = offset*step(0.5, fract(uv.y*count.y*0.5));
	count.x = count.x*(1.0+step(0.5, fract(uv.y*count.y*0.5)));
	vec2 bmin = floor(vec2(uv.x*count.x-x_offset, uv.y*count.y));
	bmin.x += x_offset;
	bmin /= count;
	return vec4(bmin, bmin+vec2(1.0)/count);
}
vec4 bricks_rb3(vec2 uv, vec2 count, float repeat, float offset) {
	vec4 bb = bricks_rb(uv, count, repeat, offset);
	
	if ( (uv.x - bb.x) / (bb.z - bb.x) < 1.0/3.0) {
		bb.z = bb.x + (bb.z - bb.x) / 3.0;
	} else {
		bb.x = bb.x + (bb.z - bb.x) / 3.0;
	}
	return bb;
}
vec4 bricks_hb(vec2 uv, vec2 count, float repeat, float offset) {
	float pc = count.x+count.y;
	float c = pc*repeat;
	vec2 corner = floor(uv*c);
	float cdiff = mod(corner.x-corner.y, pc);
	if (cdiff < count.x) {
		return vec4((corner-vec2(cdiff, 0.0))/c, (corner-vec2(cdiff, 0.0)+vec2(count.x, 1.0))/c);
	} else {
		return vec4((corner-vec2(0.0, pc-cdiff-1.0))/c, (corner-vec2(0.0, pc-cdiff-1.0)+vec2(1.0, count.y))/c);
	}
}
vec4 bricks_bw(vec2 uv, vec2 count, float repeat, float offset) {
	vec2 c = 2.0*count*repeat;
	float mc = max(c.x, c.y);
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
	return vec4(corner/c, (corner+size)/c);
}
vec4 bricks_sb(vec2 uv, vec2 count, float repeat, float offset) {
	vec2 c = (count+vec2(1.0)) * repeat;
	float mc = max(c.x, c.y);
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
	return vec4(corner/c, (corner+size)/c);
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
vec3 blend_additive(vec2 uv, vec3 c1, vec3 c2, float oppacity) {
	return c2 + c1 * oppacity;
}
vec3 blend_addsub(vec2 uv, vec3 c1, vec3 c2, float oppacity) {
	return c2 + (c1 - .5) * 2.0 * oppacity;
}
float blend_linear_light_f(float c1, float c2) {
	return (c1 + 2.0 * c2) - 1.0;
}
vec3 blend_linear_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
return opacity*vec3(blend_linear_light_f(c1.x, c2.x), blend_linear_light_f(c1.y, c2.y), blend_linear_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_vivid_light_f(float c1, float c2) {
	return (c1 < 0.5) ? 1.0 - (1.0 - c2) / (2.0 * c1) : c2 / (2.0 * (1.0 - c1));
}
vec3 blend_vivid_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_vivid_light_f(c1.x, c2.x), blend_vivid_light_f(c1.y, c2.y), blend_vivid_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_pin_light_f( float c1, float c2) {
	return (2.0 * c1 - 1.0 > c2) ? 2.0 * c1 - 1.0 : ((c1 < 0.5 * c2) ? 2.0 * c1 : c2);
}
vec3 blend_pin_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_pin_light_f(c1.x, c2.x), blend_pin_light_f(c1.y, c2.y), blend_pin_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_hard_mix_f(float c1, float c2) {
	return floor(c1 + c2);
}
vec3 blend_hard_mix(vec2 uv, vec3 c1, vec3 c2, float opacity) {
		return opacity*vec3(blend_hard_mix_f(c1.x, c2.x), blend_hard_mix_f(c1.y, c2.y), blend_hard_mix_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_exclusion_f(float c1, float c2) {
	return c1 + c2 - 2.0 * c1 * c2;
}
vec3 blend_exclusion(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_exclusion_f(c1.x, c2.x), blend_exclusion_f(c1.y, c2.y), blend_exclusion_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float pingpong(float a, float b)
{
  return (b != 0.0) ? abs(fract((a - b) / (b * 2.0)) * b * 2.0 - b) : 0.0;
}
vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
float anisotropic(vec2 uv, vec2 size, float seed, float smoothness, float interpolation) {
	vec2 seed2 = rand2(vec2(seed, 1.0-seed));
	
	vec2 xy = floor(uv*size);
	vec2 offset = vec2(rand(seed2 + xy.y), 0.0);
	vec2 xy_offset = floor(uv * size + offset );
	float f0 = rand(seed2+mod(xy_offset, size));
	float f1 = rand(seed2+mod(xy_offset+vec2(1.0, 0.0), size));
	float mixer = clamp( (fract(uv.x*size.x+offset.x) -.5) / smoothness + 0.5, 0.0, 1.0 );
	float smooth_mix = smoothstep(0.0, 1.0, mixer);
	float linear = mix(f0, f1, mixer);
	float smoothed = mix(f0, f1, smooth_mix);
	
	return mix(linear, smoothed, interpolation);
}
vec2 get_from_tileset(float count, float seed, vec2 uv) {
	return clamp((uv+floor(rand2(vec2(seed))*count))/count, vec2(0.0), vec2(1.0));
}
vec2 custom_uv_transform(vec2 uv, vec2 cst_scale, float rnd_rotate, float rnd_scale, vec2 seed) {
	seed = rand2(seed);
	uv -= vec2(0.5);
	float angle = (seed.x * 2.0 - 1.0) * rnd_rotate;
	float ca = cos(angle);
	float sa = sin(angle);
	uv = vec2(ca*uv.x+sa*uv.y, -sa*uv.x+ca*uv.y);
	uv *= (seed.y-0.5)*2.0*rnd_scale+1.0;
	uv /= cst_scale;
	uv += vec2(0.5);
	return uv;
}
uniform sampler2D texture_4;
const float texture_4_size = 2048.0;
uniform sampler2D texture_5;
const float texture_5_size = 256.0;
vec2 scale(vec2 uv, vec2 center, vec2 scale) {
	uv -= center;
	uv /= scale;
	uv += center;
	return uv;
}
const float p_o10429_hue = -0.600000000;
const float p_o10429_saturation = 1.000000000;
const float p_o10429_value = 1.000000000;
const float p_o9637_amount1 = 1.000000000;
const float p_o9652_hue = 0.600000000;
const float p_o9652_saturation = 1.713783000;
const float p_o9652_value = 1.000000000;
const float p_o9638_amount1 = 0.000000000;
const float seed_o9633 = 0.000000000;
const float p_o9633_sx = 1.000000000;
const float p_o9633_sy = 1.000000000;
const float p_o9633_rotate = 0.000000000;
const float p_o9633_scale = 0.000000000;
const float seed_o9679 = 0.000000000;
const float p_o9679_sx = 1.000000000;
const float p_o9679_sy = 1.000000000;
const float p_o9679_rotate = 0.000000000;
const float p_o9679_scale = 0.000000000;
const float p_o10121_default_in1 = 0.000000000;
const float p_o10121_default_in2 = 0.000000000;
const float p_o10120_default_in1 = 0.000000000;
const float p_o10120_default_in2 = 0.000000000;
const float p_o9701_amount1 = 1.000000000;
const float p_o9701_amount2 = 1.000000000;
const float p_o9701_amount3 = 1.000000000;
const float p_o9663_translate_x = 0.000000000;
const float p_o9663_translate_y = 0.000800000;
const float p_o9663_rotate = 0.000000000;
const float p_o9663_scale_x = 1.000000000;
const float p_o9663_scale_y = 1.000000000;
const float p_o10099_amount = -0.650000000;
const float p_o10099_center = -1.600000000;
const float p_o9590_all = 1.000000000;
const float p_o9590_hue = 1.680000000;
const float p_o9590_value = 1.000000000;
const float p_o9590_saturation = 1.000000000;
const float p_o10096_hue = 0.247700000;
const float p_o10096_saturation = 1.703550000;
const float p_o10096_value = 1.959050000;
const float p_o9557_amount1 = 1.000000000;
const float p_o9557_amount2 = 0.860000000;
const float p_o9583_amount1 = 1.000000000;
const float p_o9474_translate_y = 0.000000000;
const float p_o9474_rotate = 0.000000000;
const float p_o9474_scale_x = 1.000000000;
const float p_o9474_scale_y = 1.000000000;
const float p_o9487_min = 0.750000000;
const float p_o9487_max = 1.500000000;
const float p_o9487_step = 0.000000000;
const float p_o9585_x = 1.000000000;
const float p_o9585_y = 8.000000000;
const float p_o9585_c = 32.000000000;
const float p_o9585_d = 0.000000000;
const float p_o9582_translate_y = 0.000000000;
const float p_o9582_rotate = 0.000000000;
const float p_o9582_scale_x = 4.000000000;
const float p_o9582_scale_y = 4.000000000;
const float p_o9584_x = 16.000000000;
const float p_o9584_y = 8.000000000;
const float p_o9584_c = 15.000000000;
const float p_o9584_d = -0.340000000;
const float p_o9596_translate_x = 0.000000000;
const float p_o9596_translate_y = 0.000000000;
const float p_o9596_rotate = 0.000000000;
const float p_o9596_scale_x = 8.000000000;
const float p_o9596_scale_y = 1.000000000;
const float p_o9597_value = 0.700000000;
const float p_o9597_width = 0.000000000;
const float seed_o9589 = 0.000000000;
const float seed_o9559 = 0.000000000;
const float p_o9559_edgecolor = 1.000000000;
const float p_o9558_repeat = 4.000000000;
const float p_o9558_rows = 8.000000000;
const float p_o9558_columns = 4.000000000;
const float p_o9558_row_offset = 0.500000000;
const float p_o9558_mortar = 0.050000000;
const float p_o9558_bevel = 0.050000000;
const float p_o9558_round = 0.000000000;
const float p_o9558_corner = 0.300000000;
vec3 o10092_input_in(vec2 uv, float _seed_variation_) {
vec2 o9585_0_uv = floor(((uv)*vec2(p_o9585_x, p_o9585_y)))+vec2(0.5);
vec3 o9585_0_dither = fract(vec3(dot(vec2(171.0, 231.0), o9585_0_uv))/vec3(103.0, 71.0, 97.0));
vec4 o9481_0 = textureLod(texture_2, o9585_0_uv/vec2(p_o9585_x, p_o9585_y), 0.0);
vec3 o9585_0_1_rgb = floor(((o9481_0).rgb)*p_o9585_c+p_o9585_d*(o9585_0_dither-vec3(0.5)))/p_o9585_c;
float o9487_0_x = (dot(o9585_0_1_rgb, vec3(1.0))/3.0)*(p_o9487_max-p_o9487_min);float o9487_0_1_f = p_o9487_min+o9487_0_x-mod(o9487_0_x, max(p_o9487_step, 0.00000001));
vec4 o9479_0 = textureLod(texture_1, fract(transform2((uv), vec2((elapsed_time / 3.0)*(2.0*o9487_0_1_f-1.0), p_o9474_translate_y*(2.0*1.0-1.0)), p_o9474_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9474_scale_x*(2.0*1.0-1.0), p_o9474_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o9474_0_1_rgba = o9479_0;
vec2 o9584_0_uv = floor(((fract(transform2((uv), vec2((elapsed_time / 3.0)*(2.0*o9487_0_1_f-1.0), p_o9582_translate_y*(2.0*1.0-1.0)), p_o9582_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9582_scale_x*(2.0*1.0-1.0), p_o9582_scale_y*(2.0*1.0-1.0)))))*vec2(p_o9584_x, p_o9584_y)))+vec2(0.5);
vec3 o9584_0_dither = fract(vec3(dot(vec2(171.0, 231.0), o9584_0_uv))/vec3(103.0, 71.0, 97.0));
vec4 o9558_0_rect = bricks_rb((o9584_0_uv/vec2(p_o9584_x, p_o9584_y)), vec2(p_o9558_columns, p_o9558_rows), p_o9558_repeat, p_o9558_row_offset);
vec4 o9558_0 = brick((o9584_0_uv/vec2(p_o9584_x, p_o9584_y)), o9558_0_rect.xy, o9558_0_rect.zw, p_o9558_mortar*1.0, p_o9558_round*1.0, max(0.001, p_o9558_bevel*1.0), 1.0 / p_o9558_rows);vec4 o9558_1_2_fill = round(vec4(fract(o9558_0_rect.xy), o9558_0_rect.zw - o9558_0_rect.xy)*4096.0)/4096.0;
vec4 o9559_0_bb = o9558_1_2_fill;float o9559_0_1_f = mix(p_o9559_edgecolor, rand(vec2(float((seed_o9559+fract(_seed_variation_))), rand(vec2(rand(o9559_0_bb.xy), rand(o9559_0_bb.zw))))), step(0.0000001, dot(o9559_0_bb.zw, vec2(1.0))));
vec3 o9589_0_rand = vec3(o9559_0_1_f);vec3 o9589_0_1_rgb = rand3( vec2( float((seed_o9589+fract(_seed_variation_))) + o9589_0_rand.x, rand( o9589_0_rand.yz ) ) );
vec3 o9597_0_false = clamp((vec4(o9589_0_1_rgb, 1.0).rgb-vec3(p_o9597_value))/max(0.0001, p_o9597_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o9597_0_true = vec3(1.0)-o9597_0_false;vec4 o9597_0_1_rgba = vec4(o9597_0_false, vec4(o9589_0_1_rgb, 1.0).a);
vec4 o9580_0 = textureLod(texture_3, fract(transform2((o9584_0_uv/vec2(p_o9584_x, p_o9584_y)), vec2(p_o9596_translate_x*(2.0*1.0-1.0), p_o9596_translate_y*(2.0*1.0-1.0)), p_o9596_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9596_scale_x*(2.0*(dot((o9597_0_1_rgba).rgb, vec3(1.0))/3.0)-1.0), p_o9596_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o9596_0_1_rgba = o9580_0;
vec3 o9584_0_1_rgb = floor(((o9596_0_1_rgba).rgb)*p_o9584_c+p_o9584_d*(o9584_0_dither-vec3(0.5)))/p_o9584_c;
vec4 o9582_0_1_rgba = vec4(o9584_0_1_rgb, 1.0);
vec4 o9583_0_b = o9474_0_1_rgba;
vec4 o9583_0_l;
float o9583_0_a;
o9583_0_l = o9582_0_1_rgba;
o9583_0_a = p_o9583_amount1*1.0;
o9583_0_b = vec4(blend_screen((uv), o9583_0_l.rgb, o9583_0_b.rgb, o9583_0_a*o9583_0_l.a), min(1.0, o9583_0_b.a+o9583_0_a*o9583_0_l.a));
vec4 o9583_0_2_rgba = o9583_0_b;
vec4 o9556_0_1_rgba = vec4(vec3(1.0)-o9583_0_2_rgba.rgb, o9583_0_2_rgba.a);
return ((o9556_0_1_rgba).rgb);
}
vec3 o10092_fct(vec2 uv, float _seed_variation_) {
	vec2 e = vec2(1.0/512.000000000, 0.0);
	vec3 rv = 5.0*o10092_input_in(uv, _seed_variation_);
	rv -= o10092_input_in(uv+e.xy, _seed_variation_);
	rv -= o10092_input_in(uv-e.xy, _seed_variation_);
	rv -= o10092_input_in(uv+e.yx, _seed_variation_);
	rv -= o10092_input_in(uv-e.yx, _seed_variation_);
	return rv;
}const float p_o9555_min = -1.170000000;
const float p_o9555_max = 10.000000000;
const float p_o9555_step = 0.000000000;
const float p_o9486_default_in1 = 0.540000000;
const float p_o9486_default_in2 = 0.000000000;
const float p_o9485_default_in1 = 0.000000000;
const float p_o9485_default_in2 = 1.000000000;
const float p_o9484_default_in1 = 0.000000000;
const float p_o9484_default_in2 = 4.260000000;
const float p_o9472_repeat = 1.000000000;
const float p_o9472_rows = 8.000000000;
const float p_o9472_columns = 1.000000000;
const float p_o9472_row_offset = 0.000000000;
const float p_o9472_mortar = 0.050000000;
const float p_o9472_bevel = 0.050000000;
const float p_o9472_round = 0.000000000;
const float p_o9472_corner = 0.300000000;
const float p_o10091_brightness = 0.380000000;
const float p_o10091_contrast = 2.190000000;
const float p_o10072_gradient_0_pos = 0.070540000;
const vec4 p_o10072_gradient_0_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o10072_gradient_1_pos = 0.259933000;
const vec4 p_o10072_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o10072_gradient_2_pos = 0.327273000;
const vec4 p_o10072_gradient_2_col = vec4(0.000000000, 0.671387017, 0.781250000, 1.000000000);
const float p_o10072_gradient_3_pos = 0.417761000;
const vec4 p_o10072_gradient_3_col = vec4(0.254099011, 0.769531012, 0.210418999, 1.000000000);
const float p_o10072_gradient_4_pos = 0.708165000;
const vec4 p_o10072_gradient_4_col = vec4(0.044307001, 0.420812994, 0.025781000, 1.000000000);
const float p_o10072_gradient_5_pos = 0.745455000;
const vec4 p_o10072_gradient_5_col = vec4(0.046813998, 0.460938007, 0.000000000, 1.000000000);
const float p_o10072_gradient_6_pos = 0.827872000;
const vec4 p_o10072_gradient_6_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
const float p_o10072_gradient_7_pos = 1.000000000;
const vec4 p_o10072_gradient_7_col = vec4(1.000000000, 0.164061993, 0.000000000, 1.000000000);
vec4 o10072_gradient_gradient_fct(float x) {
  if (x < p_o10072_gradient_0_pos) {
    return p_o10072_gradient_0_col;
  } else if (x < p_o10072_gradient_1_pos) {
    return mix(p_o10072_gradient_0_col, p_o10072_gradient_1_col, ((x-p_o10072_gradient_0_pos)/(p_o10072_gradient_1_pos-p_o10072_gradient_0_pos)));
  } else if (x < p_o10072_gradient_2_pos) {
    return mix(p_o10072_gradient_1_col, p_o10072_gradient_2_col, ((x-p_o10072_gradient_1_pos)/(p_o10072_gradient_2_pos-p_o10072_gradient_1_pos)));
  } else if (x < p_o10072_gradient_3_pos) {
    return mix(p_o10072_gradient_2_col, p_o10072_gradient_3_col, ((x-p_o10072_gradient_2_pos)/(p_o10072_gradient_3_pos-p_o10072_gradient_2_pos)));
  } else if (x < p_o10072_gradient_4_pos) {
    return mix(p_o10072_gradient_3_col, p_o10072_gradient_4_col, ((x-p_o10072_gradient_3_pos)/(p_o10072_gradient_4_pos-p_o10072_gradient_3_pos)));
  } else if (x < p_o10072_gradient_5_pos) {
    return mix(p_o10072_gradient_4_col, p_o10072_gradient_5_col, ((x-p_o10072_gradient_4_pos)/(p_o10072_gradient_5_pos-p_o10072_gradient_4_pos)));
  } else if (x < p_o10072_gradient_6_pos) {
    return mix(p_o10072_gradient_5_col, p_o10072_gradient_6_col, ((x-p_o10072_gradient_5_pos)/(p_o10072_gradient_6_pos-p_o10072_gradient_5_pos)));
  } else if (x < p_o10072_gradient_7_pos) {
    return mix(p_o10072_gradient_6_col, p_o10072_gradient_7_col, ((x-p_o10072_gradient_6_pos)/(p_o10072_gradient_7_pos-p_o10072_gradient_6_pos)));
  }
  return p_o10072_gradient_7_col;
}
const float p_o9587_amount1 = 0.210000000;
const float p_o9598_default_in1 = 0.000000000;
const float p_o9598_default_in2 = 1.000000000;
const float p_o9599_default_in1 = 0.000000000;
const float p_o9599_default_in2 = 27.830000000;
const float p_o9588_default_in2 = 5.000000000;
const float p_o9702_x = 512.000000000;
const float p_o9702_y = 512.000000000;
const float p_o9702_c = 8.000000000;
const float p_o9702_d = 0.000000000;
const float p_o10098_translate_x = 0.000000000;
const float p_o10098_translate_y = 0.000000000;
const float p_o10098_rotate = 60.000000000;
const float p_o10098_scale_x = 1.000000000;
const float p_o10098_scale_y = 1.000000000;
const float seed_o9672 = 0.000000000;
const float p_o9672_scale_x = 1.000000000;
const float p_o9672_scale_y = 256.000000000;
const float p_o9672_smoothness = 0.050000000;
const float p_o9672_interpolation = 0.100000000;
const float p_o10101_amount1 = 1.000000000;
const float p_o9673_value = 0.950000000;
const float p_o9673_width = 0.000000000;
const float p_o10105_value = 0.210000000;
const float p_o10105_width = 0.300000000;
const float p_o10105_contrast = 1.000000000;
const float seed_o10112 = 0.174753398;
const float p_o10112_edgecolor = 1.000000000;
const float p_o10111_repeat = 1.000000000;
const float p_o10111_rows = 4.000000000;
const float p_o10111_columns = 4.000000000;
const float p_o10111_row_offset = 0.000000000;
const float p_o10111_mortar = 0.000000000;
const float p_o10111_bevel = 0.000000000;
const float p_o10111_round = 0.000000000;
const float p_o10111_corner = 0.300000000;
const float p_o9716_default_in1 = 0.000000000;
const float p_o9716_default_in2 = 0.000000000;
const float p_o9715_value = 0.430000000;
const float p_o9715_width = 0.090000000;
const float p_o9715_contrast = 1.000000000;
const float p_o9717_value = 0.430000000;
const float p_o9717_width = 0.040000000;
const float p_o9717_contrast = 1.000000000;
const float p_o10103_default_in1 = 0.000000000;
const float p_o10103_default_in2 = 0.000000000;
const float p_o9710_default_in1 = 0.000000000;
const float p_o9710_default_in2 = 0.000000000;
const float p_o9706_default_in1 = 0.000000000;
const float p_o9706_default_in2 = 0.000000000;
const float p_o9704_default_in1 = 0.000000000;
const float p_o9704_default_in2 = 15.850000000;
const float p_o10106_default_in1 = 0.000000000;
const float p_o10106_default_in2 = 0.000000000;
const float p_o9713_default_in1 = 0.000000000;
const float p_o9713_default_in2 = 0.000000000;
const float seed_o9714 = 0.000000000;
const float p_o9714_scale_x = 1.000000000;
const float p_o9714_scale_y = 1024.000000000;
const float p_o9714_smoothness = 0.000000000;
const float p_o9714_interpolation = 0.100000000;
const float p_o9705_default_in1 = 0.000000000;
const float p_o9705_default_in2 = -0.670000000;
const float p_o9709_default_in1 = 0.000000000;
const float p_o9709_default_in2 = 39.070000000;
const float p_o9707_default_in1 = 0.000000000;
const float p_o9707_default_in2 = 4.470000000;
const float p_o9708_default_in1 = 0.000000000;
const float p_o9708_default_in2 = 14.690000000;
const float p_o10110_value = 0.470000000;
const float p_o10110_width = 0.010000000;
const float p_o10110_contrast = 0.230000000;
const float p_o10116_amount = 1.000000000;
const float p_o10119_color = 0.000000000;
const float p_o10118_color = 1.000000000;
const float p_o10117_default_in1 = 0.000000000;
const float p_o10117_default_in2 = 0.000000000;
const float p_o10115_amount = 1.000000000;
const float p_o10187_default_in1 = 0.000000000;
const float p_o10187_default_in2 = 0.000000000;
const float p_o10186_default_in1 = 0.000000000;
const float p_o10186_default_in2 = 0.000000000;
const float p_o10182_amount = 1.000000000;
const float p_o10185_color = 0.000000000;
const float p_o10184_color = 1.000000000;
const float p_o10183_default_in1 = 0.000000000;
const float p_o10183_default_in2 = 0.000000000;
const float p_o10181_amount = 1.000000000;
const float p_o10253_default_in1 = 0.000000000;
const float p_o10253_default_in2 = 0.000000000;
const float p_o10252_default_in1 = 0.000000000;
const float p_o10252_default_in2 = 0.000000000;
const float p_o10248_amount = 1.000000000;
const float p_o10251_color = 0.000000000;
const float p_o10250_color = 1.000000000;
const float p_o10249_default_in1 = 0.000000000;
const float p_o10249_default_in2 = 0.000000000;
const float p_o10247_amount = 1.000000000;
vec4 o9679_input_in(vec2 uv, float _seed_variation_) {
vec3 o10092_0_1_rgb = o10092_fct(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), _seed_variation_);
vec2 o9585_0_uv = floor((((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0))*vec2(p_o9585_x, p_o9585_y)))+vec2(0.5);
vec3 o9585_0_dither = fract(vec3(dot(vec2(171.0, 231.0), o9585_0_uv))/vec3(103.0, 71.0, 97.0));
vec4 o9481_0 = textureLod(texture_2, o9585_0_uv/vec2(p_o9585_x, p_o9585_y), 0.0);
vec3 o9585_0_1_rgb = floor(((o9481_0).rgb)*p_o9585_c+p_o9585_d*(o9585_0_dither-vec3(0.5)))/p_o9585_c;
float o9487_0_x = (dot(o9585_0_1_rgb, vec3(1.0))/3.0)*(p_o9487_max-p_o9487_min);float o9487_0_1_f = p_o9487_min+o9487_0_x-mod(o9487_0_x, max(p_o9487_step, 0.00000001));
vec4 o9479_0 = textureLod(texture_1, fract(transform2(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), vec2((elapsed_time / 3.0)*(2.0*o9487_0_1_f-1.0), p_o9474_translate_y*(2.0*1.0-1.0)), p_o9474_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9474_scale_x*(2.0*1.0-1.0), p_o9474_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o9474_0_1_rgba = o9479_0;
vec2 o9584_0_uv = floor(((fract(transform2(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), vec2((elapsed_time / 3.0)*(2.0*o9487_0_1_f-1.0), p_o9582_translate_y*(2.0*1.0-1.0)), p_o9582_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9582_scale_x*(2.0*1.0-1.0), p_o9582_scale_y*(2.0*1.0-1.0)))))*vec2(p_o9584_x, p_o9584_y)))+vec2(0.5);
vec3 o9584_0_dither = fract(vec3(dot(vec2(171.0, 231.0), o9584_0_uv))/vec3(103.0, 71.0, 97.0));
vec4 o9558_0_rect = bricks_rb((o9584_0_uv/vec2(p_o9584_x, p_o9584_y)), vec2(p_o9558_columns, p_o9558_rows), p_o9558_repeat, p_o9558_row_offset);
vec4 o9558_0 = brick((o9584_0_uv/vec2(p_o9584_x, p_o9584_y)), o9558_0_rect.xy, o9558_0_rect.zw, p_o9558_mortar*1.0, p_o9558_round*1.0, max(0.001, p_o9558_bevel*1.0), 1.0 / p_o9558_rows);vec4 o9558_1_2_fill = round(vec4(fract(o9558_0_rect.xy), o9558_0_rect.zw - o9558_0_rect.xy)*4096.0)/4096.0;
vec4 o9559_0_bb = o9558_1_2_fill;float o9559_0_1_f = mix(p_o9559_edgecolor, rand(vec2(float((seed_o9559+fract(_seed_variation_))), rand(vec2(rand(o9559_0_bb.xy), rand(o9559_0_bb.zw))))), step(0.0000001, dot(o9559_0_bb.zw, vec2(1.0))));
vec3 o9589_0_rand = vec3(o9559_0_1_f);vec3 o9589_0_1_rgb = rand3( vec2( float((seed_o9589+fract(_seed_variation_))) + o9589_0_rand.x, rand( o9589_0_rand.yz ) ) );
vec3 o9597_0_false = clamp((vec4(o9589_0_1_rgb, 1.0).rgb-vec3(p_o9597_value))/max(0.0001, p_o9597_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o9597_0_true = vec3(1.0)-o9597_0_false;vec4 o9597_0_1_rgba = vec4(o9597_0_false, vec4(o9589_0_1_rgb, 1.0).a);
vec4 o9580_0 = textureLod(texture_3, fract(transform2((o9584_0_uv/vec2(p_o9584_x, p_o9584_y)), vec2(p_o9596_translate_x*(2.0*1.0-1.0), p_o9596_translate_y*(2.0*1.0-1.0)), p_o9596_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9596_scale_x*(2.0*(dot((o9597_0_1_rgba).rgb, vec3(1.0))/3.0)-1.0), p_o9596_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o9596_0_1_rgba = o9580_0;
vec3 o9584_0_1_rgb = floor(((o9596_0_1_rgba).rgb)*p_o9584_c+p_o9584_d*(o9584_0_dither-vec3(0.5)))/p_o9584_c;
vec4 o9582_0_1_rgba = vec4(o9584_0_1_rgb, 1.0);
vec4 o9583_0_b = o9474_0_1_rgba;
vec4 o9583_0_l;
float o9583_0_a;
o9583_0_l = o9582_0_1_rgba;
o9583_0_a = p_o9583_amount1*1.0;
o9583_0_b = vec4(blend_screen(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), o9583_0_l.rgb, o9583_0_b.rgb, o9583_0_a*o9583_0_l.a), min(1.0, o9583_0_b.a+o9583_0_a*o9583_0_l.a));
vec4 o9583_0_2_rgba = o9583_0_b;
vec4 o9472_0_rect = bricks_rb(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), vec2(p_o9472_columns, p_o9472_rows), p_o9472_repeat, p_o9472_row_offset);
vec4 o9472_0 = brick(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), o9472_0_rect.xy, o9472_0_rect.zw, p_o9472_mortar*1.0, p_o9472_round*1.0, max(0.001, p_o9472_bevel*1.0), 1.0 / p_o9472_rows);vec4 o9472_1_2_fill = round(vec4(fract(o9472_0_rect.xy), o9472_0_rect.zw - o9472_0_rect.xy)*4096.0)/4096.0;
vec2 o9483_0_c = fract(o9472_1_2_fill.xy+0.5*o9472_1_2_fill.zw);float o9483_0_1_f = o9483_0_c.y;
float o9484_0_clamp_false = o9483_0_1_f*p_o9484_default_in2;
float o9484_0_clamp_true = clamp(o9484_0_clamp_false, 0.0, 1.0);
float o9484_0_2_f = o9484_0_clamp_false;
float o9485_0_clamp_false = mod(o9484_0_2_f, p_o9485_default_in2);
float o9485_0_clamp_true = clamp(o9485_0_clamp_false, 0.0, 1.0);
float o9485_0_2_f = o9485_0_clamp_true;
float o9486_0_clamp_false = (1.0-step(o9485_0_2_f,p_o9486_default_in1));
float o9486_0_clamp_true = clamp(o9486_0_clamp_false, 0.0, 1.0);
float o9486_0_2_f = o9486_0_clamp_false;
float o9555_0_x = o9486_0_2_f*(p_o9555_max-p_o9555_min);float o9555_0_1_f = p_o9555_min+o9555_0_x-mod(o9555_0_x, max(p_o9555_step, 0.00000001));
vec4 o10072_0_1_rgba = o10072_gradient_gradient_fct(o9485_0_2_f);
vec4 o10091_0_1_rgba = vec4(clamp(o10072_0_1_rgba.rgb*p_o10091_contrast+vec3(p_o10091_brightness)+0.5-p_o10091_contrast*0.5, vec3(0.0), vec3(1.0)), o10072_0_1_rgba.a);
vec4 o9557_0_b = vec4(o10092_0_1_rgb, 1.0);
vec4 o9557_0_l;
float o9557_0_a;
o9557_0_l = o9583_0_2_rgba;
o9557_0_a = p_o9557_amount1*o9555_0_1_f;
o9557_0_b = vec4(blend_normal(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), o9557_0_l.rgb, o9557_0_b.rgb, o9557_0_a*o9557_0_l.a), min(1.0, o9557_0_b.a+o9557_0_a*o9557_0_l.a));
o9557_0_l = o10091_0_1_rgba;
o9557_0_a = p_o9557_amount2*1.0;
o9557_0_b = vec4(blend_burn(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), o9557_0_l.rgb, o9557_0_b.rgb, o9557_0_a*o9557_0_l.a), min(1.0, o9557_0_b.a+o9557_0_a*o9557_0_l.a));
vec4 o9557_0_2_rgba = o9557_0_b;
vec4 o10096_0_rbga = o9557_0_2_rgba;
vec3 o10096_0_hsv = rgb_to_hsv(o10096_0_rbga.rgb);
o10096_0_hsv.x += p_o10096_hue;
o10096_0_hsv.y = clamp(o10096_0_hsv.y*p_o10096_saturation, 0.0, 1.0);
o10096_0_hsv.z = clamp(o10096_0_hsv.z*p_o10096_value, 0.0, 1.0);
	vec4 o10096_0_1_rgba = vec4(hsv_to_rgb(o10096_0_hsv), o10096_0_rbga.a);
float o9599_0_clamp_false = (dot(o9585_0_1_rgb, vec3(1.0))/3.0)*p_o9599_default_in2;
float o9599_0_clamp_true = clamp(o9599_0_clamp_false, 0.0, 1.0);
float o9599_0_2_f = o9599_0_clamp_false;
float o9598_0_clamp_false = mod(o9599_0_2_f, p_o9598_default_in2);
float o9598_0_clamp_true = clamp(o9598_0_clamp_false, 0.0, 1.0);
float o9598_0_2_f = o9598_0_clamp_false;
float o9588_0_clamp_false = sin((elapsed_time)*p_o9588_default_in2);
float o9588_0_clamp_true = clamp(o9588_0_clamp_false, 0.0, 1.0);
float o9588_0_2_f = o9588_0_clamp_true;
vec4 o9587_0_b = vec4(vec3(o9598_0_2_f), 1.0);
vec4 o9587_0_l;
float o9587_0_a;
o9587_0_l = o9582_0_1_rgba;
o9587_0_a = p_o9587_amount1*o9588_0_2_f;
o9587_0_b = vec4(blend_normal(((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0)))))+p_o10099_amount*((transform2_clamp(transform2((uv), vec2(p_o9663_translate_x*(2.0*1.0-1.0), p_o9663_translate_y*(2.0*1.0-1.0)), p_o9663_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o9663_scale_x*(2.0*1.0-1.0), p_o9663_scale_y*(2.0*1.0-1.0))))).yx-vec2(p_o10099_center))*vec2(1.0, 0.0)), o9587_0_l.rgb, o9587_0_b.rgb, o9587_0_a*o9587_0_l.a), min(1.0, o9587_0_b.a+o9587_0_a*o9587_0_l.a));
vec4 o9587_0_1_rgba = o9587_0_b;
vec4 o9590_0_rbga = o10096_0_1_rgba;
vec3 o9590_0_hsv = rgb_to_hsv(o9590_0_rbga.rgb);
o9590_0_hsv.x = fract(o9590_0_hsv.x+p_o9590_hue*p_o9590_all*((dot((o9587_0_1_rgba).rgb, vec3(1.0))/3.0)-0.5));
o9590_0_hsv.y = clamp(o9590_0_hsv.y+p_o9590_saturation*p_o9590_all*(0.5-0.5), 0.0, 1.0);
o9590_0_hsv.z = clamp(o9590_0_hsv.z+p_o9590_value*p_o9590_all*(0.5-0.5), 0.0, 1.0);
	vec4 o9590_0_2_rgba = vec4(hsv_to_rgb(o9590_0_hsv), o9590_0_rbga.a);
vec4 o10099_0_1_rgba = o9590_0_2_rgba;
vec4 o9663_0_1_rgba = o10099_0_1_rgba;
vec2 o9702_0_uv = floor(((uv)*vec2(p_o9702_x, p_o9702_y)))+vec2(0.5);
vec3 o9702_0_dither = fract(vec3(dot(vec2(171.0, 231.0), o9702_0_uv))/vec3(103.0, 71.0, 97.0));
float o9672_0_1_f = anisotropic((fract(transform2((o9702_0_uv/vec2(p_o9702_x, p_o9702_y)), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), vec2(p_o9672_scale_x, p_o9672_scale_y), (seed_o9672+fract(_seed_variation_)), p_o9672_smoothness, p_o9672_interpolation);
vec4 o10098_0_1_rgba = vec4(vec3(o9672_0_1_f), 1.0);
vec3 o9702_0_1_rgb = floor(((o10098_0_1_rgba).rgb)*p_o9702_c+p_o9702_d*(o9702_0_dither-vec3(0.5)))/p_o9702_c;
float o9672_0_3_f = anisotropic((fract(transform2((uv), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), vec2(p_o9672_scale_x, p_o9672_scale_y), (seed_o9672+fract(_seed_variation_)), p_o9672_smoothness, p_o9672_interpolation);
vec4 o10098_0_4_rgba = vec4(vec3(o9672_0_3_f), 1.0);
vec3 o9673_0_false = clamp((o10098_0_4_rgba.rgb-vec3(p_o9673_value))/max(0.0001, p_o9673_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o9673_0_true = vec3(1.0)-o9673_0_false;vec4 o9673_0_1_rgba = vec4(o9673_0_false, o10098_0_4_rgba.a);
vec4 o10111_0_rect = bricks_rb((fract(transform2((uv), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), vec2(p_o10111_columns, p_o10111_rows), p_o10111_repeat, p_o10111_row_offset);
vec4 o10111_0 = brick((fract(transform2((uv), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), o10111_0_rect.xy, o10111_0_rect.zw, p_o10111_mortar*1.0, p_o10111_round*1.0, max(0.001, p_o10111_bevel*1.0), 1.0 / p_o10111_rows);vec4 o10111_1_2_fill = round(vec4(fract(o10111_0_rect.xy), o10111_0_rect.zw - o10111_0_rect.xy)*4096.0)/4096.0;
vec4 o10112_0_bb = o10111_1_2_fill;float o10112_0_1_f = mix(p_o10112_edgecolor, rand(vec2(float((seed_o10112+fract(_seed_variation_))), rand(vec2(rand(o10112_0_bb.xy), rand(o10112_0_bb.zw))))), step(0.0000001, dot(o10112_0_bb.zw, vec2(1.0))));
vec4 o10098_2_6_rgba = vec4(vec3(o10112_0_1_f), 1.0);
float o10105_0_step = clamp(((dot((o10098_2_6_rgba).rgb, vec3(1.0))/3.0) - (p_o10105_value))/max(0.0001, p_o10105_width)+0.5, 0.0, 1.0);
float o10105_0_false = clamp((min(o10105_0_step, 1.0-o10105_0_step) * 2.0) / (1.0 - p_o10105_contrast), 0.0, 1.0);
float o10105_0_true = 1.0-o10105_0_false;float o10105_0_1_f = o10105_0_false;
vec4 o10101_0_b = o9673_0_1_rgba;
vec4 o10101_0_l;
float o10101_0_a;
o10101_0_l = o10098_0_4_rgba;
o10101_0_a = p_o10101_amount1*o10105_0_1_f;
o10101_0_b = vec4(blend_overlay((uv), o10101_0_l.rgb, o10101_0_b.rgb, o10101_0_a*o10101_0_l.a), min(1.0, o10101_0_b.a+o10101_0_a*o10101_0_l.a));
vec4 o10101_0_1_rgba = o10101_0_b;
float o9715_0_step = clamp(((dot((o10098_0_4_rgba).rgb, vec3(1.0))/3.0) - (p_o9715_value))/max(0.0001, p_o9715_width)+0.5, 0.0, 1.0);
float o9715_0_false = clamp((min(o9715_0_step, 1.0-o9715_0_step) * 2.0) / (1.0 - p_o9715_contrast), 0.0, 1.0);
float o9715_0_true = 1.0-o9715_0_false;float o9715_0_1_f = o9715_0_false;
float o9703_0_1_f = (elapsed_time / 80.0);
float o9714_0_1_f = anisotropic((fract(transform2((uv), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), vec2(p_o9714_scale_x, p_o9714_scale_y), (seed_o9714+fract(_seed_variation_)), p_o9714_smoothness, p_o9714_interpolation);
vec4 o10098_1_7_rgba = vec4(vec3(o9714_0_1_f), 1.0);
float o9713_0_clamp_false = o9703_0_1_f+(dot((o10098_1_7_rgba).rgb, vec3(1.0))/3.0);
float o9713_0_clamp_true = clamp(o9713_0_clamp_false, 0.0, 1.0);
float o9713_0_1_f = o9713_0_clamp_false;
float o10106_0_clamp_false = o9713_0_1_f*o10105_0_1_f;
float o10106_0_clamp_true = clamp(o10106_0_clamp_false, 0.0, 1.0);
float o10106_0_1_f = o10106_0_clamp_false;
float o9704_0_clamp_false = sin(o10106_0_1_f*p_o9704_default_in2);
float o9704_0_clamp_true = clamp(o9704_0_clamp_false, 0.0, 1.0);
float o9704_0_2_f = o9704_0_clamp_false;
float o9709_0_clamp_false = o10106_0_1_f+p_o9709_default_in2;
float o9709_0_clamp_true = clamp(o9709_0_clamp_false, 0.0, 1.0);
float o9709_0_2_f = o9709_0_clamp_false;
float o9705_0_clamp_false = sin(o9709_0_2_f*p_o9705_default_in2);
float o9705_0_clamp_true = clamp(o9705_0_clamp_false, 0.0, 1.0);
float o9705_0_2_f = o9705_0_clamp_false;
float o9706_0_clamp_false = o9704_0_2_f/o9705_0_2_f;
float o9706_0_clamp_true = clamp(o9706_0_clamp_false, 0.0, 1.0);
float o9706_0_1_f = o9706_0_clamp_true;
float o9708_0_clamp_false = o10106_0_1_f+p_o9708_default_in2;
float o9708_0_clamp_true = clamp(o9708_0_clamp_false, 0.0, 1.0);
float o9708_0_2_f = o9708_0_clamp_false;
float o9707_0_clamp_false = sin(o9708_0_2_f*p_o9707_default_in2);
float o9707_0_clamp_true = clamp(o9707_0_clamp_false, 0.0, 1.0);
float o9707_0_2_f = o9707_0_clamp_false;
float o9710_0_clamp_false = o9706_0_1_f+o9707_0_2_f;
float o9710_0_clamp_true = clamp(o9710_0_clamp_false, 0.0, 1.0);
float o9710_0_1_f = o9710_0_clamp_true;
float o10103_0_clamp_false = o9710_0_1_f*o10105_0_1_f;
float o10103_0_clamp_true = clamp(o10103_0_clamp_false, 0.0, 1.0);
float o10103_0_1_f = o10103_0_clamp_true;
float o9717_0_step = clamp((o10103_0_1_f - (p_o9717_value))/max(0.0001, p_o9717_width)+0.5, 0.0, 1.0);
float o9717_0_false = clamp((min(o9717_0_step, 1.0-o9717_0_step) * 2.0) / (1.0 - p_o9717_contrast), 0.0, 1.0);
float o9717_0_true = 1.0-o9717_0_false;float o9717_0_1_f = o9717_0_false;
float o9716_0_clamp_false = o9715_0_1_f*o9717_0_1_f;
float o9716_0_clamp_true = clamp(o9716_0_clamp_false, 0.0, 1.0);
float o9716_0_1_f = o9716_0_clamp_false;
float o10110_0_step = clamp(((dot((o10098_2_6_rgba).rgb, vec3(1.0))/3.0) - (p_o10110_value))/max(0.0001, p_o10110_width)+0.5, 0.0, 1.0);
float o10110_0_false = clamp((min(o10110_0_step, 1.0-o10110_0_step) * 2.0) / (1.0 - p_o10110_contrast), 0.0, 1.0);
float o10110_0_true = 1.0-o10110_0_false;float o10110_0_1_f = o10110_0_false;
vec4 o9701_0_b = o9663_0_1_rgba;
vec4 o9701_0_l;
float o9701_0_a;
o9701_0_l = vec4(o9702_0_1_rgb, 1.0);
o9701_0_a = p_o9701_amount1*(dot((o10101_0_1_rgba).rgb, vec3(1.0))/3.0);
o9701_0_b = vec4(blend_multiply((uv), o9701_0_l.rgb, o9701_0_b.rgb, o9701_0_a*o9701_0_l.a), min(1.0, o9701_0_b.a+o9701_0_a*o9701_0_l.a));
o9701_0_l = vec4(vec3(o9716_0_1_f), 1.0);
o9701_0_a = p_o9701_amount2*1.0;
o9701_0_b = vec4(blend_exclusion((uv), o9701_0_l.rgb, o9701_0_b.rgb, o9701_0_a*o9701_0_l.a), min(1.0, o9701_0_b.a+o9701_0_a*o9701_0_l.a));
o9701_0_l = vec4(vec3(o10110_0_1_f), 1.0);
o9701_0_a = p_o9701_amount3*1.0;
o9701_0_b = vec4(blend_difference((uv), o9701_0_l.rgb, o9701_0_b.rgb, o9701_0_a*o9701_0_l.a), min(1.0, o9701_0_b.a+o9701_0_a*o9701_0_l.a));
vec4 o9701_0_2_rgba = o9701_0_b;
float o10312_0_1_f = o9701_0_2_rgba.r;
float o10119_0_1_f = p_o10119_color;
float o10118_0_1_f = p_o10118_color;
float o10117_0_clamp_false = (1.0-step(o10118_0_1_f,o10119_0_1_f));
float o10117_0_clamp_true = clamp(o10117_0_clamp_false, 0.0, 1.0);
float o10117_0_1_f = o10117_0_clamp_false;
vec4 o10116_0_s1 = vec4(vec3(o10119_0_1_f), 1.0);
vec4 o10116_0_s2 = vec4(vec3(o10118_0_1_f), 1.0);
float o10116_0_a = p_o10116_amount*o10117_0_1_f;
vec4 o10116_0_1_rgba = vec4(blend_normal((uv), o10116_0_s1.rgb, o10116_0_s2.rgb, o10116_0_a*o10116_0_s1.a), min(1.0, o10116_0_s2.a+o10116_0_a*o10116_0_s1.a));
float o10120_0_clamp_false = max(o10312_0_1_f,(dot((o10116_0_1_rgba).rgb, vec3(1.0))/3.0));
float o10120_0_clamp_true = clamp(o10120_0_clamp_false, 0.0, 1.0);
float o10120_0_1_f = o10120_0_clamp_false;
vec4 o10115_0_s1 = vec4(vec3(o10118_0_1_f), 1.0);
vec4 o10115_0_s2 = vec4(vec3(o10119_0_1_f), 1.0);
float o10115_0_a = p_o10115_amount*o10117_0_1_f;
vec4 o10115_0_1_rgba = vec4(blend_normal((uv), o10115_0_s1.rgb, o10115_0_s2.rgb, o10115_0_a*o10115_0_s1.a), min(1.0, o10115_0_s2.a+o10115_0_a*o10115_0_s1.a));
float o10121_0_clamp_false = min(o10120_0_1_f,(dot((o10115_0_1_rgba).rgb, vec3(1.0))/3.0));
float o10121_0_clamp_true = clamp(o10121_0_clamp_false, 0.0, 1.0);
float o10121_0_1_f = o10121_0_clamp_false;
float o10312_1_2_f = o9701_0_2_rgba.g;
float o10185_0_1_f = p_o10185_color;
float o10184_0_1_f = p_o10184_color;
float o10183_0_clamp_false = (1.0-step(o10184_0_1_f,o10185_0_1_f));
float o10183_0_clamp_true = clamp(o10183_0_clamp_false, 0.0, 1.0);
float o10183_0_1_f = o10183_0_clamp_false;
vec4 o10182_0_s1 = vec4(vec3(o10185_0_1_f), 1.0);
vec4 o10182_0_s2 = vec4(vec3(o10184_0_1_f), 1.0);
float o10182_0_a = p_o10182_amount*o10183_0_1_f;
vec4 o10182_0_1_rgba = vec4(blend_normal((uv), o10182_0_s1.rgb, o10182_0_s2.rgb, o10182_0_a*o10182_0_s1.a), min(1.0, o10182_0_s2.a+o10182_0_a*o10182_0_s1.a));
float o10186_0_clamp_false = max(o10312_1_2_f,(dot((o10182_0_1_rgba).rgb, vec3(1.0))/3.0));
float o10186_0_clamp_true = clamp(o10186_0_clamp_false, 0.0, 1.0);
float o10186_0_1_f = o10186_0_clamp_false;
vec4 o10181_0_s1 = vec4(vec3(o10184_0_1_f), 1.0);
vec4 o10181_0_s2 = vec4(vec3(o10185_0_1_f), 1.0);
float o10181_0_a = p_o10181_amount*o10183_0_1_f;
vec4 o10181_0_1_rgba = vec4(blend_normal((uv), o10181_0_s1.rgb, o10181_0_s2.rgb, o10181_0_a*o10181_0_s1.a), min(1.0, o10181_0_s2.a+o10181_0_a*o10181_0_s1.a));
float o10187_0_clamp_false = min(o10186_0_1_f,(dot((o10181_0_1_rgba).rgb, vec3(1.0))/3.0));
float o10187_0_clamp_true = clamp(o10187_0_clamp_false, 0.0, 1.0);
float o10187_0_1_f = o10187_0_clamp_false;
float o10312_2_3_f = o9701_0_2_rgba.b;
float o10251_0_1_f = p_o10251_color;
float o10250_0_1_f = p_o10250_color;
float o10249_0_clamp_false = (1.0-step(o10250_0_1_f,o10251_0_1_f));
float o10249_0_clamp_true = clamp(o10249_0_clamp_false, 0.0, 1.0);
float o10249_0_1_f = o10249_0_clamp_false;
vec4 o10248_0_s1 = vec4(vec3(o10251_0_1_f), 1.0);
vec4 o10248_0_s2 = vec4(vec3(o10250_0_1_f), 1.0);
float o10248_0_a = p_o10248_amount*o10249_0_1_f;
vec4 o10248_0_1_rgba = vec4(blend_normal((uv), o10248_0_s1.rgb, o10248_0_s2.rgb, o10248_0_a*o10248_0_s1.a), min(1.0, o10248_0_s2.a+o10248_0_a*o10248_0_s1.a));
float o10252_0_clamp_false = max(o10312_2_3_f,(dot((o10248_0_1_rgba).rgb, vec3(1.0))/3.0));
float o10252_0_clamp_true = clamp(o10252_0_clamp_false, 0.0, 1.0);
float o10252_0_1_f = o10252_0_clamp_false;
vec4 o10247_0_s1 = vec4(vec3(o10250_0_1_f), 1.0);
vec4 o10247_0_s2 = vec4(vec3(o10251_0_1_f), 1.0);
float o10247_0_a = p_o10247_amount*o10249_0_1_f;
vec4 o10247_0_1_rgba = vec4(blend_normal((uv), o10247_0_s1.rgb, o10247_0_s2.rgb, o10247_0_a*o10247_0_s1.a), min(1.0, o10247_0_s2.a+o10247_0_a*o10247_0_s1.a));
float o10253_0_clamp_false = min(o10252_0_1_f,(dot((o10247_0_1_rgba).rgb, vec3(1.0))/3.0));
float o10253_0_clamp_true = clamp(o10253_0_clamp_false, 0.0, 1.0);
float o10253_0_1_f = o10253_0_clamp_false;
vec4 o10313_0_1_rgba = vec4(o10121_0_1_f, o10187_0_1_f, o10253_0_1_f, 1.0);
return o10313_0_1_rgba;
}
const float p_o9674_amount1 = 1.000000000;
const float p_o9674_amount2 = 0.330000000;
const float p_o9674_amount3 = 0.060000000;
const float p_o9662_translate_x = 0.000000000;
const float p_o9662_translate_y = 0.000000000;
const float p_o9668_amount = 1.500000000;
const float p_o9668_eps = 0.135000000;
float o9668_input_d(vec2 uv, float _seed_variation_) {
vec2 o9702_0_uv = floor(((uv)*vec2(p_o9702_x, p_o9702_y)))+vec2(0.5);
vec3 o9702_0_dither = fract(vec3(dot(vec2(171.0, 231.0), o9702_0_uv))/vec3(103.0, 71.0, 97.0));
float o9672_0_1_f = anisotropic((fract(transform2((o9702_0_uv/vec2(p_o9702_x, p_o9702_y)), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), vec2(p_o9672_scale_x, p_o9672_scale_y), (seed_o9672+fract(_seed_variation_)), p_o9672_smoothness, p_o9672_interpolation);
vec4 o10098_0_1_rgba = vec4(vec3(o9672_0_1_f), 1.0);
vec3 o9702_0_1_rgb = floor(((o10098_0_1_rgba).rgb)*p_o9702_c+p_o9702_d*(o9702_0_dither-vec3(0.5)))/p_o9702_c;
return (dot(o9702_0_1_rgb, vec3(1.0))/3.0);
}
vec2 o9668_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o9668_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o9668_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o9668_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o9668_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o9675_size = 32.000000000;
vec3 o9675_input_palette(vec2 uv, float _seed_variation_) {
vec4 o9662_0_1_rgba = vec4(((uv)-vec2(p_o9662_translate_x, p_o9662_translate_y)), 0.0, 1.0);
return ((o9662_0_1_rgba).rgb);
}
vec3 find_color_from_palette_o9675(vec3 color, int size, float _seed_variation_) {
	float min_dist = 10.0;
	vec3 best_color = vec3(0.0);
	for (int i = 0; i < size; ++i) {
		float x = (float(i)+0.5)/float(size);
		for (int j = 0; j < size; ++j) {
			float y = (float(j)+0.5)/float(size);
			vec3 c = o9675_input_palette(vec2(x, y), _seed_variation_);
			float l = length(color - c);
			if (l < min_dist) {
				min_dist = l;
				best_color = c;
			}
		}
	}
	return best_color;
}const float p_o9718_value = 0.260000000;
const float p_o9718_width = 0.020000000;
const float p_o9718_contrast = 0.000000000;
const vec4 p_o10109_color = vec4(0.000000000, 1.000000000, 0.000000000, 1.000000000);
const float p_o10108_value = 0.580000000;
const float p_o10108_width = 0.080000000;
const float p_o10108_contrast = 0.030000000;
vec4 o9633_input_in(vec2 uv, float _seed_variation_) {
vec4 o9662_0_1_rgba = vec4(((uv)-vec2(p_o9662_translate_x, p_o9662_translate_y)), 0.0, 1.0);
vec2 o9668_0_slope = o9668_slope((uv), p_o9668_eps, _seed_variation_);
vec2 o9668_0_warp = o9668_0_slope;
vec4 o9662_0_4_rgba = vec4((((uv)+p_o9668_amount*o9668_0_warp)-vec2(p_o9662_translate_x, p_o9662_translate_y)), 0.0, 1.0);
vec3 o9675_0_1_rgb = find_color_from_palette_o9675(((o9662_0_4_rgba).rgb), int(min(p_o9675_size, 32.0)), _seed_variation_);
vec4 o9668_0_1_rgba = vec4(o9675_0_1_rgb, 1.0);
float o9672_0_1_f = anisotropic((fract(transform2((uv), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), vec2(p_o9672_scale_x, p_o9672_scale_y), (seed_o9672+fract(_seed_variation_)), p_o9672_smoothness, p_o9672_interpolation);
vec4 o10098_0_1_rgba = vec4(vec3(o9672_0_1_f), 1.0);
vec3 o9673_0_false = clamp((o10098_0_1_rgba.rgb-vec3(p_o9673_value))/max(0.0001, p_o9673_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o9673_0_true = vec3(1.0)-o9673_0_false;vec4 o9673_0_1_rgba = vec4(o9673_0_false, o10098_0_1_rgba.a);
vec4 o10111_0_rect = bricks_rb((fract(transform2((uv), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), vec2(p_o10111_columns, p_o10111_rows), p_o10111_repeat, p_o10111_row_offset);
vec4 o10111_0 = brick((fract(transform2((uv), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), o10111_0_rect.xy, o10111_0_rect.zw, p_o10111_mortar*1.0, p_o10111_round*1.0, max(0.001, p_o10111_bevel*1.0), 1.0 / p_o10111_rows);vec4 o10111_1_2_fill = round(vec4(fract(o10111_0_rect.xy), o10111_0_rect.zw - o10111_0_rect.xy)*4096.0)/4096.0;
vec4 o10112_0_bb = o10111_1_2_fill;float o10112_0_1_f = mix(p_o10112_edgecolor, rand(vec2(float((seed_o10112+fract(_seed_variation_))), rand(vec2(rand(o10112_0_bb.xy), rand(o10112_0_bb.zw))))), step(0.0000001, dot(o10112_0_bb.zw, vec2(1.0))));
vec4 o10098_2_3_rgba = vec4(vec3(o10112_0_1_f), 1.0);
float o10105_0_step = clamp(((dot((o10098_2_3_rgba).rgb, vec3(1.0))/3.0) - (p_o10105_value))/max(0.0001, p_o10105_width)+0.5, 0.0, 1.0);
float o10105_0_false = clamp((min(o10105_0_step, 1.0-o10105_0_step) * 2.0) / (1.0 - p_o10105_contrast), 0.0, 1.0);
float o10105_0_true = 1.0-o10105_0_false;float o10105_0_1_f = o10105_0_false;
vec4 o10101_0_b = o9673_0_1_rgba;
vec4 o10101_0_l;
float o10101_0_a;
o10101_0_l = o10098_0_1_rgba;
o10101_0_a = p_o10101_amount1*o10105_0_1_f;
o10101_0_b = vec4(blend_overlay((uv), o10101_0_l.rgb, o10101_0_b.rgb, o10101_0_a*o10101_0_l.a), min(1.0, o10101_0_b.a+o10101_0_a*o10101_0_l.a));
vec4 o10101_0_1_rgba = o10101_0_b;
float o9703_0_1_f = (elapsed_time / 80.0);
float o9714_0_1_f = anisotropic((fract(transform2((uv), vec2(p_o10098_translate_x*(2.0*1.0-1.0), p_o10098_translate_y*(2.0*1.0-1.0)), p_o10098_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o10098_scale_x*(2.0*1.0-1.0), p_o10098_scale_y*(2.0*1.0-1.0))))), vec2(p_o9714_scale_x, p_o9714_scale_y), (seed_o9714+fract(_seed_variation_)), p_o9714_smoothness, p_o9714_interpolation);
vec4 o10098_1_4_rgba = vec4(vec3(o9714_0_1_f), 1.0);
float o9713_0_clamp_false = o9703_0_1_f+(dot((o10098_1_4_rgba).rgb, vec3(1.0))/3.0);
float o9713_0_clamp_true = clamp(o9713_0_clamp_false, 0.0, 1.0);
float o9713_0_1_f = o9713_0_clamp_false;
float o10106_0_clamp_false = o9713_0_1_f*o10105_0_1_f;
float o10106_0_clamp_true = clamp(o10106_0_clamp_false, 0.0, 1.0);
float o10106_0_1_f = o10106_0_clamp_false;
float o9704_0_clamp_false = sin(o10106_0_1_f*p_o9704_default_in2);
float o9704_0_clamp_true = clamp(o9704_0_clamp_false, 0.0, 1.0);
float o9704_0_2_f = o9704_0_clamp_false;
float o9709_0_clamp_false = o10106_0_1_f+p_o9709_default_in2;
float o9709_0_clamp_true = clamp(o9709_0_clamp_false, 0.0, 1.0);
float o9709_0_2_f = o9709_0_clamp_false;
float o9705_0_clamp_false = sin(o9709_0_2_f*p_o9705_default_in2);
float o9705_0_clamp_true = clamp(o9705_0_clamp_false, 0.0, 1.0);
float o9705_0_2_f = o9705_0_clamp_false;
float o9706_0_clamp_false = o9704_0_2_f/o9705_0_2_f;
float o9706_0_clamp_true = clamp(o9706_0_clamp_false, 0.0, 1.0);
float o9706_0_1_f = o9706_0_clamp_true;
float o9708_0_clamp_false = o10106_0_1_f+p_o9708_default_in2;
float o9708_0_clamp_true = clamp(o9708_0_clamp_false, 0.0, 1.0);
float o9708_0_2_f = o9708_0_clamp_false;
float o9707_0_clamp_false = sin(o9708_0_2_f*p_o9707_default_in2);
float o9707_0_clamp_true = clamp(o9707_0_clamp_false, 0.0, 1.0);
float o9707_0_2_f = o9707_0_clamp_false;
float o9710_0_clamp_false = o9706_0_1_f+o9707_0_2_f;
float o9710_0_clamp_true = clamp(o9710_0_clamp_false, 0.0, 1.0);
float o9710_0_1_f = o9710_0_clamp_true;
float o9718_0_step = clamp((o9710_0_1_f - (p_o9718_value))/max(0.0001, p_o9718_width)+0.5, 0.0, 1.0);
float o9718_0_false = clamp((min(o9718_0_step, 1.0-o9718_0_step) * 2.0) / (1.0 - p_o9718_contrast), 0.0, 1.0);
float o9718_0_true = 1.0-o9718_0_false;float o9718_0_1_f = o9718_0_false;
vec4 o10109_0_1_rgba = p_o10109_color;
float o10108_0_step = clamp(((dot((o10098_2_3_rgba).rgb, vec3(1.0))/3.0) - (p_o10108_value))/max(0.0001, p_o10108_width)+0.5, 0.0, 1.0);
float o10108_0_false = clamp((min(o10108_0_step, 1.0-o10108_0_step) * 2.0) / (1.0 - p_o10108_contrast), 0.0, 1.0);
float o10108_0_true = 1.0-o10108_0_false;float o10108_0_1_f = o10108_0_false;
vec4 o9674_0_b = o9662_0_1_rgba;
vec4 o9674_0_l;
float o9674_0_a;
o9674_0_l = o9668_0_1_rgba;
o9674_0_a = p_o9674_amount1*(dot((o10101_0_1_rgba).rgb, vec3(1.0))/3.0);
o9674_0_b = vec4(blend_normal((uv), o9674_0_l.rgb, o9674_0_b.rgb, o9674_0_a*o9674_0_l.a), min(1.0, o9674_0_b.a+o9674_0_a*o9674_0_l.a));
o9674_0_l = vec4(vec3(o9718_0_1_f), 1.0);
o9674_0_a = p_o9674_amount2*1.0;
o9674_0_b = vec4(blend_screen((uv), o9674_0_l.rgb, o9674_0_b.rgb, o9674_0_a*o9674_0_l.a), min(1.0, o9674_0_b.a+o9674_0_a*o9674_0_l.a));
o9674_0_l = o10109_0_1_rgba;
o9674_0_a = p_o9674_amount3*o10108_0_1_f;
o9674_0_b = vec4(blend_dissolve((uv), o9674_0_l.rgb, o9674_0_b.rgb, o9674_0_a*o9674_0_l.a), min(1.0, o9674_0_b.a+o9674_0_a*o9674_0_l.a));
vec4 o9674_0_2_rgba = o9674_0_b;
vec3 o9679_0_map = ((o9674_0_2_rgba).rgb);
float o9679_0_rnd =  float((seed_o9679+fract(_seed_variation_)))+o9679_0_map.z;
vec4 o9679_0_1_rgba = o9679_input_in(get_from_tileset(1.0, o9679_0_rnd, custom_uv_transform(o9679_0_map.xy, vec2(p_o9679_sx, p_o9679_sy), p_o9679_rotate*0.01745329251, p_o9679_scale, vec2(o9679_0_map.z, float((seed_o9679+fract(_seed_variation_)))))), false ? o9679_0_rnd : 0.0);
return o9679_0_1_rgba;
}
const float p_o9639_color = 2.000000000;
const float p_o9636_cx = 0.000000000;
const float p_o9636_cy = 0.000000000;
const float p_o9661_value = 0.500000000;
const float p_o9661_width = 0.410000000;
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec4 o9659_0 = textureLod(texture_4, (uv), 0.0);
vec3 o9633_0_map = ((o9659_0).rgb);
float o9633_0_rnd =  float((seed_o9633+fract(_seed_variation_)))+o9633_0_map.z;
vec4 o9633_0_1_rgba = o9633_input_in(get_from_tileset(1.0, o9633_0_rnd, custom_uv_transform(o9633_0_map.xy, vec2(p_o9633_sx, p_o9633_sy), p_o9633_rotate*0.01745329251, p_o9633_scale, vec2(o9633_0_map.z, float((seed_o9633+fract(_seed_variation_)))))), false ? o9633_0_rnd : 0.0);
float o9639_0_1_f = p_o9639_color;
vec4 o9638_0_b = o9633_0_1_rgba;
vec4 o9638_0_l;
float o9638_0_a;

o9638_0_l = vec4(vec3(o9639_0_1_f), 1.0);
o9638_0_a = p_o9638_amount1*1.0;
o9638_0_b = vec4(blend_multiply((uv), o9638_0_l.rgb, o9638_0_b.rgb, o9638_0_a*o9638_0_l.a), min(1.0, o9638_0_b.a+o9638_0_a*o9638_0_l.a));

vec4 o9638_0_2_rgba = o9638_0_b;
vec4 o9652_0_rbga = o9638_0_2_rgba;
vec3 o9652_0_hsv = rgb_to_hsv(o9652_0_rbga.rgb);
o9652_0_hsv.x += p_o9652_hue;
o9652_0_hsv.y = clamp(o9652_0_hsv.y*p_o9652_saturation, 0.0, 1.0);
o9652_0_hsv.z = clamp(o9652_0_hsv.z*p_o9652_value, 0.0, 1.0);
	vec4 o9652_0_1_rgba = vec4(hsv_to_rgb(o9652_0_hsv), o9652_0_rbga.a);
vec4 o9653_0 = textureLod(texture_5, (scale((uv), vec2(0.5+p_o9636_cx, 0.5+p_o9636_cy), vec2((1.0 / 26.0), (1.0 / 26.0)))), 0.0);
vec3 o9661_0_false = clamp((o9653_0.rgb-vec3(p_o9661_value))/max(0.0001, p_o9661_width)+vec3(0.5), vec3(0.0), vec3(1.0));
vec3 o9661_0_true = vec3(1.0)-o9661_0_false;vec4 o9661_0_1_rgba = vec4(o9661_0_false, o9653_0.a);
vec4 o9636_0_1_rgba = o9661_0_1_rgba;
vec4 o9637_0_b = o9652_0_1_rgba;
vec4 o9637_0_l;
float o9637_0_a;

o9637_0_l = o9636_0_1_rgba;
o9637_0_a = p_o9637_amount1*1.0;
o9637_0_b = vec4(blend_multiply((uv), o9637_0_l.rgb, o9637_0_b.rgb, o9637_0_a*o9637_0_l.a), min(1.0, o9637_0_b.a+o9637_0_a*o9637_0_l.a));

vec4 o9637_0_2_rgba = o9637_0_b;
vec4 o10429_0_rbga = o9637_0_2_rgba;
vec3 o10429_0_hsv = rgb_to_hsv(o10429_0_rbga.rgb);
o10429_0_hsv.x += p_o10429_hue;
o10429_0_hsv.y = clamp(o10429_0_hsv.y*p_o10429_saturation, 0.0, 1.0);
o10429_0_hsv.z = clamp(o10429_0_hsv.z*p_o10429_value, 0.0, 1.0);
	vec4 o10429_0_1_rgba = vec4(hsv_to_rgb(o10429_0_hsv), o10429_0_rbga.a);

	vec4 color_tex = o10429_0_1_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	COLOR = color_tex;

}



