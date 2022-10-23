extends "res://addons/material_maker/sdf_builder/tex/fbm.gd"


func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
		{ label="Value", name="value", type="float", min=0.0, max=1.0, step=0.01, default=1.0 }		]

func get_includes():
	return [ ]

func get_color_code_gs(ctxt : Dictionary = { uv="$uv" }):
		return "$value"
