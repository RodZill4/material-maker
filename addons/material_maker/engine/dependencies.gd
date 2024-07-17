extends Node


class Buffer:
	enum {
		Invalidated,
		Updating,
		UpdatingInvalidated,
		Updated,
		Error
	}
	
	var name : String
	var object : Object
	var dependencies : Array
	var pending_dependencies : int
	var status : int
	var renders : int
	var shader_generations : int
	
	const STATUS = ["Invalidated","Updating","UpdatingInvalidated","Updated","Error"]
	
	func _init(n : String, o : Object = null):
		name = n
		object = o
		dependencies = []
		pending_dependencies = 0
		status = Updated
		renders = 0
		shader_generations = 0


var dependencies : Dictionary = {}
var dependencies_values : Dictionary = {}
var buffers : Dictionary = {}

var reset_stats : bool = true
var render_queue_size : int = 0


signal render_queue_empty


func create_buffer(buffer_name : String, object : Object = null):
	buffers[buffer_name] = Buffer.new(buffer_name, object)
	buffer_invalidate(buffer_name)
	if object is Node and not object.is_connected("tree_exiting", self.delete_buffers_from_object.bind(object)):
		object.connect("tree_exiting", self.delete_buffers_from_object.bind(object))

func delete_buffer(buffer_name : String):
	buffer_clear_dependencies(buffer_name)
	buffers.erase(buffer_name)
	if dependencies.has(buffer_name):
		for b in dependencies[buffer_name]:
			buffers[b].dependencies.erase(buffer_name)
	dependencies_values.erase(buffer_name)

func delete_buffers_from_object(object : Object):
	var remove_buffers : Array = []
	for b in buffers.keys():
		if buffers[b].object == object:
			remove_buffers.append(b)
	for b in remove_buffers:
		delete_buffer(b)

func buffer_clear_dependencies(buffer_name : String):
	assert(buffers.has(buffer_name))
	reset_stats = true
	var b : Buffer = buffers[buffer_name]
	for d in b.dependencies:
		if dependencies.has(d):
			var dep_index = dependencies[d].find(buffer_name)
			assert(dep_index != -1)
			if dependencies[d].size() == 1:
				dependencies.erase(d)
				if dependencies_values.has(d) and ! (dependencies_values[d] is MMTexture):
					dependencies_values.erase(d)
			else:
				dependencies[d].remove_at(dep_index)
				assert(dependencies[d].find(buffer_name) == -1)
	b.dependencies = []
	b.pending_dependencies = 0
	buffer_invalidate(buffer_name)

func buffer_add_dependency(buffer_name : String, dependency_name : String):
	var buffer : Buffer = buffers[buffer_name]
	if buffer.dependencies.find(dependency_name) != -1:
		return null
	reset_stats = true
	buffer.dependencies.append(dependency_name)
	if ! dependencies.has(dependency_name):
		dependencies[dependency_name] = []
	if dependencies[dependency_name].find(buffer_name) == -1:
		dependencies[dependency_name].push_back(buffer_name)
		if buffers.has(dependency_name) and buffers[dependency_name].status != Buffer.Updated:
			buffer.pending_dependencies += 1
	buffer_invalidate(buffer_name)
	return dependencies_values[dependency_name] if dependencies_values.has(dependency_name) else null

func buffer_has_pending_dependencies(buffer_name : String) -> bool:
	return buffers[buffer_name].pending_dependencies > 0

func buffer_invalidate(buffer_name):
	assert(buffers.has(buffer_name))
	var buffer : Buffer = buffers[buffer_name]
	match buffer.status:
		Buffer.Invalidated, Buffer.UpdatingInvalidated:
			return
		Buffer.Updated:
			buffer.status = Buffer.Invalidated
			if dependencies.has(buffer_name):
				for d in dependencies[buffer_name]:
					var b : Buffer = buffers[d]
					b.pending_dependencies += 1
					buffer_invalidate(d)
		_:
			buffer.status = Buffer.UpdatingInvalidated
	update()
	if buffer.object != null and buffer.object.has_method("on_dep_buffer_invalidated"):
		buffer.object.on_dep_buffer_invalidated(buffer_name)

