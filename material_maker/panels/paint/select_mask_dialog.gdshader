shader_type spatial;
render_mode unshaded;

uniform sampler2D tex : source_color;
uniform sampler2D mask : hint_default_white;

void fragment() {
	vec4 albedo_tex = texture(tex, UV);
	vec4 mask_tex = texture(mask, UV);
	ALBEDO = albedo_tex.rgb*vec3(0.1+0.9*mask_tex.r);
}
