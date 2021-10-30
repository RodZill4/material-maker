extends Node

var stack = []
var position = 0
var lock = false

var composite

func _ready():
	pass # Replace with function body.

func can_undo() -> bool:
	return position > 0 && stack.size() > 0
func can_redo() -> bool:
	return position + 1 < stack.size()


func undo() -> void:
	if !can_undo():	return
	var action = stack[position]
	
	lock = true
	
	action.undo()
	
	lock = false
	position -= 1
	position = clamp(position, 0, stack.size() - 1)

func redo() -> void:
	if !can_redo():	return
	position += 1
	var action = stack[position]
	lock = true
	action.do()
	lock = false
	position = clamp(position, 0, stack.size() - 1)

func add_action(action) -> void:
	if lock:	return

	for i in range(position + 1, stack.size()):
		stack[i].destroy()
	stack = stack.slice(0, position)
	
	if composite != null:
		composite.actions.append(action)
	else:
		stack.append(action)
	position = stack.size() - 1
	
	
# creates a composite action, adds every action into the composite until end_composite is called
func begin_composite():
	var new_composite = CompositeUndoAction.new()
	add_action(new_composite)
	composite = new_composite

func end_composite():
	composite = null
