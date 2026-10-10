class_name ColorSwap
extends Resource

@export var name : String = ""

## Original color to be replaced
@export var orig : Color = Color():
	set(val):
		orig = val
		emit_changed()

## Replacement color
@export var target : Color = Color():
	set(val):
		target = val
		emit_changed()


func _init(_orig : Color =Color(), _target : Color =Color()) -> void:
	orig = _orig
	target = _target
