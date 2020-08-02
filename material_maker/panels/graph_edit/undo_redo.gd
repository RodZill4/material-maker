extends Node

var stack = []
var available_undos = 0

func _ready():
	pass # Replace with function body.

func can_undo() -> bool:
	return available_undos > 0

func undo() -> void:
	print("undo")

func can_redo() -> bool:
	return available_undos < stack.size()

func redo() -> void:
	print("redo")

func add_action(action_name : String, actions : Array) -> void:
	stack.append( { name:action_name, actions: actions} )
	available_undos += 1
