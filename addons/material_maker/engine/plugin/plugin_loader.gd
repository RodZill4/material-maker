extends Node

const PluginContext = preload("res://addons/material_maker/engine/plugin/plugin_context.gd")
const instance = preload("res://addons/material_maker/engine/plugin/plugin_instance.tscn")
@onready var mm_plugins = get_node("/root/mm_plugins")

func _ready()-> void:
	load_plugins()

func load_plugins():
	var plugin_dir = DirAccess.open("user://plugins")
	if not plugin_dir:
		return
		
	var any_plugins_loaded = false
	
	var directories = plugin_dir.get_directories()
	print(directories)
	
	for directory in directories:
		print(directory)
		var scene_path = "user://plugins/" + directory + "/plugin.tscn"
		print(scene_path)
		
		var real_path = "user://plugins/" + directory
		
		var context = PluginContext.PluginContext.new(real_path)
		
		var dependencies = ResourceLoader.get_dependencies(scene_path)
		for dependency in dependencies:
			context.load_resource(dependency)
			
		print("Dependencies:")
		print(dependencies)
		
		var scene = ResourceLoader.load(scene_path)

		var plugin_node = scene.instantiate()
		var id = plugin_node.get_id()
		
		var addon_instance = instance.instantiate()
		
		addon_instance.name = id
		addon_instance.context = context
		
		mm_plugins.add_child(addon_instance)
		addon_instance.add_child(plugin_node)
		print("Finished loading plugin: " + id)
