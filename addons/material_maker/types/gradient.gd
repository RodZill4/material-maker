extends Object
class_name MMGradient

class CustomSorter:
	static func compare(a, b) -> bool:
		return a.v < b.v

var points = [ { v=0.0, c=Color(0.0, 0.0, 0.0, 0.0) }, { v=1.0, c=Color(1.0, 1.0, 1.0, 1.0) } ]
var interpolation = 1
var sorted = true

func to_string() -> String:
	var rv = PoolStringArray()
	for p in points:
		rv.append("("+str(p.v)+","+str(p.c)+")")
	return rv.join(",")

func duplicate() -> Object:
	var copy = get_script().new()
	copy.clear()
	for p in points:
		copy.add_point(p.v, p.c)
	return copy

func clear() -> void:
	points.clear()
	sorted = true

func add_point(v, c) -> void:
	points.append({ v=v, c=c })
	sorted = false

func sort() -> void:
	if !sorted:
		points.sort_custom(CustomSorter, "compare")
		sorted = true

func get_color(x) -> Color:
	sort()
	if points.size() > 0:
		if x < points[0].v:
			return points[0].c
		var s = points.size()-1
		for i in range(s):
			if x < points[i+1].v:
				var p0 = points[i].v
				var c0 = points[i].c
				var p1 = points[i+1].v
				var c1 = points[i+1].c
				return c0 + (c1-c0) * (x-p0) / (p1-p0)
		return points[s].c
	else:
		return Color(0.0, 0.0, 0.0, 1.0)

# get_color_in_shader
func gcis(color) -> String:
	return "vec4(%.9f,%.9f,%.9f,%.9f)" % [color.r, color.g, color.b, color.a]

func get_shader(name) -> String:
	sort()
	var shader
	shader  = "vec4 "+name+"(float x) {\n"
	match interpolation:
		0:
			if points.size() > 0:
				shader += "  if (x < %.9f) {\n" % (0.5*(points[0].v + points[1].v))
				shader += "    return "+gcis(points[0].c)+";\n"
				var s = points.size()-1
				for i in range(s):
					var p0 = points[i].v
					var c0 = points[i].c
					var p1mp0 = points[i+1].v-p0
					var c1mc0 = points[i+1].c-c0
					if p1mp0 > 0:
						shader += "  } else if (x < %.9f) {\n" % (0.5*(points[i].v + points[i+1].v))
						shader += "    return "+gcis(points[i].c)+";\n"
				shader += "  }\n"
				shader += "  return "+gcis(points[s].c)+";\n"
			else:
				shader += "  return vec4(0.0, 0.0, 0.0, 1.0);\n"
		1, 2:
			if points.size() > 0:
				shader += "  if (x < %.9f) {\n" % points[0].v
				shader += "    return "+gcis(points[0].c)+";\n"
				var s = points.size()-1
				for i in range(s):
					var p1mp0 = points[i+1].v-points[i].v
					if p1mp0 > 0:
						shader += "  } else if (x < %.9f) {\n" % points[i+1].v
						var function = "(" if interpolation == 1 else "0.5-0.5*cos(3.14159265359*"
						shader += "    return mix(%s, %s, %s(x-%.9f)/%.9f));\n" % [ gcis(points[i].c), gcis(points[i+1].c), function, points[i].v, p1mp0 ]
				shader += "  }\n"
				shader += "  return "+gcis(points[s].c)+";\n"
			else:
				shader += "  return vec4(0.0, 0.0, 0.0, 1.0);\n"
		3:
			if points.size() > 0:
				shader += "  if (x < %.9f) {\n" % points[0].v
				shader += "    return "+gcis(points[0].c)+";\n"
				var s = points.size()-1
				for i in range(s):
					var p1mp0 = points[i+1].v-points[i].v
					if p1mp0 > 0:
						shader += "  } else if (x < %.9f) {\n" % points[i+1].v
						var dx : String = "(x-%.9f)/%.9f" % [ points[i].v, p1mp0 ]
						var b : String = "mix(%s, %s, %s)" % [ gcis(points[i].c), gcis(points[i+1].c), dx ]
						if i > 0 and points[i-1].v < points[i].v:
							var a : String = "mix(%s, %s, (x-%.9f)/%.9f)" % [ gcis(points[i-1].c), gcis(points[i].c), points[i-1].v, points[i].v-points[i-1].v ]
							if i < s-1 and points[i+1].v < points[i+2].v:
								var c : String = "mix(%s, %s, (x-%.9f)/%.9f)" % [ gcis(points[i+1].c), gcis(points[i+2].c), points[i+1].v, points[i+2].v-points[i+1].v ]
								var ac : String = "mix("+a+", "+c+", 0.5-0.5*cos(3.14159265359*"+dx+"))"
								shader += "    return 0.5*("+b+" + "+ac+");\n"
							else:
								shader += "    return mix("+a+", "+b+", 0.5+0.5*"+dx+");\n"
						elif i < s-1 and points[i+1].v < points[i+2].v:
							var c : String = "mix(%s, %s, (x-%.9f)/%.9f)" % [ gcis(points[i+1].c), gcis(points[i+2].c), points[i+1].v, points[i+2].v-points[i+1].v ]
							shader += "    return mix("+c+", "+b+", 1.0-0.5*"+dx+");\n"
						else:
							shader += "    return "+b+";\n"
				shader += "  }\n"
				shader += "  return "+gcis(points[s].c)+";\n"
			else:
				shader += "  return vec4(0.0, 0.0, 0.0, 1.0);\n"
		_:
			print("interpolation: "+str(interpolation))
	shader += "}\n"
	return shader

func serialize() -> Dictionary:
	sort()
	var rv = []
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
	elif typeof(v) == TYPE_DICTIONARY and v.has("type") && v.type == "Gradient":
		for i in v.points:
			if !i.has("a"): i.a = 1.0
			add_point(i.pos, Color(i.r, i.g, i.b, i.a))
		if v.has("interpolation"):
			interpolation = int(v.interpolation)
		else:
			interpolation = 1
	elif typeof(v) == TYPE_OBJECT and v.get_script() == get_script():
		clear()
		for p in v.points:
			add_point(p.v, p.c)
	else:
		print("Cannot deserialize gradient")
