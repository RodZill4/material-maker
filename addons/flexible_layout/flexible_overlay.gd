extends ColorRect


var flex_layout

var arrow_icon = preload("res://addons/flexible_layout/arrow.svg")
var tab_icon = preload("res://addons/flexible_layout/tab.svg")


func find_position_from_target(at_position, target):
	const POSITIONS = [ -1, 1, -1, 2, 0, 3, -1, 4, -1]
	var pos_x = int(3*(at_position.x-target.rect.position.x) / target.rect.size.x)
	var pos_y = int(3*(at_position.y-target.rect.position.y) / target.rect.size.y)
	return POSITIONS[pos_x+3*pos_y]

func _drop_data(at_position, data):
	at_position /= get_window().content_scale_factor
	var target = flex_layout.get_flexnode_at(at_position)
	if target:
		var destination = find_position_from_target(at_position, target)
		if destination != -1:
			flex_layout.move_panel(data, target, destination)

func _can_drop_data(at_position, data):
	at_position /= get_window().content_scale_factor
	var target = flex_layout.get_flexnode_at(at_position)
	if target:
		var rect : Rect2 = target.rect
		match find_position_from_target(at_position, target):
			0:
				if data.flex_panel.get_meta("flex_node") == target:
					$Arrow.visible = false
					return false
				$Arrow.visible = true
				$Arrow.texture = tab_icon
				$Arrow.position = rect.get_center()-Vector2(32, 32)
				$Arrow.rotation_degrees = 0
			1:
				$Arrow.visible = true
				$Arrow.texture = arrow_icon
				$Arrow.position = Vector2(rect.get_center().x-32, rect.position.y)
				$Arrow.rotation_degrees = 0
			2:
				$Arrow.visible = true
				$Arrow.texture = arrow_icon
				$Arrow.position = Vector2(rect.position.x, rect.get_center().y-32)
				$Arrow.rotation_degrees = -90
			3:
				$Arrow.visible = true
				$Arrow.texture = arrow_icon
				$Arrow.position = Vector2(rect.end.x-64, rect.get_center().y-32)
				$Arrow.rotation_degrees = 90
			4:
				$Arrow.visible = true
				$Arrow.texture = arrow_icon
				$Arrow.position = Vector2(rect.get_center().x-32, rect.end.y-64)
				$Arrow.rotation_degrees = 180
			_:
				$Arrow.visible = false
				return false
	return true

