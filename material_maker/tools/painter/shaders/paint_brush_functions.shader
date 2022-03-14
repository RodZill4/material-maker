
GENERATED_CODE

float brush(vec2 uv) {
	return clamp(brush_function(uv)/(1.0-brush_hardness), 0.0, 1.0);
}

vec2 seams_uv(vec2 uv) {
	return texture(seams, uv).xy;
}
