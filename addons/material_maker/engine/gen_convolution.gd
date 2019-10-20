tool
extends MMGenBase
class_name MMGenConvolution

var convolution_params : Dictionary = {}

func get_type() -> String:
	return "shader"

func get_type_name() -> String:
	if convolution_params.has("name"):
		return convolution_params.name
	return .get_type_name()

func get_parameter_defs() -> Array:
	return [ { name="size", type="size", first=4, last=11, default=4 } ]

func get_input_defs() -> Array:
	return [ { name="in", type=convolution_params.input_type } ]

func get_output_defs() -> Array:
	return [ { type=convolution_params.output_type } ]

func set_convolution_params(data: Dictionary) -> void:
	convolution_params = data

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var genname = "o"+str(get_instance_id())
	var epsilon = 1.0/pow(2, 4+parameters.size)
	var types = { "rgba": { type="vec4", init="vec4(0.0)" }, "rgb": { type="vec3", init="vec3(0.0)" }, "f": { type="float", init="0.0" } }
	var rv = { globals=[], defs="", code="", textures={} }
	var source = get_source(0)
	if source == null:
		return rv
	var variant_index = context.get_variant(self, uv)
	if variant_index == -1:
		variant_index = context.get_variant(self, uv)
		rv.code += "%s %s_%d = %s;\n" % [ types[convolution_params.output_type].type, genname, variant_index, types[convolution_params.output_type].init ]
		for dy in range(-convolution_params.y, convolution_params.y+1):
			for dx in range(-convolution_params.x, convolution_params.x+1):
				var coef = convolution_params.matrix[dy+convolution_params.y][dx+convolution_params.x]
				if typeof(coef) == TYPE_INT:
					coef = float(coef)
				if typeof(coef) == TYPE_REAL:
					coef = Vector3(coef, coef, coef)
				if typeof(coef) == TYPE_ARRAY:
					coef = Vector3(coef[0], coef[1], coef[2])
				var coef_str = "vec3(%.9f,%.9f,%.9f)" % [ coef.x, coef.y, coef.z ]
				var uv_str = "((%s)+vec2(%.9f,%.9f))" % [ uv, dx*epsilon, dy*epsilon ]
				var src_code = source.generator.get_shader_code(uv_str, source.output_index, context)
				while src_code is GDScriptFunctionState:
					src_code = yield(src_code, "completed")
				rv.defs += src_code.defs
				rv.code += src_code.code
				rv.code += "%s_%d += %s*%s;\n" % [ genname, variant_index, coef_str, src_code[convolution_params.input_type] ]
				for t in src_code.textures.keys():
					rv.textures[t] = src_code.textures[t]
		rv.rgb = "%s_%d" % [ genname, variant_index ]
	return rv

func _serialize(data: Dictionary) -> Dictionary:
	data.convolution_params = convolution_params
	return data
