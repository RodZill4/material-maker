@tool
extends MMGenBase
class_name MMGenIOs


# IOs just forward their inputs to their outputs and are used to specify graph interfaces


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
		var port = { name=p.name, type=p.type }
		if p.has("shortdesc"):
			port.shortdesc = p.shortdesc
		if p.has("longdesc"):
			port.longdesc = p.longdesc
		if p.has("group_size") and p.group_size > 1:
			port.group_size = p.group_size
		rv.push_back(port)
	return rv

func get_input_defs() -> Array:
	return [] if name == "gen_inputs" else get_io_defs()

func get_output_defs(_show_hidden : bool = false) -> Array:
	return [] if name == "gen_outputs" else get_io_defs()


func add_port() -> void:
	ports.append({ name="unnamed", type="rgba" })
	emit_signal("parameter_changed", "__update_all__", null)

func set_port_name(i : int, n : String) -> void:
	ports[i].name = n

func set_port_type(i : int, t : String) -> void:
	ports[i].type = t
	emit_signal("parameter_changed", "__update_all__", null)

func set_port_descriptions(i : int, short_description : String, long_description : String) -> void:
	ports[i].shortdesc = short_description
	ports[i].longdesc = long_description

func set_port_groups_sizes(g : Dictionary) -> void:
	for i in ports.size():
		if g.has(i):
			ports[i].group_size = g[i]
		else:
			ports[i].group_size = 0

func delete_port(i : int) -> void:
	ports.remove_at(i)
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

func all_sources_changed() -> void:
	if name == "gen_outputs":
		if get_parent() != null:
			for i in ports.size():
				get_parent().notify_output_change(i)
	else:
		for i in ports.size():
			notify_output_change(i)

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var source = get_source(output_index)
	if source != null:
		return source.generator._get_shader_code(uv, source.output_index, context)
	return DEFAULT_GENERATED_SHADER

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "ios"
	data.ports = ports.duplicate(true)
	return data

func _deserialize(data : Dictionary) -> void:
	ports = data.ports.duplicate(true)
