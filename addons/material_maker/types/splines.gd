extends RefCounted
class_name MMSplines


class SplinesPoint:
	var position : Vector2
	var width : float
	var offset : float
	
	func _init(p : Vector2 = Vector2(0, 0), w : float = 0.01, o : float = 0.0):
		position = p
		width = w
		offset = o

class Bezier:
	var points : Array[SplinesPoint]
	
	func _init():
		for i in range(4):
			points.append(SplinesPoint.new())


var splines : Array[Bezier] = []
var point_groups : Array = []


func _to_string() -> String:
	var rv = PackedStringArray()
	for s in splines:
		for i in range(4):
			var p : SplinesPoint = s.points[i]
			rv.append("("+str(p.position.x)+","+str(p.position.y)+"/"+str(p.width)+"/"+str(p.offset)+")")
	return ",".join(rv)

func duplicate() -> Object:
	var copy = get_script().new()
	copy.splines = splines.duplicate(true)
	return copy

func clear() -> void:
	splines.clear()

func compare(spline) -> bool:
	if spline.splines.size() != splines.size():
		return false
	for i in splines.size():
		if not splines[i].is_equal(spline.splines[i]):
			return false
	return true

func get_point_index(s : int, p : int) -> int:
	return (s << 2) + p

func get_point_by_index(i : int) -> SplinesPoint:
	return splines[i >> 2].points[i & 3]

func add_bezier(b : Bezier) -> int:
	var rv : int = splines.size()
	splines.append(b)
	return rv

func move_points(points : Array[int], offset : Vector2):
	for p in points:
		get_point_by_index(p).position += offset

func move_point(point_index : int, new_position : Vector2, other_points : Array[int] = []) -> void:
	var offset : Vector2 = new_position - get_point_by_index(point_index).position
	var tmp_points : Array[int] = other_points.duplicate()
	if not point_index in tmp_points:
		tmp_points.append(point_index)
	for g in point_groups:
		var insert_group : bool = false
		if point_index in g:
			insert_group = true
		else:
			for p in other_points:
				if p in g:
					insert_group = true
					break
		if insert_group:
			for p in g:
				if not p in tmp_points:
					tmp_points.append(p)
	var points : Array[int] = []
	for p in tmp_points:
		if not p in points:
			points.append(p)
			match p & 3:
				0:
					var new_p = 1 | (p & ~3)
					if not new_p in points:
						points.append(new_p)
				3:
					var new_p = 2 | (p & ~3)
					if not new_p in points:
						points.append(new_p)
	move_points(points, offset)

func delete_points_by_index(points : Array[int]) -> void:
	# Gather all connected points
	var deleted_splines : Array[int] = []
	for p in points:
		var s : int = p >> 2
		if not s in deleted_splines:
			deleted_splines.append(s)
		for g in point_groups:
			if p in g:
				for p2 in g:
					var s2 : int = p2 >> 2
					if not s2 in deleted_splines:
						deleted_splines.append(s2)
	# Create new splines list
	var new_indexes : Array[int]
	var new_splines : Array[Bezier] = []
	new_indexes.resize(splines.size())
	new_indexes.fill(-1)
	for i in splines.size():
		if not i in deleted_splines:
			new_indexes[i] = new_splines.size()
			new_splines.append(splines[i])
	splines = new_splines
	# Update point groups
	var new_point_groups : Array = []
	for g in point_groups:
		var new_point_group : Array[int] = []
		for fi in g:
			var i : int = int(fi)
			var s : int = i >> 2
			if s >=0 and s < new_indexes.size() and new_indexes[s] != -1:
				new_point_group.append((i & 3) | (new_indexes[s] << 2))
		if new_point_group.size() > 1:
			new_point_groups.append(new_point_group)
	point_groups = new_point_groups

