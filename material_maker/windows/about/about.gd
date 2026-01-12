extends Window

@onready var application_name_label = $HBoxContainer/VBoxContainer/HBoxContainer3/VBoxContainer/ApplicationName
@onready var authors_grid = $HBoxContainer/VBoxContainer/VBoxContainer/Authors/List
@onready var patrons_list = $HBoxContainer/VBoxContainer/VBoxContainer/Donors/VBoxContainer/Patrons

const CONTRIBUTORS = [
	{ icon="res://material_maker/icons/godot_logo.svg", contribution="99% of Material Maker's code is the awesome Godot Engine GODOT_VERSION", url="https://godotengine.org/" },
	{ name="Rodolphe Suescun", contribution="Lead developer", url="https://github.com/RodZill4/material-maker/commits/master/?author=RodZill4" },
	{ name="williamchange", contribution="Many UI updates, many nodes (including Seven/Sixteen Segment Display, Roman numerals, Japanese Glyphs and Triangle Voronoi) and node updates", url="https://github.com/RodZill4/material-maker/commits/master/?author=williamchange" },
	{ name="Jowan-Spooner", contribution="UI redesign", url="https://github.com/RodZill4/material-maker/commits/master/?author=Jowan-Spooner" },
	{ name="NotArme", contribution="Many improvements and bug fixes", url="https://github.com/RodZill4/material-maker/commits/master/?author=NotArme" },
	{ name="Thibaud Goiffon", contribution="Website design", url="https://github.com/gtibo" },
	{ name="Kasper Arnklit Frandsen", contribution="Several nodes (including Auto Tones, Mask to SDF, Normal Blend and many Bricks nodes) and node updates, and very nice video tutorials", url="https://github.com/RodZill4/material-maker/commits/master/?author=Arnklit" },
	{ name="Hugo Locurcio", contribution="Lots of contributions, mostly related to rendering and user interface", url="https://github.com/RodZill4/material-maker/commits/master/?author=Calinou" },
	{ name="Theaninova", contribution="Spiral Gradient node, many SDF nodes", url="https://github.com/RodZill4/material-maker/commits/master/?author=Theaninova" },
	{ name="Roujel Williams", contribution="Curvature, Ambient Occlusion and Thickness maps generation", url="https://github.com/RodZill4/material-maker/commits/master/?author=SIsilicon" },
	{ name="wojtekpil", contribution="Multiwarp, HBAO and Denoiser nodes as well as fixes in baker tools", url="https://github.com/RodZill4/material-maker/commits/master/?author=wojtekpil" },
	{ name="GoldenThumbs", contribution="Wavefront (OBJ) model loader", url="https://github.com/RodZill4/material-maker/commits/master/?author=GoldenThumbs" },
	{ name="Bonbonmiel", contribution="Many user interface improvements (in Nodes popup, 3D preview...)", url="https://github.com/mieldepoche" },
	{ name="myaaaaaaaaa", contribution="Many improvements and bug fixes including better and faster connection loop detection, nicer file format for shader nodes, as well as colorspace nodes", url="https://github.com/RodZill4/material-maker/commits/master/?author=myaaaaaaaaa" },
	{ name="Donald Mull Jr.", contribution="Export for Unity HDRP", url="https://github.com/RodZill4/material-maker/commits/master/?author=luggage66" },
	{ name="Metin ÇETİN", contribution="Add node popup menu", url="https://github.com/RodZill4/material-maker/commits/master/?author=metincetin" },
	{ name="Jack Perkins", contribution="User interface improvements", url="https://github.com/RodZill4/material-maker/commits/master/?author=jackaperkins" },
	{ name="Paulo Falcao", contribution="Preview for v4v4 input/outputs, Temporal Anti Aliasing and lots of ideas/feedback for SDF nodes", url="https://github.com/RodZill4/material-maker/commits/master/?author=paulofalcao" },
	{ name="Jesse Dubay", contribution="3D preview and user interface improvements, Colormap node", url="https://github.com/RodZill4/material-maker/commits/master/?author=vreon" },
	{ name="escargot-sans-gluten", contribution="3D preview and user interface improvements", url="https://github.com/RodZill4/material-maker/commits/master/?author=escargot-sans-gluten" },
	{ name="Tarox", contribution="Material Maker icon and lots of very useful feedback", url="https://x.com/pavel_oliva" },
	{ name="Easynam", contribution="Propagate Changes function in subgraph nodes", url="https://github.com/RodZill4/material-maker/commits/master/?author=easynam" },
	{ name="Zhibade", contribution="Auto size new comment nodes to current selection", url="https://github.com/RodZill4/material-maker/commits/master/?author=Zhibade" },
	{ name="paddy-exe", contribution="New modes in the Blend node", url="https://github.com/RodZill4/material-maker/commits/master/?author=paddy-exe" },
	{ name="Variable", contribution="UI fixes", url="https://github.com/RodZill4/material-maker/commits/master/?author=Variable-ind" },
	{ name="jeremybeier", contribution="Unity export fixes", url="https://github.com/RodZill4/material-maker/commits/master/?author=jeremybeier" },
	{ name="Maybe you?", contribution="If I forgot anyone here, or if you wish to contribute to this project, please don't hesitate to join our Discord channel and/or contact me directly", url="https://discord.gg/PF5V3mFwFM" },
]

