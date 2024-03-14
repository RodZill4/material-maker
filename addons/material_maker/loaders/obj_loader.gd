extends RefCounted

static func load_obj_file(path : String) -> ArrayMesh:
	if path == null:
		return null
	var ext := path.get_extension()
	if !ext.matchn("obj"):
		print("given file isn't an OBJ mesh")
		return null
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mdlFile : FileAccess = FileAccess.open(path, FileAccess.READ)
	if mdlFile == null:
		print("cannot open file at path[", path,"]")
		mdlFile.close()
		return null
	var newTriMsh : TriMesh = _import_obj(mdlFile)
	mdlFile.close()
	
	var hasTex := newTriMsh.uvs.size() > 0
	var hasNrm := newTriMsh.normals.size() > 0
	
	for i in newTriMsh.indices.size():
		var triangle : Triangle = newTriMsh.indices[i]
		if hasTex:
			st.set_uv(newTriMsh.uvs[triangle.uv_id_0])
		if hasNrm:
			st.set_normal(newTriMsh.normals[triangle.nrm_id_0])
		st.add_vertex(newTriMsh.vertices[triangle.id_0])
		
		if hasTex:
			st.set_uv(newTriMsh.uvs[triangle.uv_id_1])
		if hasNrm:
			st.set_normal(newTriMsh.normals[triangle.nrm_id_1])
		st.add_vertex(newTriMsh.vertices[triangle.id_1])
		
		if hasTex:
			st.set_uv(newTriMsh.uvs[triangle.uv_id_2])
		if hasNrm:
			st.set_normal(newTriMsh.normals[triangle.nrm_id_2])
		st.add_vertex(newTriMsh.vertices[triangle.id_2])
	
	if !hasNrm:
		st.generate_normals()
	if hasTex:
		st.generate_tangents()
	var mdl : ArrayMesh = st.commit()
	
	return mdl

static func _obj_rel_indice(indice : Vector3, cur_vArr_size : int) -> Vector3:
	var output := Vector3.ZERO
	var indSign := indice.sign()
	output.x = indice.x - 1 if (indSign.x >= 0) else cur_vArr_size + indice.x
	output.y = indice.y - 1 if (indSign.y >= 0) else cur_vArr_size + indice.y
	output.z = indice.z - 1 if (indSign.z >= 0) else cur_vArr_size + indice.z
	
	return output

static func _import_obj(mdlFile : FileAccess) -> TriMesh:
	var newMsh := TriMesh.new()
	
	while !mdlFile.eof_reached():
		var mdlData := mdlFile.get_line()
		if mdlData.begins_with("#"):
			continue
		
		var f2c = mdlData.substr(0, 2)
		var lineData := mdlData.split(" ", false)
		
		match f2c:
			"v ":
				var vertex := Vector3(
					float(lineData[1]),
					float(lineData[2]),
					float(lineData[3])
				)
				newMsh.vertices.push_back(vertex)
			"vt":
				var uv := Vector2(
					float(lineData[1]),
					1.0 - float(lineData[2])
				)
				newMsh.uvs.push_back(uv)
			"vn":
				var normal := Vector3(
					float(lineData[1]),
					float(lineData[2]),
					float(lineData[3])
				)
				newMsh.normals.push_back(normal)
			"f ":
				var misc = []
				
				for i in lineData.size() - 1:
					misc.push_back(lineData[i + 1].split("/"))
				for i in misc.size() - 2:
					var intVar : int = i + 2
					var num : int = misc[intVar].size()
					var vArr_size : int = newMsh.vertices.size()
					var tArr_size : int = newMsh.uvs.size()
					var nArr_size : int = newMsh.normals.size()
					
					var faceIndices = Vector3(
					int(misc[intVar][0]),
					int(misc[intVar-1][0]),
					int(misc[0][0]))
					faceIndices = _obj_rel_indice(faceIndices, vArr_size)
					
					var uvIndices : Vector3
					if num >= 2:
						uvIndices = Vector3(
						int(misc[intVar][1]),
						int(misc[intVar-1][1]),
						int(misc[0][1]))
					uvIndices = _obj_rel_indice(uvIndices, tArr_size)
					
					var normIndices : Vector3
					if num == 3:
						normIndices = Vector3(
						int(misc[intVar][2]),
						int(misc[intVar-1][2]),
						int(misc[0][2]))
					normIndices = _obj_rel_indice(normIndices, nArr_size)
					
					var triangle := Triangle.new()
					
					triangle.id_0 = int(faceIndices.x)
					triangle.id_1 = int(faceIndices.y)
					triangle.id_2 = int(faceIndices.z)
					
					triangle.uv_id_0 = int(uvIndices.x)
					triangle.uv_id_1 = int(uvIndices.y)
					triangle.uv_id_2 = int(uvIndices.z)
					
					triangle.nrm_id_0 = int(normIndices.x)
					triangle.nrm_id_1 = int(normIndices.y)
					triangle.nrm_id_2 = int(normIndices.z)
					
					newMsh.indices.push_back(triangle)
	
	return newMsh

class TriMesh:
	var vertices : Array
	var normals : Array
	var uvs : Array
	var indices : Array

class Triangle:
	var id_0 : int
	var uv_id_0 : int
	var nrm_id_0 : int
	var id_1 : int
	var uv_id_1 : int
	var nrm_id_1 : int
	var id_2 : int
	var uv_id_2 : int
	var nrm_id_2 : int
