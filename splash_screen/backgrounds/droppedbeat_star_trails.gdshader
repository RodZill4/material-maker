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
vec2 rotate(vec2 uv, float rotate) {
 	vec2 rv;
	rv.x = cos(rotate)*uv.x + sin(rotate)*uv.y;
	rv.y = -sin(rotate)*uv.x + cos(rotate)*uv.y;
	return rv;	
}
vec2 scale(vec2 uv, vec2 center, vec2 scale) {
	uv -= center;
	uv /= scale;
	uv += center;
	return uv;
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
const float p_o168576_amount1 = 1.000000000;
const float p_o168546_count = 8.000000000;
const float p_o168546_width = 4.000000000;
const float p_o168550_amount1 = 1.000000000;
const float p_o168594_cx = 0.000000000;
const float p_o168594_cy = 0.000000000;
const float p_o168594_scale_x = 1.000000000;
const float p_o168594_scale_y = 3.000000000;
const float p_o168593_cx = 0.000000000;
const float p_o168593_cy = 0.000000000;
const float p_o168593_rotate = 90.000000000;
const float p_o168579_gradient_0_pos = 0.000000000;
const vec4 p_o168579_gradient_0_col = vec4(0.000000000, 0.032349002, 0.078125000, 1.000000000);
const float p_o168579_gradient_1_pos = 0.747442000;
const vec4 p_o168579_gradient_1_col = vec4(0.000000000, 0.111450002, 0.171875000, 1.000000000);
const float p_o168579_gradient_2_pos = 1.000000000;
const vec4 p_o168579_gradient_2_col = vec4(0.129639000, 0.297876000, 0.460938007, 1.000000000);
vec4 o168579_gradient_gradient_fct(float x) {
  if (x < p_o168579_gradient_0_pos) {
    return p_o168579_gradient_0_col;
  } else if (x < p_o168579_gradient_1_pos) {
    return mix(mix(p_o168579_gradient_1_col, p_o168579_gradient_2_col, (x-p_o168579_gradient_1_pos)/(p_o168579_gradient_2_pos-p_o168579_gradient_1_pos)), mix(p_o168579_gradient_0_col, p_o168579_gradient_1_col, (x-p_o168579_gradient_0_pos)/(p_o168579_gradient_1_pos-p_o168579_gradient_0_pos)), 1.0-0.5*(x-p_o168579_gradient_0_pos)/(p_o168579_gradient_1_pos-p_o168579_gradient_0_pos));
  } else if (x < p_o168579_gradient_2_pos) {
    return mix(mix(p_o168579_gradient_0_col, p_o168579_gradient_1_col, (x-p_o168579_gradient_0_pos)/(p_o168579_gradient_1_pos-p_o168579_gradient_0_pos)), mix(p_o168579_gradient_1_col, p_o168579_gradient_2_col, (x-p_o168579_gradient_1_pos)/(p_o168579_gradient_2_pos-p_o168579_gradient_1_pos)), 0.5+0.5*(x-p_o168579_gradient_1_pos)/(p_o168579_gradient_2_pos-p_o168579_gradient_1_pos));
  }
  return p_o168579_gradient_2_col;
}
const float p_o168551_hue = 0.000000000;
const float p_o168551_saturation = 0.300000000;
const float p_o168551_value = 1.000000000;
const float seed_o168558 = 0.904035091;
const float p_o168557_steps = 500.000000000;
const float p_o168575_amount1 = 0.000000000;
const float p_o168559_repeat = 1.000000000;
const float p_o168559_gradient_0_pos = 0.000000000;
const vec4 p_o168559_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o168559_gradient_1_pos = 1.000000000;
const vec4 p_o168559_gradient_1_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o168559_gradient_gradient_fct(float x) {
  if (x < p_o168559_gradient_0_pos) {
    return p_o168559_gradient_0_col;
  } else if (x < p_o168559_gradient_1_pos) {
    return mix(p_o168559_gradient_0_col, p_o168559_gradient_1_col, ((x-p_o168559_gradient_0_pos)/(p_o168559_gradient_1_pos-p_o168559_gradient_0_pos)));
  }
  return p_o168559_gradient_1_col;
}
const float p_o168577_sides = 6.000000000;
const float p_o168577_radius = 8.000000000;
const float p_o168577_edge = 1.000000000;
const float p_o168573_cx = 0.000000000;
const float p_o168573_cy = 0.000000000;
const float p_o168573_rotate = 45.000000000;
const float p_o168596_default_in1 = 0.000000000;
const float p_o168596_default_in2 = 0.000000000;
const float p_o168554_default_in1 = 0.000000000;
const float p_o168554_default_in2 = 20.000000000;
const float p_o168555_default_in1 = 0.000000000;
const float p_o168555_default_in2 = 0.000000000;
const float p_o168556_default_in1 = 0.000000000;
const float p_o168556_default_in2 = 0.000000000;
const float p_o168553_default_in1 = 0.000000000;
const float p_o168552_default_in1 = 0.000000000;
const float p_o168552_default_in2 = 0.200000000;
const float p_o168595_sides = 6.000000000;
const float p_o168595_radius = 0.063200000;
const float p_o168595_edge = 0.650000000;
vec4 o168546_input_in(vec2 uv, float _seed_variation_) {
vec2 o168593_0_c = vec2(0.5+p_o168593_cx, 0.5+p_o168593_cy);vec4 o168579_0_1_rgba = o168579_gradient_gradient_fct(((rotate((scale((uv), vec2(0.5+p_o168594_cx, 0.5+p_o168594_cy), vec2(p_o168594_scale_x, p_o168594_scale_y)))-o168593_0_c, p_o168593_rotate*0.01745329251)+o168593_0_c)).x);
vec4 o168593_0_1_rgba = o168579_0_1_rgba;
vec4 o168594_0_1_rgba = o168593_0_1_rgba;
vec4 o168559_0_1_rgba = o168559_gradient_gradient_fct(fract(p_o168559_repeat*0.15915494309*atan((uv).y-0.5, (uv).x-0.5)));
float o168577_0_1_f = shape_circle((uv), p_o168577_sides, p_o168577_radius*1.0, p_o168577_edge*1.0);
vec4 o168578_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o168577_0_1_f), 1.0).rgb, vec4(vec3(o168577_0_1_f), 1.0).a);
vec4 o168572_0_1_rgba = vec4((dot((o168559_0_1_rgba).rgb, vec3(1.0))/3.0), (dot((o168578_0_1_rgba).rgb, vec3(1.0))/3.0), 0.0, 1.0);
vec2 o168573_0_c = vec2(0.5+p_o168573_cx, 0.5+p_o168573_cy);vec4 o168573_0_1_rgba = vec4((rotate((uv)-o168573_0_c, p_o168573_rotate*0.01745329251)+o168573_0_c), 0.0, 1.0);
vec4 o168575_0_b = o168572_0_1_rgba;
vec4 o168575_0_l;
float o168575_0_a;
o168575_0_l = o168573_0_1_rgba;
o168575_0_a = p_o168575_amount1*1.0;
o168575_0_b = vec4(blend_normal((uv), o168575_0_l.rgb, o168575_0_b.rgb, o168575_0_a*o168575_0_l.a), min(1.0, o168575_0_b.a+o168575_0_a*o168575_0_l.a));
vec4 o168575_0_2_rgba = o168575_0_b;
float o168574_1_1_f = o168575_0_2_rgba.g;
vec4 o168557_0_1_rgba = vec4(floor(vec4(vec3(o168574_1_1_f), 1.0).rgb*p_o168557_steps)/p_o168557_steps, vec4(vec3(o168574_1_1_f), 1.0).a);
vec3 o168558_0_rand = ((o168557_0_1_rgba).rgb);vec3 o168558_0_1_rgb = rand3( vec2( float((seed_o168558+fract(_seed_variation_))) + o168558_0_rand.x, rand( o168558_0_rand.yz ) ) );
vec4 o168551_0_rbga = vec4(o168558_0_1_rgb, 1.0);
vec3 o168551_0_hsv = rgb_to_hsv(o168551_0_rbga.rgb);
o168551_0_hsv.x += p_o168551_hue;
o168551_0_hsv.y = clamp(o168551_0_hsv.y*p_o168551_saturation, 0.0, 1.0);
o168551_0_hsv.z = clamp(o168551_0_hsv.z*p_o168551_value, 0.0, 1.0);
	vec4 o168551_0_1_rgba = vec4(hsv_to_rgb(o168551_0_hsv), o168551_0_rbga.a);
