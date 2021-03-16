tool
extends MMGenTexture
class_name MMGenIterateBuffer

"""
Iterate buffers, that render their input in a specific resolution and apply
a loop n times on the result.
"""

var material : ShaderMaterial = null
var loop_material : ShaderMaterial = null
var updating : bool = false
var update_again : bool = false
var current_iteration : int = 0

var current_renderer = null
var is_pending : bool = false

var pending_textures = [[], []]

func _ready() -> void:
	texture.flags = Texture.FLAG_REPEAT
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	loop_material = ShaderMaterial.new()
	loop_material.shader = Shader.new()
	if !parameters.has("size"):
		parameters.size = 9
	add_to_group("preview")

func _exit_tree() -> void:
	if current_renderer != null:
		current_renderer.release(self)

func get_type() -> String:
	return "iterate_buffer"

func get_type_name() -> String:
	return "Iterate Buffer"

func get_parameter_defs() -> Array:
	return [
			{ name="size", type="size", first=4, last=12, default=4 },
			{ name="iterations", type="float", min=1, max=50, step=1, default=5 },
			{ name="filter", type="boolean", default=true },
			{ name="mipmap", type="boolean", default=true }
		]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" }, { name="loop_in", type="rgba" } ]

func get_output_defs() -> Array:
	return [ { type="rgba" }, { type="rgba" } ]

func source_changed(input_port_index : int) -> void:
	current_iteration = 0
	call_deferred("update_shader", input_port_index)

func all_sources_changed() -> void:
	current_iteration = 0
	call_deferred("update_shader", 0)
	call_deferred("update_shader", 1)

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
	if source.has("pending_textures"):
		pending_textures[input_port_index] = source.pending_textures
	else:
		pending_textures[input_port_index] = []
	if pending_textures[input_port_index].empty():
		update_buffer()
	else:
		set_pending()

func set_pending() -> void:
	if ! is_pending:
		mm_renderer.add_pending_request()
		is_pending = true

func set_parameter(n : String, v) -> void:
	.set_parameter(n, v)
	current_iteration = 0
	if is_inside_tree():
		update_buffer()

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	var do_update : bool = false
	if parameter_changes.has("p_o%s_iterations" % str(get_instance_id())):
		do_update = true
	for i in range(2):
		var m : Material = [ material, loop_material ][i]
		if mm_renderer.update_float_parameters(m, parameter_changes):
			update_again = true
			current_iteration = 0
			if pending_textures[i].empty():
				update_buffer()

func on_texture_changed(n : String) -> void:
	for i in range(2):
		pending_textures[i].erase(n)
		if pending_textures[i].empty():
			var m : Material = [ material, loop_material ][i]
			for p in VisualServer.shader_get_param_list(m.shader.get_rid()):
				if p.name == n:
					if i == 0:
						current_iteration = 0
					update_buffer()
					return

func on_texture_invalidated(n : String) -> void:
	for i in range(2):
		var m : Material = [ material, loop_material ][i]
		if mm_renderer.material_has_parameter(m, n):
			if pending_textures[i].empty():
				get_tree().call_group("preview", "on_texture_invalidated", "o%s_tex" % str(get_instance_id()))
				get_tree().call_group("preview", "on_texture_invalidated", "o%s_loop_tex" % str(get_instance_id()))
				set_pending()
			if pending_textures[i].find(n) == -1:
				pending_textures[i].push_back(n)

func update_buffer() -> void:
	update_again = true
	if !updating:
		updating = true
		while update_again:
			if is_pending:
				mm_renderer.remove_pending_request()
				is_pending = false
			var renderer = mm_renderer.request(self)
			while renderer is GDScriptFunctionState:
				renderer = yield(renderer, "completed")
			update_again = false
			if current_iteration == 0:
				renderer = renderer.render_material(self, material, pow(2, get_parameter("size")))
			else:
				renderer = renderer.render_material(self, loop_material, pow(2, get_parameter("size")))
			while renderer is GDScriptFunctionState:
				renderer = yield(renderer, "completed")
			if renderer == null:
				return
			current_renderer = renderer
			if !update_again:
				renderer.copy_to_texture(texture)
				texture.flags = 0
			renderer.release(self)
			current_renderer = null
		updating = false
		if current_iteration < get_parameter("iterations"):
			get_tree().call_group("preview", "on_texture_changed", "o%s_loop_tex" % str(get_instance_id()))
		else:
			get_tree().call_group("preview", "on_texture_changed", "o%s_tex" % str(get_instance_id()))
		current_iteration += 1

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var shader_code = _get_shader_code_lod(uv, output_index, context, -1.0, "_tex" if output_index == 0 else "_loop_tex")
	if updating or update_again:
		shader_code.pending_textures = shader_code.textures.keys()
	match output_index:
		0:
			shader_code.texture = "o%s_tex" % str(get_instance_id())
			shader_code.texture_size = pow(2, get_parameter("size"))
		1:
			shader_code.texture = "o%s_loop_tex" % str(get_instance_id())
			shader_code.texture_size = pow(2, get_parameter("size"))
			shader_code.global = [ "uniform int o%s_iteration = 0;" % str(get_instance_id()) ]
			shader_code.iteration = "o%s_iteration" % str(get_instance_id())
	return shader_code

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "iterate_buffer"
	return data
