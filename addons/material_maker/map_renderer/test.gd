extends TextureRect

var map_list : Array

func _ready():
	var s : int = 512
	get_window().size = Vector2i(s, s)
	map_list = MMMapGenerator.MAP_DEFINITIONS.keys()
	$Maps.clear()
	for map in map_list:
		$Maps.add_item(map)
	$Maps.select(0)
	show_map(map_list[0])

func show_map(map_name : String):
	var mesh = load("res://material_maker/meshes/suzanne.obj")
	var t : MMTexture = MMTexture.new()
	await MMMapGenerator.generate(mesh, map_name, get_window().size.x, t)
	texture = await t.get_texture()

func _on_maps_item_selected(index):
	show_map(map_list[index])
