extends MMGraphNodeBase

func _ready():
	super._ready()

func _on_Button_pressed() -> void:
	print("debug")
	var src = generator.get_source(0)
	if src != null:
		var context : MMGenContext = MMGenContext.new()
		var source = src.generator.get_shader_code("UV", src.output_index, context)
		var popup = preload("res://material_maker/nodes/debug/debug_popup.tscn").instantiate()
		get_parent().add_child(popup)
		popup.show_code(source)
