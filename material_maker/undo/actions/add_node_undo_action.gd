extends UndoAction
class_name AddNodeUndoAction

var graph_edit
var node

func do():
	graph_edit.add_child(node)
	pass
func undo():
	graph_edit.remove_node(node)
	pass
func destroy():
	graph_edit.destroy_node(node)
