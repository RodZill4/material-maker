tool
extends "res://addons/material_maker/node_base.gd"

var resolution = 1
var suffix = "suffix"

func _ready():
	initialize_properties([ $resolution ])

func _get_shader_code(uv):
	var rv = { defs="", code="", f="0.0" }
	var src = get_source()
	if src != null:
		rv = src.get_shader_code(uv)
	return rv

func export_textures(prefix, size = null):
	var suffix = $Suffix.text
	if suffix != "":
		if size == null:
			size = int(pow(2, 8+resolution))
		get_parent().renderer.export_texture(get_source(), "%s_%s.png" % [ prefix, suffix ], size)

func serialize():
	var data = .serialize()
	data.suffix = $Suffix.text
	return data

func deserialize(data):
	if data.has("suffix"):
		$Suffix.text = data.suffix
	.deserialize(data)
