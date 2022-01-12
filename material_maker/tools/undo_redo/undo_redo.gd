extends Node

const VERBOSE: bool = true

var stack: Array = []
var step: int = 0

var group_level: int = 0
var group = null

var performing_action: bool = false


func _ready():
	pass  # Replace with function body.


func can_undo() -> bool:
	return step > 0


func undo() -> void:
	if !performing_action and step > 0:
		print("Undo...")
		performing_action = true
		step -= 1
		var parent = get_parent()
		var state = ""
		if parent.has_method("undoredo_pre"):
			state = parent.undoredo_pre()
		for a in stack[step].undo_actions:
			if VERBOSE and OS.is_debug_build():
				print("Executing undo action on %s:" % str(parent))
				print(a)
			parent.undoredo_command(a)
		if parent.has_method("undoredo_post"):
			parent.undoredo_post(state)
		performing_action = false


func can_redo() -> bool:
	return step < stack.size()


func redo() -> void:
	if !performing_action and step < stack.size():
		print("Redo...")
		performing_action = true
		var parent = get_parent()
		var state = ""
		if parent.has_method("undoredo_pre"):
			state = parent.undoredo_pre()
		for a in stack[step].redo_actions:
			if VERBOSE and OS.is_debug_build():
				print("Executing redo action on %s:" % str(parent))
				print(a)
			parent.undoredo_command(a)
		if parent.has_method("undoredo_post"):
			parent.undoredo_post(state)
		step += 1
		performing_action = false


func compare_actions(a, b):
	if a == b:
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if !compare_actions(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		if !compare_actions(a.keys(), b.keys()):
			return false
		for k in a.keys():
			if !compare_actions(a[k], b[k]):
				return false
		return true
	return false


func start_group():
	group_level += 1
	if group_level == 1:
		group = null


func end_group():
	if group_level <= 0:
		return
	group_level -= 1
	if group_level == 0:
		group = null


func add(
	action_name: String, undo_actions: Array, redo_actions: Array, merge_with_previous: bool = false
) -> void:
	if performing_action:
		print("ERROR: undo/redo action tries to register undo/redo action")
		return
	while stack.size() > step:
		stack.pop_back()
	if (
		merge_with_previous
		and step > 0
		and compare_actions(undo_actions, stack.back().redo_actions)
	):
		stack.back().redo_actions = redo_actions
	elif (
		merge_with_previous
		and step > 0
		and get_parent().has_method("undoredo_merge")
		and get_parent().undoredo_merge(action_name, undo_actions, redo_actions, stack.back())
	):
		pass
	elif group_level > 0 and group != null:
		undo_actions.append_array(stack.back().undo_actions)
		group.undo_actions = undo_actions
		group.redo_actions.append_array(redo_actions)
	else:
		var undo_redo = {
			name = action_name, undo_actions = undo_actions, redo_actions = redo_actions
		}
		stack.push_back(undo_redo)
		step += 1
		if group_level > 0:
			group = undo_redo
	get_node("/root/MainWindow/UndoRedoLabel").show_step(step)
