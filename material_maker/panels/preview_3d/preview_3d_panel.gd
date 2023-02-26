extends "res://material_maker/panels/preview_3d/preview_3d.gd"


@export var click_material : Material

var new_pivot_position : Vector3


func _ready():
	pass # Replace with function body.

func on_right_click():
	# Hide viewport while we capture the position
	var hide_texture : ImageTexture = ImageTexture.new()
	hide_texture.create_from_image($MaterialPreview.get_texture().get_image())
	$TextureRect.texture = hide_texture
	$TextureRect.size = size
	$TextureRect.visible = true
	# Setup local position rendering
	var material_save = current_object.get_surface_override_material(0)
	var aabb = current_object.get_aabb()
	current_object.set_surface_override_material(0, click_material)
	click_material.set_shader_parameter("aabb_position", aabb.position)
	click_material.set_shader_parameter("aabb_size", aabb.size)
	# Render
	#todo $MaterialPreview.keep_3d_linear = true
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	# Pick position in image
	var texture : ViewportTexture = $MaterialPreview.get_texture()
	var image : Image = texture.get_image()
	var mouse_position = get_local_mouse_position()*$MaterialPreview.size/size
	mouse_position.y = $MaterialPreview.size.y-mouse_position.y
	var position_color : Color = image.get_pixelv(mouse_position)
	var pos : Vector3 = Vector3(position_color.r, position_color.g, position_color.b)
	pos -= Vector3(0.5, 0.5, 0.5)
	pos *= aabb.size
	new_pivot_position = -pos
	# Reset normal rendering
	current_object.set_surface_override_material(0, material_save)
	$MaterialPreview.keep_3d_linear = false
	$TextureRect.visible = false
	$PopupMenu.popup(Rect2(get_global_mouse_position(), $PopupMenu.get_minimum_size()))

func _on_PopupMenu_id_pressed(id):
	var pivot = get_node("MaterialPreview/Preview3d/ObjectsPivot/Objects")
	match id:
		0:
			pivot.transform.origin = Vector3(0, 0, 0)
		1:
			pivot.transform.origin = new_pivot_position

func _on_Preview3D_mouse_entered():
	mm_globals.set_tip_text("#LMB: Rotate view, #RMB: Tilt view, Mouse wheel: Zoom", 3)
