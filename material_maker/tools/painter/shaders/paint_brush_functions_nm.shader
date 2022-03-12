#include "paint_brush_functions.shader"

vec2 tex2view(vec2 uv, vec2 duv) {
	vec4 v = texture(tex2view_tex, seams_uv(uv));
	if (v.w < 0.99) {
		v = texture(tex2view_tex, seams_uv(duv));
	}
	return v.xy;
}

vec2 dTex2View(vec2 uv, vec2 epsilon) {
	vec2 returnValue = tex2view(uv+epsilon, uv);
	returnValue += 0.5*tex2view(uv+2.0*epsilon, uv);
	returnValue -= tex2view(uv-epsilon, uv);
	returnValue -= 0.5*tex2view(uv-2.0*epsilon, uv);
	return normalize(returnValue.xy);
}