func dependency_update(dependency_name : String, value = null, internal : bool = false):
	var need_update : bool = false
	var is_buffer_just_updated : bool = false
	if value != null:
		dependencies_values[dependency_name] = value
	#print("%s = %s" % [ dependency_name, str(value) ])
	if buffers.has(dependency_name):
		var b : Buffer = buffers[dependency_name]
		match b.status:
			Buffer.Invalidated:
				print_debug("Buffer %s (updating) should not be invalidated status" % dependency_name)
				is_buffer_just_updated = true
			Buffer.UpdatingInvalidated:
				#print_debug("Buffer %s (updating) reset to invalidated status" % dependency_name)
				b.status = Buffer.Invalidated
				update()
				return
			Buffer.Updated:
				print_debug("Buffer %s updated again?" % dependency_name)
				pass
			_:
				#print_debug("Buffer %s updated" % dependency_name)
				is_buffer_just_updated = true
		b.status = Buffer.Updated
		b.renders += 1
	if ! internal:
		#print("Resetting stats because of %s" % dependency_name)
		reset_stats = true
	if dependencies.has(dependency_name):
		for d in dependencies[dependency_name]:
			assert(buffers.has(d))
			var b : Buffer = buffers[d]
			if is_buffer_just_updated:
				b.pending_dependencies -= 1
				if b.pending_dependencies == 0:
					need_update = true
			if b.object.has_method("on_dep_update_value") and await b.object.on_dep_update_value(d, dependency_name, value):
				continue
			buffer_invalidate(d)
			need_update = true
	update()

func dependencies_update(dependency_values : Dictionary):
	for k in dependency_values.keys():
		dependency_update(k, dependency_values[k])

var updating : bool = false
var update_scheduled : bool = false

func update():
	if update_scheduled:
		return
	update_scheduled = true
	if !updating:
		do_update.call_deferred()

# on_dep_update_buffer:
# - returns true if update was performed immediately, set to updated
# - if returns false or a gdScriptFunctionState, set to updating

func do_update():
	updating = true
	while update_scheduled:
		update_scheduled = false
		var invalidated_buffers : int = 0
		for b in buffers.keys():
			if ! buffers.has(b):
				continue
			var buffer : Buffer = buffers[b]
			if buffer.object != null and buffer.object is MMGenBase and buffer.status != Buffer.Updated:
				invalidated_buffers += 1
			if (buffer.status == Buffer.Invalidated or buffer.status == Buffer.UpdatingInvalidated) and buffer.pending_dependencies == 0:
				if buffer.object.has_method("on_dep_update_buffer"):
					buffer.status = Buffer.Updating
					var status = await buffer.object.on_dep_update_buffer(b)
					if status is bool and ! status:
						buffer.status = Buffer.Error
		if reset_stats:
			render_queue_size = invalidated_buffers
			reset_stats = false
		get_tree().call_group("render_counter", "on_counter_change", render_queue_size, invalidated_buffers)
		if invalidated_buffers == 0:
			emit_signal("render_queue_empty")
	updating = false

func get_render_queue_size() -> int:
	var invalidated_buffers : int = 0
	for b in buffers.keys():
		var buffer : Buffer = buffers[b]
		if buffer.object != null and buffer.object is MMGenBase and buffer.status != Buffer.Updated:
			invalidated_buffers += 1
	return invalidated_buffers

func material_update_params(material : MMShaderBase):
	for p in material.get_parameters().keys():
		if dependencies_values.has(p):
			material.set_parameter(p, dependencies_values[p])

func buffer_create_compute_material(buffer_name : String, material : MMShaderBase):
	buffer_clear_dependencies(buffer_name)
	for p in material.get_parameters().keys():
		var value = buffer_add_dependency(buffer_name, p)
		if value != null:
			await material.set_parameter(p, value)
	buffers[buffer_name].shader_generations += 1

func buffer_create_shader_material(buffer_name : String, material : MMShaderBase, shader : String):
	if await material.set_shader(shader):
		await buffer_create_compute_material(buffer_name, material)

func print_stats(object = null):
	var statuses : Dictionary = {}
	for s in Buffer.STATUS:
		statuses[s] = PackedStringArray()
	for b in buffers.keys():
		if object != null and object != buffers[b].object:
			continue
		print("Buffer "+b+":")
		print("  Dependencies: "+str(buffers[b].dependencies))
		print("  Status: "+Buffer.STATUS[buffers[b].status])
		var a = statuses[Buffer.STATUS[buffers[b].status]]
		a.append(b)
		statuses[Buffer.STATUS[buffers[b].status]] = a
		print(statuses[Buffer.STATUS[buffers[b].status]])
		var pending : PackedStringArray = PackedStringArray()
		if buffers[b].pending_dependencies > 0:
			for d in buffers[b].dependencies:
				if buffers.has(d) and buffers[d].status != Buffer.Updated:
					pending.append(d)
			print("  Pending: %d (%s)" % [ buffers[b].pending_dependencies, ", ".join(pending) ])
		else:
			print("  Pending: 0")
		print("  Renders: %d" % buffers[b].renders)
		print("  Shader generations: %d" % buffers[b].shader_generations)
		if buffers[b].object.has_method("on_dep_shader_generations"):
			var count = buffers[b].object.on_dep_shader_generations(b)
	for s in Buffer.STATUS:
		print("%s: %s" % [ s, ", ".join(statuses[s]) ])
