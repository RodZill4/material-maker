extends Object
class_name MMAdjacencyGenerator


# Code ported from:
# https://github.com/blender/blender/blob/594f47ecd2d5367ca936cf6fc6ec8168c2b360d0/intern/cycles/blender/blender_mesh.cpp#L541


var progress : int = 0
var progress_total : int = 0


func get_progress() -> float:
	if progress_total == 0:
		return 0.0
	return float(progress)/float(progress_total)

func generate(mesh: Mesh) -> Mesh:
	var b_mesh : MeshDataTool = MeshDataTool.new()
	if not mesh is ArrayMesh:
		b_mesh.create_from_surface(mesh.create_outline(0.0), 0)
	else:
		b_mesh.create_from_surface(mesh, 0)
	
	progress = 0
	progress_total = b_mesh.get_vertex_count()
	
	var num_verts = b_mesh.get_vertex_count()
	if (num_verts == 0):
		return Mesh.new()
	
	for i in b_mesh.get_vertex_count():
		b_mesh.set_vertex_normal(i, Vector3(0, 0, 0))
	
	var found_edges : Array[int] = []
	for i in b_mesh.get_edge_count():
		if b_mesh.get_edge_faces(i).size() > 1:
			continue
		if i in found_edges:
			continue
		var i0 : int = b_mesh.get_edge_vertex(i, 0)
		var i1 : int = b_mesh.get_edge_vertex(i, 1)
		var pi0 : Vector3 = b_mesh.get_vertex(i0)
		var pi1 : Vector3 = b_mesh.get_vertex(i1)
		print("Edge ", i, " (", pi0, ", ", pi1,")")
		for j in range(i+1, b_mesh.get_edge_count()):
			var j0 : int = b_mesh.get_edge_vertex(j, 0)
			var j1 : int = b_mesh.get_edge_vertex(j, 1)
			var pj0 = b_mesh.get_vertex(j0)
			var pj1 = b_mesh.get_vertex(j1)
			var uvi0 : Vector2 = b_mesh.get_vertex_uv(i0)
			var uvi1 : Vector2 = b_mesh.get_vertex_uv(i1)
			if pi0 == pj0 and pi1 == pj1:
				print("  Edge ", j, " matches")
				var uvj0 : Vector2 = b_mesh.get_vertex_uv(j0)
				var uvj1 : Vector2 = b_mesh.get_vertex_uv(j1)
				b_mesh.set_vertex_normal(i0, Vector3(uvj0.x, uvj0.y, 0))
				b_mesh.set_vertex_normal(i1, Vector3(uvj1.x, uvj1.y, 0))
				b_mesh.set_vertex_normal(j0, Vector3(uvi0.x, uvi0.y, 0))
				b_mesh.set_vertex_normal(j1, Vector3(uvi1.x, uvi1.y, 0))
			elif pi0 == pj1 and pi1 == pj0:
				print("  Edge ", j, " matches backwards")
				var uvj0 : Vector2 = b_mesh.get_vertex_uv(j0)
				var uvj1 : Vector2 = b_mesh.get_vertex_uv(j1)
				b_mesh.set_vertex_normal(i1, Vector3(uvj0.x, uvj0.y, 0))
				b_mesh.set_vertex_normal(i0, Vector3(uvj1.x, uvj1.y, 0))
				b_mesh.set_vertex_normal(j1, Vector3(uvi0.x, uvi0.y, 0))
				b_mesh.set_vertex_normal(j0, Vector3(uvi1.x, uvi1.y, 0))
			else:
				b_mesh.set_vertex_normal(i0, Vector3(uvi0.x, uvi0.y, 1))
				b_mesh.set_vertex_normal(i1, Vector3(uvi1.x, uvi1.y, 1))
				continue
			print("     Edge ", j, " (", pj0, ", ", pj1,")")
			found_edges.append(j)
			break
	
	var new_mesh : ArrayMesh = ArrayMesh.new()
	var _err := b_mesh.commit_to_surface(new_mesh)
	
	return new_mesh
