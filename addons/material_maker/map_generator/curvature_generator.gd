extends Object
class_name MMCurvatureGenerator


# Code ported from:
# https://github.com/blender/blender/blob/594f47ecd2d5367ca936cf6fc6ec8168c2b360d0/intern/cycles/blender/blender_mesh.cpp#L541


const FLT_EPSILON = 1.192092896e-7


static func generate(mesh: Mesh) -> Mesh:
	var b_mesh : MeshDataTool = MeshDataTool.new()
	if not mesh is ArrayMesh:
		b_mesh.create_from_surface(mesh.create_outline(0.0), 0)
	else:
		b_mesh.create_from_surface(mesh, 0)
	
	var num_verts = b_mesh.get_vertex_count()
	if (num_verts == 0):
		return Mesh.new()
	
	var b_mesh_vertices : Array = []
	var b_mesh_normals : Array = []
	for i in b_mesh.get_vertex_count():
		b_mesh_vertices.append(b_mesh.get_vertex(i))
		b_mesh_normals.append(b_mesh.get_vertex_normal(i))
	
	# STEP 1: Find out duplicated vertices and point duplicates to a single
	#         original vertex.
	var sorted_vert_indices : Array[int] = []
	sorted_vert_indices.resize(num_verts)
	sorted_vert_indices.fill(0)
	for vert_index in num_verts:
		sorted_vert_indices[vert_index] = vert_index
	var comparator : VertexAverageComparator = VertexAverageComparator.new(b_mesh_vertices)
	sorted_vert_indices.sort_custom(comparator.sort)
	
	# This array stores index of the original vertex for the given vertex
	# index.
	var vert_orig_index : Array[int] = []
	vert_orig_index.resize(num_verts)
	vert_orig_index.fill(0)
	for sorted_vert_index in num_verts:
		var vert_index : int = sorted_vert_indices[sorted_vert_index]
		var vert_co : Vector3 = b_mesh_vertices[vert_index]
		var found : bool = false
		for other_sorted_vert_index in range(sorted_vert_index + 1, num_verts):
			var other_vert_index : int = sorted_vert_indices[other_sorted_vert_index]
			var other_vert_co : Vector3 = b_mesh_vertices[other_vert_index]
			# We are too far away now, we wouldn't have duplicate.
			if (other_vert_co.x + other_vert_co.y + other_vert_co.z) - \
				(vert_co.x + vert_co.y + vert_co.z) > 3 * FLT_EPSILON:
				break
			# Found duplicate.
			if (other_vert_co - vert_co).length_squared() < FLT_EPSILON:
				found = true
				vert_orig_index[vert_index] = other_vert_index
				break
	
		if not found:
			vert_orig_index[vert_index] = vert_index
	
	# Make sure we always point to the very first orig vertex.
	for vert_index in num_verts:
		var orig_index: int = vert_orig_index[vert_index]
		while orig_index != vert_orig_index[orig_index]:
			orig_index = vert_orig_index[orig_index]
		vert_orig_index[vert_index] = orig_index
	
	var b_mesh_edges : Array = []
	var known_edges : Dictionary = {}
	var correct : int = 0
	var error1 : int = 0
	var error2 : int = 0
	for i in b_mesh.get_edge_count():
		var v1 : int = vert_orig_index[b_mesh.get_edge_vertex(i, 0)]
		var v2 : int = vert_orig_index[b_mesh.get_edge_vertex(i, 1)]
		var faces : PackedInt32Array = b_mesh.get_edge_faces(i)
		var edge_index : int
		if known_edges.has(Vector2i(v1, v2)):
			edge_index = known_edges[Vector2i(v1, v2)]
			#b_mesh_edges[][2].append_array(b_mesh.get_edge_faces(i))
		elif known_edges.has(Vector2i(v2, v1)):
			edge_index = known_edges[Vector2i(v2, v1)]
			var tmp : int = v1
			v1 = v2
			v2 = tmp
			#b_mesh_edges[known_edges[Vector2i(v2, v1)]][2].append_array(b_mesh.get_edge_faces(i))
		else:
			edge_index = b_mesh_edges.size()
			known_edges[Vector2i(v1, v2)] = edge_index
			b_mesh_edges.append([v1, v2, -1, -1])
		for f in faces:
			var slot = -1
			if v1 == vert_orig_index[b_mesh.get_face_vertex(f, 0)]:
				if v2 == vert_orig_index[b_mesh.get_face_vertex(f, 1)]:
					slot = 0
				elif v2 == vert_orig_index[b_mesh.get_face_vertex(f, 2)]:
					slot = 1
			elif v1 == vert_orig_index[b_mesh.get_face_vertex(f, 1)]:
				if v2 == vert_orig_index[b_mesh.get_face_vertex(f, 2)]:
					slot = 0
				elif v2 == vert_orig_index[b_mesh.get_face_vertex(f, 0)]:
					slot = 1
			elif v1 == vert_orig_index[b_mesh.get_face_vertex(f, 2)]:
				if v2 == vert_orig_index[b_mesh.get_face_vertex(f, 0)]:
					slot = 0
				elif v2 == vert_orig_index[b_mesh.get_face_vertex(f, 1)]:
					slot = 1
			if slot == -1:
				error1 += 1
			elif b_mesh_edges[edge_index][2+slot] != -1:
				error2 += 1
			else:
				correct += 1
				b_mesh_edges[edge_index][2+slot] = f
	print("%d %d %d" % [ correct, error1, error2 ])
	
	# STEP 2: Calculate vertex normals taking into account their possible
	#         duplicates which gets "welded" together.
	var vert_normal : Array[Vector3] = []
	vert_normal.resize(num_verts)
	vert_normal.fill(Vector3())
	# First we accumulate all vertex normals in the original index.
	for vert_index in num_verts:
		var normal: Vector3 = b_mesh_normals[vert_index]
		var orig_index: int = vert_orig_index[vert_index]
		vert_normal[orig_index] += normal
	
	# Then we normalize the accumulated result and flush it to all duplicates
	# as well.
	for vert_index in num_verts:
		var orig_index: int = vert_orig_index[vert_index]
		vert_normal[vert_index] = vert_normal[orig_index].normalized()
	
	# STEP 3: Calculate mean curvature
	var mean_curvature_data : Array[float] = []
	mean_curvature_data.resize(num_verts)
	mean_curvature_data.fill(0.0)
	for edge_index in b_mesh_edges.size():
		var triangle_0 = b_mesh_edges[edge_index][2]
		var triangle_1 = b_mesh_edges[edge_index][3]
		if triangle_0 == -1 or triangle_1 == -1:
			continue
		var v0 : int = vert_orig_index[b_mesh_edges[edge_index][0]]
		var v1 : int = vert_orig_index[b_mesh_edges[edge_index][1]]
		var e : Vector3 = b_mesh_vertices[v1] - b_mesh_vertices[v0]
		var x : float = 0.5*e.length()
		var n0 : Vector3 = b_mesh.get_face_normal(triangle_0)
		var n1 : Vector3 = b_mesh.get_face_normal(triangle_1)
		var cosTheta : float = n0.dot(n1);
		var sinTheta : float = n0.cross(n1).dot(e.normalized());
		mean_curvature_data[v0] -= x * atan2(sinTheta, cosTheta)
		mean_curvature_data[v1] -= x * atan2(sinTheta, cosTheta)

	# STEP 4: Walk triangles to calculate Gaussian and mean curvatures
	var gaussian_angles : Array[float] = []
	gaussian_angles.resize(num_verts)
	gaussian_angles.fill(0.0)
	var area_data : Array[float] = []
	area_data.resize(num_verts)
	area_data.fill(0.0)
	for f in b_mesh.get_face_count():
		var a : int = vert_orig_index[b_mesh.get_face_vertex(f, 0)]
		var b : int = vert_orig_index[b_mesh.get_face_vertex(f, 1)]
		var c : int = vert_orig_index[b_mesh.get_face_vertex(f, 2)]
		var va : Vector3 = b_mesh_vertices[a]
		var vb : Vector3 = b_mesh_vertices[b]
		var vc : Vector3 = b_mesh_vertices[c]
		var a_a : float = (vb-va).angle_to(vc-va)
		var a_b : float = (vc-vb).angle_to(va-vb)
		var a_c : float = (va-vc).angle_to(vb-vc)
		var ts_div_3 : float = (vb-va).cross(vc-va).length()/6.0
		gaussian_angles[a] += a_a
		gaussian_angles[b] += a_b
		gaussian_angles[c] += a_c
		area_data[a] += ts_div_3
		area_data[b] += ts_div_3
		area_data[c] += ts_div_3
	
	# FINAL STEP: Data gets transferred to the vertex info f the mesh
	for i in num_verts:
		var orig_index : int = vert_orig_index[i]
		var H : float = mean_curvature_data[orig_index]/area_data[orig_index]
		var K : float = (2*PI-gaussian_angles[orig_index])/area_data[orig_index]
		var discriminant : float = H*H-K
		if discriminant < 0:
			discriminant = 0
		b_mesh.set_vertex(i, Vector3(H+sqrt(discriminant), H-sqrt(discriminant), 0))
	
	var new_mesh : ArrayMesh = ArrayMesh.new()
	var _err := b_mesh.commit_to_surface(new_mesh)
	
	return new_mesh


class EdgeMap:
	var edges : Dictionary = {}

	func insert(v0: int, v1: int) -> void:
		edges[Vector2i(v0, v1)] = true

	func exists(v0: int, v1: int) -> bool:
		return edges.has(Vector2i(v0, v1)) or edges.has(Vector2i(v1, v0))

	func clear() -> void:
		edges.clear()


class VertexAverageComparator:
	var verts_: Array

	func _init(verts: Array) -> void:
		verts_ = verts

	func sort(vert_idx_a: int, vert_idx_b: int) -> bool:
		var vert_a: Vector3 = verts_[vert_idx_a]
		var vert_b: Vector3 = verts_[vert_idx_b]
		if vert_a.is_equal_approx(vert_b):
			# Special case for doubles, so we ensure ordering.
			return vert_idx_a > vert_idx_b
		var x1 := vert_a.x + vert_a.y + vert_a.z
		var x2 := vert_b.x + vert_b.y + vert_b.z
		return x1 < x2
