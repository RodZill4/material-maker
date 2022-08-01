extends Node

export var item_type : String
export var item_category : String
export var icon : Texture

func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Color", name="color", type="color", default={ r=1.0, g=1.0, b=1.0, a=1.0 } }
	]

func get_includes():
	return [ ]

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf2d=output_name, type="sdf2d" } ] }
	data.code = "vec2 %s_p = %s;\n" % [ output_name, uv ]
	return data
