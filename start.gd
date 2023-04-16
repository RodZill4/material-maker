extends Control

var loader : ResourceInteractiveLoader

onready var progress_bar = $VBoxContainer/ProgressBar

func _ready():
	randomize()
	set_process(false)
	var resource_path : String
	if Directory.new().file_exists("res://material_maker/main_window.tscn"):
		if ("--export" in OS.get_cmdline_args()) or ("--export-material" in OS.get_cmdline_args()):
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
			var target : String = "Godot/Godot 4 Standard"
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
			resource_path = "res://material_maker/main_window.tscn"
	else:
		resource_path = "res://demo/demo.tscn"
	
	var patrons = $Background.permutations(preload("res://material_maker/windows/about/about.gd").PATRONS, 3)
	$VBoxContainer/Patreon.text = "Join %s, %s and %s in supporting this project on Patreon and help us continue to improve our software." % [patrons[0], patrons[1], patrons[2]]
	
	var locale = load("res://material_maker/locale/locale.gd").new()
	locale.read_translations()
	
	loader = ResourceLoader.load_interactive(resource_path)
	if loader != null: # check for errors
		set_process(true)

func start_ui():
	if OS.get_name() == "HTML5":
		var dialog = load("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instance()
		dialog.dialog_text = """
			This HTML5 version of Material Maker has many limitations (such as lack of export, 16 bits rendering and 3D model painting) and is meant for evaluation only.
			If you intend to use this software seriously, it is recommended to download a Windows, MacOS or Linux version.
			Note there's a known 3D preview rendering problem in Safari.
		"""
		add_child(dialog)
		var result = dialog.ask()
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
	var root = get_tree().root
	# Remove the current scene
	root.remove_child(self)
	call_deferred("free")
	# Add the next scene
	progress_bar.value = 100.0
	var scene = loader.get_resource()
	var instance = scene.instance()
	root.add_child(instance)
	
var wait : float = 0.0
func _process(delta) -> void:
	wait += delta
	if wait < 0.01:
		return
	wait = 0.0
	var err = loader.poll()
	if err == ERR_FILE_EOF:
		set_process(false)
		start_ui()
	elif err == OK:
		progress_bar.value = 100.0*float(loader.get_stage()) / loader.get_stage_count()

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
							show_error("ERROR: Unsupported target '%s', please select from the following:\n%s" % [target, "\n".join(c.get_export_profiles())])
							continue
					var export_msg = "Exporting %s to %s..." % [f.get_file(), output_dir]
					$VBoxContainer/Label.text = export_msg
					print(export_msg)
					var prefix : String = output_dir+"/"+f.get_file().get_basename()
					var result = c.export_material(prefix, target, size)
					while result is GDScriptFunctionState:
						result = yield(result, "completed")
			gen.queue_free()
		$VBoxContainer/ProgressBar.value += 1
	get_tree().quit()

func show_error(message : String):
	print(message)
	$ErrorPanel.show()
	$ErrorPanel/Label.text = message


func _on_Patreon_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		OS.shell_open("https://www.patreon.com/rodzlabs")