float o168574_0_2_f = o168575_0_2_rgba.r;
float o168552_0_clamp_false = (dot(o168558_0_1_rgb, vec3(1.0))/3.0)*p_o168552_default_in2;
float o168552_0_clamp_true = clamp(o168552_0_clamp_false, 0.0, 1.0);
float o168552_0_2_f = o168552_0_clamp_false;
float o168553_0_clamp_false = o168552_0_2_f*(elapsed_time+100.);
float o168553_0_clamp_true = clamp(o168553_0_clamp_false, 0.0, 1.0);
float o168553_0_2_f = o168553_0_clamp_false;
float o168556_0_clamp_false = o168574_0_2_f-o168553_0_2_f;
float o168556_0_clamp_true = clamp(o168556_0_clamp_false, 0.0, 1.0);
float o168556_0_1_f = o168556_0_clamp_false;
float o168555_0_clamp_false = fract(o168556_0_1_f);
float o168555_0_clamp_true = clamp(o168555_0_clamp_false, 0.0, 1.0);
float o168555_0_1_f = o168555_0_clamp_false;
float o168554_0_clamp_false = pow(o168555_0_1_f,p_o168554_default_in2);
float o168554_0_clamp_true = clamp(o168554_0_clamp_false, 0.0, 1.0);
float o168554_0_2_f = o168554_0_clamp_false;
float o168595_0_1_f = shape_circle((uv), p_o168595_sides, p_o168595_radius*1.0, p_o168595_edge*1.0);
vec4 o168597_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o168595_0_1_f), 1.0).rgb, vec4(vec3(o168595_0_1_f), 1.0).a);
float o168596_0_clamp_false = o168554_0_2_f*(dot((o168597_0_1_rgba).rgb, vec3(1.0))/3.0);
float o168596_0_clamp_true = clamp(o168596_0_clamp_false, 0.0, 1.0);
float o168596_0_1_f = o168596_0_clamp_false;
vec4 o168550_0_b = o168594_0_1_rgba;
vec4 o168550_0_l;
float o168550_0_a;
o168550_0_l = o168551_0_1_rgba;
o168550_0_a = p_o168550_amount1*o168596_0_1_f;
o168550_0_b = vec4(blend_normal((uv), o168550_0_l.rgb, o168550_0_b.rgb, o168550_0_a*o168550_0_l.a), min(1.0, o168550_0_b.a+o168550_0_a*o168550_0_l.a));
vec4 o168550_0_1_rgba = o168550_0_b;
return o168550_0_1_rgba;
}
vec4 supersample_o168546(vec2 uv, float size, int count, float width, float _seed_variation_) {
	vec4 rv = vec4(0.0);
	vec2 step_size = vec2(width)/size/float(count);
	uv -= vec2(0.5)/size;
	for (int x = 0; x < count; ++x) {
		for (int y = 0; y < count; ++y) {
			rv += o168546_input_in(uv+(vec2(float(x), float(y))+vec2(0.5))*step_size, _seed_variation_);
		}
	}
	return rv/float(count*count);
}const float p_o168541_translate_x = 0.002200000;
const float p_o168541_translate_y = 0.002200000;
const float p_o168542_count = 12.000000000;
const float p_o168542_width = 4.000000000;
vec4 o168542_input_in(vec2 uv, float _seed_variation_) {
vec2 o168593_0_c = vec2(0.5+p_o168593_cx, 0.5+p_o168593_cy);vec4 o168579_0_1_rgba = o168579_gradient_gradient_fct(((rotate((scale((uv), vec2(0.5+p_o168594_cx, 0.5+p_o168594_cy), vec2(p_o168594_scale_x, p_o168594_scale_y)))-o168593_0_c, p_o168593_rotate*0.01745329251)+o168593_0_c)).x);
vec4 o168593_0_1_rgba = o168579_0_1_rgba;
vec4 o168594_0_1_rgba = o168593_0_1_rgba;
vec4 o168559_0_1_rgba = o168559_gradient_gradient_fct(fract(p_o168559_repeat*0.15915494309*atan((uv).y-0.5, (uv).x-0.5)));
float o168577_0_1_f = shape_circle((uv), p_o168577_sides, p_o168577_radius*1.0, p_o168577_edge*1.0);
vec4 o168578_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o168577_0_1_f), 1.0).rgb, vec4(vec3(o168577_0_1_f), 1.0).a);
vec4 o168572_0_1_rgba = vec4((dot((o168559_0_1_rgba).rgb, vec3(1.0))/3.0), (dot((o168578_0_1_rgba).rgb, vec3(1.0))/3.0), 0.0, 1.0);
vec2 o168573_0_c = vec2(0.5+p_o168573_cx, 0.5+p_o168573_cy);vec4 o168573_0_1_rgba = vec4((rotate((uv)-o168573_0_c, p_o168573_rotate*0.01745329251)+o168573_0_c), 0.0, 1.0);
vec4 o168575_0_b = o168572_0_1_rgba;
vec4 o168575_0_l;
float o168575_0_a;
o168575_0_l = o168573_0_1_rgba;
o168575_0_a = p_o168575_amount1*1.0;
o168575_0_b = vec4(blend_normal((uv), o168575_0_l.rgb, o168575_0_b.rgb, o168575_0_a*o168575_0_l.a), min(1.0, o168575_0_b.a+o168575_0_a*o168575_0_l.a));
vec4 o168575_0_2_rgba = o168575_0_b;
float o168574_1_1_f = o168575_0_2_rgba.g;
vec4 o168557_0_1_rgba = vec4(floor(vec4(vec3(o168574_1_1_f), 1.0).rgb*p_o168557_steps)/p_o168557_steps, vec4(vec3(o168574_1_1_f), 1.0).a);
vec3 o168558_0_rand = ((o168557_0_1_rgba).rgb);vec3 o168558_0_1_rgb = rand3( vec2( float((seed_o168558+fract(_seed_variation_))) + o168558_0_rand.x, rand( o168558_0_rand.yz ) ) );
vec4 o168551_0_rbga = vec4(o168558_0_1_rgb, 1.0);
vec3 o168551_0_hsv = rgb_to_hsv(o168551_0_rbga.rgb);
o168551_0_hsv.x += p_o168551_hue;
o168551_0_hsv.y = clamp(o168551_0_hsv.y*p_o168551_saturation, 0.0, 1.0);
o168551_0_hsv.z = clamp(o168551_0_hsv.z*p_o168551_value, 0.0, 1.0);
	vec4 o168551_0_1_rgba = vec4(hsv_to_rgb(o168551_0_hsv), o168551_0_rbga.a);
