extends PanelContainer

func _ready():
	pass # Replace with function body.

func set_layer(l) -> void:
	$VBoxContainer/LayerName.text = l.name
	var thumbnail_scene = preload("res://material_maker/panels/layers/layer_tooltip_thumbnail.tscn")
	for c in l.get_channels():
		if c == "mr":
			var t = thumbnail_scene.instance()
			t.init_m(l)
			$VBoxContainer/Thumbnails.add_child(t)
			t = thumbnail_scene.instance()
			t.init_r(l)
			$VBoxContainer/Thumbnails.add_child(t)
		else:
			var t = thumbnail_scene.instance()
			t.init(l, c)
			$VBoxContainer/Thumbnails.add_child(t)
