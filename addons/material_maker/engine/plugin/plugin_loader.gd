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
		var plugin_folder = "user://plugins/" + directory
		var plugin_content = DirAccess.open(plugin_folder)
		var plugin_directories = plugin_content.get_directories()
		print(plugin_directories)
		
		var plugin_id = plugin_directories[0]
		var scene_path = "user://plugins/" + directory + "/" + plugin_id + "/plugin.tscn"
		print(scene_path)
		
		var real_path = "user://plugins/" + directory
		
		var context = PluginContext.PluginContext.new(real_path)
		
		var dependencies = ResourceLoader.get_dependencies(scene_path)
		for dependency in dependencies:
			context.load_resource(dependency)
			
		var scene = ResourceLoader.load(scene_path)
		if scene == null:
			continue
		
		if not scene is PackedScene:
			continue

		var plugin_node = scene.instantiate()
		var addon_instance = instance.instantiate()
		
		addon_instance.name = plugin_id
		addon_instance.context = context
		
		mm_plugins.add_child(addon_instance)
		addon_instance.add_child(plugin_node)
		print("Finished loading plugin: " + plugin_id)
