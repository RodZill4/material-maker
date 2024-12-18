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
vec2 scale(vec2 uv, vec2 center, vec2 scale) {
	uv -= center;
	uv /= scale;
	uv += center;
	return uv;
}
vec2 rotate(vec2 uv, float rotate) {
 	vec2 rv;
	rv.x = cos(rotate)*uv.x + sin(rotate)*uv.y;
	rv.y = -sin(rotate)*uv.x + cos(rotate)*uv.y;
	return rv;	
}
float shape_circle(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = max(edge, 1.0e-8);
	float distance = length(uv);
	return clamp((1.0-distance/size)/edge, 0.0, 1.0);
}
float shape_polygon(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = max(edge, 1.0e-8);
	float angle = atan(uv.x, uv.y)+3.14159265359;
	float slice = 6.28318530718/sides;
	return clamp((1.0-(cos(floor(0.5+angle/slice)*slice-angle)*length(uv))/size)/edge, 0.0, 1.0);
}
float shape_star(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = max(edge, 1.0e-8);
	float angle = atan(uv.x, uv.y);
	float slice = 6.28318530718/sides;
	return clamp((1.0-(cos(floor(angle*sides/6.28318530718-0.5+2.0*step(fract(angle*sides/6.28318530718), 0.5))*slice-angle)*length(uv))/size)/edge, 0.0, 1.0);
}
float shape_curved_star(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = max(edge, 1.0e-8);
	float angle = 2.0*(atan(uv.x, uv.y)+3.14159265359);
	float slice = 6.28318530718/sides;
	return clamp((1.0-cos(floor(0.5+0.5*angle/slice)*2.0*slice-angle)*length(uv)/size)/edge, 0.0, 1.0);
}
float shape_rays(vec2 uv, float sides, float size, float edge) {
	uv = 2.0*uv-1.0;
	edge = 0.5*max(edge, 1.0e-8)*size;
	float slice = 6.28318530718/sides;
	float angle = mod(atan(uv.x, uv.y)+3.14159265359, slice)/slice;
	return clamp(min((size-angle)/edge, angle/edge), 0.0, 1.0);
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
float pingpong(float a, float b)
{
  return (b != 0.0) ? abs(fract((a - b) / (b * 2.0)) * b * 2.0 - b) : 0.0;
}
const float p_o150460_amount1 = 1.000000000;
const float p_o150416_count = 8.000000000;
const float p_o150416_width = 4.000000000;
const float p_o150434_amount1 = 1.000000000;
const float p_o150477_cx = 0.000000000;
const float p_o150477_cy = 0.000000000;
const float p_o150477_rotate = 90.000000000;
const float p_o150492_cx = 0.000000000;
const float p_o150492_cy = 0.000000000;
const float p_o150492_scale_x = 1.700000000;
const float p_o150492_scale_y = 1.000000000;
const float p_o150478_gradient_0_pos = 0.000000000;
const vec4 p_o150478_gradient_0_col = vec4(0.000000000, 0.032349002, 0.078125000, 1.000000000);
const float p_o150478_gradient_1_pos = 0.747442000;
const vec4 p_o150478_gradient_1_col = vec4(0.000000000, 0.111450002, 0.171875000, 1.000000000);
const float p_o150478_gradient_2_pos = 1.000000000;
const vec4 p_o150478_gradient_2_col = vec4(0.129639000, 0.297876000, 0.460938007, 1.000000000);
vec4 o150478_gradient_gradient_fct(float x) {
  if (x < p_o150478_gradient_0_pos) {
    return p_o150478_gradient_0_col;
  } else if (x < p_o150478_gradient_1_pos) {
    return mix(mix(p_o150478_gradient_1_col, p_o150478_gradient_2_col, (x-p_o150478_gradient_1_pos)/(p_o150478_gradient_2_pos-p_o150478_gradient_1_pos)), mix(p_o150478_gradient_0_col, p_o150478_gradient_1_col, (x-p_o150478_gradient_0_pos)/(p_o150478_gradient_1_pos-p_o150478_gradient_0_pos)), 1.0-0.5*(x-p_o150478_gradient_0_pos)/(p_o150478_gradient_1_pos-p_o150478_gradient_0_pos));
  } else if (x < p_o150478_gradient_2_pos) {
    return mix(mix(p_o150478_gradient_0_col, p_o150478_gradient_1_col, (x-p_o150478_gradient_0_pos)/(p_o150478_gradient_1_pos-p_o150478_gradient_0_pos)), mix(p_o150478_gradient_1_col, p_o150478_gradient_2_col, (x-p_o150478_gradient_1_pos)/(p_o150478_gradient_2_pos-p_o150478_gradient_1_pos)), 0.5+0.5*(x-p_o150478_gradient_1_pos)/(p_o150478_gradient_2_pos-p_o150478_gradient_1_pos));
  }
  return p_o150478_gradient_2_col;
}
const float p_o150435_hue = 0.000000000;
const float p_o150435_saturation = 0.300000000;
const float p_o150435_value = 1.000000000;
const float seed_o150442 = 0.904035091;
const float p_o150441_steps = 300.000000000;
const float p_o150459_amount1 = 1.000000000;
const float p_o150443_repeat = 1.000000000;
const float p_o150443_gradient_0_pos = 0.000000000;
const vec4 p_o150443_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o150443_gradient_1_pos = 1.000000000;
const vec4 p_o150443_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o150443_gradient_gradient_fct(float x) {
  if (x < p_o150443_gradient_0_pos) {
    return p_o150443_gradient_0_col;
  } else if (x < p_o150443_gradient_1_pos) {
    return mix(p_o150443_gradient_0_col, p_o150443_gradient_1_col, ((x-p_o150443_gradient_0_pos)/(p_o150443_gradient_1_pos-p_o150443_gradient_0_pos)));
  }
  return p_o150443_gradient_1_col;
}
const float p_o150461_sides = 6.000000000;
const float p_o150461_radius = 4.000000000;
const float p_o150461_edge = 1.000000000;
const float p_o150457_cx = 0.000000000;
const float p_o150457_cy = 0.000000000;
const float p_o150457_rotate = 45.000000000;
const float p_o150438_default_in1 = 0.000000000;
const float p_o150438_default_in2 = 20.000000000;
const float p_o150439_default_in1 = 0.000000000;
const float p_o150439_default_in2 = 0.000000000;
const float p_o150440_default_in1 = 0.000000000;
const float p_o150440_default_in2 = 0.000000000;
const float p_o150437_default_in1 = 0.000000000;
const float p_o150436_default_in1 = 0.000000000;
const float p_o150436_default_in2 = 0.200000000;
vec4 o150416_input_in(vec2 uv, float _seed_variation_) {
vec2 o150477_0_c = vec2(0.5+p_o150477_cx, 0.5+p_o150477_cy);vec4 o150478_0_1_rgba = o150478_gradient_gradient_fct(((scale((rotate((uv)-o150477_0_c, p_o150477_rotate*0.01745329251)+o150477_0_c), vec2(0.5+p_o150492_cx, 0.5+p_o150492_cy), vec2(p_o150492_scale_x, p_o150492_scale_y)))).x);
vec4 o150492_0_1_rgba = o150478_0_1_rgba;
vec4 o150477_0_1_rgba = o150492_0_1_rgba;
vec4 o150443_0_1_rgba = o150443_gradient_gradient_fct(fract(p_o150443_repeat*0.15915494309*atan((uv).y-0.5, (uv).x-0.5)));
float o150461_0_1_f = shape_circle((uv), p_o150461_sides, p_o150461_radius*1.0, p_o150461_edge*1.0);
vec4 o150462_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o150461_0_1_f), 1.0).rgb, vec4(vec3(o150461_0_1_f), 1.0).a);
vec4 o150456_0_1_rgba = vec4((dot((o150443_0_1_rgba).rgb, vec3(1.0))/3.0), (dot((o150462_0_1_rgba).rgb, vec3(1.0))/3.0), 0.0, 1.0);
vec2 o150457_0_c = vec2(0.5+p_o150457_cx, 0.5+p_o150457_cy);vec4 o150457_0_1_rgba = vec4((rotate((uv)-o150457_0_c, p_o150457_rotate*0.01745329251)+o150457_0_c), 0.0, 1.0);
vec4 o150459_0_b = o150456_0_1_rgba;
vec4 o150459_0_l;
float o150459_0_a;
o150459_0_l = o150457_0_1_rgba;
o150459_0_a = p_o150459_amount1*1.0;
o150459_0_b = vec4(blend_normal((uv), o150459_0_l.rgb, o150459_0_b.rgb, o150459_0_a*o150459_0_l.a), min(1.0, o150459_0_b.a+o150459_0_a*o150459_0_l.a));
vec4 o150459_0_2_rgba = o150459_0_b;
float o150458_1_1_f = o150459_0_2_rgba.g;
vec4 o150441_0_1_rgba = vec4(floor(vec4(vec3(o150458_1_1_f), 1.0).rgb*p_o150441_steps)/p_o150441_steps, vec4(vec3(o150458_1_1_f), 1.0).a);
vec3 o150442_0_rand = ((o150441_0_1_rgba).rgb);vec3 o150442_0_1_rgb = rand3( vec2( float((seed_o150442+fract(_seed_variation_))) + o150442_0_rand.x, rand( o150442_0_rand.yz ) ) );
vec4 o150435_0_rbga = vec4(o150442_0_1_rgb, 1.0);
vec3 o150435_0_hsv = rgb_to_hsv(o150435_0_rbga.rgb);
o150435_0_hsv.x += p_o150435_hue;
o150435_0_hsv.y = clamp(o150435_0_hsv.y*p_o150435_saturation, 0.0, 1.0);
o150435_0_hsv.z = clamp(o150435_0_hsv.z*p_o150435_value, 0.0, 1.0);
	vec4 o150435_0_1_rgba = vec4(hsv_to_rgb(o150435_0_hsv), o150435_0_rbga.a);
