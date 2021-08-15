shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D tex2view_tex;
uniform float     texture_size = 512.0;
uniform sampler2D seams : hint_white;
uniform float     seams_multiplier = 256.0;
uniform sampler2D mesh_normal_tex;
uniform sampler2D layer_albedo_tex;
uniform sampler2D layer_mr_tex;
uniform sampler2D layer_emission_tex;
uniform sampler2D layer_depth_tex;

uniform bool      erase             = false;
uniform bool      fill              = false;
uniform bool      reset             = false;
uniform float     pressure          = 1.0;
uniform vec2      brush_pos         = vec2(0.5, 0.5);
uniform vec2      brush_ppos        = vec2(0.5, 0.5);
uniform vec2      brush_size        = vec2(0.25, 0.25);
uniform float     brush_hardness    = 0.5;
uniform float     stroke_length     = 0.0;
uniform float     stroke_angle      = 0.0;
uniform float     brush_opacity     = 1.0;
uniform float     pattern_scale     = 10.0;
uniform float     pattern_angle     = 0.0;
