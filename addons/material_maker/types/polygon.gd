extends RefCounted
class_name MMPolygon

var points : PackedVector2Array = PackedVector2Array([Vector2(0.2, 0.2), Vector2(0.7, 0.4), Vector2(0.4, 0.7)])

func to_string() -> String:
	var rv = PackedStringArray()
	for p in points:
		rv.append("("+str(p.x)+","+str(p.y)+")")
	return ",".join(rv)

func duplicate() -> Object:
	var copy = get_script().new()
	copy.clear()
	for p in points:
		copy.points.append(p)
	return copy

func clear() -> void:
	points.clear()

func compare(polygon) -> bool:
	if polygon.points.size() != points.size():
		return false
	for i in points.size():
		if points[i] != polygon.points[i]:
			return false
	return true

func add_point(x : float, y : float, closed : bool = true) -> void:
	var p : Vector2 = Vector2(x, y)
	var points_count = points.size()
	if points_count < 3:
		points.append(p)
		return
	var min_length : float = (p-Geometry2D.get_closest_point_to_segment(p, points[0], points[points_count-1])).length()
	var insert_point = 0
	for i in points_count-1:
		var length = (p-Geometry2D.get_closest_point_to_segment(p, points[i], points[i+1])).length()
		if length < min_length:
			min_length = length
			insert_point = i+1
	if !closed and insert_point == 0 and (points[0]-p).length() > (points[points_count-1]-p).length():
		insert_point = points_count
	points.insert(insert_point, p)

func remove_point(index : int) -> bool:
	var s = points.size()
	if s < 4 or index < 0 or index >= s:
		return false
	else:
		points.remove_at(index)
	return true

func get_point_count() -> int:
	return points.size()

func get_point(i : int) -> Vector2:
	return points[i]

func set_point(i : int, v : Vector2) -> void:
	points[i] = v

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
	return { type="Polygon", points=rv }

func deserialize(v) -> void:
	clear()
	if typeof(v) == TYPE_DICTIONARY and v.has("type") and v.type == "Polygon":
		for p in v.points:
			points.push_back(Vector2(p.x, p.y))
	elif typeof(v) == TYPE_OBJECT and v.get_script() == get_script():
		clear()
		for p in v.points:
			points.push_back(Vector2(p.x, p.y))
	else:
		print("Cannot deserialize polygon")
