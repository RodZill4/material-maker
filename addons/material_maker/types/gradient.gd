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

func get_point_count() -> int:
	return points.size()

func get_point_position(i : int) -> float:
	return points[i].v

func set_point_position(i : int, v : float) -> void:
	points[i].v = v

func sort() -> void:
	if !sorted:
		points.sort_custom(CustomSorter, "compare")
		for i in range(points.size()-1):
			if points[i].v+0.0000005 >= points[i+1].v:
				points[i+1].v = points[i].v+0.000001
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

func get_shader_params(name) -> Dictionary:
	sort()
	var rv = {}
	for i in range(points.size()):
		rv["p_"+name+"_"+str(i)+"_pos"] = points[i].v
		rv["p_"+name+"_"+str(i)+"_r"] = points[i].c.r
		rv["p_"+name+"_"+str(i)+"_g"] = points[i].c.g
		rv["p_"+name+"_"+str(i)+"_b"] = points[i].c.b
		rv["p_"+name+"_"+str(i)+"_a"] = points[i].c.a
	return rv

# get_color_in_shader
func gcis(color) -> String:
	return "vec4(%.9f,%.9f,%.9f,%.9f)" % [color.r, color.g, color.b, color.a]

func pv(name : String, i : int) -> String:
	return "p_"+name+"_"+str(i)+"_pos"

func pc(name : String, i : int) -> String:
	return "vec4(p_"+name+"_"+str(i)+"_r,p_"+name+"_"+str(i)+"_g,p_"+name+"_"+str(i)+"_b,p_"+name+"_"+str(i)+"_a)"

func get_shader(name) -> String:
	sort()
	var shader
	shader  = "vec4 "+name+"_gradient_fct(float x) {\n"
	match interpolation:
		0:
			if points.size() > 0:
				shader += "  if (x < 0.5*(%s+%s)) {\n" % [ pv(name, 0), pv(name, 1) ]
				shader += "    return "+pc(name, 0)+";\n"
				var s = points.size()-1
				for i in range(1, s):
					shader += "  } else if (x < 0.5*(%s+%s)) {\n" % [ pv(name, i), pv(name, i+1) ]
					shader += "    return "+pc(name, i)+";\n"
				shader += "  }\n"
				shader += "  return "+pc(name, s)+";\n"
			else:
				shader += "  return vec4(0.0, 0.0, 0.0, 1.0);\n"
		1, 2:
			if points.size() > 0:
				shader += "  if (x < %s) {\n" % pv(name, 0)
				shader += "    return "+pc(name, 0)+";\n"
				var s = points.size()-1
				for i in range(s):
					shader += "  } else if (x < %s) {\n" % pv(name, i+1)
					var function = "(" if interpolation == 1 else "0.5-0.5*cos(3.14159265359*"
					shader += "    return mix(%s, %s, %s(x-%s)/(%s-%s)));\n" % [ pc(name, i), pc(name, i+1), function, pv(name, i), pv(name, i+1), pv(name, i) ]
				shader += "  }\n"
				shader += "  return "+pc(name, s)+";\n"
			else:
				shader += "  return vec4(0.0, 0.0, 0.0, 1.0);\n"
		3:
			if points.size() > 0:
				shader += "  if (x < %s) {\n" % pv(name, 0)
				shader += "    return "+pc(name, 0)+";\n"
				var s = points.size()-1
				for i in range(s):
					shader += "  } else if (x < %s) {\n" % pv(name, i+1)
					var dx : String = "(x-%s)/(%s-%s)" % [ pv(name, i), pv(name, i+1), pv(name, i) ]
					var b : String = "mix(%s, %s, %s)" % [ pc(name, i), pc(name, i+1), dx ]
					if i > 0:
						var a : String = "mix(%s, %s, (x-%s)/(%s-%s))" % [ pc(name, i-1), pc(name, i), pv(name, i-1), pv(name, i), pv(name, i-1) ]
						if i < s-1:
							var c : String = "mix(%s, %s, (x-%s)/(%s-%s))" % [ pc(name, i+1), pc(name, i+2), pv(name, i+1), pv(name, i+2), pv(name, i+1) ]
							var ac : String = "mix("+a+", "+c+", 0.5-0.5*cos(3.14159265359*"+dx+"))"
							shader += "    return 0.5*("+b+" + "+ac+");\n"
						else:
							shader += "    return mix("+a+", "+b+", 0.5+0.5*"+dx+");\n"
					elif i < s-1:
						var c : String = "mix(%s, %s, (x-%s)/(%s-%s))" % [ pc(name, i+1), pc(name, i+2), pv(name, i+1), pv(name, i+2), pv(name, i+1) ]
						shader += "    return mix("+c+", "+b+", 1.0-0.5*"+dx+");\n"
					else:
						shader += "    return "+b+";\n"
				shader += "  }\n"
				shader += "  return "+pc(name, s)+";\n"
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
		interpolation = v.interpolation
	else:
		print("Cannot deserialize gradient")
