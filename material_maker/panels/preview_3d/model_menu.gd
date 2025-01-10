extends PanelContainer


func _ready() -> void:
	await owner.ready
	update_model_selector()


func update_model_selector() -> void:
	%Model.clear()
	for i in owner.objects.get_child_count():
		var o = owner.objects.get_child(i)
		#var thumbnail := load("res://material_maker/panels/preview_3d/thumbnails/meshes/%s.png" % o.name)
		#if thumbnail:
			#%Model.add_icon_item(thumbnail, o.name, i)
		#else:
		%Model.add_item(o.name, i)


func _on_model_item_selected(index: int) -> void:
	owner.set_model(index)

#
#func _on_generate_map_header_toggled(toggled_on: bool) -> void:
	#%GenerateMapSection.visible = toggled_on
	#size = Vector2()


func _on_model_configurate_pressed() -> void:
	owner.configure_model()


func _on_speed_pause_toggled(toggled_on: bool) -> void:
	owner.set_rotate_model_speed(0)


func _on_speed_slow_toggled(toggled_on: bool) -> void:
	owner.set_rotate_model_speed(0.01)


func _on_speed_medium_toggled(toggled_on: bool) -> void:
	owner.set_rotate_model_speed(0.05)


func _on_speed_fast_toggled(toggled_on: bool) -> void:
	owner.set_rotate_model_speed(0.1)
