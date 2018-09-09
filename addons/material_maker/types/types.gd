extends Node

const Gradient = preload("res://addons/material_maker/types/gradient.gd")

static func serialize_value(value):
	if typeof(value) == TYPE_COLOR:
		return { type= "Color", r=value.r, g=value.g, b=value.b, a=value.a }
	elif typeof(value) == TYPE_OBJECT && value.has_method("serialize"):
		return value.serialize()
	return value

static func deserialize_value(data):
	if typeof(data) == TYPE_DICTIONARY:
		if data.has("type"):
			if data.type == "Color":
				return Color(data.r, data.g, data.b, data.a)
			elif data.type == "Gradient":
				var gradient = Gradient.new()
				gradient.deserialize(data)
				return gradient
	# in previous releases, Gradients were serialized as arrays
	elif typeof(data) == TYPE_ARRAY:
		var gradient = Gradient.new()
		gradient.deserialize(data)
		return gradient
	return data
