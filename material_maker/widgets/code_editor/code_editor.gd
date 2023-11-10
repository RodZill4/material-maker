extends CodeEdit


const KEYWORDS : Array[String]  = [ "attribute", "uniform", "varying", "const", "in", "out",
									"inout", "discard", "return", "break", "continue", "do",
									"for", "while", "if", "else", "switch", "case", "default",
									"true", "false", "highp", "mediump", "lowp", "precision",
									"struct" ]
const TYPES : Array[String] = [ "void", "bool", "int", "uint", "float", "double", "bvec2",
								"bvec3", "bvec4", "ivec2", "ivec3", "ivec4", "uvec2",
								"uvec3", "uvec4", "vec2", "vec3", "vec4", "dvec2",
								"dvec3", "dvec4", "mat2", "mat3", "mat4", "mat2x2",
								"mat2x3", "mat2x4", "mat3x2", "mat3x3", "mat3x4",
								"mat4x2", "mat4x3", "mat4x4", "sampler1D", "sampler2D",
								"sampler3D", "samplerCube" ]

const FUNCTIONS : Array[String] = [ "radians", "degrees", "sin", "cos", "tan", "asin",
									"acos", "atan", "pow", "exp", "log", "exp2", "log2",
									"sqrt", "inversesqrt", "abs", "sign", "floor", "ceil",
									"fract", "mod", "min", "max", "clamp", "mix", "step",
									"smoothstep", "length", "distance", "dot", "cross",
									"normalize" ]

func _ready():
	add_comment_delimiter("//", "", true)
	add_comment_delimiter("/*", "*/", false)
	for t in KEYWORDS:
		syntax_highlighter.add_keyword_color(t, Color(1.0, 0.6, 0.6))
	for t in TYPES:
		syntax_highlighter.add_keyword_color(t, Color(1.0, 1.0, 0.5))
	for t in FUNCTIONS:
		syntax_highlighter.add_keyword_color(t, Color(0.5, 0.5, 1.0))
