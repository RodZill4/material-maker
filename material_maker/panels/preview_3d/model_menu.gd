extends PanelContainer


const SETTING_3D_PREVIEW_MODEL := "3D_preview_model"
const SETTING_3D_PREVIEW_ROTATION_SPEED := "3D_preview_rotation_speed"

@onready var preview3D := owner

@onready var Model := %Model
@onready var SpeedPause := %Speed_Pause
@onready var SpeedSlow := %Speed_Slow
@onready var SpeedMedium := %Speed_Medium
@onready var SpeedFast := %Speed_Fast

func _ready() -> void:
	await preview3D.ready
	update_model_selector()

	if mm_globals.has_config(SETTING_3D_PREVIEW_MODEL):
		Model.select(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))
		_on_model_item_selected(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))
	else:
		_on_model_item_selected(0)

	if mm_globals.has_config(SETTING_3D_PREVIEW_ROTATION_SPEED):
		match mm_globals.get_config(SETTING_3D_PREVIEW_ROTATION_SPEED):
			0: SpeedPause.button_pressed = true
			1: SpeedSlow.button_pressed = true
			2: SpeedMedium.button_pressed = true
			3: SpeedFast.button_pressed = true

func _open() -> void:
	pass

func update_model_selector() -> void:
	Model.clear()
	for i in preview3D.objects.get_child_count():
		var o: Node = preview3D.objects.get_child(i)
		Model.add_item(o.name, i)


func _on_model_item_selected(index: int) -> void:
	if await preview3D.set_model(index):
		mm_globals.set_config(SETTING_3D_PREVIEW_MODEL, index)
		get_node("../../ExportMenu").visible = index == Model.item_count-1

	# Return to the previous model, if the selection failed (can happen on custom models)
	elif mm_globals.has_config(SETTING_3D_PREVIEW_MODEL):
		Model.select(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))
		_on_model_item_selected(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))
	else:
		Model.select(0)
		_on_model_item_selected(0)




func _on_model_configurate_pressed() -> void:
	preview3D.configure_model()


func _on_speed_pause_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 0)
	preview3D.set_rotate_model_speed(0)


func _on_speed_slow_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 1)
	preview3D.set_rotate_model_speed(0.01)


func _on_speed_medium_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 2)
	preview3D.set_rotate_model_speed(0.05)


func _on_speed_fast_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 3)
	preview3D.set_rotate_model_speed(0.1)
