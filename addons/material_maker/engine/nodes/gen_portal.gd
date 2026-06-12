extends MMGenBase
class_name MMGenPortal

signal target_updated(from_gen : MMGenPortal)

## Wireless links

var port_type : String = "any"

enum Portal {
	IN,
	OUT,
}

var io : Portal
var source : MMGenBase.OutputPort

var editable := false
var color : Color = Color.WHITE

func is_editable() -> bool:
	return true

func toggle_editable() -> bool:
	editable = !editable
	return true

func get_input_defs() -> Array:
	return [ { type=port_type, shortdesc="" } ] if io == Portal.IN else []

func get_output_defs(_show_hidden : bool = false) -> Array:
	return [ { type=port_type, shortdesc="" } ] if io == Portal.OUT else []

func get_type() -> String:
	return "portal"

func get_type_name() -> String:
	return "Portal %s" % [ "In" if io == Portal.IN else "Out" ]

func set_parameter(n : String, v : Variant) -> void:
	super.set_parameter(n, v)
	var old_link = parameters.link
	if n == "link":
		parameters.link = v
		if io == Portal.IN:
			update_target(old_link)
		else:
			update_source()

func get_parameter_defs() -> Array:
	return [{ name="link", type="string", default="aperture_1" }]

func source_changed(_input_index : int) -> void:
	if io == Portal.IN:
		update_target(parameters.link)

func follow_input(_input_index : int) -> Array:
	if io == Portal.OUT or not get_parent():
		return []
	var rv : Array[OutputPort] = []
	for p in get_parent().get_children():
		if p is MMGenPortal and p.io == Portal.OUT and p.parameters.link == parameters.link:
			rv.push_back(OutputPort.new(p, 0))
	return rv

func update_source() -> void:
	source = null
	if get_parent() == null:
		return
	for w in get_parent().get_children():
		if w is MMGenPortal and w.io == Portal.IN and w != self:
			if w.parameters.link == parameters.link:
				source = w.get_source(0)
				break

func update_target(old_link: String) -> void:
	if get_parent() == null:
		return
	if io == Portal.IN:
		target_updated.emit(name)
	for w in get_parent().get_children():
		if w is MMGenPortal and w.io == Portal.OUT and w != self:
			if w.parameters.link in [parameters.link, old_link]:
				w.notify_output_change(0)

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	update_source()
	if source != null:
		return source.generator._get_shader_code(uv, source.output_index, context)
	return get_default_generated_shader()

func _serialize(data : Dictionary) -> Dictionary:
	data.io = io
	data.port_type = port_type
	data.color = MMType.serialize_value(color)

	# remove unused field
	data.erase("seed_int")
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("io"):
		io = data.io
	if data.has("port_type"):
		port_type = data.port_type
	if data.has("color"):
		color = MMType.deserialize_value(data.color)
