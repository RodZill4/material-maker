shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_emission : hint_black_albedo;
uniform vec4 emission : hint_color;
uniform float emission_energy;
uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-16,16);
uniform sampler2D texture_ambient_occlusion : hint_white;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect;
uniform sampler2D texture_depth : hint_black;
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
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	NORMALMAP = texture(texture_normal,base_uv).rgb;
	NORMALMAP_DEPTH = normal_scale;
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	EMISSION = (emission.rgb+emission_tex)*emission_energy;
	AO = dot(texture(texture_ambient_occlusion,base_uv),ao_texture_channel);
	AO_LIGHT_AFFECT = ao_light_affect;
}
