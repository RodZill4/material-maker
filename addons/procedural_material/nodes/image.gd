tool
extends "res://addons/procedural_material/node_base.gd"

var file_path = null

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))

func set_texture(path):
	file_path = path
	var texture = ImageTexture.new()
	if path != null:
		texture.load(path)
	$TextureButton.texture_normal = texture
	get_parent().get_parent().generate_shader()

func get_textures():
	var list = {}
	list[name] = $TextureButton.texture_normal
	return list

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "uniform sampler2D "+name+"_tex;\n"
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "vec3 "+name+"_"+str(variant_index)+"_rgb = texture("+name+"_tex, "+uv+").rgb;\n"
	rv.rgb = name+"_"+str(variant_index)+"_rgb"
	return rv

func _on_TextureButton_pressed():
	var dialog = EditorFileDialog.new()
	add_child(dialog)
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.png;PNG image")
	dialog.add_filter("*.jpg;JPG image")
	dialog.connect("file_selected", self, "set_texture")
	dialog.popup_centered()

func serialize():
	var data = .serialize()
	data.file_path = file_path
	return data

func deserialize(data):
	set_texture(data.file_path)
	.deserialize(data)
