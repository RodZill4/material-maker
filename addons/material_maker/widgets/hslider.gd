tool
extends HSlider

func _ready():
	update_label(value)

func set_value(v):
	.set_value(v)
	update_label(v)

func update_label(v):
	$Label.text = str(v)