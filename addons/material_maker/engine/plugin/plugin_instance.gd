extends Node

const PluginContext = preload("res://addons/material_maker/engine/plugin/plugin_context.gd")

var context: PluginContext.PluginContext = null

signal on_ui_loaded

func load(resource_path):
	return context.load_resource(resource_path)

func ui_ready():
	on_ui_loaded.emit()
