extends "res://addons/material_maker/sdf_builder/sdf3d/boolean/union.gd"

func _ready():
	pass # Replace with function body.

func get_children_types():
	return [ "SDF3D", "SDF3D_COLOR", "TEX" ]

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.z", name="position_z", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Rotation.x", name="angle_x", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.y", name="angle_y", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.z", name="angle_z", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0 },
		{ label="Amount", name="amount", type="float", min=0.0, max=1.0, step=0.01, default=0.1 }
	]

func get_includes():
	return [ "rotate" ]

func mod_code(scene : Dictionary, output_name : String, editor : bool) -> String:
	for s in scene.children:
		if mm_sdf_builder.item_types[mm_sdf_builder.item_ids[s.type]].item_category != "TEX":
			continue
		var ctxt : Dictionary = { uv=output_name+"_p", geometry="sdf3d", type="float", glsl_type="float" }
		var distort_map : Dictionary = mm_sdf_builder.get_color_code(s, ctxt, editor)
		if distort_map.has("color"):
			return "%s += $amount*(%s-0.5);\n" % [ output_name, distort_map.color ]
	return ""

func get_coloring_tolerance() -> String:
	return "0.001+$amount"
