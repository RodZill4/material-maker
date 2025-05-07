extends Window

@onready var application_name_label = $HBoxContainer/VBoxContainer/HBoxContainer3/VBoxContainer/ApplicationName
@onready var authors_grid = $HBoxContainer/VBoxContainer/VBoxContainer/Authors/List
@onready var patrons_list = $HBoxContainer/VBoxContainer/VBoxContainer/Donors/VBoxContainer/Patrons

const CONTRIBUTORS = [
	{ icon="res://material_maker/icons/godot_logo.svg", contribution="99% of Material Maker's code is the awesome Godot Engine GODOT_VERSION" },
	{ name="Rodolphe Suescun", contribution="Lead developer" },
	{ name="Kasper Arnklit Frandsen", contribution="Several nodes (including Auto Tones, Mask to SDF, Normal Blend and many Bricks nodes) and node updates, and very nice video tutorials" },
	{ name="Hugo Locurcio", contribution="Lots of contributions, mostly related to rendering and user interface" },
	{ name="Roujel Williams", contribution="Curvature, Ambient Occlusion and Thickness maps generation" },
	{ name="wojtekpil", contribution="Multiwarp, HBAO and Denoiser nodes as well as fixes in baker tools" },
	{ name="williamchange", contribution="Several nodes (including Seven/Sixteen Segment Display, Roman numerals, Japanese Glyphs and Triangle Voronoi) and node updates" },
	{ name="GoldenThumbs", contribution="Wavefront (OBJ) model loader" },
	{ name="Bonbonmiel", contribution="Many user interface improvements (in Nodes popup, 3D preview...)" },
	{ name="myaaaaaaaaa", contribution="Many improvements and bug fixes including better and faster connection loop detection, nicer file format for shader nodes, as well as colorspace nodes" },
	{ name="Donald Mull Jr.", contribution="Export for Unity HDRP" },
	{ name="Metin ÇETİN", contribution="Add node popup menu" },
	{ name="Jack Perkins", contribution="User interface improvements" },
	{ name="Paulo Falcao", contribution="Preview for v4v4 input/outputs, Temporal Anti Aliasing and lots of ideas/feedback for SDF nodes" },
	{ name="Jesse Dubay", contribution="3D preview and user interface improvements, Colormap node" },
	{ name="escargot-sans-gluten", contribution="3D preview and user interface improvements" },
	{ name="Tarox", contribution="Material Maker icon and lots of very useful feedback" },
	{ name="Easynam", contribution="Propagate Changes function in subgraph nodes" },
	{ name="Zhibade", contribution="Auto size new comment nodes to current selection" },
	{ name="Theaninova", contribution="Spiral Gradient node" },
	{ name="paddy-exe", contribution="New modes in the Blend node" },
	{ name="Variable", contribution="UI fixes" },
	{ name="jeremybeier", contribution="Unity export fixes" },
	{ name="Maybe you?", contribution="If I forgot anyone here, or if you wish to contribute to this project, please don't hesitate to join our Discord channel and/or contact me directly" },
]

const PATRONS = [
	"Edward Herbert", "Andres Hernandez", "LitmusZest", "Hugo Locurcio", "Jose Ivan Lopez Romo",
	"Interstice", "MrDG", "rustweaver", "BasicIncomePlz", "AdamRatai",
	"Harken", "Ian Genskowsky Chang", "Hanzhong Wang", "Ryan Roden-Corrent", "Micha Grandel",
	"Andreas Ratchev", "Miouyouyou", "Valerian Bedin", "Mikael Nordenberg"
]

const PATRONS2 = [
	"Preclude Interactive", "nargacu83", "realkotob", "Shikher Pandey", "The5",
	"a critter in flux", "Tom Wor"
]

func _ready() -> void:
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	min_size = Vector2(600, 500) * content_scale_factor
	if Engine.is_editor_hint():
		application_name_label.text = "Material Maker"
	else:
		application_name_label.text = ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/actual_release")
	
	# Contributors list
	for c in CONTRIBUTORS:
		var name_control : Control
		if c.has("name"):
			var label : Label = Label.new()
			label.text = c.name
			name_control = label
		elif c.has("icon"):
			var icon : TextureRect = TextureRect.new()
			icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			icon.texture = load(c.icon)
			name_control = icon
		name_control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		authors_grid.add_child(name_control)

		var label : Label = Label.new()
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
		patrons_list.add_item(p)

func open_url(url) -> void:
	OS.shell_open(url)
