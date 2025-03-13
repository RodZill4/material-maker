extends RefCounted
class_name MMGradient

class Point:
	var v : float
	var c : Color
	func _init(pos : float, color : Color):
		v = pos
		c = color

class CustomSorter:
	static func compare(a : Point, b : Point) -> bool:
		return a.v < b.v

var points = [ Point.new(0.0, Color(0.0, 0.0, 0.0, 0.0)), { v=1.0, c=Color(1.0, 1.0, 1.0, 1.0) } ]

enum {CONSTANT=0, LINEAR=1, SMOOTHSTEP=2, CUBIC=3}
var interpolation := LINEAR
var sorted := true

func to_string() -> String:
	var rv := PackedStringArray()
	for p in points:
		rv.append("("+str(p.v)+","+str(p.c)+")")
	return ",".join(rv)

func duplicate() -> Object:
	var copy = get_script().new()
	copy.clear()
	for p in points:
		copy.add_point(p.v, p.c)
	copy.interpolation = interpolation
	return copy


func clear() -> void:
	points.clear()
	sorted = true


func add_point(v : float, c : Color) -> void:
	points.append(Point.new(v, c))
	sorted = false


func get_point_count() -> int:
	return points.size()


func get_point_position(i : int) -> float:
	return points[i].v


func set_point_position(i : int, v : float) -> void:
	points[i].v = v
	sorted = false


func sort() -> void:
	if not sorted:
		points.sort_custom(Callable(CustomSorter, "compare"))
		for i in range(points.size()-1):
			if points[i].v+0.0000005 >= points[i+1].v:
				points[i+1].v = points[i].v+0.000001
		sorted = true


func get_color(x:float) -> Color:
	sort()
	if points.size() > 0:
		# x is before the first point
		if x < points[0].v:
			return points[0].c

		# x is after the last point
		var s := points.size()-1
		if x > points[s].v:
			return points[s].c

		for i in range(s):
			if x < points[i+1].v:
				return get_color_between_points(i, i+1, x)

	return Color(0.0, 0.0, 0.0, 1.0)


func get_shader_params(parameter_name : String, attribute : String = "uniform") -> String:
	var rv := ""
	for p : MMGenBase.ShaderUniform in get_parameters(parameter_name):
		rv += p.to_str(attribute)
	return rv


func get_parameters(parameter_name : String) -> Array[MMGenBase.ShaderUniform]:
	var rv : Array[MMGenBase.ShaderUniform] = []
	var parameter_values : Dictionary = get_parameter_values(parameter_name)
	rv.append(MMGenBase.ShaderUniform.new("p_%s_pos" % parameter_name, "float", parameter_values["p_%s_pos" % parameter_name], points.size()))
	rv.append(MMGenBase.ShaderUniform.new("p_%s_col" % parameter_name, "vec4", parameter_values["p_%s_col" % parameter_name], points.size()))
	return rv


func get_parameter_values(parameter_name : String) -> Dictionary:
	sort()
	var rv : Dictionary = {}
	var point_positions : PackedFloat32Array = PackedFloat32Array()
	var point_colors : PackedColorArray = PackedColorArray()
	for i in range(points.size()):
		point_positions.append(points[i].v)
		point_colors.append(points[i].c)
	rv["p_%s_pos" % parameter_name] = point_positions
	rv["p_%s_col" % parameter_name] = point_colors
	return rv

# get_color_in_shader
func gcis(color : Color) -> String:
	return "vec4(%.9f,%.9f,%.9f,%.9f)" % [color.r, color.g, color.b, color.a]

func pv(parameter_name : String, i : int) -> String:
	return "p_"+parameter_name+"_pos["+str(i)+"]"

func pc(parameter_name : String, i : int) -> String:
	return "p_"+parameter_name+"_col["+str(i)+"]"

