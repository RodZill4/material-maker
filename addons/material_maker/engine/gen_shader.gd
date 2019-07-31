extends MMGenBase
class_name MMGenShader

var config
var parameters

func configure(c: Dictionary):
	config = c

func initialize(data: Dictionary):
	if data.has("name"):
		name = data.name
	if data.has("parameters"):
		parameters = data.parameters
