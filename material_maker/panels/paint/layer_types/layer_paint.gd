extends "res://material_maker/panels/paint/layer_types/layer.gd"

# warning-ignore:unused_class_variable
var albedo : Texture
# warning-ignore:unused_class_variable
var mr : Texture
# warning-ignore:unused_class_variable
var emission : Texture
# warning-ignore:unused_class_variable
var normal : Texture
# warning-ignore:unused_class_variable
var do : Texture

# warning-ignore:unused_class_variable
var albedo_alpha : float = 1.0
# warning-ignore:unused_class_variable
var metallic_alpha : float = 1.0
# warning-ignore:unused_class_variable
var roughness_alpha : float = 1.0
# warning-ignore:unused_class_variable
var emission_alpha : float = 1.0
# warning-ignore:unused_class_variable
var normal_alpha : float = 1.0
# warning-ignore:unused_class_variable
var depth_alpha : float = 1.0
# warning-ignore:unused_class_variable
var occlusion_alpha : float = 1.0

# warning-ignore:unused_class_variable
var albedo_color_rects : Array = []
# warning-ignore:unused_class_variable
var metallic_color_rects : Array = []
# warning-ignore:unused_class_variable
var roughness_color_rects : Array = []
# warning-ignore:unused_class_variable
var emission_color_rects : Array = []
# warning-ignore:unused_class_variable
var normal_color_rects : Array = []
# warning-ignore:unused_class_variable
var depth_color_rects : Array = []
# warning-ignore:unused_class_variable
var occlusion_color_rects : Array = []

func get_layer_type() -> int:
	return LAYER_PAINT

func duplicate():
	var layer = .duplicate()
	for c in get_expanded_channels():
		layer.set(c+"_alpha", get(c+"_alpha"))
	return layer


func get_channels() -> Array:
	return [ "albedo", "mr", "emission", "normal", "do" ]

func get_expanded_channels() -> Array:
	return [ "albedo", "metallic", "roughness", "emission", "normal", "depth", "occlusion" ]


func _load_layer(data : Dictionary) -> void:
	for c in get_expanded_channels():
		set(c+"_alpha", data[c+"_alpha"] if data.has(c+"_alpha") else 1.0)

func _save_layer(data : Dictionary):
	for c in get_expanded_channels():
		data[c+"_alpha"] = get(c+"_alpha")


func set_alpha(channel : String, value : float) -> void:
	set(channel+"_alpha", value)

func update_color_rects(channel : String, parent_alpha : float = 1.0) -> void:
	var alpha = parent_alpha * get(channel+"_alpha")
	for cr in get(channel+"_color_rects"):
		if cr.material is ShaderMaterial:
			cr.material.set_shader_param("modulate", alpha)
		else:
			cr.modulate.a = alpha
	for l in layers:
		if l.has_method("update_color_rects"):
			l.update_color_rects(channel, alpha)
