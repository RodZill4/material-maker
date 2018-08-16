tool
extends WindowDialog

func _ready():
	pass

func set_object(o):
	$PaintTool.set_mesh(o.name, o.mesh)
