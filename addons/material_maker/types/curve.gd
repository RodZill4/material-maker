extends Object
class_name MMCurve

class Point:
	var p : Vector2
	var ls : float
	var rs : float
	func _init(x : float, y : float, nls : float, nrs : float) -> void:
		p = Vector2(x, y)
		ls = nls
		rs = nrs

var points = [ Point.new(0.0, 0.0, 0.0, 1.0), Point.new(1.0, 1.0, 1.0, 0.0) ]

func to_string() -> String:
	var rv = PoolStringArray()
	for p in points:
		rv.append("("+str(p.x)+","+str(p.y)+","+str(p.ls)+","+str(p.rs)+")")
	return rv.join(",")

func duplicate() -> Object:
	var copy = get_script().new()
	copy.clear()
	for p in points:
		copy.add_point(p.p.x, p.p.y, p.ls, p.rs)
	return copy

func clear() -> void:
	points.clear()

func add_point(x : float, y : float, ls : float = INF, rs : float = INF) -> void:
	for i in points.size():
		if x < points[i].p.x:
			if ls == INF:
				ls = 0
			if rs == INF:
				rs = 0
			points.insert(i, Point.new(x, y, ls, rs))
			return
	points.append(Point.new(x, y, ls, rs))

func remove_point(index : int) -> bool:
	if index <= 0 or index >= points.size() - 1:
		return false
	else:
		points.remove(index)
	return true

func get_point_count() -> int:
	return points.size()

func set_point(i : int, v : Point) -> void:
	points[i] = v

func get_shader_params(name) -> Dictionary:
	var rv = {}
	for i in range(points.size()):
		rv["p_"+name+"_"+str(i)+"_x"] = points[i].p.x
		rv["p_"+name+"_"+str(i)+"_y"] = points[i].p.y
		rv["p_"+name+"_"+str(i)+"_ls"] = points[i].ls
		rv["p_"+name+"_"+str(i)+"_rs"] = points[i].rs
	return rv

func get_shader(name) -> String:
	var shader
	shader = "float "+name+"_curve_fct(float x) {\n"
	for i in range(points.size()-1):
		if i < points.size()-2:
			shader += "if (x <= p_"+name+"_"+str(i+1)+"_x) "
		shader += "{\n"
		shader += "float dx = x - p_"+name+"_"+str(i)+"_x;\n"
		shader += "float d = p_"+name+"_"+str(i+1)+"_x - p_"+name+"_"+str(i)+"_x;\n"
		shader += "float t = dx/d;\n"
		shader += "float omt = (1.0 - t);\n"
		shader += "float omt2 = omt * omt;\n"
		shader += "float omt3 = omt2 * omt;\n"
		shader += "float t2 = t * t;\n"
		shader += "float t3 = t2 * t;\n"
		shader += "d /= 3.0;\n"
		shader += "float y1 = p_"+name+"_"+str(i)+"_y;\n"
		shader += "float yac = p_"+name+"_"+str(i)+"_y + d*p_"+name+"_"+str(i)+"_rs;\n"
		shader += "float ybc = p_"+name+"_"+str(i+1)+"_y - d*p_"+name+"_"+str(i+1)+"_ls;\n"
		shader += "float y2 = p_"+name+"_"+str(i+1)+"_y;\n"
		shader += "return y1*omt3 + yac*omt2*t*3.0 + ybc*omt*t2*3.0 + y2*t3;\n"
		shader += "}\n"
	shader += "}\n"
	return shader

func serialize() -> Dictionary:
	var rv = []
	for p in points:
		rv.append({ x=p.p.x, y=p.p.y, ls=p.ls, rs=p.rs })
	return { type="Curve", points=rv }

func deserialize(v) -> void:
	clear()
	if typeof(v) == TYPE_DICTIONARY and v.has("type") and v.type == "Curve":
		for p in v.points:
			add_point(p.x, p.y, p.ls, p.rs)
	elif typeof(v) == TYPE_OBJECT and v.get_script() == get_script():
		clear()
		for p in v.points:
			add_point(p.p.x, p.p.y, p.ls, p.rs)
	else:
		print("Cannot deserialize curve")
