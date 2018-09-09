extends Object

class CustomSorter:
	static func compare(a, b):
		return a.v < b.v

var points = [ { v=0.0, c=Color(0.0, 0.0, 0.0) }, { v=1.0, c=Color(1.0, 1.0, 1.0) } ]
var sorted = true

func _ready():
	pass

func duplicate():
	var copy = get_script().new()
	copy.clear()
	for p in points:
		copy.add_point(p.v, p.c)
	return copy

func clear():
	points.clear()
	sorted = true

func add_point(v, c):
	points.append({ v=v, c=c })
	sorted = false

func sort():
	if !sorted:
		points.sort_custom(CustomSorter, "compare")
		sorted = true

func get_color(x):
	sort()
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

# get_color_in_shader
func gcis(color):
	return "vec3(%.9f,%.9f,%.9f)" % [color.r, color.g, color.b]

func get_shader(name):
	sort()
	var shader
	shader  = "vec3 "+name+"(float x) {\n"
	shader += "  if (x < %.9f) {\n" % points[0].v
	shader += "    return "+gcis(points[0].c)+";\n"
	var s = points.size()-1
	for i in range(s):
		var p0 = points[i].v
		var c0 = points[i].c
		var p1mp0 = points[i+1].v-p0
		var c1mc0 = points[i+1].c-c0
		if p1mp0 > 0:
			shader += "  } else if (x < %.9f) {\n" % points[i+1].v
			shader += "    return %s+x*%s;\n" % [gcis(c0-c1mc0*(p0/p1mp0)), gcis(c1mc0/p1mp0)]
	shader += "  }\n"
	shader += "  return "+gcis(points[s].c)+";\n"
	shader += "}\n"
	return shader

func serialize():
	sort()
	var rv = []
	for p in points:
		rv.append({ pos=p.v, r=p.c.r, g=p.c.g, b=p.c.b })
	rv = { type="Gradient", points=rv }
	return rv

func deserialize(v):
	clear()
	if typeof(v) == TYPE_ARRAY:
		for i in v:
			add_point(i.pos, Color(i.r, i.g, i.b))
	elif typeof(v) == TYPE_DICTIONARY && v.has("type") && v.type == "Gradient":
		for i in v.points:
			add_point(i.pos, Color(i.r, i.g, i.b))
