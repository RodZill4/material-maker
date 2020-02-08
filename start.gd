extends Control

var loader

onready var progress_bar = $VBoxContainer/ProgressBar

func _ready():
	var path : String
	if Directory.new().file_exists("res://material_maker/main_window.tscn"):
		path = "res://material_maker/main_window.tscn"
	else:
		path = "res://demo/demo.tscn"
	loader = ResourceLoader.load_interactive(path)
	if loader == null: # check for errors
		print("error")
		queue_free()

func _process(_delta):
	var err = loader.poll()
	if err == ERR_FILE_EOF:
		var resource = loader.get_resource()
		get_node("/root").add_child(resource.instance())
		queue_free()
	elif err == OK:
		var progress = float(loader.get_stage()) / loader.get_stage_count()
		progress_bar.value = 100.0*progress
	else: # error during loading
		print("error")
		queue_free()
