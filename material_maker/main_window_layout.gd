extends HBoxContainer


const PANELS = [
	{ name="Library", scene=preload("res://material_maker/panels/library/library.tscn"), position="TopLeft" },
	{ name="Preview2D", scene=preload("res://material_maker/panels/preview_2d/preview_2d_panel.tscn"), position="TopRight" , parameters={preview_mode=1} },
	{ name="Preview3D", scene=preload("res://material_maker/panels/preview_3d/preview_3d_panel.tscn"), position="BottomLeft" },
	{ name="Preview2D (2)", scene=preload("res://material_maker/panels/preview_2d/preview_2d_panel.tscn"), position="BottomRight", parameters={preview_mode=2} },
	{ name="Histogram", scene=preload("res://material_maker/widgets/histogram/histogram.tscn"), position="BottomRight" },
	{ name="Hierarchy", scene=preload("res://material_maker/panels/hierarchy/hierarchy_panel.tscn"), position="TopRight"},
	{ name="Reference", scene=preload("res://material_maker/panels/reference/reference_panel.tscn"), position="BottomLeft"},
	{ name="Brushes", scene=preload("res://material_maker/panels/brushes/brushes.tscn"), position="TopLeft" },
	{ name="Layers", scene=preload("res://material_maker/panels/layers/layers.tscn"), position="BottomRight" },
	{ name="Parameters", scene=preload("res://material_maker/panels/parameters/parameters.tscn"), position="TopRight" },
]

var default_material_layout := {
	&"main": { &"type": "FlexTop", &"w": 1900.0, &"h": 939.0, &"children": [
		{ &"type": "FlexSplit", &"w": 1900.0, &"h": 939.0, &"children": [
			{ &"type": "FlexTab", &"w": 373.0, &"h": 939.0, &"children": [], &"tabs": [
				&"Library", &"Hierarchy"], &"current": 0 },
			{ &"type": "FlexMain", &"w": 1073.0, &"h": 939.0, &"children": [] },
			{ &"type": "FlexSplit", &"w": 434.0, &"h": 939.0, &"children": [
				{ &"type": "FlexTab", &"w": 434.0, &"h": 501.0, &"children": [], &"tabs": [
					&"Preview2D", &"Histogram"], &"current": 0 },
				{ &"type": "FlexTab", &"w": 434.0, &"h": 427.0, &"children": [], &"tabs": [
					&"Preview3D", &"Preview2D (2)", &"Reference"], &"current": 0 }
			], &"dir": "v" }], &"dir": "h" }]}, &"windows": [] }

var default_paint_layout : Dictionary = { main={ children=[ { children=[ { children=[], current=0, h=766.0, tabs=["Brushes"], type="FlexTab", w=279.0 }, { children=[], h=766.0, type="FlexMain", w=844.0 }, { children=[ { children=[], current=0, h=370.0, tabs=["Parameters"], type="FlexTab", w=240.0 }, { children=[], current=0, h=386.0, tabs=["Layers"], type="FlexTab", w=240.0 }], dir="v", h=766.0, type="FlexSplit", w=240.0 }], dir="h", h=766.0, type="FlexSplit", w=1383.0 }], h=766.0, type="FlexTop", w=1383.0 }, windows=[] }

const HIDE_PANELS = {
	material=[ "Brushes", "Layers", "Parameters" ],
	paint=[ "Preview3D", "Histogram", "Hierarchy" ]
}


var panels = {}
var previous_width : float
var current_mode : String = "material"
var layout : Dictionary = {}


func _ready() -> void:
	previous_width = size.x

func toggle_side_panels() -> void:
	pass

func load_panels() -> void:
	# Create panels
	for panel in PANELS:
		var node : Node = panel.scene.instantiate()
		node.name = panel.name
		if panel.has("parameters"):
			for p in panel.parameters.keys():
				node.set(p, panel.parameters[p])
		panels[panel.name] = node
		$FlexibleLayout.add(panel.name, node)

	for mode in [ "material", "paint" ]:
		if mm_globals.config.has_section_key("layout", mode):
			layout[mode] = JSON.parse_string(mm_globals.config.get_value("layout", mode))
		elif mode == "material":
			layout[mode] = default_material_layout
		elif mode == "paint":
			layout[mode] = default_paint_layout
	$FlexibleLayout.init(layout[current_mode] if layout.has(current_mode) else null)


func save_config() -> void:
	layout[current_mode] = $FlexibleLayout.serialize()
	for mode in [ "material", "paint" ]:
		if layout.has(mode):
			mm_globals.config.set_value("layout", mode, JSON.stringify(layout[mode]))


func get_panel(n) -> Control:
	if panels.has(n):
		return panels[n]
	return Control.new()

func get_panel_list() -> Array:
	var panels_list = panels.keys()
	panels_list.sort()
	return panels_list

func is_panel_visible(panel_name : String) -> bool:
	return $FlexibleLayout.flex_layout.is_panel_shown(panel_name)

func set_panel_visible(panel_name : String, v : bool) -> void:
	$FlexibleLayout.show_panel(panel_name, v)
	$FlexibleLayout.layout()

func change_mode(m : String) -> void:
	if m == current_mode:
		return
	layout[current_mode] = $FlexibleLayout.serialize()
	current_mode = m
	if layout.has(current_mode):
		$FlexibleLayout.init(layout[current_mode])

func _on_tab_changed(_tab):
	pass
