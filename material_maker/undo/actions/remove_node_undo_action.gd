extends UndoAction
class_name RemoveNodeUndoAction

var graph_edit
var node
var connections = []

func do():
	graph_edit.remove_node(node)
	pass
func undo():
	graph_edit.add_child(node)
	pass
