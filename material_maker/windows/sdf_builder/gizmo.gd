extends Spatial


signal translated(v)
signal rotated(v, a)


func _ready():
	pass # Replace with function body.

func _on_Arrow_move(v):
	translation += v
	emit_signal("translated", v)

func _on_Arrow_rotate(v, a):
	emit_signal("rotated", v, a)
