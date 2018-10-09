tool
extends HBoxContainer

func _ready():
	pass

func set_model_data(data):
	if data.has("rgb"):
		$Type.selected = 1
		$Default.text = data.rgb
	elif data.has("f"):
		$Type.selected = 0
		$Default.text = data.f

func get_model_data():
	if $Type.selected == 1:
		return { rgb=$Default.text }
	else:
		return { f=$Default.text }

func _on_Delete_pressed():
	queue_free()
