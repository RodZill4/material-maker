shader_type spatial;
render_mode unshaded;

uniform int mode : hint_range(0, 2) = 0;
uniform sampler2D tex : source_color;
uniform sampler2D mask : hint_default_white;

void fragment() {
	vec4 albedo_tex = texture(tex, UV);
	vec4 mask_tex = texture(mask, UV);
	if (mode == 0) {
		ALBEDO = albedo_tex.rgb;
	} else if (mode == 1) {
		ALBEDO = vec3(mask_tex.r);
	} else {
		ivec2 uv = ivec2(UV*64.0) % 2;
		ALBEDO = max(albedo_tex.rgb, vec3(mask_tex.r));
	}

}
