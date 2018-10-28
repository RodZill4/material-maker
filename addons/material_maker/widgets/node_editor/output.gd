tool
extends HBoxContainer

func _ready():
	pass

func set_model_data(data):
	if data.has("rgb"):
		$Type.selected = 1
		$Value.text = data.rgb
	elif data.has("rgba"):
		$Type.selected = 2
		$Value.text = data.rgba
	elif data.has("f"):
		$Type.selected = 0
		$Value.text = data.f

func get_model_data():
	if $Type.selected == 1:
		return { rgb=$Value.text }
	elif $Type.selected == 2:
		return { rgba=$Value.text }
	else:
		return { f=$Value.text }

func _on_Delete_pressed():
	queue_free()