float o150458_0_2_f = o150459_0_2_rgba.r;
float o150436_0_clamp_false = (dot(o150442_0_1_rgb, vec3(1.0))/3.0)*p_o150436_default_in2;
float o150436_0_clamp_true = clamp(o150436_0_clamp_false, 0.0, 1.0);
float o150436_0_2_f = o150436_0_clamp_false;
float o150437_0_clamp_false = o150436_0_2_f*(elapsed_time+100.);
float o150437_0_clamp_true = clamp(o150437_0_clamp_false, 0.0, 1.0);
float o150437_0_2_f = o150437_0_clamp_false;
float o150440_0_clamp_false = o150458_0_2_f-o150437_0_2_f;
float o150440_0_clamp_true = clamp(o150440_0_clamp_false, 0.0, 1.0);
float o150440_0_1_f = o150440_0_clamp_false;
float o150439_0_clamp_false = fract(o150440_0_1_f);
float o150439_0_clamp_true = clamp(o150439_0_clamp_false, 0.0, 1.0);
float o150439_0_1_f = o150439_0_clamp_false;
float o150438_0_clamp_false = pow(o150439_0_1_f,p_o150438_default_in2);
float o150438_0_clamp_true = clamp(o150438_0_clamp_false, 0.0, 1.0);
float o150438_0_2_f = o150438_0_clamp_false;
vec4 o150434_0_b = o150477_0_1_rgba;
vec4 o150434_0_l;
float o150434_0_a;
o150434_0_l = o150435_0_1_rgba;
o150434_0_a = p_o150434_amount1*o150438_0_2_f;
o150434_0_b = vec4(blend_normal((uv), o150434_0_l.rgb, o150434_0_b.rgb, o150434_0_a*o150434_0_l.a), min(1.0, o150434_0_b.a+o150434_0_a*o150434_0_l.a));
vec4 o150434_0_1_rgba = o150434_0_b;
return o150434_0_1_rgba;
}
vec4 supersample_o150416(vec2 uv, float size, int count, float width, float _seed_variation_) {
	vec4 rv = vec4(0.0);
	vec2 step_size = vec2(width)/size/float(count);
	uv -= vec2(0.5)/size;
	for (int x = 0; x < count; ++x) {
		for (int y = 0; y < count; ++y) {
			rv += o150416_input_in(uv+(vec2(float(x), float(y))+vec2(0.5))*step_size, _seed_variation_);
		}
	}
	return rv/float(count*count);
}const float p_o150411_translate_x = 0.002200000;
const float p_o150411_translate_y = 0.002200000;
const float p_o150412_count = 12.000000000;
const float p_o150412_width = 4.000000000;
vec4 o150412_input_in(vec2 uv, float _seed_variation_) {
vec2 o150477_0_c = vec2(0.5+p_o150477_cx, 0.5+p_o150477_cy);vec4 o150478_0_1_rgba = o150478_gradient_gradient_fct(((scale((rotate((uv)-o150477_0_c, p_o150477_rotate*0.01745329251)+o150477_0_c), vec2(0.5+p_o150492_cx, 0.5+p_o150492_cy), vec2(p_o150492_scale_x, p_o150492_scale_y)))).x);
vec4 o150492_0_1_rgba = o150478_0_1_rgba;
vec4 o150477_0_1_rgba = o150492_0_1_rgba;
vec4 o150443_0_1_rgba = o150443_gradient_gradient_fct(fract(p_o150443_repeat*0.15915494309*atan((uv).y-0.5, (uv).x-0.5)));
float o150461_0_1_f = shape_circle((uv), p_o150461_sides, p_o150461_radius*1.0, p_o150461_edge*1.0);
vec4 o150462_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o150461_0_1_f), 1.0).rgb, vec4(vec3(o150461_0_1_f), 1.0).a);
vec4 o150456_0_1_rgba = vec4((dot((o150443_0_1_rgba).rgb, vec3(1.0))/3.0), (dot((o150462_0_1_rgba).rgb, vec3(1.0))/3.0), 0.0, 1.0);
vec2 o150457_0_c = vec2(0.5+p_o150457_cx, 0.5+p_o150457_cy);vec4 o150457_0_1_rgba = vec4((rotate((uv)-o150457_0_c, p_o150457_rotate*0.01745329251)+o150457_0_c), 0.0, 1.0);
vec4 o150459_0_b = o150456_0_1_rgba;
vec4 o150459_0_l;
float o150459_0_a;
o150459_0_l = o150457_0_1_rgba;
o150459_0_a = p_o150459_amount1*1.0;
o150459_0_b = vec4(blend_normal((uv), o150459_0_l.rgb, o150459_0_b.rgb, o150459_0_a*o150459_0_l.a), min(1.0, o150459_0_b.a+o150459_0_a*o150459_0_l.a));
vec4 o150459_0_2_rgba = o150459_0_b;
float o150458_1_1_f = o150459_0_2_rgba.g;
vec4 o150441_0_1_rgba = vec4(floor(vec4(vec3(o150458_1_1_f), 1.0).rgb*p_o150441_steps)/p_o150441_steps, vec4(vec3(o150458_1_1_f), 1.0).a);
vec3 o150442_0_rand = ((o150441_0_1_rgba).rgb);vec3 o150442_0_1_rgb = rand3( vec2( float((seed_o150442+fract(_seed_variation_))) + o150442_0_rand.x, rand( o150442_0_rand.yz ) ) );
vec4 o150435_0_rbga = vec4(o150442_0_1_rgb, 1.0);
vec3 o150435_0_hsv = rgb_to_hsv(o150435_0_rbga.rgb);
o150435_0_hsv.x += p_o150435_hue;
o150435_0_hsv.y = clamp(o150435_0_hsv.y*p_o150435_saturation, 0.0, 1.0);
o150435_0_hsv.z = clamp(o150435_0_hsv.z*p_o150435_value, 0.0, 1.0);
	vec4 o150435_0_1_rgba = vec4(hsv_to_rgb(o150435_0_hsv), o150435_0_rbga.a);
