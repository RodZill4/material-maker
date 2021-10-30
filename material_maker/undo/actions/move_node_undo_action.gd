extends UndoAction
class_name MoveNodeUndoAction

var from_position:Vector2
var to_position:Vector2

var node:GraphNode

func do():
	node.offset = to_position
	pass
func undo():
	node.offset = from_position
	pass
