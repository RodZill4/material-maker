extends Label

func _ready():
	pass # Replace with function body.

func _on_AchievementSection_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var section = get_parent().get_child(get_index()+1)
		section.visible = !section.visible
