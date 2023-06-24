extends MarginContainer


var resource_path : String
var tween : Tween

@onready var progress_bar = $SplashScreen/TextureRect/ProgressBar

const BACKGROUNDS :Array[Dictionary] = [
	{ title="Lace Material", author="Tarox", file="res://splash_screen/tarox_lace_material.png" },
	{ title="Golden Tiles", author="PixelMuncher", file="res://splash_screen/pixelmuncher_golden_tiles.png" },
	{ title="Spiral Trails", author="DroppedBeat", file="res://splash_screen/droppedbeat_spiral_trails.tres" },
	{ title="Matrix Rain", author="DroppedBeat", file="res://splash_screen/droppedbeat_matrix_rain.tres" },
	{ title="Procedural Material", author="DroppedBeat", file="res://splash_screen/droppedbeat_procedural_material.png" },
	{ title="Vending Machines", author="DroppedBeat", file="res://splash_screen/droppedbeat_vending_machines.png" },
	{ title="Terminator Ball", author="Paulo Falcao", file="res://splash_screen/paulo_falcao_terminator_ball.tres" },
	{ title="Fractal Octahedron", author="Paulo Falcao", file="res://splash_screen/paulo_falcao_fractal_octahedron.tres" },
	{ title="Dirty Tiles", author="cybereality", file="res://splash_screen/cybereality_dirty_tiles.png" },
	{ title="Future Visions", author="cybereality", file="res://splash_screen/cybereality_future_visions.png" },
	{ title="Brutalism", author="cybereality", file="res://splash_screen/cybereality_brutalism.png" }
]


func _enter_tree():
	randomize()
	var background_index : int = randi() % BACKGROUNDS.size()
	#background_index = 10
	var background : Dictionary = BACKGROUNDS[background_index]
	match background.file.get_extension():
		"png":
			$SplashScreen.texture = load(background.file)
		"tres":
			$SplashScreen.material = load(background.file)
	%Title.text = background.title
	%Author.text = background.author
	%Version.text = ProjectSettings.get_setting("application/config/actual_release")
	var window : Window = get_window()
	window.position = (DisplayServer.screen_get_size(window.current_screen)-Vector2i(size))/2
	window.size = size

func _ready():
	set_process(false)

	resource_path = "res://material_maker/main_window.tscn"
	
	await get_tree().process_frame
	
	var locale = load("res://material_maker/locale/locale.gd").new()
	locale.read_translations()
	
	# TODO: enable threaded loading
	if false:
		start_ui(ResourceLoader.load(resource_path))
	elif ResourceLoader.load_threaded_request(resource_path) == OK: # check for errors
		print("Loading...")
		set_process(true)
	else:
		print("Error loading "+resource_path)

func start_ui(scene):
	var window : Window = get_window()
	if OS.get_name() == "HTML5":
		var dialog = load("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instantiate()
		dialog.dialog_text = """
			This HTML5 version of Material Maker has many limitations (such as lack of export, 16 bits rendering and 3D model painting) and is meant for evaluation only.
			If you intend to use this software seriously, it is recommended to download a Windows, MacOS or Linux version.
			Note there's a known 3D preview rendering problem in Safari.
		"""
		add_child(dialog)
		await dialog.ask()
	var root = get_tree().root
	# Remove the current scene
	root.remove_child(self)
	call_deferred("free")
	# Add the next scene
	var instance = scene.instantiate()
	root.add_child(instance)
	window.borderless = false

var wait : float = 0.0
func _process(delta) -> void:
	wait += delta
	if wait < 0.01:
		return
	wait = 0.0
	var percent : Array = []
	var status = ResourceLoader.load_threaded_get_status(resource_path, percent)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var new_progress_value : float = percent[0]*100.0
			if tween:
				tween.kill()
			tween = get_tree().create_tween()
			tween.tween_property(progress_bar, "value", new_progress_value, 0.5).set_trans(Tween.TRANS_LINEAR)
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			if tween:
				tween.kill()
			tween = get_tree().create_tween()
			tween.tween_property(progress_bar, "value", 100.0, 1.0).set_trans(Tween.TRANS_LINEAR)
			tween.tween_callback(self.start_ui.bind(ResourceLoader.load_threaded_get(resource_path)))
		_:
			print("error "+str(status))
			set_process(false)