float o150458_0_2_f = o150459_0_2_rgba.r;
float o150436_0_clamp_false = (dot(o150442_0_1_rgb, vec3(1.0))/3.0)*p_o150436_default_in2;
float o150436_0_clamp_true = clamp(o150436_0_clamp_false, 0.0, 1.0);
float o150436_0_2_f = o150436_0_clamp_false;
float o150437_0_clamp_false = o150436_0_2_f*(elapsed_time+100.);
float o150437_0_clamp_true = clamp(o150437_0_clamp_false, 0.0, 1.0);
float o150437_0_2_f = o150437_0_clamp_false;
float o150440_0_clamp_false = o150458_0_2_f-o150437_0_2_f;
float o150440_0_clamp_true = clamp(o150440_0_clamp_false, 0.0, 1.0);
float o150440_0_1_f = o150440_0_clamp_false;
float o150439_0_clamp_false = fract(o150440_0_1_f);
float o150439_0_clamp_true = clamp(o150439_0_clamp_false, 0.0, 1.0);
float o150439_0_1_f = o150439_0_clamp_false;
float o150438_0_clamp_false = pow(o150439_0_1_f,p_o150438_default_in2);
float o150438_0_clamp_true = clamp(o150438_0_clamp_false, 0.0, 1.0);
float o150438_0_2_f = o150438_0_clamp_false;
vec4 o150434_0_b = o150477_0_1_rgba;
vec4 o150434_0_l;
float o150434_0_a;
o150434_0_l = o150435_0_1_rgba;
o150434_0_a = p_o150434_amount1*o150438_0_2_f;
o150434_0_b = vec4(blend_normal((uv), o150434_0_l.rgb, o150434_0_b.rgb, o150434_0_a*o150434_0_l.a), min(1.0, o150434_0_b.a+o150434_0_a*o150434_0_l.a));
vec4 o150434_0_1_rgba = o150434_0_b;
return o150434_0_1_rgba;
}
vec4 supersample_o150412(vec2 uv, float size, int count, float width, float _seed_variation_) {
	vec4 rv = vec4(0.0);
	vec2 step_size = vec2(width)/size/float(count);
	uv -= vec2(0.5)/size;
	for (int x = 0; x < count; ++x) {
		for (int y = 0; y < count; ++y) {
			rv += o150412_input_in(uv+(vec2(float(x), float(y))+vec2(0.5))*step_size, _seed_variation_);
		}
	}
	return rv/float(count*count);
}
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec4 o150416_0_1_rgba = supersample_o150416((uv), 1024.000000000, int(p_o150416_count), p_o150416_width, _seed_variation_);
vec4 o150412_0_1_rgba = supersample_o150412(((uv)-vec2(p_o150411_translate_x, p_o150411_translate_y)), 256.000000000, int(p_o150412_count), p_o150412_width, _seed_variation_);
vec4 o150411_0_1_rgba = o150412_0_1_rgba;
vec4 o150460_0_b = o150416_0_1_rgba;
vec4 o150460_0_l;
float o150460_0_a;

o150460_0_l = o150411_0_1_rgba;
o150460_0_a = p_o150460_amount1*1.0;
o150460_0_b = vec4(blend_additive((uv), o150460_0_l.rgb, o150460_0_b.rgb, o150460_0_a*o150460_0_l.a), min(1.0, o150460_0_b.a+o150460_0_a*o150460_0_l.a));

vec4 o150460_0_2_rgba = o150460_0_b;

	vec4 color_tex = o150460_0_2_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	COLOR = color_tex;

}



