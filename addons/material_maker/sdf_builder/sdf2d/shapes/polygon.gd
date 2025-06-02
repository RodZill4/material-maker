extends "res://addons/material_maker/sdf_builder/sdf2d/boolean/union.gd"

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.x" },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0, control="P1.y" },
		{ label="Rotation", name="angle", type="float", min=-180.0, max=180.0, step=0.01, default=0.0, control="RotateScale1.a" },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0, control="RotateScale1.r" },
		{ label="Radius", name="radius", type="float", min=0.0, max=1.0, step=0.01, default=0.5 },
		{ label="Points", name="polygon", type="polygon", default= { points= [ {x= 0.2, y= 0.2 }, { x= 0.4, y= 0.7 }, { x= 0.7, y= 0.4 } ], type= "Polygon" } }
	]

func get_includes():
	return [ "rotate" ]

func shape_code_pre(scene : Dictionary, uv : String = "$uv") -> String:
	var code : String = ""
	code += "vec2 <prefix>uv = %s+vec2(0.5);" % [ uv ]
	code += "vec2 <prefix>v[] = $polygon;"
	code += "int <prefix>l = <prefix>v.length();"
	code += "float <prefix>d = dot(<prefix>uv-<prefix>v[0], <prefix>uv-<prefix>v[0]);"
	code += "float <prefix>s = 1.0;"
	code += "int <prefix>j = <prefix>l-1;"
	code += "for (int <prefix>i=0; <prefix>i<<prefix>l; <prefix>i++) {"
	code += "    vec2 <prefix>e = <prefix>v[<prefix>j] - <prefix>v[<prefix>i];"
	code += "    vec2 <prefix>w = <prefix>uv - <prefix>v[<prefix>i];"
	code += "    vec2 <prefix>b = <prefix>w - <prefix>e*clamp(dot(<prefix>w,<prefix>e)/dot(<prefix>e,<prefix>e), 0.0, 1.0 );"
	code += "    <prefix>d = min(<prefix>d, dot(<prefix>b, <prefix>b));"
	code += "    bvec3 <prefix>c = bvec3(<prefix>uv.y>=<prefix>v[<prefix>i].y,<prefix>uv.y<<prefix>v[<prefix>j].y,<prefix>e.x*<prefix>w.y><prefix>e.y*<prefix>w.x);"
	code += "    if (all(<prefix>c) || all(not(<prefix>c))) <prefix>s*=-1.0;"
	code += "    <prefix>j = <prefix>i;"
	code += "}"
	return code.replace("<prefix>", "$(name_uv)_n%d_" % scene.index)

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "<prefix>s*sqrt(<prefix>d)".replace("<prefix>", "$(name_uv)_n%d_" % scene.index)
