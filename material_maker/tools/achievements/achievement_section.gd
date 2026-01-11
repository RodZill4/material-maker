extends Label

func _ready():
	pass # Replace with function body.

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.RED, false)

func _on_AchievementSection_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var section = get_parent().get_child(get_index()+1)
		section.visible = !section.visible
