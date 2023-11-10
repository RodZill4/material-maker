shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color;
uniform float specular;
uniform sampler2D texture_orm : source_color;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_emission : hint_default_black;
uniform vec4 emission : source_color;
uniform float emission_energy;
uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-16,16);
uniform float ao_light_affect;
uniform sampler2D texture_depth : hint_default_black;
uniform float depth_scale;
uniform int depth_min_layers;
uniform int depth_max_layers;
uniform vec2 depth_flip;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	UV = UV*uv1_scale.xy+uv1_offset.xy;
	VERTEX = VERTEX+NORMAL*depth_scale*(1.0-texture(texture_depth, UV).r);
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	albedo_tex.rgb = mix(pow((albedo_tex.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),albedo_tex.rgb.rgb * (1.0 / 12.92),lessThan(albedo_tex.rgb,vec3(0.04045)));
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	vec4 orm_tex = texture(texture_orm, base_uv);
	METALLIC = metallic*orm_tex.b;
	ROUGHNESS = roughness*orm_tex.g;
	SPECULAR = specular;
	NORMAL_MAP = texture(texture_normal,base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	EMISSION = (emission.rgb+emission_tex)*emission_energy;
	AO = orm_tex.r;
	AO_LIGHT_AFFECT = ao_light_affect;
}
