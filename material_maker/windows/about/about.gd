extends Window

@onready var application_name_label = $HBoxContainer/VBoxContainer/HBoxContainer3/VBoxContainer/ApplicationName
@onready var authors_grid = $HBoxContainer/VBoxContainer/VBoxContainer/Authors/List
@onready var patrons_list = $HBoxContainer/VBoxContainer/VBoxContainer/Donors/VBoxContainer/Patrons

const CONTRIBUTORS = [
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
	"Edward Herbert", "LitmusZest", "Hugo Locurcio", "Jose Ivan Lopez Romo", "Andres Hernandez",
	"Interstice", "Preclude Interactive", "Rafe Hall", "rustweaver", "Harken", "BasicIncomePlz",
	"AdamRatai", "Hanzhong Wang", "Ryan Roden-Corrent", "Micha Grandel", "Ian Genskowsky Chang",
	"Andreas Ratchev",
	
	"The5", "nargacu83", "Shikher Pandey", "a critter in flux", "Tom Wor"
]

func _ready() -> void:
	if Engine.is_editor_hint():
		application_name_label.text = "Material Maker"
	else:
		application_name_label.text = ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/actual_release")
	for c in CONTRIBUTORS:
		var label : Label = Label.new()
		label.text = c.name
		authors_grid.add_child(label)
		label = Label.new()
		label.autowrap = true
		label.text = c.contribution
		authors_grid.add_child(label)
	for p in PATRONS:
		patrons_list.add_item(p)

func open_url(url) -> void:
	OS.shell_open(url)
