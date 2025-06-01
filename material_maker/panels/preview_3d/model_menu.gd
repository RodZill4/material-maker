extends PanelContainer


const SETTING_3D_PREVIEW_MODEL : String = "3D_preview_model"
const SETTING_3D_PREVIEW_CUSTOM_MODELS : String = "3D_preview_custom_models"
const SETTING_3D_PREVIEW_ROTATION_SPEED : String = "3D_preview_rotation_speed"
const MAX_CUSTOM_MODELS : int = 5

var custom_models : PackedStringArray = PackedStringArray()

@onready var preview3D := owner

@onready var Model := %Model
@onready var SpeedPause := %Speed_Pause
@onready var SpeedSlow := %Speed_Slow
@onready var SpeedMedium := %Speed_Medium
@onready var SpeedFast := %Speed_Fast

@onready var SnapTop := %SnapTop
@onready var SnapFront := %SnapFront
@onready var SnapRight := %SnapRight

enum SnapView {Top, Front, Right}

func _ready() -> void:
	await preview3D.ready
	
	await get_tree().process_frame
	
	if mm_globals.has_config(SETTING_3D_PREVIEW_CUSTOM_MODELS):
		custom_models = mm_globals.get_config(SETTING_3D_PREVIEW_CUSTOM_MODELS).split(";")

	update_model_selector()

	if mm_globals.has_config(SETTING_3D_PREVIEW_MODEL):
		var custom_model : String = ""
		if custom_models.size() > 0:
			custom_model = custom_models[0]
		Model.select(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))
		_on_model_item_selected(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL), custom_model)
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
	var objects_count : int = preview3D.objects.get_child_count()
	Model.clear()
	for i in objects_count:
		var o: Node = preview3D.objects.get_child(i)
		Model.add_item(o.name, i)
	for i in min(custom_models.size(), MAX_CUSTOM_MODELS):
		Model.add_item(custom_models[i].get_file(), i+objects_count)


func _on_model_item_selected(index: int, custom_model_path : String = "") -> void:
	var objects_count : int = preview3D.objects.get_child_count()
	if index >= objects_count:
		custom_model_path = custom_models[index-objects_count]
		index = objects_count-1
	if await preview3D.set_model(index, custom_model_path):
		mm_globals.set_config(SETTING_3D_PREVIEW_MODEL, index)
		get_node("../../ExportMenu").visible = ( Model.get_item_text(index) == "Custom" )
		custom_model_path = preview3D.get_current_model_path()
		if custom_model_path != "":
			while true:
				var i = custom_models.find(custom_model_path)
				if i == -1:
					break
				custom_models.remove_at(i)
			custom_models.insert(0, custom_model_path)
			update_model_selector()
			Model.selected = objects_count
			mm_globals.set_config(SETTING_3D_PREVIEW_CUSTOM_MODELS, ";".join(custom_models))

	# Return to the previous model, if the selection failed (can happen on custom models)
	elif mm_globals.has_config(SETTING_3D_PREVIEW_MODEL):
		Model.select(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))
		_on_model_item_selected(mm_globals.get_config(SETTING_3D_PREVIEW_MODEL))
	else:
		Model.select(0)
		_on_model_item_selected(0)


func _on_model_configurate_pressed() -> void:
	preview3D.configure_model()


func _on_speed_pause_toggled(_toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 0)
	preview3D.set_rotate_model_speed(0)


func _on_speed_slow_toggled(_toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 1)
	preview3D.set_rotate_model_speed(0.01)


func _on_speed_medium_toggled(_toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 2)
	preview3D.set_rotate_model_speed(0.05)


func _on_speed_fast_toggled(_toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_3D_PREVIEW_ROTATION_SPEED, 3)
	preview3D.set_rotate_model_speed(0.1)


func _process(delta: float) -> void:
	var shift_down : bool = Input.is_key_pressed(KEY_SHIFT)
	SnapTop.text = "Bottom" if shift_down else "Top"
	SnapFront.text = "Back" if shift_down else "Front"
	SnapRight.text = "Left" if shift_down else "Right"


func _on_snap_pressed(id: int) -> void:
	var tween := get_tree().create_tween()
	var pivot := preview3D.get_node("MaterialPreview/Preview3d/ObjectsPivot/Objects")
	var cam_control := preview3D.get_node("MaterialPreview/Preview3d/CameraController")
	var camrot2 : Node3D = preview3D.camera_controller.camera_rotation2
	var camrot1 : Node3D = preview3D.camera_controller.camera_rotation1
	var rot2 := camrot2.rotation
	var rot1 := Vector3(camrot1.rotation.x, 0.0, camrot2.rotation.z)
	match id:
		SnapView.Top:
			rot2.x = -PI * (-0.5 if Input.is_key_pressed(KEY_SHIFT) else 0.5)
			rot1.y = 0.0
		SnapView.Front:
			rot2.x = 0.0
			rot1.y = PI * (1.0 if Input.is_key_pressed(KEY_SHIFT) else 0.0)
		SnapView.Right:
			rot2.x = 0.0
			rot1.y = -PI * (0.5 if Input.is_key_pressed(KEY_SHIFT) else -0.5)
	# Snap view
	tween.tween_property(camrot2, "rotation", rot2, 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(camrot1, "rotation", rot1, 0.2).set_trans(Tween.TRANS_CUBIC)
	# Reset center
	tween.parallel().tween_property(pivot, "transform:origin", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(cam_control, "transform:origin", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_CUBIC)
