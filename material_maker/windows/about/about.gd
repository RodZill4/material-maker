extends WindowDialog

onready var application_name_label = $HBoxContainer/VBoxContainer/HBoxContainer3/VBoxContainer/ApplicationName
onready var authors_grid = $HBoxContainer/VBoxContainer/VBoxContainer/Authors/List

const CONTRIBUTORS = [
	{ name="Rodolphe Suescun", contribution="Lead developer" },
	{ name="Hugo Locurcio", contribution="Lots of contributions, mostly related to rendering and user interface" },
	{ name="Kasper Arnklit Frandsen", contribution="Several nodes (including Auto Tones and Mask to SDF) and node updates, and very nice video tutorials" },
	{ name="Roujel Williams", contribution="Curvature, Ambient Occlusion and Thickness maps generation" },
	{ name="Bonbonmiel", contribution="Many user interface improvements (in Nodes popup, 3D preview...)" },
	{ name="Donald Mull Jr.", contribution="Export for Unity HDRP" },
	{ name="Metin ÇETİN", contribution="Add node popup menu" },
	{ name="Jack Perkins", contribution="User interface improvements" },
	{ name="Paulo Falcao", contribution="Preview for v4v4 input/outputs and lots of ideas/feedback for SDF nodes" },
	{ name="Jesse Dubay", contribution="3D preview and user interface improvements" },
	{ name="escargot-sans-gluten", contribution="3D preview and user interface improvements" },
	{ name="Maybe you?", contribution="If I forgot anyone here, or if you wish to contribute to this project, please don't hesitate to join our Discord channel and/or contact me directly" },
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

func open_url(url) -> void:
	OS.shell_open(url)
