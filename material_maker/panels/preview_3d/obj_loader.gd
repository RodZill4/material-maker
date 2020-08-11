extends Node

func _ready():
	pass # Replace with function body.

func count(string, txt):
	var num = 0
	for i in range(0, string.length()):
		if (txt == string[i]):
			num += 1
	return num

func load_obj_file(path) -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	#st.set_material(mat)
	var mdlFile = File.new()
	mdlFile.open(path, File.READ)
	
	var mdlVerts = []
	var mdlNorm = []
	var mdlUV = []
	
	var mdlFaceIndex = []
	var mdlUVIndex = []
	var mdlNormIndex = []
	
	while !mdlFile.eof_reached():
		var mdlData = mdlFile.get_line()
		if mdlData.begins_with("v "):
			var vertData = mdlData.split(" ", false)
			var vertex = Vector3(
			float(vertData[1]),
			float(vertData[2]),
			float(vertData[3]))
			
			mdlVerts.push_back(vertex)
		elif mdlData.begins_with("vt"):
			var uvData = mdlData.split(" ", false)
			var uv = Vector2(
			float(uvData[1]),
			1.0 - float(uvData[2]))
			
			mdlUV.push_back(uv)
		elif mdlData.begins_with("vn"):
			var normData = mdlData.split(" ", false)
			var normal = Vector3(
			float(normData[1]),
			float(normData[2]),
			float(normData[3]))
			
			mdlNorm.push_back(normal)
		elif mdlData.begins_with("f "):
			var miscData = mdlData.split(" ", false)
			var misc = []
			
			var num = count(mdlData, "/")
			
			if num == 6:
				misc.push_back(miscData[1].split("/"))
				misc.push_back(miscData[2].split("/"))
				misc.push_back(miscData[3].split("/"))
				
				var faceIndices = Vector3(
				int(misc[2][0]) - 1,
				int(misc[1][0]) - 1,
				int(misc[0][0]) - 1)
				
				var uvIndices = Vector3(
				int(misc[2][1]) - 1,
				int(misc[1][1]) - 1,
				int(misc[0][1]) - 1)
				
				var normIndices = Vector3(
				int(misc[2][2]) - 1,
				int(misc[1][2]) - 1,
				int(misc[0][2]) - 1)
				
				mdlFaceIndex.push_back(faceIndices)
				mdlUVIndex.push_back(uvIndices)
				mdlNormIndex.push_back(normIndices)
			elif num == 3:
				misc.push_back(miscData[1].split("/"))
				misc.push_back(miscData[2].split("/"))
				
				var faceIndices = Vector3(
				int(misc[2][0]) - 1,
				int(misc[1][0]) - 1,
				int(misc[0][0]) - 1)
				
				var uvIndices = Vector3(
				int(misc[2][1]) - 1,
				int(misc[1][1]) - 1,
				int(misc[0][1]) - 1)
				
				mdlFaceIndex.push_back(faceIndices)
				mdlUVIndex.push_back(uvIndices)
			elif num == 0:
				var faceIndices = Vector3(
				int(miscData[3]) - 1,
				int(miscData[2]) - 1,
				int(miscData[1]) - 1)
				
				mdlFaceIndex.push_back(faceIndices)
			elif num > 6:
				for i in miscData.size() - 1:
					misc.push_back(miscData[i + 1].split("/"))
				var faceIndices = []
				var uvIndices = []
				var normIndices = []
				for i in misc.size() - 2:
					var intVar = i + 2
					faceIndices.push_back(Vector3(
					int(misc[intVar][0]) - 1,
					int(misc[intVar-1][0]) - 1,
					int(misc[0][0]) - 1))
					
					uvIndices.push_back(Vector3(
					int(misc[intVar][1]) - 1,
					int(misc[intVar-1][1]) - 1,
					int(misc[0][1]) - 1))
					
					normIndices.push_back(Vector3(
					int(misc[intVar][2]) - 1,
					int(misc[intVar-1][2]) - 1,
					int(misc[0][2]) - 1))
					
					mdlFaceIndex.push_back(faceIndices[i])
					mdlUVIndex.push_back(uvIndices[i])
					mdlNormIndex.push_back(normIndices[i])
			else:
				print("MODEL NOT VALID!")
		elif mdlData.begins_with("s "):
			var smooth = mdlData.substr(2, mdlData.length()).strip_edges()
			if smooth == "off":
				st.add_smooth_group(false)
			else:
				st.add_smooth_group(true)
	for i in mdlFaceIndex.size():
		if mdlUV.size() > 0:
			st.add_uv(mdlUV[mdlUVIndex[i][0]])
		if mdlNorm.size() > 0:
			st.add_normal(mdlNorm[mdlNormIndex[i][0]])
		st.add_vertex(mdlVerts[mdlFaceIndex[i][0]])
		
		if mdlUV.size() > 0:
			st.add_uv(mdlUV[mdlUVIndex[i][1]])
		if mdlNorm.size() > 0:
			st.add_normal(mdlNorm[mdlNormIndex[i][1]])
		st.add_vertex(mdlVerts[mdlFaceIndex[i][1]])
		
		if mdlUV.size() > 0:
			st.add_uv(mdlUV[mdlUVIndex[i][2]])
		if mdlNorm.size() > 0:
			st.add_normal(mdlNorm[mdlNormIndex[i][2]])
		st.add_vertex(mdlVerts[mdlFaceIndex[i][2]])
	if mdlNorm.size() == 0:
		st.generate_normals()
	st.generate_tangents()
	var mdl = Mesh.new()
	mdl = st.commit()
	return mdl
