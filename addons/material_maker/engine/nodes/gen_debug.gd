@tool
extends MMGenBase
class_name MMGenDebug


# Can be used to get generated shader


func get_type() -> String:
	return "debug"

func get_type_name() -> String:
	return "Debug"

func get_description() -> String:
	var shortdesc = "Debug"
	var longdesc = ("Shows generated shader of an input and code " +
			"which can be copied and used directly in Shadertoy")
	return "\n".join(
			[TranslationServer.translate(shortdesc),
			TranslationServer.translate(longdesc)])

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func _serialize(data: Dictionary) -> Dictionary:
	return data
