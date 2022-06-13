extends Node


class Buffer:
	var name : String
	var object : Object
	var method : String
	var parameters : Array
	var dependencies : Array
	var pending_dependencies : int
	var updated : bool
	
	func _init(n : String, o : Object = null, m : String = "", p : Array = []):
		name = n
		object = o
		method = m
		parameters = p
		dependencies = []
		pending_dependencies = 0
		updated = false


var dependencies : Dictionary = {}
var buffers : Dictionary = {}


func _ready():
	pass # Replace with function body.

func create_buffer(buffer_name : String, object : Object = null, method : String = "", parameters : Array = []):
	print("Creating buffer "+buffer_name)
	buffers[buffer_name] = Buffer.new(buffer_name, object, method, parameters)
	if dependencies.has(buffer_name):
		for b in dependencies[buffer_name]:
			var buffer = buffers[b]
			buffer.pending_dependencies += 1
			buffer.updated = false

func delete_buffer(buffer_name : String):
	print("Deleting buffer "+buffer_name)
	buffer_clear_dependencies(buffer_name)
	buffers.erase(buffer_name)
	if dependencies.has(buffer_name):
		for b in dependencies[buffer_name]:
			buffers[b].dependencies.remove(buffer_name)

func buffer_clear_dependencies(buffer_name : String):
	assert(buffers.has(buffer_name))
	print("Clearing dependencies for buffer "+buffer_name)
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

func buffer_add_dependency(buffer_name : String, dependency_name : String):
	var buffer : Buffer = buffers[buffer_name]
	if buffer.dependencies.find(dependency_name) != -1:
		return
	print("Adding dependency "+buffer_name+" - "+dependency_name)
	buffer.dependencies.append(dependency_name)
	if ! dependencies.has(dependency_name):
		dependencies[dependency_name] = []
	if dependencies[dependency_name].find(buffer_name) == -1:
		dependencies[dependency_name].push_back(buffer_name)
		if buffers.has(dependency_name) and ! buffers[dependency_name].updated:
			buffer.pending_dependencies += 1
	print("Buffer "+buffer_name+" depends on "+dependency_name)

func buffer_has_pending_dependencies(buffer_name : String) -> bool:
	print("buffer_has_pending_dependencies("+buffer_name+") = "+str(buffers[buffer_name].pending_dependencies > 0))
	return buffers[buffer_name].pending_dependencies > 0

func buffer_updated(buffer_name):
	print("Buffer "+buffer_name+" updated")
	if ! dependencies.has(buffer_name):
		return
	for d in dependencies[buffer_name]:
		print("touching "+d)
		var buffer : Buffer = buffers[d]
		buffer.pending_dependencies -= 1
		if buffer.pending_dependencies == 0:
			print("Rendering "+d)

func dependency_update(dependency_name : String, value = null):
	pass
