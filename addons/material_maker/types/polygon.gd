extends Object
class_name MMPolygon

var points : Array = [Vector2(0.2, 0.2), Vector2(0.7, 0.4), Vector2(0.4, 0.7)]

func to_string() -> String:
	var rv = PoolStringArray()
	for p in points:
		rv.append("("+str(p.x)+","+str(p.y)+")")
	return rv.join(",")

func duplicate() -> Object:
	var copy = get_script().new()
	copy.clear()
	for p in points:
		copy.points.append(p)
	return copy

func clear() -> void:
	points.clear()

func add_point(x : float, y : float, closed : bool = true) -> void:
	var p : Vector2 = Vector2(x, y)
	var points_count = points.size()
	if points_count < 3:
		points.append(p)
		return
	var min_length : float = (p-Geometry.get_closest_point_to_segment_2d(p, points[0], points[points_count-1])).length()
	var insert_point = 0
	for i in points_count-1:
		var length = (p-Geometry.get_closest_point_to_segment_2d(p, points[i], points[i+1])).length()
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
		points.remove(index)
	return true

func get_point_count() -> int:
	return points.size()

func get_point(i : int) -> Vector2:
	return points[i]

func set_point(i : int, v : Vector2) -> void:
	points[i] = v

func get_shader() -> String:
	var elements : PoolStringArray = PoolStringArray()
	for p in points:
		elements.append("vec2(%.9f, %.9f)" % [p.x, p.y])
	return "{"+elements.join(", ")+"}"

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
