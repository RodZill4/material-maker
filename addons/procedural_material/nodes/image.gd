tool
extends "res://addons/procedural_material/node_base.gd"

var rows

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))

func set_texture(path):
	var texture = ImageTexture.new()
	texture.load(path)

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
