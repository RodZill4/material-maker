@tool
extends Node

var type_names : Array = []
var types : Dictionary = {}

func _ready():
	for p in MMPaths.get_nodes_paths():
		var file : FileAccess = FileAccess.open(p+"/io_types.mmt", FileAccess.READ)
		if file != null:
			var test_json_conv = JSON.new()
			test_json_conv.parse(file.get_as_text())
			var type_list = test_json_conv.get_data()
			file = null
			for t in type_list:
				if t.has("label"):
					type_names.push_back(t.name)
				var c = t.color
				t.color = Color(c.r, c.g, c.b, c.a)
				file = FileAccess.open(p+"/preview_"+t.name+".gdshader", FileAccess.READ)
				if file != null:
					t.preview = file.get_as_text()
				types[t.name] = t
			return
	print("Failed to load io types")
