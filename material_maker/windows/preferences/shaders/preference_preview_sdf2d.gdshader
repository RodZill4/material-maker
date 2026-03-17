// The MIT License, Copyright © 2020 Inigo Quilez
// https://www.shadertoy.com/view/3ltSW2
// (adapated and modified)

shader_type canvas_item;

uniform vec3 bg = vec3(0.51,0.55,0.62);		// background color
uniform vec3 fg1 = vec3(0.8,0.57,1.0);		// foreground 1
uniform vec3 fg2 = vec3(0.5,0.84,1.0);		// foreground 2
uniform float _border = 0.05;				// border thickness
uniform float _it = 0.2;					// isoline thickness
uniform float io = 1.0;						// isoline opacity
uniform float is = 0.1;						// isoline smoothness
uniform float _id = 0.5;					// isoline density
uniform float sha = 1.0;					// shadow opacity
uniform bool solid = true;					// solid/isoline bg

uniform float preview_sdf_radius = 0.3;

void fragment() {
	float d = length(UV - 0.5) - preview_sdf_radius;
	float _is = max(is, 0.0001);
	float id = _id * 250.0;
	float border = _border * 0.25;

	vec3 col = ( d > 0.0 ) ? bg : mix(fg1, fg2, smoothstep(0.0, 0.5, abs(d)));
	float it = (_it * 2.0 - 1.0) * (1.0 + _is * 0.75);

	col *= 1.2 - exp(-6.0 * abs(d)) * sha;
	if (solid)
		col *= 0.85 + 0.125 * io * smoothstep( it + _is ,it - _is, cos(id * d));
	else
		col *= smoothstep( it + _is ,it - _is, cos(id * d)) * io;
	col = mix(col, vec3(1.0), 1.0 - smoothstep(border - 0.007, border, abs(d)));
    COLOR = vec4(col, 1.0);
}