tool
extends MMGenBase
class_name MMGenSwitch

"""
Texture generator switch
"""

var editable = false

func get_type() -> String:
	return "switch"

func get_type_name() -> String:
	return "Switch"

func toggle_editable() -> bool:
	editable = !editable
	return true

func is_editable() -> bool:
	return editable

func get_parameter_defs() -> Array:
	var choices = parameters.choices if parameters.has("choices") else 2
	return [
		{ name="outputs", label="Outputs", type="float", min=1, max=5, step=1, default=2 },
		{ name="choices", label="Choices", type="float", min=2, max=5, step=1, default=2 },
		{ name="source", label="Source", type="float", min=0, max=choices-1, step=1, default=0 },
	]

func get_input_defs() -> Array:
	var rv : Array = []
	for c in range(parameters.choices):
		for o in range(parameters.outputs):
			var n = PoolByteArray([65+o]).get_string_from_ascii()+str(c)
			rv.push_back({ name=n, label=n, type="rgba" })
	return rv

func get_output_defs() -> Array:
	var rv : Array = []
	for o in range(parameters.outputs):
		var n = PoolByteArray([65+o]).get_string_from_ascii()
		rv.push_back({ name=n, type="rgba" })
	return rv

func set_parameter(p, v) -> void:
	.set_parameter(p, v)
	emit_signal("parameter_changed", "__update_all__", null)

# get the list of outputs that depend on the input whose index is passed as parameter
func follow_input(input_index : int) -> Array:
	return [ OutputPort.new(self, input_index % int(parameters.outputs)) ]

func source_changed(input_index : int) -> void:
	notify_output_change(input_index % int(parameters.outputs))

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var source = get_source(output_index+parameters.source*parameters.outputs)
	if source != null:
		var rv = source.generator._get_shader_code(uv, source.output_index, context)
		while rv is GDScriptFunctionState:
			rv = yield(rv, "completed")
		return rv
	return { globals=[], defs="", code="", textures={} }

func _serialize(data: Dictionary) -> Dictionary:
	return data
