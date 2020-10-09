extends Spatial


func _ready() -> void:
	var thumb_size := 100
	var material: Material = preload("res://material_maker/panels/preview_3d/materials/thumbnail.material")
	var viewport := $ThumbnailGeneration
	var name_label := $ThumbnailGeneration/VBoxContainer/CenterContainer/Name
	
	viewport.size = Vector2(thumb_size, thumb_size)
	
	for c in get_children():
		if c is Viewport:
			continue
		
		remove_child(c)
		viewport.add_child(c)
		c.show()
		name_label.text = " %s " % c.name
		c.material_override = material
		
		yield(get_tree(), "idle_frame") # render
		
		c.thumbnail = ImageTexture.new()
		c.thumbnail.create_from_image(viewport.get_texture().get_data())
		
		viewport.remove_child(c)
		add_child(c)
		c.hide()
		name_label.text = ""
		c.material_override = null
	
	viewport.queue_free()


