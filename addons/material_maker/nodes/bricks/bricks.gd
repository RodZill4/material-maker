tool
extends "res://addons/material_maker/node_base.gd"

var pattern = 0
var repeat
var rows
var columns
var row_offset
var mortar
var bevel

const BRICK_PATTERNS = [
	{ name="Running bond",     suffix="rb",  has_offset=true,  has_repeat=false },
	{ name="Running bond (2)", suffix="rb2", has_offset=true,  has_repeat=false },
	{ name="HerringBone",      suffix="hb",  has_offset=false, has_repeat=true  },
	{ name="Basket weave",     suffix="bw",  has_offset=false, has_repeat=true  },
	{ name="Spanish bond",     suffix="sb",  has_offset=false, has_repeat=true  }
]

func _ready():
	$pattern.clear()
	for p in BRICK_PATTERNS:
		$pattern.add_item(p.name)
	initialize_properties([ $pattern, $HBoxContainer1/rows, $HBoxContainer2/columns, $HBoxContainer6/repeat, $HBoxContainer3/row_offset, $HBoxContainer4/mortar, $HBoxContainer5/bevel ])

func _get_shader_code(uv, slot = 0):
	var rv = { defs="", code="" }
	if generated_variants.empty():
		rv.defs = "vec3 %s_xyz(vec2 uv) { return bricks_%s(uv, vec2(%d, %d), %.9f, %.9f, %.9f, %.9f); }\n" % [ name, BRICK_PATTERNS[pattern].suffix, columns, rows, repeat, row_offset, mortar, max(0.001, bevel) ]
	var variant_index = generated_variants.find(uv)
	if variant_index == -1:
		variant_index = generated_variants.size()
		generated_variants.append(uv)
		rv.code = "vec3 %s_%d_xyz = %s_xyz(%s);\n" % [ name, variant_index, name, uv ]
	if slot == 0:
		rv.f = "%s_%d_xyz.x" % [ name, variant_index ]
	else:
		rv.rgb = "rand3(%s_%d_xyz.yz+vec2(%.9f))" % [ name, variant_index, get_seed() ]
	return rv

func _on_offset_changed():
	update_shaders()
