extends Node

var stack = []
var step = 0

func _ready():
	pass # Replace with function body.

func can_undo() -> bool:
	return step > 0

func undo() -> void:
	if step > 0:
		step -= 1
		for a in stack[step].undo_actions:
			get_parent().undoredo_command(a)

func can_redo() -> bool:
	return step < stack.size()

func redo() -> void:
	if step < stack.size():
		for a in stack[step].redo_actions:
			get_parent().undoredo_command(a)
		step += 1

func compare_actions(a, b):
	if a == b:
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if ! compare_actions(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		if ! compare_actions(a.keys(), b.keys()):
			return false
		for k in a.keys():
			if ! compare_actions(a[k], b[k]):
				return false
		return true
	return false

func add(action_name : String, undo_actions : Array, redo_actions : Array, merge_with_previous : bool = false) -> void:
	while stack.size() > step:
		stack.pop_back()
	if merge_with_previous and step > 0 and compare_actions(undo_actions, stack.back().redo_actions):
		stack.back().redo_actions = redo_actions
	else:
		var undo_redo = { name= action_name, undo_actions= undo_actions, redo_actions= redo_actions }
		stack.push_back(undo_redo)
		step += 1
	get_node("/root/MainWindow/UndoRedoLabel").show()
