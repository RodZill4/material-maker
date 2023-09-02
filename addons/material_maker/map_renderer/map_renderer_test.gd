extends Node


@export var mesh_path : String = "res://material_maker/meshes/suzanne.obj"
@export var output_path : String = "/Users/rodolphesuescun/Documents/mm_maptest_"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("Loading mesh...")
	var mesh = load(mesh_path)
	print(mesh)
	for map in MMMapGenerator.MAP_DEFINITIONS.keys():
		print("Generating "+map+" map...")
		var texture : MMTexture = MMTexture.new()
		await MMMapGenerator.generate(mesh, map, 512, texture)
		var filename : String = output_path+map+".png"
		print("Saving to "+filename)
		await texture.save_to_file(filename)
		#break
	get_tree().quit()
		
