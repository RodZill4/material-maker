extends Control

var loader = null

onready var progress_bar = $VBoxContainer/ProgressBar

func _ready():
	randomize()
	set_process(false)
	var path : String
	if Directory.new().file_exists("res://material_maker/main_window.tscn"):
		if OS.get_cmdline_args().size() > 0 and (OS.get_cmdline_args()[0] == "--export" or OS.get_cmdline_args()[0] == "--export-material"):
			var output = []
			var dir : Directory = Directory.new()
			match OS.get_name():
				"Windows":
					var bat_file_path : String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)+"\\mm_cd.bat"
					var bat_file : File = File.new()
					bat_file.open(bat_file_path, File.WRITE)
					bat_file.store_line("cd")
					bat_file.close()
					OS.execute(bat_file_path, [], true, output)
					dir.remove(bat_file_path)
					dir.change_dir(output[0].split("\n")[2])
			var target : String = "Godot"
			var output_dir : String = dir.get_current_dir()
			var size : int = 0
			var files : Array = []
			var i = 1
			while i < OS.get_cmdline_args().size():
				match OS.get_cmdline_args()[i]:
					"-t", "--target":
						i += 1
						target = OS.get_cmdline_args()[i]
					"-o", "--output-dir":
						i += 1
						output_dir = OS.get_cmdline_args()[i]
					"--size":
						i += 1
						size = int(OS.get_cmdline_args()[i])
						if size < 0:
							show_error("ERROR: incorrect size "+OS.get_cmdline_args()[i])
							return
					_:
						files.push_back(OS.get_cmdline_args()[i])
				i += 1
			if !dir.dir_exists(output_dir):
				show_error("ERROR: Output directory '%s' does not exist" % output_dir)
				return
			var expanded_files = []
			for f in files:
				var basedir : String = f.get_base_dir()
				if basedir == "":
					basedir = "."
				var basename : String = f.get_file()
				if basename.find("*") != -1:
					basename = basename.replace("*", ".*")
					if dir.open(basedir) == OK:
						var regex : RegEx = RegEx.new()
						regex.compile("^"+basename+"$")
						dir.list_dir_begin()
						var file_name = dir.get_next()
						while file_name != "":
							if regex.search(file_name) and file_name.get_extension() == "ptex":
								expanded_files.push_back(basedir+"/"+file_name)
							file_name = dir.get_next()
				else:
					expanded_files.push_back(f)
			export_files(expanded_files, output_dir, target, size)
			return
		else:
			path = "res://material_maker/main_window.tscn"
	else:
		path = "res://demo/demo.tscn"
	loader = ResourceLoader.load_interactive(path)
	if loader == null: # check for errors
		print("error")
		queue_free()
	set_process(true)

func _process(_delta) -> void:
	var err = loader.poll()
	if err == ERR_FILE_EOF:
		var resource = loader.get_resource()
		var scene = resource.instance()
		get_node("/root").add_child(scene)
		queue_free()
	elif err == OK:
		var progress = float(loader.get_stage()) / loader.get_stage_count()
		progress_bar.value = 100.0*progress
	else: # error during loading
		print("error")
		queue_free()

func export_files(files, output_dir, target, size) -> void:
	$VBoxContainer/ProgressBar.min_value = 0
	$VBoxContainer/ProgressBar.max_value = files.size()
	$VBoxContainer/ProgressBar.value = 0
	for f in files:
		var gen = mm_loader.load_gen(f)
		if gen != null:
			add_child(gen)
			for c in gen.get_children():
				if c.has_method("export_material"):
					if c.has_method("get_export_profiles"):
						if c.get_export_profiles().find(target) == -1:
							show_error("ERROR: Unsupported target %s"+target)
							continue
					$VBoxContainer/Label.text = "Exporting "+f.get_file()
					var prefix : String = output_dir+"/"+f.get_file().get_basename()
					var result = c.export_material(prefix, target, size)
					while result is GDScriptFunctionState:
						result = yield(result, "completed")
			gen.queue_free()
		$VBoxContainer/ProgressBar.value += 1
	get_tree().quit()

func show_error(message : String):
	$ErrorPanel.show()
	$ErrorPanel/Label.text = message
