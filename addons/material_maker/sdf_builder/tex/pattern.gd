extends "res://addons/material_maker/sdf_builder/tex/fbm.gd"


func _ready():
	pass # Replace with function body.

func get_parameter_defs():
	return [
			{ "default": 0, "label": "Combiner", "name": "mix", "type": "enum", "values": [
					{ "name": "Multiply", "value": "mul" },
					{ "name": "Add", "value": "add" },
					{ "name": "Max", "value": "max" },
					{ "name": "Min", "value": "min" },
					{ "name": "Xor", "value": "xor" },
					{ "name": "Pow", "value": "pow" }
				]
			},
			{ "default": 0, "label": "X", "name": "x_wave", "type": "enum", "values": [
					{ "name": "Sine", "value": "sine" },
					{ "name": "Triangle", "value": "triangle" },
					{ "name": "Square", "value": "square" },
					{ "name": "Sawtooth", "value": "sawtooth" },
					{ "name": "Constant", "value": "constant" },
					{ "name": "Bounce", "value": "bounce" }
				]
			},
			{ "control": "None", "default": 4, "label": "2:", "max": 32, "min": 0, "name": "x_scale", "step": 1, "type": "float" },
			{ "default": 0, "label": "Y", "name": "y_wave", "type": "enum", "values": [
					{ "name": "Sine", "value": "sine" },
					{ "name": "Triangle", "value": "triangle" },
					{ "name": "Square", "value": "square" },
					{ "name": "Sawtooth", "value": "sawtooth" },
					{ "name": "Constant", "value": "constant" },
					{ "name": "Bounce", "value": "bounce" }
				]
			},
			{ "control": "None", "default": 4, "label": "3:", "max": 32, "min": 0, "name": "y_scale", "step": 1, "type": "float" },
			{ "default": 0, "label": "Z", "name": "z_wave", "type": "enum", "values": [
					{ "name": "Sine", "value": "sine" },
					{ "name": "Triangle", "value": "triangle" },
					{ "name": "Square", "value": "square" },
					{ "name": "Sawtooth", "value": "sawtooth" },
					{ "name": "Constant", "value": "constant" },
					{ "name": "Bounce", "value": "bounce" }
				]
			},
			{ "control": "None", "default": 4, "label": "4:", "max": 32, "min": 0, "name": "z_scale", "step": 1, "type": "float" }
		]

func get_includes():
	return [ "pattern", "tex3d_pattern" ]

func get_color_code_gs(ctxt : Dictionary = { uv="$uv" }):
	if ctxt.has("geometry") and ctxt.geometry == "sdf3d":
		return "mix3d_$mix(wave_$x_wave($x_scale*"+ctxt.uv+".x), wave_$y_wave($y_scale*"+ctxt.uv+".y), wave_$z_wave($z_scale*"+ctxt.uv+".z))"
	else:
		return "mix_$mix(wave_$x_wave($x_scale*"+ctxt.uv+".x), wave_$y_wave($y_scale*"+ctxt.uv+".y))"
