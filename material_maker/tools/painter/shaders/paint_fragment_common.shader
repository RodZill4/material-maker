	// Get UV from seams texture
	vec2 uv;
	
	vec2 xy;
	vec2 b;
	vec2 bv;
	vec2 bs;
	vec4 tex2view;
	// Get View position
	if (texture_space) {
		uv = UV;
		tex2view = vec4(1.0);
		xy = uv;
		float min_size = min(rect_size.x, rect_size.y);
		bs = vec2(brush_size)/min_size;
		b = ((brush_pos-0.5*rect_size)*texture_scale/min_size+texture_center)/bs;
		bv = ((brush_ppos-brush_pos)*texture_scale/min_size)/bs;
	} else {
		uv = seams_uv(UV);
		tex2view = texture(tex2view_tex, uv);
		xy = tex2view.xy;
		bs = vec2(brush_size)/rect_size;
		b = brush_pos/rect_size/bs;
		bv = (brush_ppos-brush_pos)/rect_size/bs;
	}
	// Get distance to brush center
	vec2 p = xy/bs;
	float x = clamp(dot(p-b, bv)/dot(bv, bv), 0.0, 1.0);
	// Get position in brush
	vec2 local_uv = p-(b+x*bv);
