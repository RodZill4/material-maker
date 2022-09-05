extends "res://addons/material_maker/sdf_builder/base.gd"


func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ default=2, label="Noise", name="noise", type="enum", values=[
				{ name="Value", value="value" },
				{ name="Perlin", value="perlin" },
				{ name="Simplex", value="simplex" },
				{ name="Cellular", value="cellular" },
				{ name="Cellular2", value="cellular2" },
				{ name="Cellular3", value="cellular3" },
				{ name="Cellular4", value="cellular4" },
				{ name="Cellular5", value="cellular5" },
				{ name="Cellular6", value="cellular6" },
				{ name="Voronoise", value="voronoise" }
			] },
		{ default=4, label="Scale X", max=32, min=1, name="scale_x", step=1, type="float" },
		{ default=4, label="Scale Y", max=32, min=1, name="scale_y", step=1, type="float" },
		{ default=4, label="Scale Z", max=32, min=1, name="scale_z", step=1, type="float" },
		{ default=0, label="Folds", max=5, min=0, name="folds", step=1, type="float" },
		{ default=3, label="Iterations", max=10, min=1, name="iterations", step=1, type="float" },
		{ default=0.5, label="Persistence", max=1, min=0, name="persistence", step=0.01, type="float" },
		{ default=0, label="Offset", max=1, min=0, name="offset", step=0.01, type="float" }
	]

func get_includes():
	return [ "fbm2", "tex3d_fbm" ]

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var data : Dictionary = { parameters=[] }
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, uv, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
	return data

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false):
	var tex : String
	print(ctxt)
	if ctxt.has("geometry") and ctxt.geometry == "sdf3d":
		tex = "fbm3d_$noise("+ctxt.uv+", vec3($scale_x, $scale_y, $scale_z), int($iterations), $persistence, 0.0)"
	else:
		tex = "fbm_2d_$noise("+ctxt.uv+", vec2($scale_x, $scale_y), int($folds), int($iterations), $persistence, $offset, 0.0)"
	match ctxt.type:
		"rgba":
			return "vec4(vec3("+tex+"), 1.0)"
		"color":
			return "vec3("+tex+")"
		"float":
			return tex 
	return ""
