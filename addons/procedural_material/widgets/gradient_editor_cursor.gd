tool
extends ColorRect

func _ready():
	pass

func _on_gui_input(ev):
	if ev is InputEventMouseButton && ev.button_index == 1 && ev.doubleclick:
		var dialog = ColorPicker.new()
		add_child(dialog)
	elif ev is InputEventMouseMotion && (ev.button_mask & 1) != 0:
		rect_position.x += ev.relative.x
		rect_position.x = min(max(0, rect_position.x), get_parent().rect_size.x-rect_size.x)
			
