extends "res://addons/material_maker/sdf_builder/sdf2d/union.gd"


export var channel_name : String
export(int, "greyscale", "rgb", "rgba") var type : int


func _ready():
	pass # Replace with function body.

func get_children_types():
	return [ "TEX" ]

func get_parameter_defs():
	return [
		{ label="Local", name="local", type="boolean", default=false },
	]

func get_includes():
	return [ ]

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var data : Dictionary = { parameters=[] }
	for s in scene.children:
		var data2 = mm_sdf_builder.scene_to_shader_model(s, uv, editor)
		if data2.has("parameters"):
			data.parameters.append_array(data2.parameters)
	return data

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> Dictionary:
	if channel_name != ctxt.channel:
		return {}
	var ctxt2 : Dictionary = ctxt.duplicate()
	ctxt2.geometry = "sdf2d"
	if scene.parameters.has("local") and scene.parameters.local:
		ctxt2.uv = ctxt.local_uv
	for s in scene.children:
		var color_code : Dictionary = mm_sdf_builder.get_color_code(s, ctxt2, editor)
		if ! color_code.empty():
			return { color = ctxt.target+" = "+color_code.color+";" }
	return {}
