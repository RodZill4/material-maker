extends Spatial


export var thumb_size := 32
export var show_names := true


func _ready() -> void:
	yield(get_tree(), "idle_frame")
	
	var env := $Environments
	var viewport: Viewport = $ThumbnailGeneration
	var name_label := $ThumbnailGeneration/VBoxContainer/CenterContainer/Name
	
	viewport.size = Vector2(thumb_size, thumb_size)
	name_label.visible = show_names
	
	for c in env.get_children():
		env.remove_child(c)
		viewport.add_child(c)
		c.show()
		viewport.world.environment = c.environment
		name_label.text = "%s" % c.name
		
		yield(get_tree(), "idle_frame") # render
		
		viewport.get_texture().get_data().save_png("res://material_maker/panels/preview_3d/thumbnails/environments/%s.png" % c.name)
		print("Generated %s.png" % c.name)
		
		viewport.remove_child(c)
		c.queue_free()
	
	get_tree().quit()
