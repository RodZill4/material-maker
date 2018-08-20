tool
extends "res://addons/procedural_material/node_base.gd"

func _ready():
	pass

func _get_shader_code(uv):
	var rv = { defs="", code="", f="0.0" }
	var src = get_source()
	if src != null:
		rv = src.get_shader_code(uv)
	return rv

func export_textures(prefix):
	var suffix = $Suffix.text
	if suffix != "":
		get_parent().export_texture(get_source(), "%s_%s.png" % [ prefix, suffix ], 1024)

func serialize():
	var data = .serialize()
	data.suffix = $Suffix.text
	return data

func deserialize(data):
	if data.has("suffix"):
		$Suffix.text = data.suffix
	.deserialize(data)
