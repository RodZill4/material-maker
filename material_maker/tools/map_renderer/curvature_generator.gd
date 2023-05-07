# Code ported from:
# https://github.com/blender/blender/blob/594f47ecd2d5367ca936cf6fc6ec8168c2b360d0/intern/cycles/blender/blender_mesh.cpp#L541
@tool
extends Node

const FLT_EPSILON = 1.192092896e-7

func generate(mesh: Mesh) -> Mesh:
	var b_mesh := MeshDataTool.new()
	if not mesh is ArrayMesh:
		b_mesh.create_from_surface(mesh.create_outline(0.0), 0)
	else:
		b_mesh.create_from_surface(mesh, 0)

	var num_verts = b_mesh.get_vertex_count()
	if (num_verts == 0):
		return Mesh.new()

	var b_mesh_vertices := []
	var b_mesh_normals := []
	var b_mesh_edges := []
	for i in b_mesh.get_vertex_count():
		b_mesh_vertices.append(b_mesh.get_vertex(i))
		b_mesh_normals.append(b_mesh.get_vertex_normal(i))
	for i in b_mesh.get_edge_count():
		b_mesh_edges.append([b_mesh.get_edge_vertex(i, 0),
				b_mesh.get_edge_vertex(i, 1)])

	# STEP 1: Find out duplicated vertices and point duplicates to a single
	#         original vertex.
	var sorted_vert_indices := new_filled_array(num_verts, 0)
	for vert_index in num_verts:
		sorted_vert_indices[vert_index] = vert_index
	sorted_vert_indices.sort_custom(Callable(VertexAverageComparator.new(b_mesh_vertices),"sort"))

	# This array stores index of the original vertex for the given vertex
	# index.
	var vert_orig_index := new_filled_array(num_verts, 0)
	for sorted_vert_index in num_verts:
		var vert_index: int = sorted_vert_indices[sorted_vert_index]
		var vert_co: Vector3 = b_mesh_vertices[vert_index]
		var found := false
		for other_sorted_vert_index in range(sorted_vert_index + 1, num_verts):
			var other_vert_index: int = sorted_vert_indices[other_sorted_vert_index]
			var other_vert_co: Vector3 = b_mesh_vertices[other_vert_index]
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

	# STEP 2: Calculate vertex normals taking into account their possible
	#         duplicates which gets "welded" together.
	var vert_normal := new_filled_array(num_verts, Vector3())
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

	# STEP 3: Calculate pointiness using single ring neighborhood.
	var counter := new_filled_array(num_verts, 0)
	var raw_data := new_filled_array(num_verts, 0.0)
	var edge_accum := new_filled_array(num_verts, Vector3())
	var visited_edges := EdgeMap.new()
	for edge_index in b_mesh_edges.size():
		var v0: int = vert_orig_index[b_mesh_edges[edge_index][0]]
		var v1: int = vert_orig_index[b_mesh_edges[edge_index][1]]
		if visited_edges.exists(v0, v1):
			continue
		visited_edges.insert(v0, v1)
		var co0: Vector3 = b_mesh_vertices[v0]
		var co1: Vector3 = b_mesh_vertices[v1]
		var edge = (co1 - co0).normalized()
		edge_accum[v0] += edge
		edge_accum[v1] += -edge
		counter[v0] += 1
		counter[v1] += 1

	for vert_index in num_verts:
		var orig_index: int = vert_orig_index[vert_index]
		if orig_index != vert_index:
			# Skip duplicates, they'll be overwritten later on.
			continue
		if counter[vert_index] > 0:
			var normal: Vector3 = vert_normal[vert_index]
			var angle = acos(clamp(normal.dot(edge_accum[vert_index] / counter[vert_index]), -1.0, 1.0))
			raw_data[vert_index] = angle / PI
		else:
			raw_data[vert_index] = 0.0

	# STEP 3: Blur vertices to approximate 2 ring neighborhood.
	var data := raw_data.duplicate()
	counter = new_filled_array(counter.size(), 0)
	visited_edges.clear()
	for edge_index in b_mesh_edges.size():
		var v0: int = vert_orig_index[b_mesh_edges[edge_index][0]]
		var v1: int = vert_orig_index[b_mesh_edges[edge_index][1]]
		if visited_edges.exists(v0, v1):
			continue
		visited_edges.insert(v0, v1)
		data[v0] += raw_data[v1]
		data[v1] += raw_data[v0]
		counter[v0] += 1
		counter[v1] += 1

	for vert_index in num_verts:
		data[vert_index] /= counter[vert_index] + 1

	# STEP 4: Copy attribute to the duplicated vertices.
	for vert_index in num_verts:
		var orig_index: int = vert_orig_index[vert_index]
		data[vert_index] = data[orig_index]

	# STEP 5: Data gets transferred to the mesh's vertex colors.
	# Since the vertex colors are 8-bit per channel, then we'll have to
	# pack the curvature in the 4 channels to maintain precision.
	for i in data.size():
		var p: float = data[i] * 0.5 + 0.5
		var col := [p, p*255.0, p*255.0*255.0, p*255.0*255.0*255.0]
		col[0] = col[0] - int(col[0])
		col[1] = col[1] - int(col[1])
		col[2] = col[2] - int(col[2])
		col[3] = col[3] - int(col[3])
		col[0] -= col[1] / 255.0
		col[1] -= col[2] / 255.0
		col[2] -= col[3] / 255.0
		b_mesh.set_vertex_color(i, Color(col[0], col[1], col[2], col[3]))

	var new_mesh := ArrayMesh.new()
	var _err := b_mesh.commit_to_surface(new_mesh)

	return new_mesh

func new_filled_array(size: int, data = null) -> Array:
	var array := []
	array.resize(size)
	for i in size:
		array[i] = data
	return array


class EdgeMap:
	var edges := {}

	func insert(v0: int, v1: int) -> void:
		edges[Vector2(v0, v1)] = true

	func exists(v0: int, v1: int) -> bool:
		return edges.has(Vector2(v0, v1)) or edges.has(Vector2(v1, v0))

	func clear() -> void:
		edges.clear()


class VertexAverageComparator:
	var verts_: Array

	func _init(verts: Array):
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
