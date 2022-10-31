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
	
	func _init(n : String, o : Object = null):
		name = n
		object = o
		dependencies = []
		pending_dependencies = 0
		status = Invalidated


var dependencies : Dictionary = {}
var buffers : Dictionary = {}


func _ready():
	pass # Replace with function body.

func create_buffer(buffer_name : String, object : Object = null):
	buffers[buffer_name] = Buffer.new(buffer_name, object)
	if dependencies.has(buffer_name):
		for b in dependencies[buffer_name]:
			var buffer = buffers[b]
			buffer.pending_dependencies += 1
			buffer.status = Buffer.Invalidated

func delete_buffer(buffer_name : String):
	buffer_clear_dependencies(buffer_name)
	buffers.erase(buffer_name)
	if dependencies.has(buffer_name):
		for b in dependencies[buffer_name]:
			buffers[b].dependencies.remove(buffer_name)

func buffer_clear_dependencies(buffer_name : String):
	assert(buffers.has(buffer_name))
	var b : Buffer = buffers[buffer_name]
	for d in b.dependencies:
		if dependencies.has(d):
			var dep_index = dependencies[d].find(buffer_name)
			assert(dep_index != -1)
			if dependencies[d].size() == 1:
				dependencies.erase(d)
			else:
				dependencies[d].remove(dep_index)
				assert(dependencies[d].find(buffer_name) == -1)
	b.dependencies = []
	buffer_invalidate(buffer_name)

func buffer_add_dependency(buffer_name : String, dependency_name : String):
	var buffer : Buffer = buffers[buffer_name]
	if buffer.dependencies.find(dependency_name) != -1:
		return
	buffer.dependencies.append(dependency_name)
	if ! dependencies.has(dependency_name):
		dependencies[dependency_name] = []
	if dependencies[dependency_name].find(buffer_name) == -1:
		dependencies[dependency_name].push_back(buffer_name)
		if buffers.has(dependency_name) and buffers[dependency_name].status != Buffer.Updated:
			buffer.pending_dependencies += 1
	buffer_invalidate(buffer_name)

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

func buffer_updated(buffer_name):
	assert(buffers.has(buffer_name))
	var b : Buffer = buffers[buffer_name]
	match b.status:
		Buffer.Invalidated:
			print_debug("Buffer should not be invalidated")
			return
		Buffer.UpdatingInvalidated:
			b.status = Buffer.Invalidated
			update()
			return
		Buffer.Updated:
			print_debug("Buffer "+buffer_name+" updated again?")
			return
	b.status = Buffer.Updated
	if dependencies.has(buffer_name):
		for d in dependencies[buffer_name]:
			var buffer : Buffer = buffers[d]
			buffer.pending_dependencies -= 1
			if buffer.pending_dependencies == 0:
				update()

func dependency_update(dependency_name : String, value = null):
	if dependencies.has(dependency_name):
		assert(value != null)
		for d in dependencies[dependency_name]:
			assert(buffers.has(d))
			var b : Buffer = buffers[d]
			if b.object.has_method("on_dep_update_value") and b.object.on_dep_update_value(d, dependency_name, value):
				continue
			buffer_invalidate(d)
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

func do_update():
	update_scheduled = false
	for b in buffers.keys():
		var buffer : Buffer = buffers[b]
		if buffer.status == Buffer.Invalidated and buffer.pending_dependencies == 0:
			if buffer.object.has_method("on_dep_update_buffer"):
				buffer.status = Buffer.Updating
				buffer.object.on_dep_update_buffer(b)

func print_stats():
	for b in buffers.keys():
		print("Buffer "+b+":")
		print("  Dependencies: "+str(buffers[b].dependencies))
		print("  Status: "+["Invalidated","Updating","UpdatingInvalidated","Updated"][buffers[b].status])
		print("  Pending: "+str(buffers[b].pending_dependencies))
