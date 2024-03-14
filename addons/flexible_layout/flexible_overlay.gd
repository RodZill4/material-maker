extends ColorRect


var flex_layout

var arrow_icon = preload("res://addons/flexible_layout/arrow.svg")
var tab_icon = preload("res://addons/flexible_layout/tab.svg")


const MARKER_WIDTH : int = 10
const ARROW_OFFSET : int = 5


func find_position_from_target(at_position, target) -> int:
	const POSITIONS = [ -1, 1, -1, 2, 0, 3, -1, 4, -1]
	var pos_x = int(3*(at_position.x-target.rect.position.x) / target.rect.size.x)
	var pos_y = int(3*(at_position.y-target.rect.position.y) / target.rect.size.y)
	return POSITIONS[pos_x+3*pos_y]

func _drop_data(at_position, data):
	var target = flex_layout.get_flexnode_at(at_position)
	if target:
		var destination = find_position_from_target(at_position, target)
		if destination != -1:
			flex_layout.move_panel(data, target, destination)

func _can_drop_data(at_position, data):
	var target = flex_layout.get_flexnode_at(at_position)
	if target:
		var rect : Rect2 = target.rect
		var destination : int = find_position_from_target(at_position, target)
		if not flex_layout.move_panel(data, target, destination, true):
			destination = -1
		match destination:
			0:
				$Arrow.visible = true
				$Arrow.texture = tab_icon
				$Arrow.position = rect.get_center()-Vector2(32, 32)
				$Arrow.rotation_degrees = 0
				$Rect.visible = true
				$Rect.position = rect.position
				$Rect.size = rect.size
			1:
				$Arrow.visible = true
				$Arrow.texture = arrow_icon
				$Arrow.position = Vector2(rect.get_center().x-32, rect.position.y+ARROW_OFFSET)
				$Arrow.rotation_degrees = 0
				$Rect.visible = true
				$Rect.position = rect.position
				$Rect.size = Vector2i(rect.size.x, MARKER_WIDTH)
			2:
				$Arrow.visible = true
				$Arrow.texture = arrow_icon
				$Arrow.position = Vector2(rect.position.x+ARROW_OFFSET, rect.get_center().y-32)
				$Arrow.rotation_degrees = -90
				$Rect.visible = true
				$Rect.position = rect.position
				$Rect.size = Vector2i(MARKER_WIDTH, rect.size.y)
			3:
				$Arrow.visible = true
				$Arrow.texture = arrow_icon
				$Arrow.position = Vector2(rect.end.x-64-ARROW_OFFSET, rect.get_center().y-32)
				$Arrow.rotation_degrees = 90
				$Rect.visible = true
				$Rect.position = Vector2i(rect.end.x-MARKER_WIDTH, rect.position.y)
				$Rect.size = Vector2i(MARKER_WIDTH, rect.size.y)
			4:
				$Arrow.visible = true
				$Arrow.texture = arrow_icon
				$Arrow.position = Vector2(rect.get_center().x-32, rect.end.y-64-ARROW_OFFSET)
				$Arrow.rotation_degrees = 180
				$Rect.visible = true
				$Rect.position = Vector2i(rect.position.x, rect.end.y-MARKER_WIDTH)
				$Rect.size = Vector2i(rect.size.x, MARKER_WIDTH)
			_:
				$Arrow.visible = false
				$Rect.visible = false
				return false
	return true

