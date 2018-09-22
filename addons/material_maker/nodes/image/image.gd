tool
extends "res://addons/material_maker/node_base.gd"

var file_path = null

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))

func set_texture(path):
	file_path = path
	var texture = ImageTexture.new()
	if path != null:
		texture.load(path)
	$TextureButton.texture_normal = texture
	update_shaders()

func get_textures():
	var list = {}
	list[name] = $TextureButton.texture_normal
	return list

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "uniform sampler2D %s_tex;\n" % [ name ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "vec3 %s_%d_rgb = texture(%s_tex, %s).rgb;\n" % [ name, variant_index, name, uv ]
	rv.rgb = "%s_%d_rgb" % [ name, variant_index ]
	return rv

func _on_TextureButton_pressed():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.png;PNG image")
	dialog.add_filter("*.jpg;JPG image")
	dialog.connect("file_selected", self, "set_texture")
	dialog.popup_centered()

func serialize():
	var data = .serialize()
	data.file_path = file_path
	return data

func deserialize(data):
	if data.has("file_path"):
		set_texture(data.file_path)
	.deserialize(data)
