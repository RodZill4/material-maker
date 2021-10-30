extends UndoAction
class_name CompositeUndoAction

var actions = []

func do():
	for action in actions:
		action.do()
func undo():
	for action in actions:
		action.undo()
