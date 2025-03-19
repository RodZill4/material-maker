extends "res://material_maker/panels/preview_2d/preview_2d_panel.gd"


var view_style : int = 0


func generate_preview_shader(source : MMGenBase.ShaderCode, _template) -> String:
	var variables : Dictionary = {}
	variables.GENERATED_GLOBALS = source.uniforms_as_strings()
	variables.GENERATED_GLOBALS += source.get_globals_string()
	variables.GENERATED_INSTANCE = source.defs
	variables.GENERATED_CODE = source.code
	if source.output_type == "sdf2d":
		variables.VIEW_STYLE = str(view_style)
		variables.GENERATED_OUTPUT = source.output_values.sdf2d
		var node_prefix = source.output_values.sdf2d.left(source.output_values.sdf2d.find("_"))
		variables.DIST_FCT = node_prefix+"_d"
		variables.COLOR_FCT = node_prefix+"_c"
		variables.INDEX_UNIFORM = "p_"+node_prefix+"_index"
	return mm_preprocessor.preprocess_file("res://material_maker/windows/sdf_builder/preview_2d.gdshader", variables)


func _on_View_item_selected(index):
	view_style = index
	material.set_shader_parameter("view_style", view_style)
