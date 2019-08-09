tool
extends Object
class_name MMGenLoader

func load_gen(filename: String) -> MMGenBase:
	var file = File.new()
	if file.open(filename, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		return create_gen(data)
	return null

func create_gen(data) -> MMGenBase:
	var generator = null
	if data.has("connections") and data.has("nodes"):
		generator = MMGenGraph.new()
		for n in data.nodes:
			var g = create_gen(n)
			if g != null:
				generator.add_child(g)
		generator.connections = data.connections
	elif data.has("type"):
		if data.type == "material":
			generator = MMGenMaterial.new()
		else:
			generator = MMGenShader.new()
			if data.type == "custom":
				generator.set_model_data(data.model_data)
			else:
				var file = File.new()
				if file.open("res://addons/material_maker/nodes/"+data.type+".mmn", File.READ) == OK:
					var model_data = parse_json(file.get_as_text())
					print("loaded description "+data.type+".mmn")
					generator.set_model_data(model_data)
					file.close()
				else:
					print("Cannot find description for "+data.type)
	else:
		print(data)
	if generator != null and data.has("parameters"):
		generator.initialize(data)
	return generator
