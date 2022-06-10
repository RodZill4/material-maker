extends WindowDialog

onready var application_name_label = $HBoxContainer/VBoxContainer/HBoxContainer3/VBoxContainer/ApplicationName
onready var authors_grid = $HBoxContainer/VBoxContainer/VBoxContainer/Authors/List
onready var patrons_list = $HBoxContainer/VBoxContainer/VBoxContainer/Donors/VBoxContainer/Patrons

const CONTRIBUTORS = [
	{ name="Rodolphe Suescun", contribution="Lead developer" },
	{ name="Kasper Arnklit Frandsen", contribution="Several nodes (including Auto Tones, Mask to SDF and Normal Blend) and node updates, and very nice video tutorials" },
	{ name="Hugo Locurcio", contribution="Lots of contributions, mostly related to rendering and user interface" },
	{ name="Roujel Williams", contribution="Curvature, Ambient Occlusion and Thickness maps generation" },
	{ name="wojtekpil", contribution="Multiwarp, HBAO and Denoiser nodes as well as fixes in baker tools" },
	{ name="GoldenThumbs", contribution="Wavefront (OBJ) model loader" },
	{ name="Bonbonmiel", contribution="Many user interface improvements (in Nodes popup, 3D preview...)" },
	{ name="Donald Mull Jr.", contribution="Export for Unity HDRP" },
	{ name="Metin ÇETİN", contribution="Add node popup menu" },
	{ name="Jack Perkins", contribution="User interface improvements" },
	{ name="Paulo Falcao", contribution="Preview for v4v4 input/outputs and lots of ideas/feedback for SDF nodes" },
	{ name="Jesse Dubay", contribution="3D preview and user interface improvements, Colormap node" },
	{ name="escargot-sans-gluten", contribution="3D preview and user interface improvements" },
	{ name="Tarox", contribution="Material Maker icon and lots of very useful feedback" },
	{ name="Easynam", contribution="Propagate Changes function in subgraph nodes" },
	{ name="Zhibade", contribution="Auto size new comment nodes to current selection" },
	{ name="Maybe you?", contribution="If I forgot anyone here, or if you wish to contribute to this project, please don't hesitate to join our Discord channel and/or contact me directly" },
]

const PATRONS = [
	"Edward Herbert", "Hugo Locurcio", "LitmusZest", "nargacu83", "Harken"
]

func _ready() -> void:
	if Engine.editor_hint:
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
