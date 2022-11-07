extends Node


class Buffer:
	enum {
		Invalidated,
		Updating,
		UpdatingInvalidated,
		Updated
	}
	
	var name : String
	var object : Object
	var dependencies : Array
	var pending_dependencies : int
	var status : int
	var renders : int
	
	func _init(n : String, o : Object = null):
		name = n
		object = o
		dependencies = []
		pending_dependencies = 0
		status = Updated
		renders = 0


var dependencies : Dictionary = {}
var dependencies_values : Dictionary = {}
var buffers : Dictionary = {}


func _ready():
	pass # Replace with function body.

func create_buffer(buffer_name : String, object : Object = null):
	buffers[buffer_name] = Buffer.new(buffer_name, object)
	buffer_invalidate(buffer_name)
	if object is Node and not object.is_connected("tree_exiting", self, "delete_buffers_from_object"):
		object.connect("tree_exiting", self, "delete_buffers_from_object", [ object ])

func delete_buffer(buffer_name : String):
	buffer_clear_dependencies(buffer_name)
	buffers.erase(buffer_name)
	if dependencies.has(buffer_name):
		for b in dependencies[buffer_name]:
			buffers[b].dependencies.erase(buffer_name)

func delete_buffers_from_object(object : Object):
	var remove_buffers : Array = []
	for b in buffers.keys():
		if buffers[b].object == object:
			remove_buffers.append(b)
	for b in remove_buffers:
		delete_buffer(b)

func buffer_clear_dependencies(buffer_name : String):
	assert(buffers.has(buffer_name))
	var b : Buffer = buffers[buffer_name]
	for d in b.dependencies:
		if dependencies.has(d):
			var dep_index = dependencies[d].find(buffer_name)
			assert(dep_index != -1)
			if dependencies[d].size() == 1:
				dependencies.erase(d)
				dependencies_values.erase(d)
			else:
				dependencies[d].remove(dep_index)
				assert(dependencies[d].find(buffer_name) == -1)
	b.dependencies = []
	b.pending_dependencies = 0
	buffer_invalidate(buffer_name)

func buffer_add_dependency(buffer_name : String, dependency_name : String):
	var buffer : Buffer = buffers[buffer_name]
	if buffer.dependencies.find(dependency_name) != -1:
		return null
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

func dependency_update(dependency_name : String, value = null):
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
	if dependencies.has(dependency_name):
		for d in dependencies[dependency_name]:
			assert(buffers.has(d))
			var b : Buffer = buffers[d]
			if is_buffer_just_updated:
				b.pending_dependencies -= 1
				if b.pending_dependencies == 0:
					need_update = true
			if b.object.has_method("on_dep_update_value") and b.object.on_dep_update_value(d, dependency_name, value):
				continue
			buffer_invalidate(d)
			need_update = true
	if need_update:
		update()

func dependencies_update(dependency_values : Dictionary):
	for k in dependency_values.keys():
		dependency_update(k, dependency_values[k])

var update_scheduled : bool = false
func update():
	if update_scheduled:
		return
	call_deferred("do_update")
	update_scheduled = true

# on_dep_update_buffer:
# - returns true if update was performed immediately, set to updated
# - if returns false or a gdScriptFunctionState, set to updating

func do_update():
	update_scheduled = false
	for b in buffers.keys():
		var buffer : Buffer = buffers[b]
		if buffer.status == Buffer.Invalidated and buffer.pending_dependencies == 0:
			if buffer.object.has_method("on_dep_update_buffer"):
				var status = buffer.object.on_dep_update_buffer(b)
				buffer.status = Buffer.Updating
				if status is bool and ! status:
					buffer.status = Buffer.Invalidated

func print_stats(object = null):
	for b in buffers.keys():
		if object != null and object != buffers[b].object:
			continue
		print("Buffer "+b+":")
		print("  Dependencies: "+str(buffers[b].dependencies))
		print("  Status: "+["Invalidated","Updating","UpdatingInvalidated","Updated"][buffers[b].status])
		var pending : PoolStringArray = PoolStringArray()
		if buffers[b].pending_dependencies > 0:
			for d in buffers[b].dependencies:
				if buffers.has(d) and buffers[d].status != Buffer.Updated:
					pending.append(d)
			print("  Pending: %d (%s)" % [ buffers[b].pending_dependencies, pending.join(", ") ])
		else:
			print("  Pending: 0")
		print("  Renders: %d" % buffers[b].renders)
		if buffers[b].object.has_method("on_dep_shader_generations"):
			var count = buffers[b].object.on_dep_shader_generations(b)
			if count > 0:
				print("  Shader generations: %d" % count)
