extends PanelContainer


const SETTING_3D_PREVIEW_MODEL := "3D_preview_model"
const SETTING_3D_PREVIEW_ROTATION_SPEED := "3D_preview_rotation_speed"


func _ready() -> void:
	await owner.ready
	update_model_selector()

	if mm_globals.has_config(SETTING_3D_PREVIEW_MODEL):
		%Model.select(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))
		_on_model_item_selected(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))

	if mm_globals.has_config(SETTING_3D_PREVIEW_ROTATION_SPEED):
		match mm_globals.get_config(SETTING_3D_PREVIEW_ROTATION_SPEED):
			0: %Speed_Pause.button_pressed = true
			1: %Speed_Slow.button_pressed = true
			2: %Speed_Medium.button_pressed = true
			3: %Speed_Fast.button_pressed = true

func _open() -> void:
	pass

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
	mm_globals.set_config(SETTING_3D_PREVIEW_MODEL, index)
	owner.set_model(index)

#
#func _on_generate_map_header_toggled(toggled_on: bool) -> void:
	#%GenerateMapSection.visible = toggled_on
	#size = Vector2()


func _on_model_configurate_pressed() -> void:
	owner.configure_model()


func _on_speed_pause_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 0)
	owner.set_rotate_model_speed(0)


func _on_speed_slow_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 1)
	owner.set_rotate_model_speed(0.01)


func _on_speed_medium_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 2)
	owner.set_rotate_model_speed(0.05)


func _on_speed_fast_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 3)
	owner.set_rotate_model_speed(0.1)
