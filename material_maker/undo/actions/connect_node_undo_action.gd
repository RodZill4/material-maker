extends UndoAction
class_name ConnectNodeUndoAction


var graph_edit

var from
var from_slot
var to
var to_slot

func do():
	graph_edit.connect_node(from,from_slot,to,to_slot)
	pass
func undo():
	graph_edit.disconnect_node(from,from_slot,to,to_slot)
	pass
