extends "res://material_maker/panels/preview_2d/preview_2d_panel.gd"


var view_style : int = 0


func _ready():
	pass # Replace with function body.

func generate_preview_shader(source, template) -> String:
	var variables : Dictionary = {}
	variables.GENERATED_GLOBALS = PoolStringArray(source.globals).join("\n") if source.has("globals") else ""
	variables.GENERATED_INSTANCE = source.defs
	variables.GENERATED_CODE = source.code
	if source.has("sdf2d"):
		variables.VIEW_STYLE = str(view_style)
		variables.GENERATED_OUTPUT = source.sdf2d
		var node_prefix = source.sdf2d.left(source.sdf2d.find("_"))
		variables.DIST_FCT = node_prefix+"_d"
		variables.COLOR_FCT = node_prefix+"_c"
		variables.INDEX_UNIFORM = "p_"+node_prefix+"_index"
	return mm_preprocessor.preprocess_file("res://material_maker/windows/sdf_builder/preview_2d.shader", variables)


func _on_View_item_selected(index):
	view_style = index
	material.set_shader_param("view_style", view_style)
