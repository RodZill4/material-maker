shader_type spatial;
render_mode unshaded;

/*
0    	0
0.025	0.173
0.05	0.247
0.1  	0.349
0.2		0.486
0.3		0.584
0.4		0.663
0.5  	0.733
1    	1
*/
vec3 fix_unshaded(vec3 xy) {
	return 0.9999857*pow(xy, vec3(2.223058));
}

void fragment() {
	ALBEDO = fix_unshaded(vec3(UV, VERTEX.z));
}
