@tool
extends Node3D


@export var mode = 1 setget set_mode # (int, "NONE", "SDF2D", "SDF3D")


signal translated(v)
signal rotated(v, a)


func _ready():
	set_mode(mode)

func set_mode(m):
	mode = m
	if is_inside_tree():
		match mode:
			0:
				$ArrowX.mode = 3
				$ArrowY.mode = 3
				$ArrowZ.mode = 3
			1:
				$ArrowX.mode = 1
				$ArrowY.mode = 1
				$ArrowZ.mode = 2
			2:
				$ArrowX.mode = 0
				$ArrowY.mode = 0
				$ArrowZ.mode = 0

func _on_Arrow_move(v):
	position += v
	emit_signal("translated", v)

func _on_Arrow_rotate(v, a):
	emit_signal("rotated", v, a)
