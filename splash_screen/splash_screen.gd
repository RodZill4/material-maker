extends MarginContainer


var resource_path : String
var tween : Tween
var background_index : int
var background_subindex : int
var delay_start : bool = false
var mm_scene : PackedScene = null

@onready var progress_bar = $SplashScreen/TextureRect/ProgressBar


const BACKGROUNDS_DIR : String = "res://splash_screen/backgrounds/"
const BACKGROUNDS : Array[Dictionary] = [
	{ author="Angel", entries=[
		{ title="Beanbag Chair", file="angel_beanbag_chair.png" },
		{ title="Soft Nurball", file="angel_soft_nurball.png" },
	] },
	{ title="Zefyr: A Thief's Melody (stone ground texture)", author="Oneiric Worlds", odds = 2, file="oneiric_worlds_zefyr.png", url="https://store.steampowered.com/app/1344990/Zefyr_A_Thiefs_Melody" },
	{ author="Pavel Oliva", odds = 1.5, entries=[
		{ title="Carved Wood", file="pavel_oliva_carved_wood.png" },
		{ title="Celestial Floor", file="pavel_oliva_celestial_floor.png" },
		{ title="Cursed Planks", file="pavel_oliva_cursed_planks.png" },
		{ title="Flowing Lava", file="pavel_oliva_flowing_lava.png" },
		{ title="Lace", file="pavel_oliva_lace.png" },
		{ title="Pavement Generator", file="pavel_oliva_pavement_generator.png" },
		{ title="Stylized Pavement", file="pavel_oliva_stylized_pavement.png" },
		{ title="Treasures", file="pavel_oliva_treasures.png" },
		{ title="Vintage Luggage", file="pavel_oliva_vintage_luggage.png" },
	] },
	{ title="Golden Tiles", author="PixelMuncher", file="pixelmuncher_golden_tiles.png" },
	{ author="DroppedBeat", odds = 1.5, entries=[
		{ title="Spiral Trails", file="droppedbeat_spiral_trails.tres" },
		{ title="Star Trails", file="droppedbeat_star_trails.tres" },
		{ title="Matrix Rain", file="droppedbeat_matrix_rain.tres" },
		{ title="Meteor Rain", file="droppedbeat_meteor_rain.tres" },
		{ title="Procedural Material", file="droppedbeat_procedural_material.png" },
		{ title="Vending Machines", file="droppedbeat_vending_machines.png" },
	] },
	{ author="Paulo Falcao", entries=[
		{ title="Path Traced Green Thing", file="paulo_falcao_green_thing.png" },
		{ title="Terminator Ball", file="paulo_falcao_terminator_ball.tres" },
		{ title="Fractal Octahedron", file="paulo_falcao_fractal_octahedron.tres" },
	] },
	{ author="cybereality", odds = 1.5, entries=[
		{ title="Dirty Tiles", file="cybereality_dirty_tiles.png" },
		{ title="Future Visions", file="cybereality_future_visions.png" },
		{ title="Brutalism", file="cybereality_brutalism.png" },
	] },
	{ title="Old Doors", author="cgmytro", file="cgmytro_old_doors.png" },
	{ author="Wild Mage Games",
	  title="Neverlooted Dungeon",
	  url="https://store.steampowered.com/app/1171980/Neverlooted_Dungeon",
	  odds = 3,
	  entries=[
		{ file="wild_mage_neverlooted_dungeon_1.png" },
		{ file="wild_mage_neverlooted_dungeon_2.png" },
		{ file="wild_mage_neverlooted_dungeon_3.png" },
		{ file="wild_mage_neverlooted_dungeon_4.png" },
		{ file="wild_mage_neverlooted_dungeon_5.png" },
	] },
	{ author="Wild Wits",
	  title="Crown Gambit",
	  url="https://store.steampowered.com/app/2447980/Crown_Gambit",
	  odds = 3,
	  entries=[
		{ file="wild_wits_crown_gambit_1.png" },
		{ file="wild_wits_crown_gambit_2.png" },
		{ file="wild_wits_crown_gambit_3.png" },
		{ file="wild_wits_crown_gambit_4.png" },
		{ file="wild_wits_crown_gambit_5.png" },
		{ file="wild_wits_crown_gambit_6.png" },
		{ file="wild_wits_crown_gambit_7.png" },
		{ file="wild_wits_crown_gambit_8.png" },
	] },
]


