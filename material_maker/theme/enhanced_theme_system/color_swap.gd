class_name ColorSwap
extends Resource

@export var orig := Color():
	set(val):
		orig = val
		emit_changed()

@export var target := Color():
	set(val):
		target = val
		emit_changed()


func _init(_orig:=Color(), _target:=Color()):
	orig = _orig
	target = _target
