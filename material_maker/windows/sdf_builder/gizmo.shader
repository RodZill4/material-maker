shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,unshaded;
uniform vec4 color : hint_color;
uniform float highlight = 0.0;

varying float center_depth;

void vertex() {
	center_depth = (MODELVIEW_MATRIX*vec4(vec3(0.0), 1.0)).z;
}

void fragment() {
	vec3 c = vec3(highlight)+color.rgb*(0.05+0.95*smoothstep(-0.05, 0.05, VERTEX.z - center_depth));
	ALBEDO = clamp(c, vec3(0.0), vec3(1.0));
}
