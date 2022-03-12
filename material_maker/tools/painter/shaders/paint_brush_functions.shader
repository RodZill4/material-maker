
GENERATED_CODE

float brush(vec2 uv) {
	return clamp(brush_function(uv)/(1.0-brush_hardness), 0.0, 1.0);
}

vec2 seams_uv(vec2 uv) {
	vec2 seams_value = texture(seams, uv).xy-vec2(0.5);
	return fract(uv+seams_value*seams_multiplier/texture_size);
}