const PATRONS = [
	"Andres Hernandez", "Ian Genskowsky Chang", "Hugo Locurcio", "Jose Ivan Lopez Romo",
	"rustweaver", "Ryan Roden-Corrent", "ww123td",
	"Thomas Schmall", "Valerio Marty", "Twerknificent", "Cam Kilgore",
	"Schrottkatze", "3ookeeper", "Montey", "Nick", "Florian Bruehl",
	"fisj", "Botan dragneel", "Deniz Ündan"
]

const PATRONS2 = [
	"Valerian Bedin", "BasicIncomePlz", "AdamRatai", "Robert Dodd",
	"Edward Herbert", "LitmusZest", "Interstice", "Harken",
	"Vlad Erium", "MrDG", "Ap", "Trevor", "Mikael Nordenberg",
	"Miouyouyou", "Preclude Interactive", "思羽 陳", "nargacu83",
	"celestialmaze", "Andreas Ratchev", "Micha Grandel", "realkotob",
	"Mischa", "Yumemocchi", "Shikher Pandey", "The5", "Zee Gomez",
	"Richard Nespithal", "Giuseppe Modarelli", "Microplastics Farmer",
	"Some Critter", "Green Bean", "Shanxxx Official", "Leon Krykhtin",
	"Lusia Shinra", "Tom Wor"
]

func _ready() -> void:
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	min_size = Vector2(600, 500) * content_scale_factor
	if Engine.is_editor_hint():
		application_name_label.text = "Material Maker"
	else:
		application_name_label.text = ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/actual_release")
	
	# Contributors list
	var label : Label
	for c in CONTRIBUTORS:
		var name_control : Control
		if c.has("name"):
			label = Label.new()
			label.text = c.name
			name_control = label
		elif c.has("icon"):
			var icon : TextureRect = TextureRect.new()
			icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			icon.texture = load(c.icon)
			name_control = icon
		if c.has("url"):
			name_control.mouse_filter = Control.MOUSE_FILTER_STOP
			name_control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			name_control.gui_input.connect(_name_control_gui_input.bind(c.url))
		name_control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		authors_grid.add_child(name_control)

		label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var contribution : String = c.contribution
		var godot_version : Dictionary = Engine.get_version_info()
		var godot_version_str : String = "v%d.%d" % [ godot_version.major, godot_version.minor ]
		if godot_version.has("patch") and godot_version.patch > 0:
			godot_version_str += ".%d" % godot_version.patch
		if godot_version.has("status"):
			godot_version_str += godot_version.status
		contribution = contribution.replace("GODOT_VERSION", godot_version_str)
		label.text = contribution
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		authors_grid.add_child(label)
	for p in PATRONS:
		patrons_list.add_item(p)
	for p in PATRONS2:
		if p in PATRONS:
			print(p, " already in patrons list")
			continue
		patrons_list.add_item(p)

func _name_control_gui_input(event : InputEvent, url : String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_url(url)


func open_url(url) -> void:
	OS.shell_open(url)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			%EpicLogo.material.set_shader_parameter("invert", 
					"light" in mm_globals.main_window.theme.resource_path)

func _on_patrons_gui_input(event : InputEvent) -> void:
	mm_globals.handle_warped_mmb_scroll(event, %Patrons, %Patrons.get_v_scroll_bar(), 0,
			%Patrons.get_rect().size.y, %Patrons.get_local_mouse_position())

func _on_authors_gui_input(event : InputEvent) -> void:
	mm_globals.handle_warped_mmb_scroll(event, %Authors, %Authors.get_v_scroll_bar(), 0,
			%Authors.get_rect().size.y, %Authors.get_local_mouse_position())

func _on_license_gui_input(event : InputEvent) -> void:
	mm_globals.handle_warped_mmb_scroll(event, %License, %License.get_v_scroll_bar(), 0,
	%License.get_rect().size.y, %License.get_local_mouse_position(), 1.0 / %License.get_line_height())
