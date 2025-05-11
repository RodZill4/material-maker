extends RefCounted
class_name MMLattice

var size : Vector2i = Vector2i(1, 1)
var points : PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])

func to_string() -> String:
	var rv = PackedStringArray()
	for p in points:
		rv.append("("+str(p.x)+","+str(p.y)+")")
	return ",".join(rv)

func duplicate() -> Object:
	var copy = MMLattice.new()
	copy.size = size
	copy.points.clear()
	for p in points:
		copy.points.append(p)
	return copy

func compare(lattice) -> bool:
	if lattice.size != size:
		return false
	for i in points.size():
		if points[i] != lattice.points[i]:
			return false
	return true

static func get_point_from_array(v : Vector2i, size : Vector2i, points : PackedVector2Array) -> Vector2:
	return points[v.x+(size.x+1)*v.y]

static func interpolate_point(v : Vector2, size : Vector2i, points : PackedVector2Array) -> Vector2:
	v *= Vector2(size)
	var vs : Vector2i = Vector2i(floor(v.x), floor(v.y))
	vs.x = clampi(vs.x, 0, size.x-1)
	vs.y = clampi(vs.y, 0, size.y-1)
	var vt : Vector2 = Vector2(v.x-vs.x, v.y-vs.y)
	var p00 : Vector2 = get_point_from_array(vs, size, points)
	var p01 : Vector2 = get_point_from_array(vs+Vector2i(0, 1), size, points)
	var p10 : Vector2 = get_point_from_array(vs+Vector2i(1, 0), size, points)
	var p11 : Vector2 = get_point_from_array(vs+Vector2i(1, 1), size, points)
	var p0 : Vector2 = lerp(p00, p01, vt.y)
	var p1 : Vector2 = lerp(p10, p11, vt.y)
	return lerp(p0, p1, vt.x)

func resize(sx : int, sy : int) -> void:
	var old_size : Vector2i = size
	size.x = sx
	size.y = sy
	var old_points : PackedVector2Array = points
	points = PackedVector2Array()
	points.resize((sx+1)*(sy+1))
	for ix in sx+1:
		var x : float = float(ix)/float(size.x)
		for iy in sy+1:
			var y : float = float(iy)/float(size.y)
			set_point(ix, iy, interpolate_point(Vector2(x, y), old_size, old_points))

func get_point(x : int, y : int) -> Vector2:
	return points[x+(size.x+1)*y]

func set_point(x : int, y : int, v : Vector2) -> void:
	points[x+(size.x+1)*y] = v

func get_shader_params(parameter_name : String, attribute : String = "uniform") -> String:
	var rv = ""
	for p : MMGenBase.ShaderUniform in get_parameters(parameter_name):
		rv += p.to_str(attribute)
	return rv

func get_parameters(parameter_name : String) -> Array[MMGenBase.ShaderUniform]:
	var rv : Array[MMGenBase.ShaderUniform] = []
	var parameter_values : Dictionary = get_parameter_values(parameter_name)
	rv.append(MMGenBase.ShaderUniform.new("p_%s_pos" % parameter_name, "vec2", parameter_values["p_%s_pos" % parameter_name], points.size()))
	return rv

func get_parameter_values(parameter_name : String) -> Dictionary:
	var rv : Dictionary = {}
	rv["p_%s_pos" % parameter_name] = points
	return rv

func get_shader(parameter_name : String) -> String:
	return "p_%s_pos" % parameter_name

func serialize() -> Dictionary:
	var rv = []
	for p in points:
		rv.append({ x=p.x, y=p.y })
	return { type="Lattice", size={ x=size.x, y=size.y }, points=rv }

func deserialize(v) -> void:
	if typeof(v) == TYPE_DICTIONARY and v.has("type") and v.type == "Lattice":
		size = Vector2i(int(v.size.x), int(v.size.y))
		points.clear()
		for p in v.points:
			points.push_back(Vector2(p.x, p.y))
	elif typeof(v) == TYPE_OBJECT and v.get_script() == get_script():
		size = v.size
		points.clear()
		for p in v.points:
			points.push_back(p)
	else:
		print("Cannot deserialize lattice")
