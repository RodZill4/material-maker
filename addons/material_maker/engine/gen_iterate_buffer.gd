tool
extends MMGenTexture
class_name MMGenIterateBuffer

"""
Iterate buffers, that render their input in a specific resolution and apply
a loop n times on the result.
"""

var material : ShaderMaterial
var loop_material : ShaderMaterial
var updating : bool = false
var update_again : bool = false
var current_iteration : int = 0

func _ready() -> void:
	texture.flags = Texture.FLAG_REPEAT
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	loop_material = ShaderMaterial.new()
	loop_material.shader = Shader.new()
	if !parameters.has("size"):
		parameters.size = 9
	add_to_group("preview")

func get_type() -> String:
	return "iterate_buffer"

func get_type_name() -> String:
	return "Iterate Buffer"

func get_parameter_defs() -> Array:
	return [
			{ name="size", type="size", first=4, last=12, default=4 },
			{ name="iterations", type="float", min=1, max=50, step=1, default=5 }
		]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" }, { name="loop_in", type="rgba" } ]

func get_output_defs() -> Array:
	return [ { type="rgba" }, { type="rgba" } ]

func source_changed(input_port_index : int) -> void:
	current_iteration = 0
	call_deferred("update_shader", input_port_index)

func follow_input(input_index : int) -> Array:
	if input_index == 1:
		return [ OutputPort.new(self, 0) ]
	else:
		return .follow_input(input_index)

func update_shader(input_port_index : int) -> void:
	var context : MMGenContext = MMGenContext.new()
	var source = {}
	var source_output = get_source(input_port_index)
	if source_output != null:
		source = source_output.generator.get_shader_code("uv", source_output.output_index, context)
		while source is GDScriptFunctionState:
			source = yield(source, "completed")
	if source.empty():
		source = DEFAULT_GENERATED_SHADER
	var m : ShaderMaterial = [ material, loop_material ][input_port_index]
	m.shader.code = mm_renderer.generate_shader(source)
	if source.has("textures"):
		for k in source.textures.keys():
			m.set_shader_param(k, source.textures[k])
	update_buffer()

func set_parameter(n : String, v) -> void:
	.set_parameter(n, v)
	current_iteration = 0
	update_buffer()

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	var do_update : bool = false
	if parameter_changes.has("p_o%s_iterations" % str(get_instance_id())):
		do_update = true
	for m in [ material, loop_material ]:
		for n in parameter_changes.keys():
			for p in VisualServer.shader_get_param_list(m.shader.get_rid()):
				if p.name == n:
					m.set_shader_param(n, parameter_changes[n])
					do_update = true
					break
	if do_update:
		current_iteration = 0
		update_buffer()

func on_texture_changed(n : String) -> void:
	for m in [ material, loop_material ]:
		for p in VisualServer.shader_get_param_list(m.shader.get_rid()):
			if p.name == n:
				update_buffer()
				return

func update_buffer() -> void:
	update_again = true
	if !updating:
		updating = true
		while update_again:
			update_again = false
			var result
			if current_iteration == 0:
				result = mm_renderer.render_material(material, pow(2, get_parameter("size")))
			else:
				result = mm_renderer.render_material(loop_material, pow(2, get_parameter("size")))
			while result is GDScriptFunctionState:
				result = yield(result, "completed")
			if !update_again:
				result.copy_to_texture(texture)
				texture.flags = 0
			result.release()
		updating = false
		if current_iteration < get_parameter("iterations"):
			get_tree().call_group("preview", "on_texture_changed", "o%s_loop_tex" % str(get_instance_id()))
		else:
			get_tree().call_group("preview", "on_texture_changed", "o%s_tex" % str(get_instance_id()))

		current_iteration += 1

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	return _get_shader_code_lod(uv, output_index, context, -1.0, "_tex" if output_index == 0 else "_loop_tex")

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "iterate_buffer"
	return data
