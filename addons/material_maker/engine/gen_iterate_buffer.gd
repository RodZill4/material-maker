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

var used_named_parameters : Array = []
var pending_textures = [[], []]

func _init():
	texture.flags = Texture.FLAG_REPEAT
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	loop_material = ShaderMaterial.new()
	loop_material.shader = Shader.new()
	if !parameters.has("size"):
		parameters.size = 9

func _ready() -> void:
	add_to_group("preview")

func set_pending() -> void:
	if ! is_pending:
		mm_renderer.add_pending_request()
		is_pending = true

func unset_pending():
	if is_pending:
		mm_renderer.remove_pending_request()
		is_pending = false

func _exit_tree() -> void:
	if current_renderer != null:
		current_renderer.release(self)
	unset_pending()

func get_type() -> String:
	return "iterate_buffer"

func get_type_name() -> String:
	return "Iterate Buffer"

func get_buffers() -> Array:
	return [ self ]

func get_parameter_defs() -> Array:
	return [
			{ name="size", type="size", first=4, last=13, default=4 },
			{ name="iterations", type="float", min=1, max=50, step=1, default=5 },
			{ name="filter", type="boolean", default=true },
			{ name="mipmap", type="boolean", default=true }
		]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" }, { name="loop_in", type="rgba" } ]

func get_output_defs(_show_hidden : bool = false) -> Array:
	return [ { type="rgba" }, { type="rgba" } ]

func source_changed(input_port_index : int) -> void:
	set_current_iteration(0)
	call_deferred("update_shader", input_port_index)

func all_sources_changed() -> void:
	set_current_iteration(0)
	call_deferred("update_shader", 0)
	call_deferred("update_shader", 1)

func follow_input(input_index : int) -> Array:
	if input_index == 1:
		return [ OutputPort.new(self, 0) ]
	else:
		return .follow_input(input_index)

func update_shader(input_port_index : int) -> void:
	if ! is_instance_valid(self):
		return
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

func set_parameter(n : String, v) -> void:
	.set_parameter(n, v)
	set_current_iteration(0)
	if is_inside_tree():
		update_buffer()

func on_float_parameters_changed(parameter_changes : Dictionary) -> bool:
	var return_value = false
	var not_just_iteration = parameter_changes.size() > 1 or not parameter_changes.has("o%s_iteration" % str(get_instance_id()))
	var iterations_changed : bool = false
	for p in parameter_changes.keys():
		if used_named_parameters.find(p) != -1:
			iterations_changed = true
			break
	for i in range(2):
		var m : Material = [ material, loop_material ][i]
		if ( mm_renderer.update_float_parameters(m, parameter_changes) or iterations_changed ) and not_just_iteration:
			update_again = true
			return_value = true
			set_current_iteration(0)
			if pending_textures[i].empty():
				update_buffer()
	return return_value

func on_texture_changed(n : String) -> void:
	for i in range(2):
		pending_textures[i].erase(n)
		if pending_textures[i].empty():
			var m : Material = [ material, loop_material ][i]
			for p in VisualServer.shader_get_param_list(m.shader.get_rid()):
				if p.name == n:
					if i == 0:
						set_current_iteration(0)
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

func set_current_iteration(i : int) -> void:
	current_iteration = i
	var iteration_param_name = "o%s_iteration" % str(get_instance_id())
	if is_inside_tree():
		get_tree().call_group("preview", "on_float_parameters_changed", { iteration_param_name:current_iteration })

func update_buffer() -> void:
	update_again = true
	if !updating:
		updating = true
		while update_again:
			update_again = false
			unset_pending()
			var renderer = current_renderer
			if renderer == null:
				renderer = mm_renderer.request(self)
				while renderer is GDScriptFunctionState:
					renderer = yield(renderer, "completed")
				if renderer == null:
					return
				current_renderer = renderer
			if current_iteration == 0:
				renderer = renderer.render_material(self, material, pow(2, get_parameter("size")))
			else:
				renderer = renderer.render_material(self, loop_material, pow(2, get_parameter("size")))
			while renderer is GDScriptFunctionState:
				renderer = yield(renderer, "completed")
			if renderer == null:
				return
			if !update_again:
				renderer.copy_to_texture(texture)
				texture.flags = 0
			renderer.release(self)
			current_renderer = null
		set_current_iteration(current_iteration+1)
		var iterations = calculate_float_parameter("iterations")
		if iterations.has("used_named_parameters"):
			used_named_parameters = iterations.used_named_parameters
		if iterations.has("value"):
			iterations = iterations.value
		else:
			iterations = 1
		if current_iteration <= iterations:
			get_tree().call_group("preview", "on_texture_changed", "o%s_loop_tex" % str(get_instance_id()))
		else:
			get_tree().call_group("preview", "on_texture_changed", "o%s_tex" % str(get_instance_id()))
		updating = false

func get_globals(texture_name : String) -> Array:
	var texture_globals : String = "uniform sampler2D %s;\nuniform float %s_size = %d.0;\nuniform float o%s_iteration = 0.0;\n" % [ texture_name, texture_name, pow(2, get_parameter("size")), str(get_instance_id()) ]
	return [ texture_globals ]

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var shader_code = _get_shader_code_lod(uv, output_index, context, -1.0, "_tex" if output_index == 0 else "_loop_tex")
	if updating or update_again:
		shader_code.pending_textures = shader_code.textures.keys()
	match output_index:
		1:
			shader_code.global = [ "uniform int o%s_iteration = 0;" % str(get_instance_id()) ]
	return shader_code

func get_output_attributes(output_index : int) -> Dictionary:
	var attributes : Dictionary = {}
	match output_index:
		0:
			attributes.texture = "o%s_tex" % str(get_instance_id())
			attributes.texture_size = pow(2, get_parameter("size"))
		1:
			attributes.texture = "o%s_loop_tex" % str(get_instance_id())
			attributes.texture_size = pow(2, get_parameter("size"))
			attributes.iteration = "o%s_iteration" % str(get_instance_id())
	return attributes

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "iterate_buffer"
	return data