func link_points_by_index(i1 : int, i2 : int) -> void:
	var g1 = null
	var g2 = null
	if (i1 & 3) == 1 or (i1 & 3) == 2 or (i2 & 3) == 1 or (i2 & 3) == 2:
		return
	for g in point_groups:
		if g.find(i1) != -1:
			g1 = g
		elif g.find(i2) != -1:
			g2 = g
	if g1 != null:
		if g2 != null:
			if g1 != g2:
				g1.append_array(g2)
				point_groups.erase(g2)
		else:
			g1.append(i2)
		g1.sort()
	elif g2 != null:
		g2.append(i1)
		g2.sort()
		g1 = g2
	else:
		g1 = PackedInt32Array()
		g1.append(i1)
		g1.append(i2)
		g1.sort()
		point_groups.append(g1)
	var avg_position : Vector2 = Vector2(0, 0)
	for i in g1:
		avg_position += get_point_by_index(i).position
	avg_position /= g1.size()
	for i in g1:
		get_point_by_index(i).position = avg_position

func link_points(b1 : int, p1 : int, b2 : int, p2 : int) -> void:
	assert(p1 >= 0 and p1 < 4)
	assert(p2 >= 0 and p2 < 4)
	link_points_by_index(get_point_index(b1, p1), get_point_index(b2, p2))

func unlink_points_by_index(i : int) -> void:
	for g in point_groups:
		if i in g:
			point_groups.erase(g)
			break

func is_linked(b : int, p : int) -> bool:
	var i : int = b * 4 + p
	for g in point_groups:
		var found : int = g.find(i)
		if found > 0:
			return true
	return false

func set_points_property(points : Array[int], property : StringName, value : float, smooth : bool = false):
	if points.is_empty():
		return
	var v : float = value
	var value0 : float = get_point_by_index(points[0]).get(property)
	var den : float = points.size()-1
	for pi in points.size():
		var p : int = points[pi]
		var point = get_point_by_index(p)
		if smooth and den > 0:
			v = lerp(value0, value, pi/den)
		point.set(property, v)
		for g in point_groups:
			if p in g:
				for p2 in g:
					var point2 = get_point_by_index(p2)
					point2.set(property, v)

func set_points_width(points : Array[int], width : float, smooth : bool = false):
	set_points_property(points, "width", width, smooth)

func set_points_offset(points : Array[int], offset : float, smooth : bool = false):
	set_points_property(points, "offset", offset, smooth)

func get_packed_array() -> PackedFloat32Array:
	var values : PackedFloat32Array = PackedFloat32Array()
	for s in splines:
		for i in range(4):
			var p : SplinesPoint = s.points[i]
			values.append(p.position.x)
			values.append(p.position.y)
			values.append(p.width)
			values.append(p.offset)
	return values

func get_shader_params(parameter_name : String, attribute : String = "uniform") -> String:
	var rv = ""
	for p : MMGenBase.ShaderUniform in get_parameters(parameter_name):
		rv += p.to_str(attribute)
	return rv

func get_parameters(parameter_name : String) -> Array[MMGenBase.ShaderUniform]:
	var rv : Array[MMGenBase.ShaderUniform] = []
	var values : PackedFloat32Array = get_packed_array()
	rv.append(MMGenBase.ShaderUniform.new("p_%s_points" % parameter_name, "vec4", values, values.size()/4))
	return rv

func get_parameter_values(parameter_name : String) -> Dictionary:
	var rv : Dictionary = {}
	rv["p_%s_points" % parameter_name] = get_packed_array()
	return rv

func get_shader(parameter_name : String) -> String:
	return "p_%s_points" % parameter_name

func serialize() -> Dictionary:
	return { type="Splines", values=Array(get_packed_array()), point_groups=point_groups.duplicate() }

func deserialize(v) -> void:
	if typeof(v) == TYPE_DICTIONARY and v.has("type") and v.type == "Splines":
		splines = []
		for i in range(0, v.values.size(), 4*4):
			var spline : Bezier = Bezier.new()
			splines.append(spline)
			for pi in range(spline.points.size()):
				var p : SplinesPoint = spline.points[pi]
				p.position = Vector2(v.values[i+pi*4], v.values[i+pi*4+1])
				p.width = v.values[i+pi*4+2]
				p.offset = v.values[i+pi*4+3]
		if v.has("point_groups"):
			point_groups = []
			for g in v.point_groups:
				var new_point_group : Array[int] = []
				for p in g:
					new_point_group.append(int(p))
				point_groups.append(new_point_group)
		else:
			point_groups = []
	elif typeof(v) == TYPE_OBJECT and v.get_script() == get_script():
		splines = v.splines.duplicate(true)
	else:
		print("Cannot deserialize splines")
