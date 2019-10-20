tool
extends HSlider

func _ready() -> void:
	update_label(value)

func set_value(v) -> void:
	.set_value(v)
	update_label(v)

func update_label(v) -> void:
	$Label.text = str(v)
