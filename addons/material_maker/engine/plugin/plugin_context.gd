class PluginContext:
	
	var plugin_path: String
	func _init(file_path: String) -> void:
		plugin_path = file_path
		
	func load_resource(resource_path: String) -> Variant: 

		if ResourceLoader.exists(resource_path):
			print("Dependency already exists, either its been loaded or there is a dependency collision")
			return ResourceLoader.load(resource_path)
			
		print("Path slices:")
		print(resource_path.get_slice("::", 0))
		var res_path = resource_path.get_slice("::", 2)
		var file_path = res_path.replace("res://", plugin_path + "/")
		
		var dependencies = ResourceLoader.get_dependencies(file_path)
		for dependency in dependencies:
			load_resource(dependency)

		print("Loading dependency: " + file_path)
		var resource = ResourceLoader.load(file_path)
		print(resource)
		resource.take_over_path(resource_path)
		return resource
