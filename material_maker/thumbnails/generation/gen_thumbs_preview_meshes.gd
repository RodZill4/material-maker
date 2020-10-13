extends Spatial

signal generated_thumbnails


export var thumb_size := 85
export var show_names := false


func _ready() -> void:
	yield(get_tree(), "idle_frame")
	
	var objects := $Objects
	var material: Material = preload("res://material_maker/thumbnails/generation/thumbnail_mesh.material")
	var viewport: Viewport = $ThumbnailGeneration
	var name_label := $ThumbnailGeneration/VBoxContainer/CenterContainer/Name
	
	viewport.size = Vector2(thumb_size, thumb_size)
	name_label.visible = show_names
	
	for c in objects.get_children():
		objects.remove_child(c)
		viewport.add_child(c)
		c.show()
		name_label.text = " %s " % c.name
		var use_default_material: bool = (c.material_override == null)
		if use_default_material:
			c.material_override = material
		
		yield(get_tree(), "idle_frame") # render
		
		viewport.get_texture().get_data().save_png("res://material_maker/thumbnails/meshes/%s.png" % c.name)
		
#		c.thumbnail = ImageTexture.new()
#		c.thumbnail.create_from_image(viewport.get_texture().get_data())
		
		viewport.remove_child(c)
		objects.add_child(c)
		c.hide()
		name_label.text = ""
		if use_default_material:
			c.material_override = null
	emit_signal("generated_thumbnails")
	queue_free()