func _enter_tree():
	var date : Dictionary = Time.get_date_dict_from_system()
	var date_int : int = date.month*33+date.day
	var screen : int = 0
	match date_int:
		_:
			randomize()
			var sum : float = 0.0
			for i in BACKGROUNDS.size():
				if BACKGROUNDS[i].has("odds"):
					sum += BACKGROUNDS[i].odds
				else:
					sum += 1
			var value : float = randf_range(0, sum)
			sum = 0.0
			for i in BACKGROUNDS.size():
				if BACKGROUNDS[i].has("odds"):
					sum += BACKGROUNDS[i].odds
				else:
					sum += 1
				if sum >= value:
					screen = i
					break
	set_screen(screen)
	var window : Window = get_window()
	var current_screen_index = window.current_screen
	var ui_scale : int = 2 if DisplayServer.screen_get_dpi() >= 192 and DisplayServer.screen_get_size().x >= 2048 else 1
	window.position = (DisplayServer.screen_get_size(current_screen_index)-Vector2i(ui_scale*size))/2 + DisplayServer.screen_get_position(current_screen_index)
	window.size = ui_scale*size
	window.content_scale_factor = ui_scale

func set_screen(bi : int, sub_index = -1) -> void:
	background_index = bi
	var background : Dictionary = BACKGROUNDS[background_index]
	var author : String = background.author if background.has("author") else ""
	var file : String = background.file if background.has("file") else ""
	var title : String = background.title if background.has("title") else ""
	var url : String = background.url if background.has("url") else ""
	if background.has("entries"):
		if sub_index < 0:
			sub_index = randi_range(0, background.entries.size()-1)
		elif sub_index >= background.entries.size():
			sub_index = background.entries.size()-1
		background_subindex = sub_index
		background = background.entries[sub_index]
		if background.has("author"):
			author = background.author
		if background.has("file"):
			file = background.file
		if background.has("title"):
			title = background.title
		if background.has("url"):
			url = background.url
	match file.get_extension():
		"png":
			$SplashScreen.texture = load(BACKGROUNDS_DIR+background.file)
			$SplashScreen.material = null
		"tres":
			$SplashScreen.material = load(BACKGROUNDS_DIR+background.file)
	%Title.text = title
	%Author.text = author
	%Version.text = ProjectSettings.get_setting("application/config/actual_release")
	if url != "":
		%Title.gui_input.connect(self._on_title_gui_input.bind(url))
		%Title.mouse_filter = MOUSE_FILTER_STOP
		%Title.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	else:
		%Title.mouse_filter = MOUSE_FILTER_IGNORE
		%Title.mouse_default_cursor_shape = CURSOR_ARROW
		for c in %Title.gui_input.get_connections():
			%Title.gui_input.disconnect(c.callable)

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

func start_ui(scene : PackedScene):
	if delay_start:
		mm_scene = scene
	else:
		do_start_ui(scene)

func do_start_ui(scene : PackedScene):
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
	
	get_tree().change_scene_to_packed(scene)

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

func _on_secret_button_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if mm_scene != null:
			do_start_ui(mm_scene)
		else:
			delay_start = true
			$BackgroundSelect.visible = true

func _on_previous_pressed():
	if BACKGROUNDS[background_index].has("entries") and background_subindex > 0:
		set_screen(background_index, background_subindex-1)
	else:
		set_screen(background_index-1 if background_index > 0 else BACKGROUNDS.size()-1, 1000)

func _on_next_pressed():
	if BACKGROUNDS[background_index].has("entries") and background_subindex < BACKGROUNDS[background_index].entries.size()-1:
		set_screen(background_index, background_subindex+1)
	else:
		set_screen(background_index+1 if background_index < BACKGROUNDS.size()-1 else 0, 0)

func _on_title_gui_input(event, url : String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		OS.shell_open(url)


func _on_url_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		OS.shell_open("https://www.materialmaker.org")
