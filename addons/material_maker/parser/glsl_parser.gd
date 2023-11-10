extends "res://addons/material_maker/parser/glsl_parser_base.gd"

const REGEXS : Array = [
	{ type="ignore", regex="^[\\s\\r\\n]+" },
	{ type="ignore", regex="^//.*?[\\r\\n]" },
	{ type="ignore", regex="^/\\*(?:.|[\\r\\n])*?\\*/" },
	{ type="FLOATCONSTANT", regex="^(\\d*[.])?\\d+([eE][-+]?\\d+)?" },
	{ type="IDENTIFIER", regex="^\\$?[\\w_]+" },
	{ type="SYMBOLS", regex="^==" },
	{ type="SYMBOLS", regex="^(<<|>>|&&|\\|\\||^^)=" },
	{ type="SYMBOLS", regex="^(\\|\\||\\&\\&|\\^\\^|\\+\\+|--)" },
	{ type="SYMBOLS", regex="^[+-/*\\%<>!&|^]=" },
	{ type="SYMBOLS", regex="^[+-/*=<>)(,;\\{\\}.&|?:^]" },
]

const KEYWORDS = [  "const", "if", "else", "for", "while", "break", "continue", "return",
					"in", "out" ]

const TYPES = [ "void", "float", "int", "bool", "vec2", "vec3", "vec4",
				"bvec2", "bvec3", "bvec4", "ivec2", "ivec3", "ivec4",
				"mat2", "mat3", "mat4", "mat2x2", "mat2x3", "mat2x4",
				"mat3x2", "mat3x3", "mat3x4", "mat4x2", "mat4x3", "mat4x4",
				"sampler1d", "sampler2d", "sampler3d", "samplercube",
				"sampler1dshadow", "sampler2dshadow" ]

func _init():
	super._init()
	init_lexer(REGEXS)

func create_token(type : String, value, pos_begin : int, pos_end : int) -> Token:
	match type:
		"FLOATCONSTANT":
			return super.create_token(type, value.to_float(), pos_begin, pos_end)
		"IDENTIFIER":
			if value in KEYWORDS:
				return super.create_token(value.to_upper(), null, pos_begin, pos_end)
			if value in TYPES:
				return super.create_token("TYPE", value.to_upper(), pos_begin, pos_end)
			return super.create_token(type, value, pos_begin, pos_end)
		"SYMBOLS":
			return super.create_token(value, null, pos_begin, pos_end)
		_:
			return super.create_token(type, value, pos_begin, pos_end)

var selection_regex : RegEx

func build_field_selection_test(t1):
	if selection_regex == null:
		selection_regex = RegEx.new()
		selection_regex.compile("[^rgbaxyzw]")
	if selection_regex.search(t1.value):
		return null
	return t1.value

func build_function_header(t1, t2, t3):
	return { return_type=t1, name=t2, parameters=[] }

func build_function_header_with_parameters(t1, t2):
	t1.value.parameters.push_back(t2)
	return t1.value

func build_function_header_with_parameters_2(t1, t2, t3):
	t1.value.parameters.push_back(t3)
	return t1.value

func build_function_call_header(t1, t2):
	return { name=t1, parameters=[] }

func build_function_call_header_with_parameters(t1, t2):
	t1.value.parameters.push_back(t2)
	return t1.value

func build_function_call_header_with_parameters_2(t1, t2, t3):
	t1.value.parameters.push_back(t3)
	return t1.value

func build_translation_unit(t1):
	return [ t1 ]

func build_translation_unit_2(t1, t2):
	t1.value.push_back(t2)
	return t1.value