func get_shader(parameter_name : String) -> String:
	sort()
	var shader: String
	shader  = "vec4 "+parameter_name+"_gradient_fct(float x) {\n"
	match interpolation:
		CONSTANT:
			if points.size() > 0:
				shader += "  if (x < %s) {\n" % pv(parameter_name, 1)
				shader += "    return "+pc(parameter_name, 0)+";\n"
				var s = points.size()-1
				for i in range(1, s):
					shader += "  } else if (x < %s) {\n" % pv(parameter_name, i+1)
					shader += "    return "+pc(parameter_name, i)+";\n"
				shader += "  }\n"
				shader += "  return "+pc(parameter_name, s)+";\n"
			else:
				shader += "  return vec4(0.0, 0.0, 0.0, 1.0);\n"
		LINEAR, SMOOTHSTEP:
			if points.size() > 0:
				shader += "  if (x < %s) {\n" % pv(parameter_name, 0)
				shader += "    return "+pc(parameter_name, 0)+";\n"
				var s = points.size()-1
				for i in range(s):
					shader += "  } else if (x < %s) {\n" % pv(parameter_name, i+1)
					var function = "(" if interpolation == LINEAR else "0.5-0.5*cos(3.14159265359*"
					shader += "    return mix(%s, %s, %s(x-%s)/(%s-%s)));\n" % [ pc(parameter_name, i), pc(parameter_name, i+1), function, pv(parameter_name, i), pv(parameter_name, i+1), pv(parameter_name, i) ]
				shader += "  }\n"
				shader += "  return "+pc(parameter_name, s)+";\n"
			else:
				shader += "  return vec4(0.0, 0.0, 0.0, 1.0);\n"
		CUBIC:
			if points.size() > 0:
				shader += "  if (x < %s) {\n" % pv(parameter_name, 0)
				shader += "    return "+pc(parameter_name, 0)+";\n"
				var s = points.size()-1
				for i in range(s):
					shader += "  } else if (x < %s) {\n" % pv(parameter_name, i+1)
					var dx : String = "(x-%s)/(%s-%s)" % [ pv(parameter_name, i), pv(parameter_name, i+1), pv(parameter_name, i) ]
					var b : String = "mix(%s, %s, %s)" % [ pc(parameter_name, i), pc(parameter_name, i+1), dx ]
					if i > 0:
						var a : String = "mix(%s, %s, (x-%s)/(%s-%s))" % [ pc(parameter_name, i-1), pc(parameter_name, i), pv(parameter_name, i-1), pv(parameter_name, i), pv(parameter_name, i-1) ]
						if i < s-1:
							var c : String = "mix(%s, %s, (x-%s)/(%s-%s))" % [ pc(parameter_name, i+1), pc(parameter_name, i+2), pv(parameter_name, i+1), pv(parameter_name, i+2), pv(parameter_name, i+1) ]
							var ac : String = "mix("+a+", "+c+", 0.5-0.5*cos(3.14159265359*"+dx+"))"
							shader += "    return 0.5*("+b+" + "+ac+");\n"
						else:
							shader += "    return mix("+a+", "+b+", 0.5+0.5*"+dx+");\n"
					elif i < s-1:
						var c : String = "mix(%s, %s, (x-%s)/(%s-%s))" % [ pc(parameter_name, i+1), pc(parameter_name, i+2), pv(parameter_name, i+1), pv(parameter_name, i+2), pv(parameter_name, i+1) ]
						shader += "    return mix("+c+", "+b+", 1.0-0.5*"+dx+");\n"
					else:
						shader += "    return "+b+";\n"
				shader += "  }\n"
				shader += "  return "+pc(parameter_name, s)+";\n"
			else:
				shader += "  return vec4(0.0, 0.0, 0.0, 1.0);\n"
		_:
			print("interpolation: "+str(interpolation))
	shader += "}\n"
	return shader

func serialize() -> Dictionary:
	sort()
	var rv = []
	if interpolation == CONSTANT:
		var p : Point = points[0]
		rv.append({ pos=0, r=p.c.r, g=p.c.g, b=p.c.b, a=p.c.a })
		for i in range(1, points.size()):
			var next_p : Point = points[i]
			rv.append({ pos=next_p.v-0.00001, r=p.c.r, g=p.c.g, b=p.c.b, a=p.c.a })
			p = next_p
			rv.append({ pos=next_p.v+0.00001, r=p.c.r, g=p.c.g, b=p.c.b, a=p.c.a })
	else:
		for p in points:
			rv.append({ pos=p.v, r=p.c.r, g=p.c.g, b=p.c.b, a=p.c.a })
	rv = { type="Gradient", points=rv, interpolation=interpolation }
	return rv

