tool
extends MMGenBase
class_name MMGenIOs

"""
IOs just forward their inputs to their outputs and are used to specify graph interfaces
"""

var ports : Array = []

var editable = false

func can_be_deleted() -> bool:
	return name != "gen_inputs" and name != "gen_outputs"


func get_type() -> String:
	return "ios"

func get_type_name() -> String:
	match name:
		"gen_inputs": return "Inputs"
		"gen_outputs": return "Outputs"
		_: return "IOs"


func get_io_defs() -> Array:
	var rv : Array = []
	for p in ports:
		rv.push_back({ name=p.name, type="rgba" })
	return rv

func get_input_defs() -> Array:
	return [] if name == "gen_inputs" else get_io_defs()

func get_output_defs() -> Array:
	return [] if name == "gen_outputs" else get_io_defs()


func toggle_editable() -> bool:
	editable = !editable
	if editable:
		model = null
	return true

func is_editable() -> bool:
	return editable


func add_port() -> void:
	ports.append({ name="unnamed", type="rgba" })
	emit_signal("parameter_changed", "__update_all__", null)

func set_port_name(i : int, n : String) -> void:
	ports[i].name = n

func delete_port(i : int) -> void:
	ports.remove(i)
	var input_gen = get_parent() if name == "gen_inputs" else self
	var output_gen = get_parent() if name == "gen_outputs" else self
	var port_reconnects = { i:-1 }
	while i < ports.size():
		port_reconnects[i+1] = i
		i += 1
	input_gen.get_parent().reconnect_inputs(input_gen, port_reconnects)
	output_gen.get_parent().reconnect_outputs(output_gen, port_reconnects)
	emit_signal("parameter_changed", "__update_all__", null)

func swap_ports(i1 : int, i2 : int) -> void:
	var tmp = ports[i1]
	ports[i1] = ports[i2]
	ports[i2] = tmp
	var input_gen = get_parent() if name == "gen_inputs" else self
	var output_gen = get_parent() if name == "gen_outputs" else self
	var port_reconnects = { i1:i2, i2:i1 }
	input_gen.get_parent().reconnect_inputs(input_gen, port_reconnects)
	output_gen.get_parent().reconnect_outputs(output_gen, port_reconnects)
	emit_signal("parameter_changed", "__update_all__", null)
	
func source_changed(input_index : int) -> void:
	if name == "gen_outputs":
		if get_parent() != null:
			get_parent().notify_output_change(input_index)
	else:
		notify_output_change(input_index)

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var source = get_source(output_index)
	if source != null:
		var rv = source.generator._get_shader_code(uv, source.output_index, context)
		while rv is GDScriptFunctionState:
			rv = yield(rv, "completed")
		return rv
	return { defs="", code="", textures={} }

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "ios"
	data.ports = ports
	return data
