extends MMGenBase
class_name MMGenMaterial

func generate_material():
	print("Generating material")
	var material = SpatialMaterial.new()
	return material

func initialize(data: Dictionary):
	if data.has("name"):
		name = data.name