float o168574_0_2_f = o168575_0_2_rgba.r;
float o168552_0_clamp_false = (dot(o168558_0_1_rgb, vec3(1.0))/3.0)*p_o168552_default_in2;
float o168552_0_clamp_true = clamp(o168552_0_clamp_false, 0.0, 1.0);
float o168552_0_2_f = o168552_0_clamp_false;
float o168553_0_clamp_false = o168552_0_2_f*(elapsed_time+100.);
float o168553_0_clamp_true = clamp(o168553_0_clamp_false, 0.0, 1.0);
float o168553_0_2_f = o168553_0_clamp_false;
float o168556_0_clamp_false = o168574_0_2_f-o168553_0_2_f;
float o168556_0_clamp_true = clamp(o168556_0_clamp_false, 0.0, 1.0);
float o168556_0_1_f = o168556_0_clamp_false;
float o168555_0_clamp_false = fract(o168556_0_1_f);
float o168555_0_clamp_true = clamp(o168555_0_clamp_false, 0.0, 1.0);
float o168555_0_1_f = o168555_0_clamp_false;
float o168554_0_clamp_false = pow(o168555_0_1_f,p_o168554_default_in2);
float o168554_0_clamp_true = clamp(o168554_0_clamp_false, 0.0, 1.0);
float o168554_0_2_f = o168554_0_clamp_false;
float o168595_0_1_f = shape_circle((uv), p_o168595_sides, p_o168595_radius*1.0, p_o168595_edge*1.0);
vec4 o168597_0_1_rgba = vec4(vec3(1.0)-vec4(vec3(o168595_0_1_f), 1.0).rgb, vec4(vec3(o168595_0_1_f), 1.0).a);
float o168596_0_clamp_false = o168554_0_2_f*(dot((o168597_0_1_rgba).rgb, vec3(1.0))/3.0);
float o168596_0_clamp_true = clamp(o168596_0_clamp_false, 0.0, 1.0);
float o168596_0_1_f = o168596_0_clamp_false;
vec4 o168550_0_b = o168594_0_1_rgba;
vec4 o168550_0_l;
float o168550_0_a;
o168550_0_l = o168551_0_1_rgba;
o168550_0_a = p_o168550_amount1*o168596_0_1_f;
o168550_0_b = vec4(blend_normal((uv), o168550_0_l.rgb, o168550_0_b.rgb, o168550_0_a*o168550_0_l.a), min(1.0, o168550_0_b.a+o168550_0_a*o168550_0_l.a));
vec4 o168550_0_1_rgba = o168550_0_b;
return o168550_0_1_rgba;
}
vec4 supersample_o168542(vec2 uv, float size, int count, float width, float _seed_variation_) {
	vec4 rv = vec4(0.0);
	vec2 step_size = vec2(width)/size/float(count);
	uv -= vec2(0.5)/size;
	for (int x = 0; x < count; ++x) {
		for (int y = 0; y < count; ++y) {
			rv += o168542_input_in(uv+(vec2(float(x), float(y))+vec2(0.5))*step_size, _seed_variation_);
		}
	}
	return rv/float(count*count);
}
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
vec4 o168546_0_1_rgba = supersample_o168546((uv), 1024.000000000, int(p_o168546_count), p_o168546_width, _seed_variation_);
vec4 o168542_0_1_rgba = supersample_o168542(((uv)-vec2(p_o168541_translate_x, p_o168541_translate_y)), 256.000000000, int(p_o168542_count), p_o168542_width, _seed_variation_);
vec4 o168541_0_1_rgba = o168542_0_1_rgba;
vec4 o168576_0_b = o168546_0_1_rgba;
vec4 o168576_0_l;
float o168576_0_a;

o168576_0_l = o168541_0_1_rgba;
o168576_0_a = p_o168576_amount1*1.0;
o168576_0_b = vec4(blend_additive((uv), o168576_0_l.rgb, o168576_0_b.rgb, o168576_0_a*o168576_0_l.a), min(1.0, o168576_0_b.a+o168576_0_a*o168576_0_l.a));

vec4 o168576_0_2_rgba = o168576_0_b;

	vec4 color_tex = o168576_0_2_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	COLOR = color_tex;

}