func deserialize(v) -> void:
	clear()
	if typeof(v) == TYPE_ARRAY:
		for i in v:
			if !i.has("a"): i.a = 1.0
			add_point(i.pos, Color(i.r, i.g, i.b, i.a))
			interpolation = 1
	elif typeof(v) == TYPE_DICTIONARY and v.has("type") && v.type == "Gradient":
		for i in v.points:
			if !i.has("a"): i.a = 1.0
			add_point(i.pos, Color(i.r, i.g, i.b, i.a))
		if v.has("interpolation"):
			interpolation = int(v.interpolation)
			if interpolation == CONSTANT:
				for i in range(points.size()-1, 0, -1):
					if points[i].c == points[i-1].c:
						points.remove_at(i)
					else:
						points[i].v = 0.5*(points[i-1].v+points[i].v)
				points[0].v = 0
		else:
			interpolation = LINEAR
	elif typeof(v) == TYPE_OBJECT and v.get_script() == get_script():
		clear()
		for p in v.points:
			add_point(p.v, p.c)
		interpolation = v.interpolation
	else:
		print("Cannot deserialize gradient "+str(v))


func effect_reverse() -> void:
	for i in range(get_point_count()):
		set_point_position(i, 1-get_point_position(i))


func effect_evenly_distribute() -> void:
	for i in range(get_point_count()):
		set_point_position(i, 1.0/(get_point_count()-1)*i)


func effect_simplify(threshold := 0.05) -> void:
	sort()
	while true:
		var most_useless_point := -1
		var most_useless_strength := 10.0

		for point in range(get_point_count()):
			var uselessness := 10.0
			var point_color: Color = points[point].c
			if point == 0:
				uselessness = get_color_difference(point_color, points[point+1].c)
			elif point == get_point_count()-1:
				uselessness = get_color_difference(point_color, points[point-1].c)

			else:
				uselessness = get_color_difference(point_color,
					get_color_between_points(point-1, point+1, points[point].v))

			if uselessness < most_useless_strength:
				most_useless_point = point
				most_useless_strength = uselessness

		if most_useless_strength > threshold or get_point_count()<3:
			break

		points.remove_at(most_useless_point)


func get_color_difference(color1: Color, color2: Color) -> float:
	return abs((color1.r-color2.r)+(color1.g-color2.g) + (color1.b-color2.b) + (color1.a-color2.a))


func get_color_between_points(point1:int, point2:int, global_offset:float) -> Color:
	# point left to the offset
	var pl: Point = points[point1]
	# point right to the offset
	var pr: Point = points[point2]

	# offset relative between the two points
	var offset := local_offset(point1, point2, global_offset)#(global_offset-pl.v)/(pr.v-pl.v)

	if interpolation == CONSTANT:
		return pl.c
	# LINEAR
	elif interpolation == LINEAR:
		return pl.c.lerp(pr.c, offset)
	# SMOOTHSTEP
	elif interpolation == SMOOTHSTEP:
		return pl.c.lerp(pr.c, 0.5-0.5*cos(3.14159265359*offset))
	# CUBIC
	elif interpolation == CUBIC:
		if point1 == 0:
			var factor := 1.0 - 0.5 * offset
			var next_section_lerp := pr.c.lerp(points[point2+1].c, local_offset(point2, point2+1, global_offset))
			var this_section_lerp := pl.c.lerp(pr.c, offset)

			return next_section_lerp.lerp(this_section_lerp, factor)

		elif point2 == len(points)-1:
			var factor := 0.5 + 0.5 * offset
			var this_section_lerp := pl.c.lerp(pr.c, offset)
			var prev_section_lerp: Color = points[point1-1].c.lerp(pl.c, local_offset(point1-1, point1, global_offset))

			return prev_section_lerp.lerp(this_section_lerp, factor)

		else:
			var this_section_lerp := pl.c.lerp(pr.c, offset)

			var prev_section_lerp: Color = points[point1-1].c.lerp(pl.c, local_offset(point1-1, point1, global_offset))
			var next_section_lerp: Color = pr.c.lerp(points[point2+1].c, local_offset(point2, point2+1, global_offset))

			var final := 0.5 * (this_section_lerp + prev_section_lerp.lerp(next_section_lerp, 0.5-0.5*cos(3.14159265359 * offset)))

			return final

	return pl.c


func local_offset(point1:int, point2:int, global_offset:float) -> float:
	return (global_offset-points[point1].v)/(points[point2].v-points[point1].v)
